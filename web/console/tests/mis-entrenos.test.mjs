import test from 'node:test';
import assert from 'node:assert/strict';
import {renderAthleteGuidanceCircle} from '../src/ui/athlete-insights.js';
import {renderClient360} from '../src/ui/management-360.js';
import {renderTrainerWorkoutsLibrary,renderWorkoutInsertPanel,mergePrescriptionBlocks} from '../src/ui/trainer-workouts.js';
import {renderClientWorkoutFullscreen} from '../src/ui/connected-planning.js';
import {editorMarkup,emptyPrescription,canonicalPrescription,setEditorLibraryTemplates} from '../src/ui/workout-editor.js';

const client={id:'c1',name:'Ana',email:'a@e.com',status:'active',user_id:'u1'};
const tpl={id:'t1',name:'Full Body A',description:'Base',prescription:{version:1,blocks:[{kind:'strength',format:'sets',title:'Fuerza',rounds:1,timeCap:0,exercises:[{id:'squat',name:'Sentadilla',sets:3,reps:8,rir:2,weight:0,duration:0,notes:''}]}]}};
const session={id:'s1',client_id:'c1',title:'Piernas',scheduled_date:'2099-12-01',status:'scheduled',prescription:tpl.prescription};

test('círculo de registro a la derecha sin línea larga',()=>{
 const circle=renderAthleteGuidanceCircle([]);
 assert.match(circle,/pt-guidance-circle/);
 assert.match(circle,/Amateur|Medio|Avanzado/);
 assert.doesNotMatch(circle,/pt-guidance-line/);
 const html=renderClient360({clients:[client],selected:'c1',trainer:true,manager:true,sharedHistory:[],clientSection:'training'});
 assert.match(html,/pt-guidance-circle/);
 assert.match(html,/pt-profile-main/);
 assert.doesNotMatch(html,/pt-guidance-line/);
});

test('Mis entrenos lista plantillas y composer',()=>{
 const html=renderTrainerWorkoutsLibrary({templates:[tpl],templateId:'t1',manager:true});
 assert.match(html,/Mis entrenos/);
 assert.match(html,/Full Body A/);
 assert.match(html,/data-connected="save-workout-template"/);
 assert.match(html,/data-action="new-library-template"/);
 assert.match(html,/data-editor-action="open-library"/);
 assert.match(html,/data-editor-action="add-rest-in-block"/);
 const empty=renderTrainerWorkoutsLibrary({templates:[],manager:true});
 assert.match(empty,/Crea tu primera plantilla/);
});

test('pantalla completa con panel insertar y copiar',()=>{
 const html=renderClientWorkoutFullscreen({
  orgId:'00000000-0000-4000-8000-000000000001',role:'owner',
  sessions:[session],templates:[tpl],clients:[client],
  clientId:'c1',clientName:'Ana',busy:false,
 });
 assert.match(html,/pt-workout-fullscreen/);
 assert.match(html,/data-action="close-client-editor"/);
 assert.match(html,/data-action="insert-template"/);
 assert.match(html,/data-action="copy-session"/);
 assert.match(html,/De otro cliente/);
 assert.match(html,/data-editor-action="open-library"/);
 assert.match(html,/data-block-panel="library"/);
 assert.match(html,/Biblioteca de ejercicios/);
 assert.match(html,/data-connected="publish-session"/);
});

test('panel insertar y merge de bloques',()=>{
 const panel=renderWorkoutInsertPanel({templates:[tpl],sessions:[session],clients:[client],clientId:'c1'});
 assert.match(panel,/pt-insert-panel/);
 assert.match(panel,/Mis entrenos/);
 const merged=mergePrescriptionBlocks(emptyPrescription(),tpl.prescription);
 assert.equal(merged.blocks.length,1);
 assert.equal(merged.blocks[0].exercises[0].name,'Sentadilla');
});

test('editor: barra in-block con ejercicio, descanso, movimiento libre y footer app',()=>{
 const html=editorMarkup({version:1,blocks:[{kind:'strength',format:'none',title:'Bloque 1',rounds:1,timeCap:0,exercises:[]}]});
 assert.match(html,/data-editor-action="open-library"/);
 assert.match(html,/data-editor-action="add-rest-in-block"/);
 assert.match(html,/data-editor-action="open-free"/);
 assert.match(html,/data-editor-action="open-timer"/);
 assert.match(html,/data-editor-action="open-templates"/);
 assert.match(html,/data-editor-action="open-accessories"/);
 assert.match(html,/Elegir WOD|open-global-wod/);
 assert.match(html,/Escanear pizarra|scan-board/);
});

test('descanso en fuerza se publica como bloque WOD isRest (paridad app)',()=>{
 const wire=canonicalPrescription({version:1,blocks:[
  {kind:'strength',format:'sets',title:'Fuerza',rounds:1,timeCap:0,exercises:[
   {id:'squat',name:'Sentadilla',sets:3,reps:8,rir:2,weight:0,duration:0,notes:''},
   {id:'rest',name:'Descanso',itemKind:'rest',isRest:true,sets:1,reps:0,rir:0,weight:0,duration:60,notes:''}
  ]}
 ]});
 assert.equal(wire.blocks.length,2);
 assert.equal(wire.blocks[0].kind,'strength');
 assert.equal(wire.blocks[1].kind,'wod');
 assert.equal(wire.blocks[1].movements[0].isRest,true);
});

test('plantillas disponibles para el picker del bloque',()=>{
 setEditorLibraryTemplates([tpl]);
 const html=editorMarkup(tpl.prescription);
 assert.match(html,/open-templates/);
 setEditorLibraryTemplates([]);
});
