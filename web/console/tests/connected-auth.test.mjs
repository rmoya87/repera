import test from 'node:test';
import assert from 'node:assert/strict';
import {ReperaAuthAPI} from '../src/core/auth.js';
const base='https://uvzgujlrqohreoucirms.supabase.co',key='sb_publishable_test-only',userId='12345678-1234-4234-9234-123456789abc';
const storage=()=>{const s=new Map();return {getItem:k=>s.get(k)||null,setItem:(k,v)=>s.set(k,v),removeItem:k=>s.delete(k)};};
const response=(data,status=200)=>({ok:status>=200&&status<300,status,text:async()=>JSON.stringify(data)});
test('Bloquea dominio ajeno y claves privadas',()=>{
 assert.throws(()=>new ReperaAuthAPI({baseUrl:'https://cafe.supabase.co',publishableKey:key,fetcher:()=>{}}),/no autorizado/);
 assert.throws(()=>new ReperaAuthAPI({publishableKey:'sb_secret_private',fetcher:()=>{}}),/clave pública/);
});
test('Sesión real, orgs RLS, alta propietaria y logout local (sin falsos roles)',async()=>{
 const calls=[];let clock=1_000_000;
 const client=new ReperaAuthAPI({publishableKey:key,storage:storage(),clock:()=>clock,fetcher:async(url,options)=>{
  calls.push({url,options});const path=url.slice(base.length);
  if(path.includes('grant_type=password'))return response({access_token:'access-JWT',refresh_token:'refresh-1',expires_in:3600});
  if(path==='/auth/v1/user')return response({id:userId,email:'owner@example.test'});
  if(path.startsWith('/rest/v1/organizations?')&&options.method==='POST')return response([{id:'org1',name:'Norte'}],201);
  if(path.startsWith('/rest/v1/organizations?'))return response([]);
  if(path.startsWith('/rest/v1/organization_memberships?'))return response([]);
  if(path.startsWith('/auth/v1/logout?scope=local'))return response({},204);
  throw Error('Ruta inesperada '+path);
 }});
 const user=await client.signIn('owner@example.test','pass-123456');assert.equal(user.id,userId);
 assert.deepEqual(await client.organizations(),[]);
 await client.createOrganization({name:'Norte',slug:'norte-gym',kind:'gym',userId});
 const write=calls.find(x=>x.options.method==='POST'&&x.url.includes('/rest/v1/organizations'));
 assert.equal(JSON.parse(write.options.body).created_by,userId);assert.equal(write.options.headers.Authorization,'Bearer access-JWT');
 await client.signOut();assert.equal(await client.token(),null);
 assert.ok(calls.some(x=>x.url.includes('scope=local')));
});
test('Renovación serializada y sesión caducada sin mezclar tokens',async()=>{
 let clock=1_000_000,refreshes=0;
 const client=new ReperaAuthAPI({publishableKey:key,storage:storage(),clock:()=>clock,fetcher:async(url)=>{
  if(url.includes('grant_type=password'))return response({access_token:'initial',refresh_token:'r1',expires_in:100});
  if(url.includes('grant_type=refresh_token')){refreshes++;return response({access_token:'renewed',refresh_token:'r2',expires_in:3600});}
  if(url.endsWith('/auth/v1/user'))return response({id:userId});
  return response([]);
 }});
 await client.signIn('a@b.test','password');clock+=20_000;
 const tokens=await Promise.all([client.token(),client.token(),client.token()]);
 assert.deepEqual(tokens,['renewed','renewed','renewed']);assert.equal(refreshes,1);
});
test('Alta con correo a confirmar no falsifica sesión; rechaza ID/slug inválidos',async()=>{
 const client=new ReperaAuthAPI({publishableKey:key,storage:storage(),fetcher:async(url)=>url.includes('/signup')?response({user:{id:userId}}):response([])});
 assert.equal((await client.signUp('x@y.es','mypassword','https://repera.app/console/')).confirmationRequired,true);
 assert.equal(await client.token(),null);
 await assert.rejects(()=>client.createOrganization({name:'X',slug:'invalid',kind:'gym',userId}),/Comprueba/);
});
