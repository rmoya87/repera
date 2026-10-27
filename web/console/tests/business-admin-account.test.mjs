import test from 'node:test';
import assert from 'node:assert/strict';
import {ReperaAuthAPI} from '../src/core/auth.js';
import {renderPlatformAdmin} from '../src/ui/platform-admin.js';

const uid='12345678-1234-4234-9234-123456789abc';
const response=data=>({ok:true,status:200,text:async()=>JSON.stringify(data)});

test('Las consultas de atletas y ajustes usan JWT de Supabase y nunca service role',async()=>{
 const calls=[],store=new Map();
 const api=new ReperaAuthAPI({publishableKey:'sb_publishable_test-only',
  storage:{getItem:key=>store.get(key)||null,setItem:(key,val)=>store.set(key,val),removeItem:key=>store.delete(key)},
  fetcher:async(url,options)=>{
   calls.push({url,options});
   if(url.includes('grant_type=password'))return response({access_token:'test-JWT',refresh_token:'test-refresh',expires_in:3600});
   if(url.endsWith('/auth/v1/user')&&options.method==='GET')return response({id:uid,email:'admin@example.org'});
   if(url.endsWith('/rpc/platform_admin_athletes'))return response([{id:uid,email:'admin@example.org',center_count:0}]);
   if(url.endsWith('/rpc/platform_admin_settings'))return response({support_email:'test@example.org'});
   if(url.includes('/profiles?'))return response([{id:uid,role:'platform_admin',avatar_url:'https://example.org/avatar.jpg',display_name:'Admin'}]);
   return response([]);
  }});
 await api.signIn('admin@example.org','password-123456');
 assert.equal((await api.platformAdminAthletes())[0].center_count,0);
 assert.equal((await api.platformAdminSettings()).support_email,'test@example.org');
 assert.equal((await api.myProfile()).avatar_url,'https://example.org/avatar.jpg');
 await api.platformAdminSaveSettings({support_email:'new@example.org',support_url:'https://example.org/help'});
 await api.updateOwnProfile({displayName:'Admin Nuevo'});
 await api.changeOwnEmail('newadmin@example.org');
 const rpc=calls.filter(x=>x.url.includes('/rpc/'));
 assert.deepEqual(JSON.parse(rpc.find(x=>x.url.endsWith('platform_admin_update_settings')).options.body),{
  p_support_email:'new@example.org',p_support_url:'https://example.org/help',
  p_billing_email:'',p_privacy_url:'',p_terms_url:''});
 assert.ok(rpc.every(x=>x.options.headers.Authorization==='Bearer test-JWT'));
 assert.ok(!calls.some(x=>JSON.stringify(x).includes('service_role')||JSON.stringify(x).includes('sb_secret_')));
 const profile=calls.find(x=>x.options.method==='PATCH'&&x.url.includes('profiles?'));
 assert.deepEqual(JSON.parse(profile.options.body),{display_name:'Admin Nuevo'});
 const emailUpdate=calls.find(x=>x.options.method==='PUT'&&x.url.endsWith('/auth/v1/user'));
 assert.deepEqual(JSON.parse(emailUpdate.options.body),{email:'newadmin@example.org'});
});

test('La cuenta se integra en el menú inferior y no aparece un badge de conexión',()=>{
 const output=renderPlatformAdmin({email:'admin@example.org',account:{
  display_name:'Admin Nuevo',avatar_url:'https://example.org/avatar.jpg'}});
 assert.match(output,/data-admin-tab="account"/);
 assert.match(output,/Admin Nuevo/);
 assert.match(output,/avatar.jpg/);
 assert.doesNotMatch(output,/Supabase conectado/);
});

test('El formulario de alta incluye imagen optimizable y la opción de centro',()=>{
 const output=renderPlatformAdmin({tab:'provision',email:'admin@example.org'});
 assert.match(output,/data-admin-image-file/);
 assert.match(output,/data-admin-image-preview/);
 assert.match(output,/data-provision-kind/);
 assert.match(output,/avatarFile/);
});
