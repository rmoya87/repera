import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderTrainerAgenda,renderGymAssignmentDialog,collectDayEvents} from '../src/ui/trainer-agenda.js';
import {renderBusinessHome} from '../src/ui/management-360.js';

const assignSql=readFileSync(new URL('../../../supabase/migrations/20261101170000_pt_coach_assignments_billing.sql',import.meta.url),'utf8');
const coachSql=readFileSync(new URL('../../../supabase/migrations/20261101180000_coach_manage_assigned_class.sql',import.meta.url),'utf8');
const requestSql=readFileSync(new URL('../../../supabase/migrations/20261101190000_athlete_link_requests_pending.sql',import.meta.url),'utf8');

test('migraciones PT: ack, listado, mover y cancelar clase asignada',()=>{
 for(const name of ['coach_ack','list_my_coach_assignments','coach_ack_occurrence','billing_model'])
  assert.ok(assignSql.includes(name),name);
 for(const name of ['coach_reschedule_occurrence','coach_cancel_occurrence','cancellation_credit'])
  assert.ok(coachSql.includes(name),name);
});

test('migración: solicitud app queda pending (no auto-vínculo)',()=>{
 assert.match(requestSql,/organization_athlete_requests/);
 assert.match(requestSql,/status='pending'/);
 assert.match(requestSql,/business_enrollment_requests/);
 assert.doesNotMatch(requestSql,/insert into public\.organization_memberships/);
});

test('agenda PT mezcla citas, entrenos y clases gym pendientes',()=>{
 const day='2099-12-01';
 const events=collectDayEvents({
  day,
  clients:[{id:'c1',name:'Ana'}],
  occurrences:[{id:'o1',kind:'appointment',title:'Cita Ana',starts_at:day+'T10:00:00Z',ends_at:day+'T11:00:00Z',status:'active'}],
  bookings:[],
  sessions:[{id:'s1',client_id:'c1',title:'Fuerza',scheduled_date:day,status:'scheduled'}],
  gymAssignments:[{id:'g1',title:'WOD Box',starts_at:day+'T18:00:00Z',ends_at:day+'T19:00:00Z',status:'active',coach_ack:'pending',org_name:'Box Norte'}],
 });
 assert.equal(events.length,3);
 assert.ok(events.some(e=>e.source==='gym'&&e.action==='detail-gym-assignment'));
 const html=renderTrainerAgenda({
  clients:[{id:'c1',name:'Ana'}],occurrences:[],bookings:[],sessions:[],
  gymAssignments:[{id:'g1',title:'WOD Box',starts_at:day+'T18:00:00Z',ends_at:day+'T19:00:00Z',status:'active',coach_ack:'pending',org_name:'Box Norte'}],
  calendarMonth:'2099-12',agendaView:'month',agendaDay:day,manager:true,
 });
 assert.match(html,/data-action="new-date-appointment"/);
 assert.match(html,/open-notifications/);
 assert.match(html,/Clases del gimnasio/);
 assert.match(html,/data-action="coach-ack"/);
 assert.match(html,/pt-cal-add/);
 assert.doesNotMatch(html,/Próximas citas/);
});

test('diálogo de clase gym permite aceptar o mover/cancelar si aceptada',()=>{
 const pending=renderGymAssignmentDialog({
  id:'g1',title:'WOD',org_name:'Box',starts_at:'2099-12-01T18:00:00Z',ends_at:'2099-12-01T19:00:00Z',coach_ack:'pending',
 });
 assert.match(pending,/Aceptar clase/);
 assert.doesNotMatch(pending,/coach-reschedule/);
 const accepted=renderGymAssignmentDialog({
  id:'g1',title:'WOD',org_name:'Box',starts_at:'2099-12-01T18:00:00Z',ends_at:'2099-12-01T19:00:00Z',coach_ack:'accepted',
 });
 assert.match(accepted,/data-connected="coach-reschedule"/);
 assert.match(accepted,/coach-cancel-occurrence/);
});

test('inicio PT no muestra recepción de gym',()=>{
 const html=renderBusinessHome({org:{kind:'personal_trainer'},clients:[],occurrences:[],bookings:[],sessions:[],manager:true,requests:[]});
 assert.match(html,/>Agenda</);
 assert.doesNotMatch(html,/Recepción/);
});

test('vista día PT muestra panel día y data-agenda-view',()=>{
 const day='2099-12-02';
 const html=renderTrainerAgenda({
  clients:[{id:'c1',name:'Ana'}],
  occurrences:[{id:'o1',kind:'appointment',title:'Cita Ana',starts_at:day+'T10:00:00Z',ends_at:day+'T11:00:00Z',status:'active'}],
  bookings:[{id:'b1',occurrence_id:'o1',client_id:'c1',status:'booked'}],
  sessions:[],gymAssignments:[],
  calendarMonth:'2099-12',agendaView:'day',agendaDay:day,manager:true,
 });
 assert.match(html,/data-agenda-view="day"/);
 assert.match(html,/data-agenda-panel="day"/);
 assert.match(html,/pt-day-full/);
 assert.match(html,/con Ana/);
 assert.match(html,/data-action="open-quick-workout"/);
 assert.doesNotMatch(html,/business-calendar-grid/);
});

test('calendario mes selecciona día en el rail (sin vista día completa)',()=>{
 const html=renderTrainerAgenda({
  clients:[],occurrences:[],bookings:[],sessions:[],gymAssignments:[],
  calendarMonth:'2099-12',agendaView:'month',agendaDay:'2099-12-01',manager:true,
 });
 assert.match(html,/data-action="agenda-select-day"/);
 assert.match(html,/pt-month-layout/);
 assert.match(html,/pt-day-rail/);
 assert.doesNotMatch(html,/pt-day-full/);
 assert.match(html,/data-agenda-view="month"/);
});

test('inicio PT muestra badge de solicitudes pendientes',()=>{
 const html=renderBusinessHome({
  org:{kind:'personal_trainer'},manager:true,clients:[],occurrences:[],bookings:[],sessions:[],
  requests:[{id:'r1',status:'pending',name:'Luis',email:'l@e.com',pass_kind:'appointment'}],
 });
 assert.match(html,/open-notifications/);
 assert.match(html,/pt-badge/);
 assert.match(html,/>1</);
});
