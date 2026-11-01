
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderBusinessHome,renderClient360,renderClasses360} from '../src/ui/management-360.js';
import {renderGymPassPanel,renderAssignOfflinePassForm} from '../src/ui/gym-pass-panel.js';
const client={id:'c1',name:'Deportista uno',email:'cliente@example.test',status:'active',user_id:'user-1'};
const other={id:'c2',name:'Otra persona',email:'otro@example.test',status:'active'};
const occurrence={id:'o1',kind:'class',title:'Fuerza y movilidad',starts_at:'2030-08-12T09:00:00Z',ends_at:'2030-08-12T10:00:00Z',capacity:5,status:'active'};
const pass={id:'p1',client_id:'c1',kind:'class',remaining_credits:4,total_credits:10,valid_from:'2029-01-01T00:00:00Z',valid_until:'2031-01-01T00:00:00Z',status:'active',issuance_type:'manual_offline'};
const offer={id:'of1',name:'Bono 10',kind:'class',credits:10,validity_days:90,price_cents:5000,is_active:true};
test('Inicio gym: calendario (selector de mes en menú principal)',()=>{
 const html=renderBusinessHome({
  org:{kind:'gym'},clients:[client],occurrences:[occurrence],bookings:[],sessions:[],passes:[pass],
  manager:true,calendarMonth:'2030-08',agendaDay:'2030-08-12',
 });
 assert.match(html,/pt-agenda-shell/);
 assert.match(html,/Fuerza y movilidad/);
 assert.match(html,/open-new-class-modal/);
 assert.doesNotMatch(html,/business-stats/);
 // Mes vive en menú; no se duplica en el cuerpo.
 assert.doesNotMatch(html,/data-action="calendar-prev"/);
});
test('Inicio PT: calendario con chrome en menú',()=>{
 const html=renderBusinessHome({org:{kind:'personal_trainer'},clients:[client],occurrences:[],bookings:[],sessions:[],manager:true,requests:[]});
 assert.match(html,/pt-agenda-shell/);
 assert.match(html,/pt-cal-add/);
 assert.match(html,/open-quick-workout|Asignar entrenamiento/);
 // Selector mes/día se ancla al menú principal (chromeInMenu).
 assert.doesNotMatch(html,/data-action="agenda-view"/);
});
test('Ficha cliente: pestañas Bonos, saldo y asignación externa',()=>{
 const ptPass={...pass,kind:'appointment'};
 const ptOffer={...offer,kind:'appointment'};
 const html=renderClient360({clients:[client],selected:'c1',passes:[ptPass],offers:[ptOffer],manager:true,sharedHistory:[],clientSection:'passes',trainer:true,
  attendance:[{id:'a1',client_id:'c1',pass_id:'p1',performed_at:'2030-08-10T10:00:00Z',note:'Fuerza'}],
  passEvents:[{id:'e1',pass_id:'p1',action:'add_credits',previous_remaining:3,new_remaining:4,created_at:'2030-08-09T12:00:00Z'}]});
 assert.match(html,/>Bonos</);
 assert.match(html,/Alta bono/);
 assert.match(html,/4\/10/);
 assert.match(html,/Confirmado por el centro|Bono del cliente/);
 assert.match(html,/data-action="open-assign-pass"/);
 assert.match(html,/Sesión registrada|Actividad/);
 assert.match(html,/Créditos añadidos|Bono asignado/);
 assert.match(html,/data-connected="trainer-attendance"/);
 const outsider=renderClient360({clients:[client],selected:'c1',passes:[pass],offers:[offer],manager:false,clientSection:'data'});
 assert.doesNotMatch(outsider,/data-connected="client-profile"/);
 assert.doesNotMatch(outsider,/data-connected="issue-offline-pass"/);
});
test('Historial autorizado muestra actividad real pero no inventa pesos, PR ni series',()=>{
 const html=renderClient360({clients:[client],selected:'c1',sharedHistory:[{id:'h',title:'Mi sesión',started_at:'2030-08-11T07:00:00Z'}]});
 assert.match(html,/Mi sesión/);
 assert.doesNotMatch(html,/1RM|PR calculado/);
});
test('Clases: asistencia y no-show en detalle',()=>{
 const list=renderClasses360({occurrences:[occurrence],groups:[{id:'g1',name:'Equipo mañana'}],coaches:[{user_id:'staff',label:'Entrenador'}],manager:true,listMode:'list'});
 assert.match(list,/data-action="detail-occurrence"|data-action="detail-group"/);
 const detail=renderClasses360({occurrences:[occurrence],clients:[client,other],bookings:[{id:'r1',occurrence_id:'o1',client_id:'c1',status:'booked'}],passes:[pass],selected:'o1',manager:true,classEditor:true});
 assert.match(detail,/data-connected="edit-occurrence"|data-action="open-edit-class-modal"|Editar/);
 assert.match(detail,/data-action="mark-booking-attended"|Apuntados|Reservado/);
});
test('Panel gym de planes lista ofertas y el formulario de asignación',()=>{
 const html=renderGymPassPanel({clients:[client],passes:[pass],offers:[offer],manager:true});
 assert.match(html,/>Planes</);
 assert.match(html,/Bono 10/);
 assert.match(html,/open-create-plan-modal|Crear plan/);
 const form=renderAssignOfflinePassForm({clients:[client],offers:[offer],clientId:'c1',manager:true});
 assert.match(form,/name="client"|c1/);
 assert.match(form,/issue-offline-pass|Confirmado por el centro|paymentMethod/);
});
test('Panel conectado: menú PT/gym alineado (opciones de negocio distintas)',()=>{
 const code=readFileSync(new URL('../src/ui/connected.js',import.meta.url),'utf8');
 assert.match(code,/trainer\?'Agenda':'Inicio'/);
 assert.match(code,/Mis entrenos/);
 assert.match(code,/renderNewClientWorkoutModal/);
 assert.match(code,/agendaMonthChromeHTML/);
 assert.match(code,/renderTeamWorkspace/);
 assert.match(code,/markClassAttendance/);
 assert.match(code,/renderGymPassPanel/);
 assert.match(code,/pt-identity/);
 assert.match(code,/business-navigation is-pro/);
 assert.doesNotMatch(code,/\['billing','Facturación'/);
 assert.doesNotMatch(code,/\['operations'/);
 assert.doesNotMatch(code,/\['settings','Configuración'/);
});
test('Migración de asistencia de clase existe y no descuenta de nuevo',()=>{
 const sql=readFileSync(new URL('../../../supabase/migrations/20261101120000_business_class_attendance.sql',import.meta.url),'utf8');
 assert.match(sql,/business_mark_class_attendance/);
 assert.match(sql,/attended','no_show/);
 const mark=sql.slice(sql.indexOf('private.business_mark_class_attendance'),sql.indexOf('public.business_mark_class_attendance'));
 assert.doesNotMatch(mark,/remaining_credits/);
 assert.doesNotMatch(mark,/booking_debit/);
 assert.match(sql,/status in \('booked','attended'\)/);
});
test('Migraciones exigen consentimiento individual y no exponen historial global',()=>{
 const root=new URL('../../../supabase/migrations/',import.meta.url);
 const policy=readFileSync(new URL('20261020093136_business_athlete_history_consent.sql',root),'utf8');
 const trial=readFileSync(new URL('20261020091937_business_groups_recurrence_trial_gate.sql',root),'utf8');
 assert.match(policy,/athlete_user_id=athlete/);
 assert.match(policy,/revoked_at is null/);
 assert.match(policy,/private\.is_assigned_coach/);
 assert.match(trial,/TRIAL_EXPIRED_PAYMENT_REQUIRED/);
});
