import test from 'node:test';
import assert from 'node:assert/strict';
import {renderPlatformAdmin,paymentCSV} from '../src/ui/platform-admin.js';
import {ReperaAuthAPI} from '../src/core/auth.js';

const id='12345678-1234-4234-9234-123456789abc';
const orgs=[
 {id,name:'Gimnasio <script>alert(1)</script>',kind:'gym',email:'gym@example.org',slug:'gym',
  client_count:10,active_clients:8,member_count:3,sessions:7,status:'active',created_at:'2026-10-20T00:00:00Z'},
 {id:'12345678-1234-4234-9234-123456789abd',name:'Coach',kind:'personal_trainer',slug:'coach',
  client_count:4,active_clients:3,status:'suspended',created_at:'2026-10-21T00:00:00Z'}
];
const base={orgs,finance:{payments:[],intents:[]},pending:[],history:[],plans:[],filter:{search:'',status:'all',org:'all',paymentStatus:'all'}};

test('La navegación del administrador es independiente y evita HTML inyectado',()=>{
 const output=renderPlatformAdmin({...base,tab:'home',email:'admin@example.org'});
 for(const label of ['Gimnasios','Entrenadores','Usuarios y clientes','Pagos','Soporte','Auditoría','Planes y precios'])
  assert.ok(output.includes(label),label);
 assert.ok(output.includes('11')); // 8 + 3 relaciones activas
 assert.ok(!output.includes('<script>'));
 assert.ok(output.includes('repera'));
});

test('Directorio separa gimnasios y entrenadores, filtra por estado y búsqueda',()=>{
 const gyms=renderPlatformAdmin({...base,tab:'gyms',filter:{...base.filter,search:'Gimnasio'}});
 assert.match(gyms,/Gimnasio &lt;script&gt;/);
 assert.doesNotMatch(gyms,/Coach<\/button>/);
 const suspended=renderPlatformAdmin({...base,tab:'trainers',filter:{...base.filter,status:'suspended'}});
 assert.match(suspended,/Coach/);
 assert.match(suspended,/Suspendido/);
 const blank=renderPlatformAdmin({...base,tab:'gyms',filter:{...base.filter,search:'sin-coincidencia'}});
 assert.match(blank,/No se encontraron negocios/);
});

test('Detalle incorpora configuración, estado y delegación motivada',()=>{
 const output=renderPlatformAdmin({...base,tab:'gyms',selectedOrg:id});
 assert.match(output,/Perfil y configuración/);
 assert.match(output,/data-admin-form="delegate"/);
 assert.match(output,/Motivo del acceso delegado/);
 assert.match(output,/data-admin-form="status"/);
 assert.match(output,/30 minutos/);
});

test('Cobros vacíos nunca simulan ingresos y CSV está escapado',()=>{
 const output=renderPlatformAdmin({...base,tab:'payments'});
 assert.match(output,/No hay cobros verificados/);
 assert.match(output,/0,00/);
 const csv=paymentCSV(orgs,{payments:[{org_id:id,amount_cents:1100,created_at:'2026-10-25',
  status:'paid',currency:'EUR',provider:'stripe'}]},{org:'all',paymentStatus:'paid'});
 assert.match(csv,/1100/);
 assert.match(csv,/Gimnasio <script>/); // safe in CSV, quoted
 assert.match(csv,/Fecha;Negocio;Importe_centimos/);
 const injection=paymentCSV([{...orgs[0],name:'=CMD(1)'}],{payments:[{org_id:id,amount_cents:150,created_at:'2026-10-25',status:'paid',currency:'EUR',provider:'stripe'}]},{org:'all',paymentStatus:'paid'});
 assert.ok(injection.includes("'=CMD(1)"),'Excel formulas must not be evaluated');
 const b2c=paymentCSV(orgs,{payments:[],client_payments:[{org_id:id,amount_cents:2800,created_at:'2026-10-26',status:'paid',currency:'EUR',provider:'stripe_connect'}]},
  {paymentScope:'b2c',paymentStatus:'paid',org:'all',dateFrom:'2026-10-25'});
 assert.match(b2c,/2800/);
 const ignored=paymentCSV(orgs,{client_payments:[{org_id:id,amount_cents:2800,created_at:'2026-10-26',status:'paid',currency:'EUR',provider:'stripe_connect'}]},
  {paymentScope:'b2c',paymentStatus:'paid',org:'all',dateFrom:'2026-10-27'});
 assert.ok(!ignored.includes('2800'));
});

test('Operaciones administrativas solo llaman RPC con JWT y validan argumentos',async()=>{
 const calls=[];
 const fetcher=async(url,options)=>{
  calls.push({url,options});
  if(url.includes('grant_type=password'))return {ok:true,status:200,text:async()=>JSON.stringify({access_token:'token',refresh_token:'refresh',expires_in:3600})};
  if(url.endsWith('/auth/v1/user'))return {ok:true,status:200,text:async()=>JSON.stringify({id})};
  return {ok:true,status:200,text:async()=>JSON.stringify([])};
 };
 const api=new ReperaAuthAPI({publishableKey:'sb_publishable_test-only',
  storage:{getItem(){return null},setItem(){},removeItem(){}},fetcher});
 await api.signIn('admin@example.org','password');
 await api.platformAdminDirectory();
 await api.platformAdminProvision({name:'Nuevo centro',kind:'gym',email:'OWNER@EXAMPLE.ORG'});
 await api.platformAdminDelegate({orgId:id,reason:'Comprobar incidencias notificadas'});
 await api.platformAdminEndDelegation();
 const rpc=calls.filter(c=>c.url.includes('/rpc/'));
 assert.equal(rpc.length,4);
 assert.deepEqual(JSON.parse(rpc[1].options.body),{p_name:'Nuevo centro',p_kind:'gym',p_email:'owner@example.org',p_plan:null});
 assert.equal(rpc[2].options.headers.Authorization,'Bearer token');
 await assert.rejects(()=>api.platformAdminDelegate({orgId:id,reason:'sin motivo'}),/motivo/);
 await assert.rejects(()=>api.platformAdminProvision({name:'A',kind:'gym',email:'bad'}),/Revisa/);
});
