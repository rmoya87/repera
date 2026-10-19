import test from 'node:test';import assert from 'node:assert/strict';import {SupabaseBusinessAPI} from '../src/core/backend.js';
const id='12345678-1234-4234-9234-123456789abc';
test('Supabase REST requiere sesión real, dominio exacto y clave pública',async()=>{
 assert.throws(()=>new SupabaseBusinessAPI({baseUrl:'http://evil.test',publishableKey:'pk',sessionProvider:()=>id}),/HTTPS/);
 assert.throws(()=>new SupabaseBusinessAPI({baseUrl:'https://foo.supabase.co',publishableKey:'sb_secret_fake',sessionProvider:()=>id}),/inválida/);
 const api=new SupabaseBusinessAPI({baseUrl:'https://foo.supabase.co',publishableKey:'sb_publishable_fake',sessionProvider:()=>null,fetcher:async()=>{throw Error('NO DEBE CONSULTAR')}});
 await assert.rejects(()=>api.list('clients',id),/Inicia sesión/);
});
test('API no permite acceder a recursos arbitrarios ni usar IDs no UUID',async()=>{
 const api=new SupabaseBusinessAPI({baseUrl:'https://foo.supabase.co',publishableKey:'pk',sessionProvider:()=>id,fetcher:async()=>({ok:true,json:async()=>[]})});
 await assert.rejects(()=>api.list('auth.users',id),/no autorizado/);
 await assert.rejects(()=>api.list('clients','org-fit'),/inválida/);
 await assert.rejects(()=>api.list('clients',id,{limit:100000}),/Paginación/);
});
test('API envía el JWT al backend, no service_role, y parámetros exactos',async()=>{
 let captured={};const api=new SupabaseBusinessAPI({baseUrl:'https://repera.supabase.co',publishableKey:'public',sessionProvider:()=> 'jwt-from-supabase',fetcher:async(url,init)=>{captured={url,init};return {ok:true,status:200,json:async()=>[{id}]};}});
 const result=await api.bookClass({orgId:id,classId:id,clientId:id,requestId:id});assert.equal(result[0].id,id);
 assert.ok(captured.url.endsWith('rpc/book_class'));
 assert.equal(captured.init.headers.Authorization,'Bearer jwt-from-supabase');assert.equal(captured.init.headers.apikey,'public');
 assert.deepEqual(JSON.parse(captured.init.body),{_org:id,_class:id,_client:id,_request:id});
});
