import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  importMasterKey,
  getOrCreateUserDek,
  encryptField,
} from "../_shared/crypto.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await callerClient.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // ------------------------------------------------------------------
    // PRO GATE — Smart Budgets is a fully Pro feature, same as Buckets.
    // ANY failure to positively confirm Pro is treated as "not Pro."
    // ------------------------------------------------------------------
    const { data: isProRaw, error: entitlementError } = await adminClient.rpc(
      "is_user_pro",
      { uid: user.id },
    );
    const isPro = entitlementError ? false : isProRaw === true;

    if (!isPro) {
      return new Response(JSON.stringify({ error: "pro_required" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { action, cloud_id, category, limit_amount, month_year } = body;

    if (action !== "insert" && action !== "update" && action !== "delete") {
      return new Response(JSON.stringify({ error: "Invalid action" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // DELETE
    if (action === "delete") {
      if (!cloud_id) {
        return new Response(
          JSON.stringify({ error: "cloud_id is required" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      const { data: existing, error: fetchError } = await adminClient
        .from("budgets")
        .select("user_id")
        .eq("id", cloud_id)
        .maybeSingle();

      if (fetchError) {
        return new Response(JSON.stringify({ error: fetchError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (!existing || existing.user_id !== user.id) {
        return new Response(JSON.stringify({ error: "Budget not found" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { error } = await adminClient
        .from("budgets")
        .delete()
        .eq("id", cloud_id);

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true, id: cloud_id }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "update" && !cloud_id) {
      return new Response(
        JSON.stringify({ error: "cloud_id is required for update" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (
      category === undefined ||
      limit_amount === undefined ||
      month_year === undefined
    ) {
      return new Response(
        JSON.stringify({
          error: "category, limit_amount, and month_year are all required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const masterKey = await importMasterKey();
    const dek = await getOrCreateUserDek(adminClient, user.id, masterKey);

    const encryptedRow = {
      user_id: user.id,
      category: await encryptField(dek, String(category)),
      limit_amount: await encryptField(dek, String(limit_amount)),
      month_year: String(month_year), // plain — needed for querying
      updated_at: new Date().toISOString(),
    };

    if (action === "insert") {
      const { data, error } = await adminClient
        .from("budgets")
        .insert(encryptedRow)
        .select("id")
        .single();

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ id: data.id }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } else {
      const { data: existing, error: fetchError } = await adminClient
        .from("budgets")
        .select("user_id")
        .eq("id", cloud_id)
        .maybeSingle();

      if (fetchError) {
        return new Response(JSON.stringify({ error: fetchError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (!existing || existing.user_id !== user.id) {
        return new Response(JSON.stringify({ error: "Budget not found" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { error } = await adminClient
        .from("budgets")
        .update(encryptedRow)
        .eq("id", cloud_id);

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true, id: cloud_id }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  } catch (e) {
    console.error("encrypt-budget failed:", e);
    return new Response(
      JSON.stringify({ error: e?.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});