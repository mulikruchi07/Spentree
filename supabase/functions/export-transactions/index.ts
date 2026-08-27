import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  importMasterKey,
  getOrCreateUserDek,
  decryptField,
} from "../_shared/crypto.ts";

// SECURITY MODEL
// ----------------------------------------------------------------------------
// This is the only place export-window enforcement lives. `transactions`
// stores sensitive fields (amount, receiver_name, date_time) as ciphertext,
// so we CANNOT range-filter by date at the SQL level the way a plaintext
// column would allow — `date_time` in Postgres is just an opaque encrypted
// string here. Enforcement therefore happens in this order:
//
//   1. Resolve the caller's identity from their own JWT (never from
//      anything the client sends in the body).
//   2. Ask Postgres, server-side, whether that caller is Pro right now
//      (is_user_pro RPC — same authoritative check used everywhere else).
//   3. Fetch every non-hidden transaction row for that user and decrypt it.
//   4. Only AFTER decrypting do we know each row's real date — filter the
//      resolved (server-decided, not client-decided) window at that point.
//
// A Free user's client can ask for any start/end date it wants; what it
// gets back is still clamped/rejected based on step 2, computed here, not
// trusted from the request body.
// ----------------------------------------------------------------------------

const FREE_EXPORT_WINDOW_DAYS = 15;

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

    // Verify the caller's identity using their own JWT — nothing else in
    // this function trusts anything the client claims about who it is.
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

    // Authoritative entitlement check. ANY failure here (RPC error,
    // missing row, null) resolves to "not Pro" — never the other way.
    const { data: isProRaw, error: entitlementError } = await adminClient.rpc(
      "is_user_pro",
      { uid: user.id },
    );
    const isPro = entitlementError ? false : isProRaw === true;

    const body = await req.json().catch(() => ({}));
    const requestedStart = body?.start_date ? new Date(body.start_date) : null;
    const requestedEnd = body?.end_date ? new Date(body.end_date) : null;

    if (!requestedStart || isNaN(requestedStart.getTime())) {
      return new Response(JSON.stringify({ error: "start_date is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const now = new Date();
    const requestedEndResolved =
      requestedEnd && !isNaN(requestedEnd.getTime()) ? requestedEnd : now;

    let effectiveStart = requestedStart;

    if (!isPro) {
      const earliestAllowed = new Date(now);
      earliestAllowed.setUTCDate(
        earliestAllowed.getUTCDate() - (FREE_EXPORT_WINDOW_DAYS - 1),
      );
      earliestAllowed.setUTCHours(0, 0, 0, 0);

      if (requestedStart < earliestAllowed) {
        return new Response(
          JSON.stringify({
            error: "free_export_window_exceeded",
            allowed_from: earliestAllowed.toISOString(),
          }),
          {
            status: 403,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
      // Belt and suspenders: even a "valid" free request can't be clamped
      // wider than the allowed window server-side.
      if (effectiveStart < earliestAllowed) effectiveStart = earliestAllowed;
    }

    // Fetch every non-hidden, non-deleted row for this user. We cannot
    // filter by date_time in SQL (it's ciphertext) — filtering happens
    // below, after decryption, against the resolved window computed above.
    const { data: encryptedRows, error: fetchError } = await adminClient
      .from("transactions")
      .select("id, amount, receiver_name, category, date_time, type, is_hidden")
      .eq("user_id", user.id)
      .eq("is_hidden", false);

    if (fetchError) {
      console.error("export-transactions fetch error:", fetchError);
      return new Response(JSON.stringify({ error: "fetch_failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const masterKey = await importMasterKey();
    const dek = await getOrCreateUserDek(adminClient, user.id, masterKey);

    const rows: Record<string, unknown>[] = [];

    for (const row of encryptedRows ?? []) {
      try {
        const decryptedDateStr = await decryptField(dek, row.date_time as string);
        const decryptedDate = new Date(decryptedDateStr);
        if (isNaN(decryptedDate.getTime())) continue;

        if (
          decryptedDate < effectiveStart ||
          decryptedDate > requestedEndResolved
        ) {
          continue; // outside the resolved (server-decided) window
        }

        rows.push({
          id: row.id,
          amount: await decryptField(dek, row.amount as string),
          receiver_name: await decryptField(dek, row.receiver_name as string),
          category: await decryptField(dek, row.category as string),
          date_time: decryptedDate.toISOString(),
          type: await decryptField(dek, row.type as string),
        });
      } catch (fieldError) {
        // One bad/corrupt row should never take down the whole export —
        // skip it and keep going, same defensive spirit as decrypt-transaction.
        console.error(`Failed to decrypt transaction ${row.id}:`, fieldError);
      }
    }

    rows.sort((a, b) =>
      String(a.date_time).localeCompare(String(b.date_time)),
    );

    return new Response(JSON.stringify({ rows }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("export-transactions fatal error:", e);
    return new Response(
      JSON.stringify({ error: e?.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
