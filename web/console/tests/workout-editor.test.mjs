import test from 'node:test';
import assert from 'node:assert/strict';
import {APP_CATALOG} from '../src/ui/exercise-catalog.js';
import {editorMarkup,emptyPrescription,validatePrescription} from '../src/ui/workout-editor.js';
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
 assert.match(html,/art_sentadilla.jpg/);
 const escaped=editorMarkup({version:1,blocks:[{...demo.blocks[0],title:'<img src=x onerror=alert(1)>'}]});
 assert.ok(escaped.includes('&lt;img'));
 assert.ok(!escaped.includes('<img src=x onerror=alert(1)>'));
});
test('Validación de bloques y ejercicios controla parámetros e impide sesiones vacías',()=>{
 assert.deepEqual(validatePrescription(demo).blocks[0].exercises[0].rir,2);
 assert.throws(()=>validatePrescription(emptyPrescription()),/Añade un bloque/);
 assert.throws(()=>validatePrescription({...demo,blocks:[{...demo.blocks[0],exercises:[]}]}),/al menos un ejercicio/);
 assert.throws(()=>validatePrescription({...demo,blocks:[{...demo.blocks[0],exercises:[{...demo.blocks[0].exercises[0],rir:12}]}]}),/Revisa/);
 assert.throws(()=>validatePrescription({...demo,blocks:[{...demo.blocks[0],exercises:[{...demo.blocks[0].exercises[0],weight:'NaN'}]}]}),/Revisa/);
});
test('Administración visual usa superficies blancas y controles de contraste',()=>{
 const css=readFileSync(new URL('../src/admin-refresh.css',import.meta.url),'utf8');
 assert.match(css,/\.dialog\{background:#fff/);
 assert.match(css,/\.btn\.primary,\.connected-primary\{background:#176a37;color:#fff/);
 assert.match(navIcon('settings'),/<svg/);
 assert.match(navIcon('clients'),/<circle/);
});