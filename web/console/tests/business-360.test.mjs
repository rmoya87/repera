
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
test('Inicio gym prioriza recepción y clases de hoy',()=>{
 const html=renderBusinessHome({org:{kind:'gym'},clients:[client],occurrences:[occurrence],bookings:[],sessions:[],passes:[pass],manager:true});
 assert.match(html,/Recepción/);
 assert.match(html,/data-reception-filter/);
 assert.match(html,/Invitar socio/);
 assert.match(html,/Fuerza y movilidad/);
 assert.doesNotMatch(html,/business-stats/);
});
test('Inicio PT muestra agenda mes/día y crear cita',()=>{
 const html=renderBusinessHome({org:{kind:'personal_trainer'},clients:[client],occurrences:[],bookings:[],sessions:[],manager:true,requests:[]});
 assert.match(html,/Invitar cliente/);
 assert.match(html,/Crear cita/);
 assert.match(html,/data-action="agenda-view"/);
 assert.match(html,/>Agenda</);
});
test('Ficha cliente: pestañas Bonos, saldo y asignación externa',()=>{
 const html=renderClient360({clients:[client],selected:'c1',passes:[pass],offers:[offer],manager:true,sharedHistory:[],clientSection:'passes',trainer:true});
 assert.match(html,/>Bonos</);
 assert.match(html,/4\/10/);
 assert.match(html,/Confirmado por el centro/);
 assert.match(html,/data-connected="issue-offline-pass"/);
 assert.match(html,/Confirmo que he recibido el pago fuera de Repera|Confirmo que la asignación/);
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
 assert.match(list,/data-action="detail-occurrence"/);
 assert.match(list,/Agenda y clases/);
 const detail=renderClasses360({occurrences:[occurrence],clients:[client,other],bookings:[{id:'r1',occurrence_id:'o1',client_id:'c1',status:'booked'}],passes:[pass],selected:'o1',manager:true,classEditor:true});
 assert.match(detail,/data-connected="edit-occurrence"/);
 assert.match(detail,/data-action="mark-booking-attended"/);
 assert.match(detail,/data-action="mark-booking-noshow"/);
 assert.match(detail,/data-action="remove-booking"/);
});
test('Panel gym de bonos asigna con confirmación externa',()=>{
 const html=renderGymPassPanel({clients:[client],passes:[pass],offers:[offer],manager:true});
 assert.match(html,/Productos y bonos/);
 assert.match(html,/data-connected="issue-offline-pass"/);
 assert.match(html,/Confirmado por el centro/);
 const form=renderAssignOfflinePassForm({clients:[client],offers:[offer],clientId:'c1',manager:true});
 assert.match(form,/value="c1" selected/);
});
test('Panel conectado: menú PT mínimo y gym con productos',()=>{
 const code=readFileSync(new URL('../src/ui/connected.js',import.meta.url),'utf8');
 assert.match(code,/trainer\?'Agenda':'Inicio'/);
 assert.match(code,/Agenda y clases/);
 assert.match(code,/Productos y bonos/);
 assert.match(code,/markClassAttendance/);
 assert.match(code,/renderGymPassPanel/);
 assert.match(code,/pt-identity/);
 assert.doesNotMatch(code,/\['billing','Facturación'/);
 assert.doesNotMatch(code,/\['operations'/);
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
