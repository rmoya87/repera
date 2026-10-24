import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
const sql = await readFile(new URL('../../supabase/migrations/20261024162744_ai_oauth_connections.sql',import.meta.url),'utf8');
const owner='11111111-1111-4111-8111-111111111111';
const other='22222222-2222-4222-8222-222222222222';
const client='33333333-3333-4333-8333-333333333333';
const session='44444444-4444-4444-8444-444444444444';
async function setup() {
  const db=new PGlite();
  await db.exec(`CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS; CREATE ROLE supabase_auth_admin; CREATE ROLE authenticator;
    CREATE SCHEMA auth; CREATE TABLE auth.sessions(id uuid,user_id uuid,oauth_client_id uuid,created_at timestamptz,not_after timestamptz);
    CREATE TABLE public.ai_access_tokens(id uuid primary key default gen_random_uuid(),owner_id uuid,label text,token_prefix text,token_hash text unique,created_at timestamptz default now(),expires_at timestamptz,revoked_at timestamptz,last_used_at timestamptz,scopes text[]);
    GRANT ALL ON public.ai_access_tokens TO service_role;`);
  await db.exec(sql);
  await db.query(`update public.ai_oauth_providers set enabled=true,client_id=$1 where id='chatgpt'`,[client]);
  return db;
}
async function grant(db,write=true,hash='a'.repeat(64)) {
  return (await db.query('select public.create_ai_oauth_grant($1,$2,$3,$4) as id',[owner,client,write,hash])).rows[0].id;
}
async function resolve(db,user=owner,sid=session) {
  return (await db.query('select * from public.resolve_ai_oauth_grant($1,$2,$3)',[user,client,sid])).rows;
}
test('grant resolves only for its athlete, client, live session and read/write permission',async()=>{
  const db=await setup();
  try {
    const id=await grant(db,false);
    await db.query(`insert into auth.sessions values($1,$2,$3,now()+interval '1 second',null)`,[session,owner,client]);
    assert.equal((await resolve(db))[0].id,id);
    assert.deepEqual((await resolve(db))[0].scopes,['training:read']);
    assert.deepEqual(await resolve(db,other),[]);
    assert.deepEqual(await resolve(db,owner,other),[]);
    await db.query(`update public.ai_access_tokens set revoked_at=now() where id=$1`,[id]);
    assert.deepEqual(await resolve(db),[]);
  } finally {await db.close();}
});
test('reconnect cannot revive a previously issued/refreshable OAuth session',async()=>{
  const db=await setup();
  try {
    const first=await grant(db);
    await db.query(`insert into auth.sessions values($1,$2,$3,now()-interval '1 hour',null)`,[session,owner,client]);
    const second=await grant(db,false,'b'.repeat(64));
    assert.notEqual(first,second);
    assert.deepEqual(await resolve(db),[]);
    assert.equal((await db.query('select count(*)::int as n from ai_access_tokens where revoked_at is null')).rows[0].n,1);
    await db.query(`update auth.sessions set created_at=now()+interval '1 second' where id=$1`,[session]);
    assert.equal((await resolve(db))[0].id,second);
    await db.exec(`update ai_oauth_providers set enabled=false`);
    assert.deepEqual(await resolve(db),[]);
  }finally{await db.close();}
});
test('expired sessions and expired grants are rejected',async()=>{
  const db=await setup();
  try {
    await grant(db);
    await db.query(`insert into auth.sessions values($1,$2,$3,now()+interval '1 second',now()-interval '1 minute')`,[session,owner,client]);
    assert.deepEqual(await resolve(db),[]);
    await db.exec(`update auth.sessions set not_after=null; update ai_access_tokens set expires_at=now()-interval '1 minute'`);
    assert.deepEqual(await resolve(db),[]);
  }finally{await db.close();}
});
test('hook isolates delegated tokens and leaves native tokens untouched',async()=>{
  const db=await setup();
  try {
    const native={claims:{sub:owner,role:'authenticated',aud:'authenticated'}};
    const delegated={...native,client_id:client};
    const run=async e=>(await db.query('select repera_oauth.access_token_hook($1::jsonb) as e',[JSON.stringify(e)])).rows[0].e;
    assert.deepEqual(await run(native),native);
    assert.equal((await run(delegated)).claims.role,'repera_mcp');
    assert.equal((await run(delegated)).claims.aud,'https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp');
    assert.equal((await run({claims:{...native.claims,client_id:client}})).claims.role,'repera_mcp');
    const rights=(await db.query(`select has_function_privilege('authenticated','public.create_ai_oauth_grant(uuid,uuid,boolean,text)','execute') as create_grant,
      has_function_privilege('anon','public.resolve_ai_oauth_grant(uuid,uuid,uuid)','execute') as resolve,
      pg_has_role('authenticator','repera_mcp','member') as can_impersonate,
      has_table_privilege('repera_mcp','public.ai_access_tokens','select') as read_tokens`)).rows[0];
    assert.deepEqual(rights,{create_grant:false,resolve:false,can_impersonate:false,read_tokens:false});
  }finally{await db.close();}
});
