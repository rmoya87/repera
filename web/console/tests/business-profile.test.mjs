import test from 'node:test';
import assert from 'node:assert/strict';
import {slugFromName,uniqueSlug,legalProfileValues,publicBusinessValues,visiblePlans,priceLabel} from '../src/core/business-profile.js';

test('El slug se deriva del nombre comercial, sin edición manual ni colisiones fáciles',()=>{
 assert.equal(slugFromName('Alicia Parejo'),'alicia-parejo');
 assert.equal(slugFromName('Ágora & Fitness'),'agora-fitness');
 assert.equal(uniqueSlug('Alicia Parejo','12345678-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),'alicia-parejo-12345678');
 assert.throws(()=>slugFromName('!!!'));
});
test('Datos fiscales separados y normalizados sin sustituir a la autorización',()=>{
 const v=legalProfileValues({entity_type:'company',legal_name:' Alicia Parejo S.L. ',tax_id:'b12345678',billing_email:'info@example.org'});
 assert.equal(v.tax_id,'B12345678');assert.equal(v.country,'ES');assert.equal(v.entity_type,'company');
 assert.throws(()=>legalProfileValues({tax_id:'$$$'}),/NIF/);
 assert.throws(()=>legalProfileValues({billing_email:'no-valido'}),/Correo/);
 assert.equal(publicBusinessValues({name:'Alicia Parejo',website:'https://example.org'}).website,'https://example.org');
 assert.throws(()=>publicBusinessValues({name:'Alicia Parejo',website:'javascript:alert(1)'}),/https/);
});
test('Planes elegibles solo del público correcto, precios en euros',()=>{
 const plans=[{plan_key:'trainer_one',is_active:true,audience:'personal_trainer',display_order:2,monthly_price_cents:1400},
  {plan_key:'gym_one',is_active:true,audience:'gym',display_order:1,monthly_price_cents:3900},
  {plan_key:'trainer_hidden',is_active:false,audience:'personal_trainer',display_order:1,monthly_price_cents:100}];
 assert.deepEqual(visiblePlans(plans,'personal_trainer').map(p=>p.plan_key),['trainer_one']);
 assert.deepEqual(visiblePlans(plans,'gym').map(p=>p.plan_key),['gym_one']);
 assert.ok(priceLabel(1400).includes('14'));
});
