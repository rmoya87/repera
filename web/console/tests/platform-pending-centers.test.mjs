import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderPlatformAdmin} from '../src/ui/platform-admin.js';
const id='6915d93b-e8ff-4f44-aaf0-14d1a8d183f6';
const pending=[{id,name:'Entrenadora Alicia',kind:'personal_trainer',status:'active',
 registration_status:'pending',owner_email:'owner@example.org',client_count:0,
 active_clients:0,member_count:0,sessions:0,created_at:'2026-10-27T12:04:00Z'}];
const input={orgs:pending,finance:{payments:[],intents:[]},pending:[],history:[],plans:[],
 filter:{search:'',kind:'all',status:'all',paymentStatus:'all',paymentScope:'b2b'},
 email:'admin@example.org'};

test('Un centro no reclamado aparece en Centros con estado pendiente y permite abrirlo',()=>{
 const output=renderPlatformAdmin({...input,tab:'centers'});
 assert.match(output,/Entrenadora Alicia/);
 assert.match(output,/Propietario sin registrar/);
 assert.match(output,/Activo/);
 assert.match(output,/data-admin-action="view-org"/);
 assert.match(output,/value="pending"/);
 assert.doesNotMatch(output,/class="pa-top"/);
});
test('Su ficha permite gestionar estado y entrar con administración delegada, no identidad ajena',()=>{
 const output=renderPlatformAdmin({...input,tab:'centers',selectedOrg:id});
 assert.match(output,/Propietario pendiente de registro/);
 assert.match(output,/data-admin-form="status"/);
 assert.match(output,/data-admin-action="access-center"/);
 assert.match(output,/Entrar como administrador del centro/);
 assert.doesNotMatch(output,/Motivo del acceso delegado/);
 assert.doesNotMatch(output,/class="pa-top"/);
});
test('Un centro suspendido puede reactivarse aunque su titular todavía no se haya registrado',()=>{
 const output=renderPlatformAdmin({...input,tab:'centers',selectedOrg:id,
 orgs:[{...pending[0],status:'suspended',status_reason:'Motivo verificado'}]});
 assert.match(output,/Guardar estado/);
 assert.match(output,/Suspendido/);
 assert.match(output,/Propietario pendiente de registro/);
});
test('Los indicadores de Pagos van en 4 columnas y los avatares son circulares',()=>{
 const output=renderPlatformAdmin({...input,tab:'payments'});
 assert.match(output,/pa-metrics pa-payments-metrics/);
 const css=readFileSync(new URL('../src/platform-admin-polish.css',import.meta.url),'utf8');
 assert.match(css,/pa-payments-metrics\{grid-template-columns:repeat\(4,minmax\(0,1fr\)\)/);
 assert.match(css,/pa-photo\.large[\s\S]*border-radius:50%!important/);
 assert.match(css,/business-profile-preview/);
});
