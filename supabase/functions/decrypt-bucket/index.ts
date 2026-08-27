import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  importMasterKey,
  getOrCreateUserDek,
  decryptField,
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

    // Ignore any user_id the client sends — always use the authenticated
    // caller's own id, so nobody can pass someone else's id to read their data.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // ------------------------------------------------------------------
    // PRO GATE — Buckets is a fully Pro feature. A downgraded former-Pro
    // user (or a Free user who somehow still has stale local bucket rows
    // on-device) must never have this pull function hand bucket data back
    // down. ANY failure to positively confirm Pro is treated as "not Pro."
    // Returning an empty array (not an error) here is deliberate: this
    // function runs during the normal startup sync sweep, and "you have no
    // buckets" is the correct, quiet outcome for a Free user rather than a
    // surfaced error.
    // ------------------------------------------------------------------
    const { data: isProRaw, error: entitlementError } = await adminClient.rpc(
      "is_user_pro",
      { uid: user.id },
    );
    const isPro = entitlementError ? false : isProRaw === true;

    if (!isPro) {
      return new Response(JSON.stringify([]), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: rows, error: fetchError } = await adminClient
      .from("buckets")
      .select("id, name, transaction_ids, created_at, updated_at")
      .eq("user_id", user.id);

    if (fetchError) {
      return new Response(JSON.stringify({ error: fetchError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!rows || rows.length === 0) {
      return new Response(JSON.stringify([]), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const masterKey = await importMasterKey();
    const dek = await getOrCreateUserDek(adminClient, user.id, masterKey);

    const decrypted = [];
    for (const row of rows) {
      try {
        decrypted.push({
          id: row.id,
          name: await decryptField(dek, row.name),
          transaction_ids: row.transaction_ids ?? [],
          created_at: row.created_at,
          updated_at: row.updated_at,
        });
      } catch (fieldError) {
        // One bad/corrupt row should never take down the whole sync —
        // skip it and keep going, same defensive spirit as your SMS parser.
        console.error(`Failed to decrypt bucket ${row.id}:`, fieldError);
      }
    }

    return new Response(JSON.stringify(decrypted), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("decrypt-bucket failed:", e);
    return new Response(
      JSON.stringify({ error: e?.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});