import test from 'node:test';
import assert from 'node:assert/strict';

test('El shell carga, navega y cambia de rol sin backend',async()=>{
 const listeners=new Map();const app={innerHTML:'',addEventListener(name,fn){listeners.set(name,[...(listeners.get(name)||[]),fn])},querySelector(){return {focus(){}}}};
 globalThis.document={querySelector(sel){return sel==='#app'?app:null}};
 const storage=new Map();globalThis.localStorage={getItem(key){return storage.get(key)||null},setItem(key,value){storage.set(key,value)}};
 await import('../src/ui/app.js');
 assert.ok(app.innerHTML.includes('Tu negocio'));
 assert.ok(app.innerHTML.includes('Repera Business'));
 for(const fn of listeners.get('click'))fn({target:{closest(){return {dataset:{nav:'clients'}}}}});
 assert.ok(app.innerHTML.includes('Fichas de clientes'));
 for(const fn of listeners.get('change'))fn({target:{id:'roleChoice',value:'platform_admin'}});
 assert.ok(app.innerHTML.includes('Administración'));
});