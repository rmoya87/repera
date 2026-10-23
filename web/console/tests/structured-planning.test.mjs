import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {makeBlock,makeEntry,makeSet,buildPrescription,summaryHTML,WOD_FORMATS} from '../src/core/structured-prescription.js';
import {renderProfessionalPlanning} from '../src/ui/connected-planning.js';
const read=path=>readFileSync(fileURLToPath(new URL(path,import.meta.url)),'utf8');
const catalog=JSON.parse(read('../src/data/exercise-catalog.json')).exercises;
const id='fed7ae7c-b43e-4251-af81-5bf00f8234dc';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
test('full native catalog is mirrored with stable unique keys',()=>{
 assert.equal(catalog.length,288);
 assert.equal(new Set(catalog.map(x=>x.catalogKey)).size,288);
 assert.ok(catalog.every(x=>x.catalogKey==='catalog:'+x.name || (x.category==='Halterofilia' && x.aliases?.includes(x.catalogKey.slice(8)))));
 for(const [file,regex] of [
  ['CatalogEnrichment',/\bEnrichedSeed\(\s*name:\s*"([^"]+)"/g],
  ['CatalogHalterofilia',/\bh\(\s*"([^"]+)"/g],
  ['CatalogGimnasia',/\bgy\(\s*"([^"]+)"/g],
  ['CatalogCrossFit',/\bcf\(\s*"([^"]+)"/g],
  ['Catalog',/CatalogSeedBuilder\.sportRow\(\s*"([^"]+)"\s*,\s*sport:\s*"HYROX"/g],
  ['CatalogMovilidad',/\bmove\("([^"]+)", english:/g]
 ]){
  const native=read('../../../Packages/ReperaDomain/Sources/ReperaDomain/'+file+'.swift');
  for(const match of native.matchAll(regex))assert.ok(catalog.some(c=>c.catalogKey==='catalog:'+match[1]),'Missing native exercise: '+match[1]);
 }
});
test('Olympic lifting display is English while legacy IDs and Spanish aliases remain intact',()=>{
 const lifts=catalog.filter(x=>x.category==='Halterofilia');
 assert.equal(lifts.length,48);
 assert.ok(lifts.every(x=>Array.isArray(x.aliases)&&x.catalogKey.startsWith('catalog:')));
 for(const [key,title,alias] of [
  ['catalog:Arrancada','Snatch','arrancada completa'],
  ['catalog:Cargada y envión','Clean and Jerk','c&j'],
  ['catalog:Tirón alto de arrancada','Snatch High Pull','shp'],
  ['catalog:Arrancada de potencia desde bloques','Block Power Snatch','bpsn'],
 ]) {
  const row=lifts.find(x=>x.catalogKey===key);
  assert.equal(row?.name,title);
  assert.ok(row.aliases.includes(alias));
 }
});
test('strong and WOD blocks preserve sets, catalog identity and free names',()=>{
 const strength=makeBlock('strength',id),entry=makeEntry('strength','catalog');
 entry.catalogKey='catalog:Press banca';entry.name='Press banca';entry.plannedSets=[makeSet()];entry.plannedSets[0].targetRir='2';entry.plannedSets[0].targetWeightKg='42.5';strength.exercises.push(entry);
 const wod=makeBlock('wod'),free=makeEntry('wod','free');free.name='Movimiento libre';free.reps='10';wod.movements.push(free);
 const p=buildPrescription([strength,wod],catalog);
 assert.equal(p.schemaVersion,1);assert.equal(p.blocks[0].exercises[0].catalogKey,'catalog:Press banca');
 assert.equal(p.blocks[0].exercises[0].plannedSets[0].targetRir,2);
 assert.equal(p.blocks[0].exercises[0].plannedSets[0].targetWeightKg,42.5);
 assert.equal(p.blocks[1].movements[0].source,'free');
 assert.equal(p.blocks[1].movements[0].catalogKey,null);
 assert.ok(summaryHTML(p).includes('Movimiento libre'));
 assert.ok(WOD_FORMATS.some(([v])=>v==='forTime'));
});
test('invalid catalog claims, missing exercise, impossible load are rejected',()=>{
 const b=makeBlock(),item=makeEntry();item.catalogKey='catalog:Does not exist';item.name='Does not exist';b.exercises.push(item);
 assert.throws(()=>buildPrescription([b],catalog),/catálogo/);
 item.source='free';item.catalogKey=null;item.name=' ';
 assert.throws(()=>buildPrescription([b],catalog),/libre/);
 item.name='Movilidad';item.plannedSets[0].targetWeightKg=5000;
 assert.throws(()=>buildPrescription([b],catalog),/Carga/);
 item.plannedSets[0].targetWeightKg=null;item.plannedSets[0].targetReps=8.5;
 assert.throws(()=>buildPrescription([b],catalog),/Repeticiones/);
});
test('published structured blocks and free exercises are escaped in web UI',()=>{
 const block=makeBlock('wod'),item=makeEntry('wod','free');item.name='<img onerror=alert(1)>';block.movements.push(item);
 // Renderer accepts server-side content without trusting it as HTML.
 const html=summaryHTML({schemaVersion:1,blocks:[block]});
 assert.ok(html.includes('&lt;img'));assert.ok(!html.includes('<img'));
 const view=renderProfessionalPlanning({orgId:id,role:'owner',sessions:[{id,scheduled_date:'2026-11-01',status:'scheduled',client_id:id,title:'WOD <script>',instructions:'',prescription:{schemaVersion:1,blocks:[block]}}],clients:[{id,user_id:id,name:'Atleta <b>'}],catalog,draft:[block],escapeHTML:esc});
 assert.ok(view.includes('data-plan-action="add-block"'));assert.ok(view.includes('data-plan-action="add-entry"'));
 assert.ok(!view.includes('<script>'));assert.ok(!view.includes('<img'));
});
