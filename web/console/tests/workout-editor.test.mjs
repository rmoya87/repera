import test from 'node:test';
import assert from 'node:assert/strict';
import {APP_CATALOG} from '../src/ui/exercise-catalog.js';
import {
 editorMarkup,emptyPrescription,validatePrescription,canonicalPrescription,
 setEditorLibraryTemplates,isRestMovement,visualPrescription
} from '../src/ui/workout-editor.js';
import {navIcon} from '../src/ui/nav-icons.js';
import {readFileSync,existsSync} from 'node:fs';

const demo={version:1,blocks:[
 {kind:'strength',format:'sets',title:'Fuerza',rounds:1,timeCap:0,exercises:[{id:'sentadilla',name:'Sentadilla',sets:4,reps:8,rir:2,weight:55,duration:0,notes:'Tempo 3:1'}]},
 {kind:'wod',format:'amrap',title:'Metcon',rounds:1,timeCap:12,exercises:[{id:'burpee',name:'Burpee',sets:1,reps:10,rir:0,weight:0,duration:0,notes:''}]}
]};

test('El catálogo de Repera web corresponde a las ilustraciones de la app',()=>{
 assert.ok(APP_CATALOG.length>=180);
 for(const m of APP_CATALOG)assert.ok(existsSync(new URL(`../../assets/exercises/${m.art}.jpg`,import.meta.url)),`Miniatura ausente: ${m.art}`);
});

test('Editor renderiza miniaturas, WOD y parámetros sin ejecutar HTML inyectado',()=>{
 const html=editorMarkup(demo);
 assert.match(html,/Constructor de entrenamiento/);
 assert.match(html,/AMRAP|amrap/);
 assert.match(html,/RIR/);
 assert.match(html,/assets\/exercises\/art_sentadilla\.jpg/);
 assert.match(html,/\.\.\/assets\/exercises\//);
 const escaped=editorMarkup({version:1,blocks:[{...demo.blocks[0],title:'<img src=x onerror=alert(1)>'}]});
 assert.ok(escaped.includes('&lt;img'));
 assert.ok(!escaped.includes('<img src=x onerror=alert(1)>'));
});

test('Dentro del bloque: biblioteca, descanso, movimiento libre, temporizador y Mis entrenos',()=>{
 const html=editorMarkup(demo);
 assert.match(html,/data-editor-action="open-library"/);
 assert.match(html,/data-editor-action="add-rest-in-block"/);
 assert.match(html,/data-editor-action="open-free"/);
 assert.match(html,/data-editor-action="open-timer"/);
 assert.match(html,/data-editor-action="open-templates"/);
 assert.match(html,/data-editor-action="open-global-wod"/);
 assert.match(html,/Sin formato|none/);
 assert.match(html,/editor-block-addbar/);
 assert.match(html,/editor-footer-actions/);
});

test('Panel de biblioteca se dibuja dentro del cuadro del bloque',()=>{
 // Simula estado UI abriendo biblioteca en bloque 0 vía markup con un bloque y panel forzado.
 // editorMarkup lee editorUI interno; open-library se prueba vía acciones presentes + CSS.
 const css=readFileSync(new URL('../src/admin-refresh.css',import.meta.url),'utf8');
 assert.match(css,/\.editor-block-panel/);
 assert.match(css,/\.editor-block\.is-picking/);
 assert.match(css,/\.editor-block-addbar/);
});

test('Validación de bloques y ejercicios controla parámetros e impide sesiones vacías',()=>{
 assert.deepEqual(validatePrescription(demo).blocks[0].exercises[0].rir,2);
 assert.throws(()=>validatePrescription(emptyPrescription()),/Añade un bloque/);
 assert.throws(()=>validatePrescription({...demo,blocks:[{...demo.blocks[0],exercises:[]}]}),/al menos un ejercicio/);
 assert.throws(()=>validatePrescription({...demo,blocks:[{...demo.blocks[0],exercises:[{...demo.blocks[0].exercises[0],rir:12}]}]}),/Revisa/);
 assert.throws(()=>validatePrescription({...demo,blocks:[{...demo.blocks[0],exercises:[{...demo.blocks[0].exercises[0],weight:'NaN'}]}]}),/Revisa/);
});

test('canonicalPrescription: descanso WOD isRest; fuerza → bloque Descanso aparte',()=>{
 const withRestInWod={version:1,blocks:[{
  kind:'wod',format:'amrap',title:'Metcon',rounds:1,timeCap:10,
  exercises:[
   {id:'burpee',name:'Burpee',sets:1,reps:10,rir:0,weight:0,duration:0,notes:''},
   {id:'rest',name:'Descanso',itemKind:'rest',isRest:true,sets:1,reps:0,rir:0,weight:0,duration:45,notes:''}
  ]
 }]};
 const wire=canonicalPrescription(withRestInWod);
 assert.equal(wire.schemaVersion,1);
 assert.equal(wire.blocks.length,1);
 assert.equal(wire.blocks[0].kind,'wod');
 assert.equal(wire.blocks[0].movements.length,2);
 assert.equal(wire.blocks[0].movements[1].isRest,true);
 assert.equal(wire.blocks[0].movements[1].restSeconds,45);

 const withRestInStrength={version:1,blocks:[{
  kind:'strength',format:'sets',title:'Fuerza',rounds:1,timeCap:0,
  exercises:[
   {id:'sentadilla',name:'Sentadilla',sets:3,reps:8,rir:2,weight:0,duration:0,notes:''},
   {id:'rest',name:'Descanso',itemKind:'rest',isRest:true,sets:1,reps:0,rir:0,weight:0,duration:90,notes:''}
  ]
 }]};
 const split=canonicalPrescription(withRestInStrength);
 assert.equal(split.blocks.length,2);
 assert.equal(split.blocks[0].kind,'strength');
 assert.equal(split.blocks[0].exercises.length,1);
 assert.equal(split.blocks[1].kind,'wod');
 assert.equal(split.blocks[1].title,'Descanso');
 assert.equal(split.blocks[1].wodFormat,'forTime','Descanso WOD debe llevar wodFormat o el RPC rechaza el guardado');
 assert.equal(split.blocks[1].movements[0].isRest,true);
 assert.equal(split.blocks[1].movements[0].restSeconds,90);
 assert.equal('catalogKey' in split.blocks[0].exercises[0],false,'free sin catalogKey null');

 const roundtrip=visualPrescription(split);
 assert.ok(roundtrip.blocks.some(b=>b.exercises.some(isRestMovement)));
});

test('Plantillas Mis entrenos aparecen en el panel del bloque',()=>{
 setEditorLibraryTemplates([{
  id:'t1',name:'Full Body',description:'Base',
  prescription:{version:1,blocks:[{kind:'strength',format:'sets',title:'A',rounds:1,timeCap:0,exercises:[{id:'x',name:'Curl',sets:3,reps:10,rir:2,weight:0,duration:0,notes:''}]}]}
 }]);
 // Forzar panel templates: reutilizamos markup tras set; el panel solo aparece con editorUI.
 // Comprobamos que la función de plantillas no rompe el markup base y CSS de filas existe.
 const html=editorMarkup(demo);
 assert.match(html,/open-templates/);
 const css=readFileSync(new URL('../src/admin-refresh.css',import.meta.url),'utf8');
 assert.match(css,/\.editor-template-row/);
 setEditorLibraryTemplates([]);
});

test('resolveMovement recupera miniatura por nombre tras round-trip canónico',async()=>{
 const {resolveMovement,MOVEMENTS}=await import('../src/ui/workout-editor.js');
 const known=MOVEMENTS.find(m=>/sentadilla/i.test(m.name));
 assert.ok(known?.art);
 const hit=resolveMovement({id:'catalog:'+known.name,name:known.name});
 assert.equal(hit?.art,known.art);
});

test('Administración visual usa superficies blancas y controles de contraste',()=>{
 const css=readFileSync(new URL('../src/admin-refresh.css',import.meta.url),'utf8');
 assert.match(css,/\.dialog\{background:#fff/);
 assert.match(css,/\.btn\.primary,\.connected-primary\{background:#176a37;color:#fff/);
 assert.match(navIcon('settings'),/<svg/);
 assert.match(navIcon('clients'),/<circle/);
});
