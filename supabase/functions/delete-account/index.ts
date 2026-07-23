import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), { status: 401 })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { error: txError } = await adminClient.from('transactions').delete().eq('user_id', user.id)
    if (txError) throw new Error(`transactions: ${txError.message}`)

    const { error: wrapError } = await adminClient.from('monthly_wraps').delete().eq('user_id', user.id)
    if (wrapError) throw new Error(`monthly_wraps: ${wrapError.message}`)

    const { error: storageError } = await adminClient.storage.from('avatar').remove([`${user.id}/profile.jpg`])
    if (storageError && !storageError.message.includes('not found')) {
      console.error('Storage delete warning:', storageError.message)
    }

    const { error: rowError } = await adminClient.from('users').delete().eq('id', user.id)
    if (rowError) throw new Error(`users: ${rowError.message}`)

    const { error: authError } = await adminClient.auth.admin.deleteUser(user.id)
    if (authError) throw new Error(`auth.deleteUser: ${authError.message}`)

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    console.error('delete-account failed:', e)
    return new Response(JSON.stringify({ error: e.message ?? 'Unknown error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})