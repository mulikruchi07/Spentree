import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // The caller must be holding a valid session — in practice this is
    // always the short-lived RECOVERY session created by verifyOtp() on
    // the OTP step, never a normal logged-in session.
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: userError } = await callerClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { password } = await req.json()
    if (!password || typeof password !== 'string' || password.length < 8) {
      return new Response(JSON.stringify({ error: 'Invalid password' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    // The password only ever actually changes here — the very last step
    // of the whole reset flow, after email + OTP have both been verified.
    const { error: updateError } = await adminClient.auth.admin.updateUserById(user.id, { password })
    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Revoke every refresh token for this account — including the Flutter
    // app, if it's signed in there — so the change forces a fresh login
    // everywhere, not just in this browser tab.
    //
    // IMPORTANT: there is no `/admin/users/{id}/logout` REST endpoint in
    // GoTrue (an earlier version of this function called that path, which
    // is why it silently did nothing). The real mechanism is the ordinary
    // sign-out endpoint (`/auth/v1/logout`) called WITH `scope: 'global'`
    // — and per Supabase's own docs, that revokes every refresh token
    // belonging to the session's user, not just the current session. We
    // can call it here because callerClient is already authenticated as
    // that exact user (it's bound to the recovery-session token they sent
    // this function).
    try {
      await callerClient.auth.signOut({ scope: 'global' })
    } catch (revokeErr) {
      // Password change already succeeded — a failed revoke call here
      // isn't fatal, just less complete. Log it and move on.
      console.error('Session revoke warning (password was still changed):', revokeErr)
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    console.error('complete-password-reset failed:', e)
    return new Response(JSON.stringify({ error: e.message ?? 'Unknown error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})