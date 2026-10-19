import test from 'node:test';import assert from 'node:assert/strict';
import {seedData} from '../src/core/seed.js';import {mobileAgendaResponse} from '../src/core/mobile-contract.js';
const s=seedData(new Date('2026-10-19T07:00:00Z'));
test('Contrato móvil v1 emite claves snake_case, varias entradas por fecha y deeplink interno',()=>{
 const response=mobileAgendaResponse(s,'org-fit','c1','2026-10-19','2026-10-26');
 assert.equal(response.schema_version,1);assert.ok(response.events.some(e=>e.kind==='training'));
 assert.ok(response.events.some(e=>e.kind==='class'));
 assert.ok(response.events.every(e=>Object.hasOwn(e,'assignment_id')&&Object.hasOwn(e,'booking_id')&&e.deep_link.startsWith('repera://')));
});