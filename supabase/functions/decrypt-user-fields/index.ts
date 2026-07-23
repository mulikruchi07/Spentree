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

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: row, error: fetchError } = await adminClient
      .from("users")
      .select("daily_limit, goal, category_preference, profile_image_url")
      .eq("id", user.id)
      .maybeSingle();

    if (fetchError) {
      return new Response(JSON.stringify({ error: fetchError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!row) {
      return new Response(
        JSON.stringify({
          daily_limit: null,
          goal: null,
          category_preference: null,
          profile_image_url: null,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const masterKey = await importMasterKey();
    const dek = await getOrCreateUserDek(adminClient, user.id, masterKey);

    async function safeDecrypt(value: string | null): Promise<string | null> {
      if (!value) return null;
      try {
        return await decryptField(dek, value);
      } catch (e) {
        console.error("Field decrypt failed, returning null:", e);
        return null;
      }
    }

    const result = {
      daily_limit: await safeDecrypt(row.daily_limit),
      goal: await safeDecrypt(row.goal),
      category_preference: await safeDecrypt(row.category_preference),
      profile_image_url: await safeDecrypt(row.profile_image_url),
    };

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("decrypt-user-fields failed:", e);
    return new Response(
      JSON.stringify({ error: e?.message ?? "Unknown error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});