import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderPlatformAdmin} from '../src/ui/platform-admin.js';
import {renderAthleteActivity} from '../src/ui/athlete-activity.js';
import {renderBusinessHome} from '../src/ui/management-360.js';
import {renderProfessionalPlanning} from '../src/ui/connected-planning.js';
import {ReperaAuthAPI} from '../src/core/auth.js';

const org='6915d93b-e8ff-4f44-aaf0-14d1a8d183f6';
const athlete='f79094a6-a9d0-4bc8-916b-ce50628ab6a2';
const fixture={id:athlete,name:'Atleta independiente',email:'atleta@example.org',center_count:0,confirmed:true};

test('Cada fila de Atletas abre la ficha y el buscador carece de etiqueta y contador',()=>{
 const html=renderPlatformAdmin({tab:'athletes',athletes:[fixture],email:'admin@example.org',filter:{athleteSearch:''}});
 assert.match(html,/tr class="pa-athlete-row"/);
 assert.match(html,/data-admin-action="view-athlete"/);
 assert.match(html,/aria-label="Buscar atleta"/);
 assert.doesNotMatch(html,/data-bulk-count|1 cuentas|<span class="pa-filter-count">/);
 assert.doesNotMatch(html,/<label class="pa-field"><span>Buscar atleta/);
});

test('La actividad usa calendario y entrena con bloques, series, fotos y lenguaje útil',()=>{
 const html=renderAthleteActivity({month:'2026-10',days:[{day:'2026-10-25',count:1}],
  selectedDay:'2026-10-25',workouts:[{title:'Fuerza de piernas',started_at:'2026-10-25T07:00:00Z',
   exercises:[{id:'secret-id',blockId:'internal',blockHeader:'Fuerza principal',blockKind:'strength',
    exercise:{name:'Sentadilla',isFavorite:true,muscleGroup:'Piernas',id:'raw'},
    loggedSets:[{reps:5,weightKg:80,rir:2}]}],wod_results:[]}]});
 assert.match(html,/Calendario de entrenamientos/);
 assert.match(html,/data-admin-action="athlete-day"/);
 assert.match(html,/pa-workout-block/);
 assert.match(html,/art_sentadilla.jpg/);
 assert.match(html,/Series realizadas/);
 assert.match(html,/80/);
 assert.doesNotMatch(html,/secret-id|blockId|isFavorite|muscleGroup|internal/);
});

test('Los títulos no pueden inyectar HTML y ejercicios desconocidos no reciben imagen equivocada',()=>{
 const html=renderAthleteActivity({month:'2026-10',selectedDay:'2026-10-25',
  workouts:[{title:'<script>alert(1)</script>',started_at:'2026-10-25T08:00:00Z',
   exercises:[{blockId:'a',blockKind:'strength',exercise:{name:'Ejercicio sin foto verificada'},
    loggedSets:[{reps:8,weightKg:10}]}]}]});
 assert.doesNotMatch(html,/<script>/);
 assert.match(html,/&lt;script&gt;/);
 assert.match(html,/pa-exercise-placeholder/);
 assert.doesNotMatch(html,/src="\.\.\/assets\/exercises/);
});

test('Las solicitudes llegan a la portada con decisiones explícitas y actualizar',()=>{
 const html=renderBusinessHome({org:{id:org,name:'Centro'},manager:true,
  clients:[],occurrences:[],sessions:[],
  requests:[{id:'request',name:'Aspirante',email:'a@example.org',pass_kind:'class',note:'Me interesa',status:'pending'}]});
 assert.match(html,/Quieren entrenar contigo/);
 assert.match(html,/data-action="approve-enrollment"/);
 assert.match(html,/data-action="reject-enrollment"/);
 assert.match(html,/data-action="refresh-enrollments"/);
 assert.match(html,/data-workspace="planning"/);
 assert.match(html,/data-workspace="clients"/);
});

test('El editor masivo ofrece plantilla, atletas, día/semana/rango y previsualización',()=>{
 const html=renderProfessionalPlanning({orgId:org,role:'admin',templates:[
  {id:org,name:'Fuerza + WOD',prescription:{blocks:[{kind:'strength',exercises:[],movements:[]}]}}],
  clients:[{id:athlete,name:'Atleta',email:'a@example.org',user_id:athlete,status:'active'}],
  sessions:[],memberships:[],busy:false,escapeHTML:x=>String(x)});
 assert.match(html,/data-connected="bulk-training"/);
 assert.match(html,/data-bulk-preview/);
 assert.match(html,/data-bulk-submit disabled/);
 assert.match(html,/value="day"/);
 assert.match(html,/value="week"/);
 assert.match(html,/value="range"/);
 assert.match(html,/data-action="bulk-select-all"/);
 assert.match(html,/name="clients"/);
 assert.match(html,/name="weekdays"/);
});

test('El controlador mantiene validación y actualización sin borrar datos del formulario',()=>{
 const source=readFileSync(new URL('../src/ui/connected.js',import.meta.url),'utf8');
 assert.match(source,/function bulkPlanSummary\(form\)/);
 assert.match(source,/refreshBulkPlanPreview\(form\)/);
 assert.match(source,/preview\.textContent=valid\.message/);
 assert.match(source,/action==='refresh-enrollments'/);
 assert.match(source,/action==='bulk-training'/);
 assert.match(source,/action==='approve-enrollment'/);
});

test('Las peticiones y publicaciones se hacen con JWT del usuario autenticado, sin service role',async()=>{
 const requests=[],store=new Map();
 const fetcher=async(url,options)=>{
  requests.push({url,options});
  let data=[];
  if(url.includes('grant_type=password'))data={access_token:'jwt-example',refresh_token:'refresh-test',expires_in:3600};
  if(url.endsWith('/auth/v1/user')&&options.method==='GET')data={id:athlete,email:'admin@example.org'};
  if(url.endsWith('/rpc/business_publish_training_bulk'))data={created:3,skipped:0};
  return {ok:true,status:200,text:async()=>JSON.stringify(data)};
 };
 const api=new ReperaAuthAPI({publishableKey:'sb_publishable_test',
  fetcher,storage:{getItem:k=>store.get(k)||null,setItem:(k,v)=>store.set(k,v),removeItem:k=>store.delete(k)}});
 await api.signIn('admin@example.org','password');
 await api.enrollmentRequests(org);
 await api.decideEnrollment(athlete,true);
 await api.platformAdminAthleteActivity(athlete,'2026-10');
 await api.platformAdminAthleteDay(athlete,'2026-10-25');
 const result=await api.bulkPublishTraining({orgId:org,templateId:org,clientIds:[athlete],
  start:'2026-11-02',end:'2026-11-04',weekdays:[1,2,3],requestId:athlete});
 assert.equal(result.created,3);
 const rpcs=requests.filter(x=>x.url.includes('/rpc/'));
 assert.equal(rpcs.length,5);
 assert.ok(rpcs.every(r=>r.options.headers.Authorization==='Bearer jwt-example'));
 assert.ok(requests.every(x=>!JSON.stringify(x).includes('service_role')));
 await assert.rejects(()=>api.bulkPublishTraining({orgId:org,templateId:org,clientIds:[],
  start:'2026-11-02',end:'2026-11-04',weekdays:[1],requestId:athlete}),/Revisa/);
});

test('Las migraciones implementan inbox con RLS y publicación idempotente y auditada',()=>{
 const base=new URL('../../../supabase/migrations/',import.meta.url);
 const incoming=readFileSync(new URL('20261027181000_enrollments_and_operating_status.sql',base),'utf8');
 const training=readFileSync(new URL('20261027182000_athlete_activity_bulk_training.sql',base),'utf8');
 assert.match(incoming,/enable row level security/i);
 assert.match(incoming,/request_org_athlete_link/);
 assert.match(incoming,/business_decide_enrollment/);
 assert.match(incoming,/business_enrollment_requests/);
 assert.match(training,/business_publish_training_bulk/);
 assert.match(training,/p_request/);
 assert.match(training,/v_skipped/);
 assert.match(training,/platform_admin_athlete_day/);
});
