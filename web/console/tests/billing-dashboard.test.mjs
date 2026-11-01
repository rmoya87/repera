import test from 'node:test';
import assert from 'node:assert/strict';
import {buildBillingSummary,renderBillingDashboard,passPaidCents} from '../src/ui/billing-dashboard.js';
import {renderClientPassesPanel} from '../src/ui/client-passes.js';

const client={id:'c1',name:'Ana',status:'active',user_id:'u1'};
const offer={id:'o1',name:'Bono 10',price_cents:25000,credits:10,is_active:true,kind:'appointment'};
const pass={id:'p1',client_id:'c1',offer_id:'o1',status:'active',issuance_type:'manual_offline',
 total_credits:10,remaining_credits:4,valid_until:'2099-12-01',payment_method:'transfer',
 paid_at:'2026-11-01T10:00:00Z',paid_amount_cents:25000,created_at:'2026-11-01T10:00:00Z'};

test('resumen de facturación suma cobros y saldo restante por cliente',()=>{
 const s=buildBillingSummary({clients:[client],passes:[pass],offers:[offer],attendance:[]});
 assert.equal(s.totalBilled,25000);
 assert.equal(s.byMethod.transfer,25000);
 assert.equal(s.perClient[0].remainingCredits,4);
 assert.equal(s.perClient[0].remainingValue,10000); // 4/10 * 25000
 assert.equal(passPaidCents(pass,offer),25000);
});

test('panel Facturación muestra total y clientes',()=>{
 const html=renderBillingDashboard({clients:[client],passes:[pass],offers:[offer],attendance:[],manager:true});
 assert.match(html,/Facturación/);
 assert.match(html,/Facturado en total/);
 assert.match(html,/Ana/);
 assert.match(html,/Transferencia/);
 assert.match(html,/data-action="detail-client-passes"/);
});

test('ficha Bonos muestra forma de pago y permite descontar',()=>{
 const html=renderClientPassesPanel({
  client,passes:[pass],offers:[offer],attendance:[],bookings:[],occurrences:[],passEvents:[],
  manager:true,trainer:true,busy:false,
 });
 assert.match(html,/Transferencia/);
 assert.match(html,/data-connected="trainer-attendance"/);
 assert.match(html,/data-connected="issue-offline-pass"/);
 assert.match(html,/name="paymentMethod"/);
});
