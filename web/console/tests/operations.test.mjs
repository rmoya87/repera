import test from 'node:test';
import assert from 'node:assert/strict';
import {seedData} from '../src/core/seed.js';
import {sellPass,entitlements,getBalance,createClass,assignToClients,reserveClass} from '../src/core/domain.js';
import {createGroup,updateGroupMembers,assignGroup,createStaff,createLocation,updateClient,overrideAssignedDay,plannedWorkoutWithOverrides,checkClassConflicts,scheduleClassSeries,cancelClass,recordAttendance,confirmPendingPayment,queueNotification,publishProgramNotifications,clientAgenda,financialSnapshot} from '../src/core/operations.js';
const setup=()=>seedData(new Date('2026-10-19T07:00:00Z'));
test('grupos: alta, deduplicación, cambio de miembros y aislamiento',()=>{
 const s=setup(),g=createGroup(s,'org-fit','Nuevos grupos',['c1','c1','c2']);assert.equal(g.clientIds.length,2);
 assert.throws(()=>createGroup(s,'org-fit','otros',['c4']),/no pertenece/);
 assert.throws(()=>updateGroupMembers(s,'org-fit',g.id,['c4']),/no pertenece/);
 assert.deepEqual(updateGroupMembers(s,'org-fit',g.id,['c2']).clientIds,['c2']);
 assert.throws(()=>createGroup(s,'org-fit','nuevos grupos',[]),/Ya hay/);
});
test('asignación masiva de grupo sin duplicados + notificaciones',()=>{
 const s=setup(),g=createGroup(s,'org-fit','Quedada',['c1','c2']);
 const assigned=assignGroup(s,'org-fit',g.id,'t1','2026-10-19');assert.equal(assigned.length,2);
 assert.equal(assignGroup(s,'org-fit',g.id,'t1','2026-10-19').length,0);
 assert.equal(publishProgramNotifications(s,'org-fit',assigned.map(x=>x.id)),2);
 assert.equal(s.notifications.length,2);assert.ok(s.notifications.every(n=>n.deepLink.startsWith('repera://diary/')));
});
test('ajuste individual no cambia la plantilla ni el plan de otros',()=>{
 const s=setup();const [a,b]=assignToClients(s,'org-fit','t1',['c1','c2'],'2026-10-19');
 const before=plannedWorkoutWithOverrides(s,'org-fit','c2','2026-10-19');
 overrideAssignedDay(s,'org-fit',a.id,'2026-10-19',{title:'Recuperación',exercises:'Caminar 20 min'});
 assert.equal(plannedWorkoutWithOverrides(s,'org-fit','c1','2026-10-19').at(-1).title,'Recuperación');
 assert.deepEqual(plannedWorkoutWithOverrides(s,'org-fit','c2','2026-10-19').at(-1).title,before.at(-1).title);
 assert.ok(!s.templates.find(t=>t.id==='t1').days.some(d=>d.title==='Recuperación'));
 overrideAssignedDay(s,'org-fit',a.id,'2026-10-20',{skip:true});assert.deepEqual(plannedWorkoutWithOverrides(s,'org-fit','c1','2026-10-20').filter(x=>x.assignmentId===a.id),[]);
 assert.throws(()=>overrideAssignedDay(s,'org-fit',a.id,'2027-12-01',{skip:true}),/Fuera/);
 assert.ok(b);
});
test('miembros y salas: validación de roles, correo y aforo',()=>{
 const s=setup();const p=createStaff(s,'org-fit',{name:'Eva',email:'eva@example.com',role:'coach'});assert.equal(p.status,'invited');
 assert.throws(()=>createStaff(s,'org-fit',{name:'Eva',email:'eva@example.com',role:'coach'}),/ya existe/);
 assert.throws(()=>createStaff(s,'org-fit',{name:'Hacker',email:'hacker@example.com',role:'owner'}),/Función no válida/);
 const room=createLocation(s,'org-fit',{name:'Sala nueva',capacity:6});assert.equal(room.capacity,6);
 assert.throws(()=>createLocation(s,'org-fit',{name:'Grande',capacity:0}),/Capacidad/);
 assert.throws(()=>createLocation(s,'org-fit',{name:'Sala nueva',capacity:6}),/Ya existe/);
});
test('edición de cliente: estados, duplicado y aislamiento',()=>{
 const s=setup();updateClient(s,'org-fit','c1',{status:'paused',name:'Lucía F.'});assert.equal(s.clients.find(c=>c.id==='c1').status,'paused');
 assert.throws(()=>updateClient(s,'org-fit','c1',{email:'marcos@example.com'}),/duplicado/);
 assert.throws(()=>updateClient(s,'org-fit','c4',{status:'paused'}),/no pertenece/);
});
test('conflicto de entrenador y sala impide dobles reservas de espacios',()=>{
 const s=setup();
 assert.throws(()=>checkClassConflicts(s,'org-fit',{start:'2026-10-19T09:20',duration:60,capacity:3,locationId:'l1',coachId:null}),/sala/);
 assert.throws(()=>checkClassConflicts(s,'org-fit',{start:'2026-10-19T09:20',duration:60,capacity:3,locationId:null,coachId:'s2'}),/entrenador/);
 assert.throws(()=>checkClassConflicts(s,'org-fit',{start:'2026-10-19T14:00',duration:60,capacity:13,locationId:'l1',coachId:null}),/Aforo/);
 assert.equal(checkClassConflicts(s,'org-fit',{start:'2026-10-19T11:00',duration:60,capacity:8,locationId:'l1',coachId:'s2'}),true);
});
test('recurrencia limitada con exclusión de días y conservando instancias',()=>{
 const s=setup();const created=scheduleClassSeries(s,'org-coach',{name:'Online',start:'2026-10-20T17:00',duration:45,capacity:1,locationId:null,coachId:'s3',status:'scheduled'},{count:3,intervalDays:7,exclude:['2026-10-27']});
 assert.equal(created.length,2);assert.equal(created[1].start.slice(0,10),'2026-11-03');
 assert.throws(()=>scheduleClassSeries(s,'org-coach',{name:'Bad',start:'2026-10-20T19:00',duration:20,capacity:1,status:'scheduled'},{count:53}),/Recurrencia/);
});
test('cancelar una clase devuelve el crédito una sola vez y crea avisos',()=>{
 const s=setup();const prev=getBalance(s,'pass1');cancelClass(s,'org-fit','cl1');assert.equal(s.classes.find(x=>x.id==='cl1').status,'cancelled');
 assert.equal(getBalance(s,'pass1'),prev+1);assert.ok(s.notifications.some(n=>n.clientId==='c1'&&n.type==='class_cancelled'));
 assert.throws(()=>cancelClass(s,'org-fit','cl1'),/no está programada/);
});
test('asistencia de una reserva confirmada y ausencia, sin inventar saldo',()=>{
 const s=setup(),balance=getBalance(s,'pass1');recordAttendance(s,'org-fit','b1','attended');assert.equal(s.bookings.find(b=>b.id==='b1').status,'attended');
 assert.equal(getBalance(s,'pass1'),balance);recordAttendance(s,'org-fit','b1','no_show');assert.equal(s.bookings.find(b=>b.id==='b1').status,'no_show');
 assert.throws(()=>recordAttendance(s,'org-fit','b1','paid'),/inválida/);
});
test('cobro pendiente necesita confirmación explícita e idempotencia',()=>{
 const s=setup(),o=sellPass(s,'org-fit','c1','p1',{method:'pending',startsOn:'2026-10-19'});
 assert.equal(o.pass.paymentId,o.payment.id);assert.equal(entitlements(s,'org-fit','c1').filter(x=>x.pass.id===o.pass.id).length,0);
 confirmPendingPayment(s,'org-fit',o.payment.id);assert.equal(entitlements(s,'org-fit','c1').find(x=>x.pass.id===o.pass.id).balance,10);
 assert.throws(()=>confirmPendingPayment(s,'org-fit',o.payment.id),/no está pendiente/);
 assert.equal(s.credits.filter(x=>x.passId===o.pass.id&&x.reason==='purchase').length,1);
});
test('agenda móvil reúne clases y entrenamientos sin mezclar clientes ni centros',()=>{
 const s=setup();const agenda=clientAgenda(s,'org-fit','c1','2026-10-19','2026-10-31');
 assert.ok(agenda.some(e=>e.kind==='training'));assert.ok(agenda.some(e=>e.kind==='class'));
 assert.ok(agenda.every(e=>e.deepLink.startsWith('repera://')));
 assert.throws(()=>clientAgenda(s,'org-fit','c4','2026-10-19','2026-10-31'),/no pertenece/);
 assert.throws(()=>clientAgenda(s,'org-fit','c1','2026-01-01','2027-01-01'),/Máximo/);
});
test('aviso bloquea enlace externo e identifica org',()=>{
 const s=setup();assert.throws(()=>queueNotification(s,'org-fit','c1','news','Click','https://evil.test/'),/Enlace/);
 assert.throws(()=>queueNotification(s,'org-fit','c4','news','Click','repera://today/c4'),/no pertenece/);
 const n=queueNotification(s,'org-fit','c1','news','Click','repera://today/c1');assert.equal(n.status,'queued');
});
test('analítica financiera aisla negocios',()=>{
 const s=setup();const a=financialSnapshot(s,'org-fit'),b=financialSnapshot(s,'org-coach');assert.equal(a.grossCents,15400);assert.equal(b.grossCents,0);
});