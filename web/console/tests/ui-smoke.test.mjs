import test from 'node:test';
import assert from 'node:assert/strict';
import {seedData} from '../src/core/seed.js';
import {pageHtml,clientDetail,classDetail} from '../src/ui/pages.js';
import {modal} from '../src/ui/components.js';
const state=seedData(new Date('2026-10-19T09:00:00'));
test('Todos los apartados permiten renderizar sin datos externos',()=>{
 for(const section of ['overview','clients','planning','groups','agenda','calendar','operations','products','billing','analytics','notifications','team','settings','admin']){
  const html=pageHtml(section,state,'org-fit','platform_admin');assert.ok(html.length>300,section);assert.ok(html.includes('<h1>'),section);
 }
});
test('No refleja HTML inyectado en nombres al construir la UI',()=>{
 const testState=structuredClone(state);testState.clients[0].name='<img src=x onerror=alert(1)>';
 const output=pageHtml('clients',testState,'org-fit','gym_admin');assert.ok(!output.includes('<img src=x'));assert.ok(output.includes('&lt;img'));
});
test('Fichas y reservas muestran únicamente datos de su organización',()=>{
 assert.equal(clientDetail(state,'org-fit','c4'),null);assert.equal(classDetail(state,'org-coach','cl1'),null);
 assert.ok(clientDetail(state,'org-fit','c1').title.includes('Lucía'));
});
test('Un rol no administrador no puede ver panel admin',()=>{
 const output=pageHtml('admin',state,'org-fit','coach');assert.ok(output.includes('Sin permiso'));assert.ok(!output.includes('Organizaciones registradas'));
});
test('El modal incluye controles y acción',()=>{const html=modal('Alta', '<input name="test">','Guardar','save');assert.ok(html.includes('data-form="save"'));assert.ok(html.includes('aria-label="Cerrar"'))});
