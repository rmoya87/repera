import test from 'node:test';
import assert from 'node:assert/strict';
import {seedData} from '../src/core/seed.js';
import {addClient,assignToClients,availablePlaces,cancelBooking,createClass,createProduct,createTemplate,draftInvoice,entitlements,getBalance,plannedForClient,recordPayment,reserveClass,sellPass} from '../src/core/domain.js';
const init=()=>seedData(new Date('2026-10-19T09:00:00'));
test('Aísla los clientes por empresa al crear y evita correos duplicados dentro de la misma',()=>{
 const s=init();const data={name:'Cliente especial',email:'test@x.com'};addClient(s,'org-fit',data);addClient(s,'org-coach',data);
 assert.throws(()=>addClient(s,'org-fit',data),/existe un cliente/);assert.throws(()=>addClient(s,'org-fit',{name:'',email:'x@y.com'}),/obligatorio/);
});
test('No permite asignar a clientes de otra organización',()=>{const s=init();assert.throws(()=>assignToClients(s,'org-fit','t1',['c4'],'2026-10-19'),/no pertenece/);});
test('Asigna un programa a varios clientes sin crear duplicados',()=>{const s=init();const rows=assignToClients(s,'org-coach','t2',['c4','c5','c4'],'2026-10-19');assert.equal(rows.length,2);assert.equal(assignToClients(s,'org-coach','t2',['c4'],'2026-10-19').length,0);});
test('La planificación refleja día y fecha, y termina al acabar las semanas',()=>{
 const s=init();assignToClients(s,'org-coach','t2',['c4'],'2026-10-19');
 assert.equal(plannedForClient(s,'org-coach','c4','2026-10-20')[0].title,'Movilidad cadera');
 assert.deepEqual(plannedForClient(s,'org-coach','c4','2026-12-15'),[]);
});
test('Valida productos, aforo y sesiones',()=>{const s=init();assert.throws(()=>createProduct(s,'org-fit',{name:'Test',mode:'credits',credits:0,price:'5',validityDays:20}),/Sesiones/);assert.throws(()=>createClass(s,'org-fit',{name:'Test',start:'2026-10-22T09:00',duration:60,capacity:0}),/Aforo/);});
test('Vender bono crea crédito y pago, que permite reservar',()=>{
 const s=init();const {pass}=sellPass(s,'org-coach','c4','p3',{startsOn:'2026-10-19'});
 assert.equal(getBalance(s,pass.id),4);assert.equal(entitlements(s,'org-coach','c4','2026-10-19').length,1);
 const booking=reserveClass(s,'org-coach','cl3','c4');assert.equal(booking.status,'confirmed');assert.equal(getBalance(s,pass.id),3);
 assert.throws(()=>reserveClass(s,'org-coach','cl3','c4'),/ya está apuntado/);
});
test('Una compra pendiente nunca otorga derechos',()=>{const s=init();const {pass}=sellPass(s,'org-coach','c4','p3',{startsOn:'2026-10-19',method:'pending'});assert.equal(pass.status,'pending');assert.equal(entitlements(s,'org-coach','c4','2026-10-19').length,0);assert.throws(()=>reserveClass(s,'org-coach','cl3','c4'),/no tiene un bono/);});
test('Lista de espera no consume créditos y cancelación promueve primera persona',()=>{
 const s=init();s.classes.find(x=>x.id==='cl1').capacity=1;s.bookings=[];s.credits=[];s.passes=[];
 const p1=sellPass(s,'org-fit','c1','p1',{startsOn:'2026-10-19'}).pass;
 const p2=sellPass(s,'org-fit','c2','p1',{startsOn:'2026-10-19'}).pass;
 const a=reserveClass(s,'org-fit','cl1','c1');const b=reserveClass(s,'org-fit','cl1','c2');assert.equal(a.status,'confirmed');assert.equal(b.status,'waitlist');assert.equal(getBalance(s,p2.id),10);
 cancelBooking(s,'org-fit',a.id);assert.equal(b.status,'confirmed');assert.equal(getBalance(s,p1.id),10);assert.equal(getBalance(s,p2.id),9);assert.equal(availablePlaces(s,'org-fit','cl1'),0);
});
test('Facturación en local es únicamente borrador, no confirma cobros pendientes',()=>{const s=init();const pay=recordPayment(s,'org-coach',{clientId:'c4',amount:12.5});const doc=draftInvoice(s,'org-coach',pay.id);assert.equal(doc.status,'draft');assert.equal(doc.amountCents,1250);assert.throws(()=>draftInvoice(s,'org-coach',pay.id),/existe un borrador/);});
test('Impide emitir borradores de pagos de otro centro',()=>{const s=init();assert.throws(()=>draftInvoice(s,'org-coach','pay1'),/no pertenece/);});
