// @ts-nocheck
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { Client } from 'https://deno.land/x/postgres@v0.17.0/mod.ts'
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' }
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  const client = new Client(Deno.env.get('SUPABASE_DB_URL') ?? '')
  await client.connect()
  const r = []
  const { rows: mario } = await client.queryArray(`SELECT id, email, referral_code, points FROM public.users WHERE email = 'mario.rossi@cdm86.com'`)
  r.push({ check: 'mario_rossi', found: mario.length > 0, data: mario[0] ? { id: mario[0][0], email: mario[0][1], referral_code: mario[0][2], points: mario[0][3] } : null })
  const { rows: allUsers } = await client.queryArray(`SELECT email, referral_code, points, created_at FROM public.users ORDER BY created_at DESC`)
  r.push({ check: 'all_users', count: allUsers.length, list: allUsers.map(u => ({ email: u[0], referral_code: u[1], points: u[2] })) })
  const { rows: triggerCheck } = await client.queryArray(`SELECT tgname, tgenabled FROM pg_trigger WHERE tgname = 'on_auth_user_created'`)
  r.push({ check: 'trigger_active', found: triggerCheck.length > 0, enabled: triggerCheck[0]?.[1] })
  const { rows: policyCheck } = await client.queryArray(`SELECT policyname, roles FROM pg_policies WHERE schemaname='public' AND tablename='users' AND cmd='INSERT'`)
  r.push({ check: 'insert_policies', data: policyCheck.map(p => ({ name: p[0], roles: p[1] })) })
  await client.end()
  return new Response(JSON.stringify(r, null, 2), { headers: { ...cors, 'Content-Type': 'application/json' } })
})
