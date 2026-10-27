import test from 'node:test';
import assert from 'node:assert/strict';
import {renderAthleteInsights,renderAthleteGuidance} from '../src/ui/athlete-insights.js';
import {renderAthleteActivity} from '../src/ui/athlete-activity.js';
import {renderClient360} from '../src/ui/management-360.js';
import {trainerSeatInfo,renderTrainerPassPanel} from '../src/ui/trainer-pass-panel.js';
import {nativeExerciseArt} from '../src/ui/exercise-art-map.js';
import {nativeBodyPaths} from '../src/ui/body-paths-data.js';

const athlete={id:'client-1',name:'Ana Atleta',email:'ana@example.com',
 user_id:'user-1',status:'active',avatar_url:'https://example.com/avatar.jpg'};
const scheduled={id:'workout-1',client_id:athlete.id,title:'Entreno mañana',
 scheduled_date:'2099-10-29',status:'scheduled',
 prescription:{schemaVersion:1,blocks:[{
  kind:'strength',title:'Halterofilia',exercises:[{name:'Hang Squat Snatch',
   plannedSets:[{targetReps:3,targetWeightKg:40}]}],movements:[]
 }]}};
const logged={id:'logged-1',title:'Entreno realizado',started_at:'2099-10-28T08:00:00Z',
 result:{exercises:[{exercise:{name:'Sentadilla',muscleGroup:'Piernas'},
  loggedSets:[{reps:5,weightKg:60,isWarmup:false}]}]}};

test('mapa muscular de Business reutiliza siluetas de la aplicación y 18 regiones',()=>{
 assert.ok(nativeBodyPaths.male.front.p.quadriceps);
 assert.ok(nativeBodyPaths.male.back.p.hamstring);
 const html=renderAthleteInsights([]);
 assert.equal((html.match(/pa-muscle-map-native/g)||[]).length,2);
 assert.match(html,/Sin datos/);
 assert.match(html,/Recuperando/);
 assert.match(html,/Fatigado/);
 assert.doesNotMatch(renderAthleteInsights([] ,null,{showGuidance:false}),/pa-coaching-inline/);
 assert.match(renderAthleteGuidance([]),/Orientación de entrenamiento/);
});

test('calendario del entrenador muestra sesiones futuras y WOD por bloques',()=>{
 const html=renderAthleteActivity({month:'2099-10',selectedDay:'2099-10-29',
  days:[{day:'2099-10-29',count:1}],plannedSessions:[scheduled],
  actionNamespace:'trainer',athleteId:athlete.id,canPlan:true});
 assert.match(html,/data-action="trainer-day"/);
 assert.match(html,/data-action="trainer-month"/);
 assert.match(html,/Entreno mañana/);
 assert.match(html,/Hang Squat Snatch/);
 assert.match(html,/Editar entrenamiento programado/);
 assert.match(html,/pa-workout-block/);
 assert.match(html,/data-action="plan-client"/);
});

test('miniatura de Hang Squat Snatch corresponde a un recurso nativo explícito',()=>{
 assert.equal(nativeExerciseArt['Hang Squat Snatch'],'art_hl_hang_sq_snatch');
});

test('ficha de entrenador no obliga a abrir el editor hasta elegir añadir entreno',()=>{
 const html=renderClient360({clients:[athlete],selected:athlete.id,manager:true,trainer:true,
  sessions:[scheduled],sharedHistory:[logged],trainerActivityDay:'2099-10-29',trainerActivityMonth:'2099-10'});
 assert.match(html,/Calendario de entrenamientos/);
 assert.match(html,/Mapa de grupos trabajados/);
 assert.match(html,/Orientación de entrenamiento/);
 assert.match(html,/Entreno mañana/);
 assert.match(html,/data-action="trainer-session"/);
 assert.doesNotMatch(html,/data-connected="publish-session"/);
});

test('plazas se ajustan al plan activo sin confundir leads con vinculados',()=>{
 const nowPast='2020-01-01T00:00:00Z',future='2099-01-01T00:00:00Z';
 const plans=[{plan_key:'trainer_5',audience:'personal_trainer',title:'Inicio',max_clients:5},
  {plan_key:'trainer_50',audience:'personal_trainer',title:'Profesional',max_clients:50}];
 const c=[athlete,{...athlete,id:'lead-1',user_id:null,status:'lead'}];
 assert.deepEqual(trainerSeatInfo({clients:c,trials:[{paid_plan:'trainer_50',paid_until:future}],plans}).max,50);
 const trial=trainerSeatInfo({clients:c,trials:[{paid_plan:null,trial_ends_at:future}],plans});
 assert.equal(trial.used,1);assert.equal(trial.max,5);
 assert.equal(trainerSeatInfo({clients:c,trials:[{paid_plan:null,trial_ends_at:nowPast}],plans}).max,0);
});

test('bonos permiten emitir y registrar sesiones distinguiendo pagos externos',()=>{
 const p={id:'pass-1',client_id:athlete.id,kind:'appointment',status:'active',
  total_credits:10,remaining_credits:3,valid_until:'2099-11-20',issuance_type:'manual_offline'};
 const offer={id:'offer-1',name:'Bono 10',kind:'appointment',is_active:true,
  credits:10,validity_days:90,price_cents:20000};
 const seat={max:5,used:1,left:4,label:'Inicio'};
 const html=renderTrainerPassPanel({clients:[athlete],passes:[p],offers:[offer],
  attendance:[],occurrences:[],seat,manager:true});
 assert.match(html,/data-connected="create-pass-offer"/);
 assert.match(html,/data-connected="issue-offline-pass"/);
 assert.match(html,/data-connected="trainer-attendance"/);
 assert.match(html,/fuera de Repera/);
 assert.match(html,/3\/10 sesiones/);
});
