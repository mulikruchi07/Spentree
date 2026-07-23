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

    const body = await req.json();
    const {
      action,
      cloud_id,
      amount,
      receiver_name,
      category,
      type,
      date_time,
      is_hidden,
      sms_hash,
    } = body;

    if (action !== "insert" && action !== "update") {
      return new Response(
        JSON.stringify({ error: "action must be 'insert' or 'update'" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    if (action === "update" && !cloud_id) {
      return new Response(
        JSON.stringify({ error: "cloud_id is required for update" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    if (
      amount === undefined ||
      receiver_name === undefined ||
      category === undefined ||
      type === undefined ||
      date_time === undefined
    ) {
      return new Response(
        JSON.stringify({
          error:
            "amount, receiver_name, category, type, and date_time are all required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Admin client — bypasses RLS deliberately. Safe here because we already
    // verified `user` above, and every write below is scoped to user.id.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const masterKey = await importMasterKey();
    const dek = await getOrCreateUserDek(adminClient, user.id, masterKey);

    const encryptedRow = {
      user_id: user.id,
      amount: await encryptField(dek, String(amount)),
      receiver_name: await encryptField(dek, String(receiver_name)),
      category: await encryptField(dek, String(category)),
      type: await encryptField(dek, String(type)),
      date_time: await encryptField(dek, String(date_time)),
      is_hidden: Boolean(is_hidden ?? false),
      sms_hash: sms_hash ?? null,
    };

    if (action === "insert") {
      const { data, error } = await adminClient
        .from("transactions")
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
        .from("transactions")
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
        return new Response(
          JSON.stringify({ error: "Transaction not found" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const { error } = await adminClient
        .from("transactions")
        .update(encryptedRow)
        .eq("id", cloud_id);

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  } catch (e) {
    console.error("encrypt-transaction failed:", e);
    return new Response(
      JSON.stringify({ error: e?.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});