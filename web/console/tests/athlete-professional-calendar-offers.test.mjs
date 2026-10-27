import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderProfessionalPlanning} from '../src/ui/connected-planning.js';

const read=(relative)=>readFileSync(new URL(relative,import.meta.url),'utf8');
const org='6915d93b-e8ff-4f44-aaf0-14d1a8d183f6';
const athlete='f79094a6-a9d0-4bc8-916b-ce50628ab6a2';

test('Entrenamientos profesionales permiten programar y editar una hora real',()=>{
 const html=renderProfessionalPlanning({orgId:org,role:'owner',
  sessions:[{id:'a',client_id:athlete,scheduled_date:'2026-10-30',
   scheduled_time_minutes:19*60+30,title:'Fuerza',prescription:{blocks:[]}}],
  sessionId:'a',templates:[],
  clients:[{id:athlete,name:'Test',email:'test@example.org',status:'active',user_id:athlete}],
  escapeHTML:x=>String(x)});
 assert.match(html,/name="time" value="19:30"/);
 assert.match(html,/name="date"/);
 const api=read('../src/core/auth.js');
 assert.match(api,/setProfessionalSessionTime/);
 assert.match(api,/rpc\/set_professional_session_time/);
});

test('Inicio integra reservas y planes de profesionales en las tarjetas del día',()=>{
 const home=read('../../../Apps/Repera/Sources/HomeView.swift');
 assert.match(home,/ForEach\(professionalPlans\)/);
 assert.match(home,/ForEach\(businessBookings\)/);
 assert.match(home,/selectedDayBusinessBookings/);
 assert.match(home,/sourceOccurrenceId/);
 assert.match(home,/BusinessBookedOccurrenceDetailView/);
 assert.doesNotMatch(home,/confirmedBusinessBookingsCard|professionalSessionsForSelectedDay/);
});

test('La ficha del centro muestra catálogo auténtico y no permite bonos falsamente pagados',()=>{
 const view=read('../../../Apps/Repera/Sources/BusinessCenterViews.swift');
 assert.match(view,/Bonos disponibles/);
 assert.doesNotMatch(view,/Text\("Planificación"\)|Text\("Privacidad"\)/);
 const web=read('../src/ui/connected.js');
 assert.match(web,/data-connected="create-pass-offer"/);
 assert.match(web,/toggle-pass-offer/);
 assert.match(web,/La compra se activará cuando la pasarela/);
 const db=read('../../../supabase/migrations/20261027193500_business_pass_offers_catalog.sql');
 assert.match(db,/enable row level security/);
 assert.match(db,/private\.has_org_role/);
 assert.doesNotMatch(db,/insert into public\.service_passes/);
});

test('Desvincularse revoca la relación del propio atleta, no borra historial ni permite suplantar',()=>{
 const migration=read('../../../supabase/migrations/20261027193000_athlete_unlink_and_professional_time.sql');
 assert.match(migration,/create or replace function private\.leave_org_as_athlete/);
 assert.match(migration,/m\.user_id = v_actor/);
 assert.match(migration,/m\.role = 'athlete' and m\.status = 'active'/);
 assert.match(migration,/update public\.athlete_workout_sharing/);
 assert.match(migration,/update public\.organization_memberships/);
 assert.doesNotMatch(migration,/delete from public\.athlete_workout_mirror/);
});
