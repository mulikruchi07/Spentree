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

    const body = await req.json();
    // Only encrypt fields the caller actually sent — a partial update
    // (e.g. just daily_limit) must not touch the other three fields.
    const { daily_limit, goal, category_preference, profile_image_url } = body;

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const masterKey = await importMasterKey();
    const dek = await getOrCreateUserDek(adminClient, user.id, masterKey);

    const updatePayload: Record<string, string | null> = {};

    if (daily_limit !== undefined) {
      updatePayload.daily_limit =
        daily_limit === null ? null : await encryptField(dek, String(daily_limit));
    }
    if (goal !== undefined) {
      updatePayload.goal =
        goal === null ? null : await encryptField(dek, String(goal));
    }
    if (category_preference !== undefined) {
      updatePayload.category_preference =
        category_preference === null
          ? null
          : await encryptField(dek, String(category_preference));
    }
    if (profile_image_url !== undefined) {
      updatePayload.profile_image_url =
        profile_image_url === null
          ? null
          : await encryptField(dek, String(profile_image_url));
    }

    if (Object.keys(updatePayload).length === 0) {
      return new Response(
        JSON.stringify({ error: "No fields provided to encrypt" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { error: updateError } = await adminClient
  .from("users")
  .upsert({ id: user.id, ...updatePayload }); // was .update(updatePayload).eq("id", user.id)

if (updateError) {
  return new Response(JSON.stringify({ error: updateError.message }), {
    status: 500,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("encrypt-user-fields failed:", e);
    return new Response(
      JSON.stringify({ error: e?.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});