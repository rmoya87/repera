import test from 'node:test';
import assert from 'node:assert/strict';
import {renderBusinessHome,renderClient360} from '../src/ui/management-360.js';
import {renderProfessionalPlanning} from '../src/ui/connected-planning.js';
import {renderTrainerPassPanel} from '../src/ui/trainer-pass-panel.js';
import {renderRequestsModal,renderBroadcastModal,renderTrainerAgenda,renderQuickWorkoutModal,countQuickWorkoutSessions} from '../src/ui/trainer-agenda.js';

const client={id:'client-1',name:'María Deportista',email:'maria@example.com',user_id:'user-1',status:'active',avatar_url:'https://example.com/avatar.png'};
const training={id:'training-1',client_id:'client-1',title:'Fuerza de tren inferior',scheduled_date:'2099-10-30',status:'scheduled',prescription:{version:1,blocks:[]}};
const occurrence={id:'occ-1',kind:'appointment',title:'Sesión individual',starts_at:'2099-10-30T10:00:00Z',ends_at:'2099-10-30T11:00:00Z',status:'active',capacity:1};
const booking={id:'b1',occurrence_id:'occ-1',client_id:'client-1',status:'booked'};

test('inicio de entrenador: agenda, avisos, solicitudes e invitar',()=>{
 const html=renderBusinessHome({org:{kind:'personal_trainer'},clients:[{...client,status:'lead'}],occurrences:[occurrence],bookings:[],sessions:[training],manager:true,calendarMonth:'2099-10',requests:[{id:'r1',status:'pending',name:'Ana'}]});
 assert.match(html,/Crear cita/);
 assert.match(html,/open-broadcast-modal/);
 assert.match(html,/open-requests-modal/);
 assert.match(html,/pt-badge/);
 assert.match(html,/open-invite-modal/);
 assert.match(html,/pt-cal-add/);
 assert.match(html,/Sesión individual|Fuerza de tren inferior/);
 assert.doesNotMatch(html,/Próximas citas/);
 assert.doesNotMatch(html,/Aviso a clientes/);
});

test('ficha de entrenador reutiliza agenda PT con acciones del cliente',()=>{
 const html=renderClient360({clients:[client],selected:client.id,trainer:true,manager:true,passes:[{id:'pass-1',client_id:client.id,kind:'appointment',total_credits:10,remaining_credits:4,valid_until:'2099-11-30',status:'active'}],sessions:[training],bookings:[booking],occurrences:[occurrence],clientSection:'training',calendarMonth:'2099-10',agendaDay:'2099-10-30',agendaView:'month'});
 assert.match(html,/Agenda de María Deportista/);
 assert.match(html,/pt-agenda-shell/);
 assert.match(html,/pt-month-layout/);
 assert.match(html,/pt-day-rail/);
 assert.match(html,/pt-view-toggle/);
 assert.match(html,/open-quick-workout/);
 assert.match(html,/new-date-appointment/);
 assert.match(html,/Fuerza de tren inferior|Sesión individual/);
 assert.doesNotMatch(html,/pa-activity-calendar/);
 assert.doesNotMatch(html,/data-section="agenda"/);
 // Una sola pareja de CTAs en el panel del día (no en topbar).
 assert.equal((html.match(/data-action="open-quick-workout"/g)||[]).length,1);
 const topActions=html.match(/pt-client-top-actions">([\s\S]*?)<\/div>\s*<div class="business-profile-header/)?.[1]||'';
 assert.doesNotMatch(topActions,/open-quick-workout/);
});

test('plan rápido: un día, semanal o plan completo',()=>{
 assert.equal(countQuickWorkoutSessions({mode:'day',start:'2026-11-03'}),1);
 assert.equal(countQuickWorkoutSessions({mode:'weekly',start:'2026-11-02',weeks:1,weekdays:[1,2,3,4,5]}),5);
 const modal=renderQuickWorkoutModal({clients:[client],clientId:client.id,day:'2026-11-03'});
 assert.match(modal,/value="weekly"/);
 assert.match(modal,/value="plan"/);
 assert.match(modal,/pt-scope-cards/);
 assert.match(modal,/pt-weekday-chips/);
 assert.match(modal,/pt-ex-grid/);
 assert.match(modal,/pt-ex-tile/);
 assert.match(modal,/assets\/exercises\/art_/);
 assert.match(modal,/quick-pick-exercise/);
 const agenda=renderTrainerAgenda({manager:true,mode:'client',clientId:client.id,clientName:client.name,agendaView:'month',agendaDay:'2026-11-03',calendarMonth:'2026-11'});
 assert.match(agenda,/pt-month-layout/);
 assert.match(agenda,/pt-day-tools/);
});

test('modales de avisos y solicitudes',()=>{
 const broadcast=renderBroadcastModal({clients:[client],occurrences:[],groups:[],manager:true});
 assert.match(broadcast,/Avisos a clientes|pt-sheet/);
 assert.match(broadcast,/pt-sheet-hero/);
 const requests=renderRequestsModal({waiting:[{id:'r1',name:'Ana',email:'a@b.com',status:'pending'}],manager:true});
 assert.match(requests,/Aceptar/);
 assert.match(requests,/pt-sheet/);
});

test('vista día en ficha cliente',()=>{
 const html=renderClient360({
  clients:[client],selected:client.id,trainer:true,manager:true,
  passes:[],sessions:[training],bookings:[booking],occurrences:[occurrence],
  clientSection:'training',calendarMonth:'2099-10',agendaDay:'2099-10-30',agendaView:'day',
 });
 assert.match(html,/data-agenda-panel="day"/);
 assert.match(html,/con María Deportista|Sesión individual/);
});

test('tarifas: mensual e ilimitado ocultan sesiones; asignar muestra formulario',()=>{
 const html=renderTrainerPassPanel({
  clients:[client],offers:[{id:'o1',name:'Mensual',credits:9999,validity_days:30,price_cents:9000,is_active:true,billing_model:'monthly'}],
  passes:[],attendance:[],bookings:[],occurrences:[],seat:{used:1,max:5,left:4,label:'Prueba'},manager:true,
 });
 assert.match(html,/data-billing-fields="monthly"/);
 assert.match(html,/data-billing-fields="unlimited"/);
 assert.match(html,/data-connected="issue-offline-pass"/);
 assert.match(html,/Asignar tarifa/);
 const empty=renderTrainerPassPanel({
  clients:[],offers:[],passes:[],attendance:[],bookings:[],occurrences:[],
  seat:{used:0,max:5,left:5,label:'Prueba'},manager:true,
 });
 assert.match(empty,/pt-assign-empty/);
 assert.match(empty,/Crear tarifa/);
});

test('el editor individual no obliga a guardar el entrenamiento en biblioteca',()=>{
 const html=renderProfessionalPlanning({orgId:'org-1',role:'owner',sessions:[training],templates:[],clients:[client],memberships:[],escapeHTML:x=>String(x),clientId:client.id,embedded:true});
 assert.match(html,/client-workout-editor/);
 assert.match(html,/Publicar para deportista/);
 assert.doesNotMatch(html,/Biblioteca de plantillas <span>/);
});
