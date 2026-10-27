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
 for(const label of ['Centros','Atletas','Pagos','Soporte','Auditoría','Planes y precios'])
  assert.ok(output.includes(label),label);
 assert.ok(output.includes('11')); // 8 + 3 relaciones activas
 assert.ok(!output.includes('<script>'));
 assert.ok(output.includes('repera'));
});

test('Centros unifica los tipos y filtra con columna de categoría',()=>{
 const all=renderPlatformAdmin({...base,tab:'centers'});
 assert.match(all,/Coach/);
 assert.match(all,/Entrenador personal/);
 assert.match(all,/Gimnasio &lt;script&gt;/);
 assert.match(all,/Tipo/);
 const gyms=renderPlatformAdmin({...base,tab:'centers',filter:{...base.filter,search:'Gimnasio'}});
 assert.doesNotMatch(gyms,/Coach<\/button>/);
 const suspended=renderPlatformAdmin({...base,tab:'centers',filter:{...base.filter,status:'suspended'}});
 assert.match(suspended,/Coach/);
 assert.match(suspended,/Suspendido/);
 const blank=renderPlatformAdmin({...base,tab:'centers',filter:{...base.filter,search:'sin-coincidencia'}});
 assert.match(blank,/No hay centros con esos filtros/);
});

test('Atletas incluye perfiles sin gimnasio, avatares y administradores',()=>{
 const athletes=[{name:'Atleta sin centro',id:'x',email:'atleta@example.org',center_count:0,
    avatar_url:'https://example.org/athlete.jpg',confirmed:true,created_at:'2026-10-27'},
   {name:'Admin',id:'y',email:'admin@example.org',center_count:0,platform_role:'platform_admin',confirmed:true}];
 const html=renderPlatformAdmin({...base,tab:'athletes',athletes});
 assert.match(html,/Atleta sin centro/);
 assert.match(html,/Sin centro/);
 assert.match(html,/athlete.jpg/);
 assert.match(html,/Administrador de plataforma/);
});

test('Configuración de plataforma y cuenta permiten acciones reales',()=>{
 const settings=renderPlatformAdmin({...base,tab:'admin-settings',settings:{support_email:'help@example.org'}});
 assert.match(settings,/data-admin-form="platform-settings"/);
 assert.match(settings,/help@example.org/);
 const account=renderPlatformAdmin({...base,tab:'account',email:'admin@example.org',
  account:{display_name:'Administrador',avatar_url:'https://example.org/admin.jpg'}});
 assert.match(account,/data-admin-form="account-profile"/);
 assert.match(account,/data-admin-form="account-password"/);
 assert.match(account,/data-admin-form="account-email"/);
 assert.match(account,/admin.jpg/);
 assert.doesNotMatch(account,/Supabase conectado/);
});

test('Planes se muestran agrupados y se edita solo un formulario',()=>{
 const plan={plan_key:'gym_one',title:'Gimnasio Pro',audience:'gym',monthly_price_cents:3900,is_active:true,display_order:1};
 const html=renderPlatformAdmin({...base,tab:'plans',plans:[plan]});
 assert.match(html,/Gimnasios y centros/);
 assert.match(html,/data-admin-action="edit-plan"/);
 assert.doesNotMatch(html,/data-connected="save-plan"/);
 const edit=renderPlatformAdmin({...base,tab:'plans',plans:[plan],editingPlan:'gym_one'});
 assert.match(edit,/data-connected="save-plan"/);
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
