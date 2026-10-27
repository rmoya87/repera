import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderPlatformAdmin} from '../src/ui/platform-admin.js';
import {ReperaAuthAPI} from '../src/core/auth.js';

const centerId='6915d93b-e8ff-4f44-aaf0-14d1a8d183f6';
const athleteId='f79094a6-a9d0-4bc8-916b-ce50628ab6a2';
const org={id:centerId,name:'Centro Prueba',kind:'gym',status:'pending',registration_status:'pending',
 client_count:1,active_clients:1,member_count:2,sessions:3};
const athlete={id:athleteId,name:'Atleta Individual',email:'atleta@example.org',center_count:0,confirmed:true};
const base={orgs:[org],athletes:[athlete],finance:{payments:[],intents:[]},pending:[],history:[],plans:[],
 filter:{search:'',kind:'all',status:'all',paymentStatus:'all',paymentScope:'b2b'},email:'admin@example.org'};
const show=props=>renderPlatformAdmin({...base,...props});

test('El favicon web es el archivo binario original de AppIcon en iOS',()=>{
 const native=readFileSync(new URL('../../../Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png',import.meta.url));
 const web=readFileSync(new URL('../../assets/repera-app-icon.png',import.meta.url));
 assert.ok(native.equals(web));
 const html=readFileSync(new URL('../index.html',import.meta.url),'utf8');
 assert.match(html,/repera-app-icon.png/);
});

test('Barra lateral sin marca repetida, plegable y sin entrada de auditoría',()=>{
 const html=show({tab:'home'});
 assert.doesNotMatch(html,/class="pa-brand"/);
 assert.doesNotMatch(html,/class="pa-sidebar-label"/);
 assert.doesNotMatch(html,/data-admin-tab="audit"/);
 assert.match(html,/data-admin-action="toggle-sidebar"/);
 assert.match(show({tab:'home',collapsed:true}),/pa-shell is-collapsed/);
});

test('Centro: cuatro indicadores, datos fiscales, equipo, clientes y acceso directo',()=>{
 const detail={center:{is_discoverable:false},legal:{legal_name:'Centro Fiscal S.L.',tax_id:'ABC123'},
 team:[{name:'Entrenador',email:'coach@example.org',role:'coach',status:'active'}],
 clients:[{name:'Atleta Individual',user_id:athleteId,email:'atleta@example.org',status:'active'}],
 groups:[],services:[],payments:[],booking_count:2,training_count:1,client_count:1};
 const html=show({tab:'centers',selectedOrg:centerId,centerDetail:detail});
 assert.match(html,/pa-center-metrics/);
 assert.match(html,/Centro Fiscal S\.L\./);
 assert.match(html,/coach@example.org/);
 assert.match(html,/atleta@example.org/);
 assert.match(html,/data-admin-action="view-athlete"/);
 assert.match(html,/data-admin-action="access-center"/);
 assert.match(html,/data-admin-form="status"/);
 assert.doesNotMatch(html,/Motivo del acceso delegado|data-admin-form="delegate"/);
});

test('Atleta: muestra accesos, vinculaciones, ejercicios y datos estructurados sin inyección',()=>{
 const detail={account:{...athlete,email_confirmed_at:'2026-10-01',last_sign_in_at:'2026-10-25',role:'user'},
 workout_count:1,booking_count:0,training_count:0,memberships:[],client_profiles:[],
 providers:['email'],programs:[],reservations:[],professional_sessions:[],training_profile:null};
 const workout={id:'w',title:'Fuerza <script>alert(1)</script>',started_at:'2026-10-27',
 exercises:[{name:'Sentadilla',sets:[{reps:5,weight:80}]}],wod_results:[]};
 const html=show({tab:'athletes',selectedAthlete:athleteId,
  athleteData:detail,athleteWorkouts:[workout]});
 assert.match(html,/Último inicio de sesión/);
 assert.match(html,/Entrenamientos registrados/);
 assert.match(html,/Sentadilla/);
 assert.match(html,/80/);
 assert.match(html,/Ver ejercicios y resultados/);
 assert.doesNotMatch(html,/<script>/);
 assert.doesNotMatch(html,/data-admin-action="more-athlete-workouts"/);
});

test('Los cinco filtros de pagos comparten fila y la auditoría sigue siendo interna',()=>{
 const html=show({tab:'payments'});
 assert.match(html,/pa-payments-filters/);
 assert.equal((html.match(/data-admin-filter="(?:paymentScope|org|paymentStatus|dateFrom|dateTo)"/g)||[]).length,5);
 const css=readFileSync(new URL('../src/platform-admin-polish.css',import.meta.url),'utf8');
 assert.match(css,/pa-payments-filters/);
 assert.match(css,/grid-template-columns:minmax\(185px/);
});

test('Configuración ofrece prueba real de negocio y distingue integraciones pendientes',()=>{
 const html=show({tab:'admin-settings',settings:{trial_days:14,support_email:'help@example.org'}});
 assert.match(html,/data-admin-form="platform-trial"/);
 assert.match(html,/value="14"/);
 assert.match(html,/Stripe Billing/);
 assert.match(html,/Emails y notificaciones/);
 assert.match(html,/Monitorización y continuidad/);
});

test('RPCs de fichas y ajustes usan JWT del administrador y comprueban parámetros',async()=>{
 const calls=[],values=new Map();
 const fetcher=async(url,options)=>{
  calls.push({url,options});
  let result=[];
  if(url.includes('grant_type=password'))
   result={access_token:'jwt',refresh_token:'refresh',expires_in:3600};
  if(url.endsWith('/auth/v1/user')&&options.method==='GET')result={id:athleteId};
  return {ok:true,status:200,text:async()=>JSON.stringify(result)};
 };
 const auth=new ReperaAuthAPI({publishableKey:'sb_publishable_test',
  fetcher,storage:{getItem:k=>values.get(k)||null,setItem:(k,v)=>values.set(k,v),removeItem:k=>values.delete(k)}});
 await auth.signIn('admin@example.org','password');
 await auth.platformAdminCenterDetail(centerId);
 await auth.platformAdminAthleteDetail(athleteId);
 await auth.platformAdminAthleteWorkouts(athleteId,0,30);
 await auth.platformAdminSaveTrialDays(14);
 const rpcs=calls.filter(c=>c.url.includes('/rpc/'));
 assert.equal(rpcs.length,4);
 assert.ok(rpcs.every(c=>c.options.headers.Authorization==='Bearer jwt'));
 assert.deepEqual(JSON.parse(rpcs[3].options.body),{p_days:14});
 await assert.rejects(()=>auth.platformAdminSaveTrialDays(0),/periodo/);
 await assert.rejects(()=>auth.platformAdminAthleteWorkouts(athleteId,-1,30),/Paginación/);
});
