import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {deriveCoachingInsights,renderAthleteInsights} from '../src/ui/athlete-insights.js';
import {renderClient360} from '../src/ui/management-360.js';
import {renderPlatformAdmin} from '../src/ui/platform-admin.js';
import {ReperaAuthAPI} from '../src/core/auth.js';

const uid='f79094a6-a9d0-4bc8-916b-ce50628ab6a2',org='6915d93b-e8ff-4f44-aaf0-14d1a8d183f6';
const workout={title:'Fuerza',started_at:'2026-10-25T09:00:00Z',exercises:[
 {blockId:'secret',exercise:{name:'Sentadilla',muscleGroup:'Cuadriceps'},loggedSets:[{reps:5,weightKg:80,rir:2}]},
 {blockId:'secret',exercise:{name:'Remo',muscleGroup:'Espalda'},plannedSets:[{reps:10,weightKg:100}]}
]};
test('PR y e1RM sólo de series registradas, no de prescripciones',()=>{
 const insights=deriveCoachingInsights([workout]);
 assert.equal(insights.best.length,1);
 assert.equal(insights.best[0].bestKg,80);
 assert.ok(insights.best[0].e1rm>93&&insights.best[0].e1rm<94);
 assert.ok(insights.rating>=0&&insights.rating<=100);
 const html=renderAthleteInsights([workout],1);
 assert.match(html,/Mapa de grupos trabajados/);
 assert.match(html,/e1RM aprox/);
 assert.match(html,/no certifica nivel profesional/i);
 assert.doesNotMatch(html,/blockId|isFavorite/);
});

test('El administrador separa Ejercicios, Datos, Acceso y Reservas; los centros también usan pestañas',()=>{
 const athlete={id:uid,name:'Atleta',email:'atleta@example.org'};
 const base={orgs:[{id:org,name:'Gimnasio',kind:'gym',status:'active'}],athletes:[athlete],email:'admin@example.org',plans:[]};
 const data={account:{name:'Atleta',email:'atleta@example.org'},client_profiles:[],workout_count:1,
 memberships:[],reservations:[],professional_sessions:[],providers:[]};
 const exercise=renderPlatformAdmin({...base,selectedAthlete:uid,athleteData:data,
 athleteWorkouts:[workout],activityMonth:'2026-10',activityDay:'2026-10-25',
 activityDayWorkouts:[workout],athleteSection:'exercises'});
 assert.match(exercise,/pa-athlete-hero/);
 assert.match(exercise,/pa-athlete-training-grid/);
 assert.doesNotMatch(exercise,/<h1>Ficha de atleta/);
 const access=renderPlatformAdmin({...base,selectedAthlete:uid,athleteData:data,athleteSection:'access'});
 assert.match(access,/Acceso/);
 const center=renderPlatformAdmin({...base,selectedOrg:org,centerDetail:{center:{is_discoverable:false},
 team:[],clients:[],services:[],groups:[],payments:[]},centerSection:'data'});
 assert.match(center,/data-admin-form="center-visibility"/);
 assert.match(center,/Propietario/);
});

test('Centro y clientes usan filas completas, sin columna de acciones y con datos acotados',()=>{
 const out=renderPlatformAdmin({orgs:[{id:org,name:'Gimnasio',kind:'gym',status:'active'}],tab:'centers',filter:{status:'all',kind:'all'}});
 assert.match(out,/pa-center-row/);
 assert.doesNotMatch(out,/<th scope="col">Acción<\/th>/);
 const list=renderClient360({clients:[{id:uid,name:'Atleta',email:'a@example.org',status:'lead'}],manager:true});
 assert.match(list,/business-client-table/);
 assert.match(list,/Pendiente de aceptación/);
 const restricted=renderClient360({clients:[{id:uid,name:'Atleta',email:'a@example.org',status:'active',user_id:uid}],
 selected:uid,role:'coach',manager:false,sharedHistory:[]});
 assert.match(restricted,/Actividad compartida/);
 assert.doesNotMatch(restricted,/Notas internas|NIF\/CIF|Último inicio de sesión/);
});

test('Invitaciones solo se aceptan con correo verificado y email puede quedar sin entregar',async()=>{
 const calls=[],storage=new Map();
 const fetcher=async(url,options)=>{
  calls.push({url,options});
  let body=[];
  let status=200;
  if(url.includes('grant_type=password'))body={access_token:'token-test',refresh_token:'refresh-test',expires_in:3600};
  if(url.endsWith('/auth/v1/user')&&options.method==='GET')body={id:uid,email:'owner@example.org'};
  if(url.includes('/functions/v1/repera-business-invite')){status=503;body={error:'EMAIL_PROVIDER_NOT_CONFIGURED'};}
  return {ok:status<400,status,text:async()=>JSON.stringify(body)};
 };
 const api=new ReperaAuthAPI({publishableKey:'sb_publishable_test',fetcher,
 storage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)}});
 await api.signIn('owner@example.org','password');
 const r=await api.sendInvitationEmail(uid);
 assert.equal(r.sent,false);
 assert.match(r.reason,/proveedor/i);
 const call=calls.find(c=>c.url.includes('/functions/v1/repera-business-invite'));
 assert.equal(call.options.headers.Authorization,'Bearer token-test');
 assert.ok(!calls.some(c=>JSON.stringify(c).includes('service_role')));
});

test('Política: operador no se convierte en propietario ni se envía email sin proveedor',()=>{
 const base=new URL('../../../supabase/migrations/',import.meta.url);
 const sql=readFileSync(new URL('20261027184500_platform_center_visibility.sql',base),'utf8');
 assert.match(sql,/private.is_repera_platform_admin/);
 assert.match(sql,/SUSPENDED_CENTER_NOT_DISCOVERABLE/);
 const invitation=readFileSync(new URL('20261027185000_business_invitation_email_dispatch.sql',base),'utf8');
 assert.match(invitation,/business_invite_email_payload/);
 assert.match(invitation,/INVITATION_RATE_LIMIT/);
 const edge=readFileSync(new URL('../../../supabase/functions/repera-business-invite/index.ts',import.meta.url),'utf8');
 assert.match(edge,/RESEND_API_KEY/);
 assert.match(edge,/EMAIL_PROVIDER_NOT_CONFIGURED/);
 assert.match(edge,/auth\/v1\/user/);
});
