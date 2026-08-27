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

    // Verify the caller's identity using their own JWT.
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

    // Admin client — bypasses RLS deliberately. Safe here because we already
    // verified `user` above, and every write below is scoped to user.id.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // ------------------------------------------------------------------
    // PRO GATE — Buckets is a fully Pro feature. This is the actual
    // security boundary; the app's UI hiding the Buckets icon/screen for
    // Free users is convenience only. ANY failure to positively confirm
    // Pro (RPC error, missing row) is treated as "not Pro" — fail closed.
    // ------------------------------------------------------------------
    const { data: isProRaw, error: entitlementError } = await adminClient.rpc(
      "is_user_pro",
      { uid: user.id },
    );
    const isPro = entitlementError ? false : isProRaw === true;

    if (!isPro) {
      return new Response(
        JSON.stringify({ error: "pro_required" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const body = await req.json();
    const { action, cloud_id, name, transaction_ids } = body;

    if (
      action !== "insert" &&
      action !== "update" &&
      action !== "delete"
    ) {
      return new Response(
        JSON.stringify({ error: "Invalid action" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // DELETE
    // Delete does not require name or transaction_ids.
    if (action === "delete") {
      if (!cloud_id) {
        return new Response(
          JSON.stringify({ error: "cloud_id is required" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Verify that the bucket belongs to the authenticated user.
      const { data: existing, error: fetchError } = await adminClient
        .from("buckets")
        .select("user_id")
        .eq("id", cloud_id)
        .maybeSingle();

      if (fetchError) {
        return new Response(
          JSON.stringify({ error: fetchError.message }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (!existing || existing.user_id !== user.id) {
        return new Response(
          JSON.stringify({ error: "Bucket not found" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const { error } = await adminClient
        .from("buckets")
        .delete()
        .eq("id", cloud_id);

      if (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({ success: true, id: cloud_id }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // UPDATE still requires cloud_id.
    if (action === "update" && !cloud_id) {
      return new Response(
        JSON.stringify({ error: "cloud_id is required for update" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // These validations are ONLY for insert/update.
    if (name === undefined || !Array.isArray(transaction_ids)) {
      return new Response(
        JSON.stringify({
          error: "name and transaction_ids (array) are both required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // A bucket must hold at least 2 expenses.
    if (transaction_ids.length < 2) {
      return new Response(
        JSON.stringify({
          error: "A bucket must include at least 2 expenses",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const masterKey = await importMasterKey();
    const dek = await getOrCreateUserDek(adminClient, user.id, masterKey);

    const encryptedRow = {
      user_id: user.id,
      name: await encryptField(dek, String(name)),
      transaction_ids: transaction_ids.map((id: unknown) => String(id)),
      updated_at: new Date().toISOString(),
    };

    if (action === "insert") {
      const { data, error } = await adminClient
        .from("buckets")
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
      // update — verify the row actually belongs to this user before writing.
      const { data: existing, error: fetchError } = await adminClient
        .from("buckets")
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
        return new Response(JSON.stringify({ error: "Bucket not found" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { error } = await adminClient
        .from("buckets")
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
    console.error("encrypt-bucket failed:", e);
    return new Response(
      JSON.stringify({ error: e?.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});