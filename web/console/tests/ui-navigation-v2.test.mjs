import test from 'node:test';import assert from 'node:assert/strict';
test('Nuevas secciones y modales de Repera Business no quedan desconectados',async()=>{
 const listeners=new Map();const app={innerHTML:'',addEventListener(name,fn){listeners.set(name,[...(listeners.get(name)||[]),fn])},querySelector(){return {focus(){}}}};
 globalThis.document={querySelector(sel){return sel==='#app'?app:null}};
 const local=new Map();globalThis.localStorage={getItem(k){return local.get(k)||null},setItem(k,v){local.set(k,v)}};
 await import('../src/ui/app.js?navigation-v2');
 const click=(dataset)=>{for(const fn of listeners.get('click'))fn({target:{closest(){return {dataset}},id:''}})};
 for(const nav of ['groups','agenda','operations','notifications']){
  click({nav});assert.ok(app.innerHTML.includes('page-heading'),nav);
 }
 click({action:'add-group'});assert.match(app.innerHTML,/Nuevo grupo/);
 click({action:'close-modal'});click({action:'add-staff'});assert.match(app.innerHTML,/Invitar profesional/);
 click({action:'close-modal'});click({action:'add-location'});assert.match(app.innerHTML,/Nueva sala/);
});
