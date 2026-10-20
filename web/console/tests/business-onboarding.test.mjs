import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderOrganizationCreateForm,renderOrganizationFields,renderPlanAdministration} from '../src/ui/business-onboarding.js';
const migration=readFileSync(new URL('../../../supabase/migrations/20261020161825_business_org_identity_plans.sql',import.meta.url),'utf8');

test('Formulario empresarial genera slug y permite foto/logotipo y datos fiscales',()=>{
 const html=renderOrganizationCreateForm([{plan_key:'trainer_5',title:'Inicio',audience:'personal_trainer',is_active:true,display_order:1,monthly_price_cents:1400}]);
 for(const field of ['name','kind','tax_id','entity_type','legal_name','representative_name','contact_name','billing_email','billing_address','postal_code','city','province','country','avatarFile','planKey','public_email','phone','website'])assert.match(html,new RegExp('name="'+field+'"'));
 assert.match(html,/data-generated-slug/);
 assert.doesNotMatch(html,/name="slug"/);
 assert.doesNotMatch(html,/Centro deportivo/);
 assert.match(html,/Foto del entrenador/);
 assert.match(renderOrganizationFields({kind:'gym'}),/Logotipo del gimnasio/);
});
test('Render seguro y catálogo configurado por admin',()=>{
 const html=renderOrganizationFields({legal:{legal_name:'<script>alert(1)</script>'}});
 assert.doesNotMatch(html,/<script>/);
 const admin=renderPlanAdministration([{plan_key:'gym_basic',audience:'gym',title:'Básico',description:'Alta',monthly_price_cents:3900,max_clients:35,discount_percent:0,discount_months:0,is_active:true,display_order:1}]);
 assert.match(admin,/data-connected="save-plan"/);assert.match(admin,/data-connected="new-plan"/);
});
test('Datos fiscales con RLS por negocio; cambios de plan nunca activan pagos',()=>{
 assert.match(migration,/organization_legal_profiles enable row level security/);
 assert.match(migration,/business_legal_managers_read/);
 assert.match(migration,/private\.has_org_role\(org_id,array\['owner','admin'/);
 assert.match(migration,/business_plans_update/);
 assert.match(migration,/private\.is_repera_platform_admin\(\)/);
 assert.match(migration,/business_subscription_intents_plan_fk/);
 assert.doesNotMatch(migration,/update\s+public\.organization_trials\s+set\s+paid_plan/i);
 assert.match(migration,/business_branding_insert/);
});
