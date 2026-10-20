
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderBusinessHome,renderClient360,renderClasses360} from '../src/ui/management-360.js';
const client={id:'c1',name:'Deportista uno',email:'cliente@example.test',status:'active',user_id:'user-1'};
const other={id:'c2',name:'Otra persona',email:'otro@example.test',status:'active'};
const occurrence={id:'o1',kind:'class',title:'Fuerza y movilidad',starts_at:'2030-08-12T09:00:00Z',ends_at:'2030-08-12T10:00:00Z',capacity:5,status:'active'};
const pass={id:'p1',client_id:'c1',kind:'class',remaining_credits:4,total_credits:10,valid_from:'2029-01-01T00:00:00Z',valid_until:'2031-01-01T00:00:00Z',status:'active'};
test('Inicio presenta clases pulsables con inscritos y aforo',()=>{
 const html=renderBusinessHome({org:{kind:'gym'},clients:[client],occurrences:[occurrence],bookings:[],sessions:[]});
 assert.match(html,/Fuerza y movilidad/);
 assert.match(html,/data-action="detail-occurrence"/);
 assert.match(html,/0\/5 plazas/);
});
test('Ficha 360 de cliente mantiene datos, bonos, opciones por rol y confidencialidad',()=>{
 const html=renderClient360({clients:[client],selected:'c1',passes:[pass],manager:true,sharedHistory:[]});
 assert.match(html,/Datos personales/);
 assert.match(html,/4\/10 disponibles/);
 assert.match(html,/manage-pass/);
 assert.match(html,/sin consentimiento|sincronizaci[oó]n|no est[aá]n disponibles/i);
 const outsider=renderClient360({clients:[client],selected:'c1',passes:[pass],manager:false});
 assert.doesNotMatch(outsider,/data-connected="client-profile"/);
 assert.doesNotMatch(outsider,/data-connected="manage-pass"/);
});
test('Historial autorizado muestra actividad real pero no inventa pesos, PR ni series',()=>{
 const html=renderClient360({clients:[client],selected:'c1',sharedHistory:[{id:'h',title:'Mi sesión',started_at:'2030-08-11T07:00:00Z'}]});
 assert.match(html,/Mi sesión/);
 assert.match(html,/compartidas por semana/);
 assert.doesNotMatch(html,/1RM|PR calculado/);
});
test('Clases: calendario, participantes, modificación y entrenos de grupo',()=>{
 const list=renderClasses360({occurrences:[occurrence],groups:[{id:'g1',name:'Equipo mañana'}],coaches:[{user_id:'staff',label:'Entrenador'}],manager:true,listMode:'list'});
 assert.match(list,/data-action="detail-occurrence"/);
 assert.match(list,/data-action="detail-group"/);
 const detail=renderClasses360({occurrences:[occurrence],clients:[client,other],bookings:[{id:'r1',occurrence_id:'o1',client_id:'c1',status:'booked'}],passes:[pass],selected:'o1',manager:true,classEditor:true});
 assert.match(detail,/data-connected="edit-occurrence"/);
 assert.match(detail,/data-action="remove-booking"/);
 assert.match(detail,/data-connected="publish-class-plan"/);
 const group=renderClasses360({occurrences:[],clients:[client,other],groups:[{id:'g1',name:'Equipo mañana'}],groupMembers:[{group_id:'g1',client_id:'c1'}],selectedGroup:'g1',manager:true});
 assert.match(group,/data-connected="edit-group"/);
 assert.match(group,/value="c1" checked/);
});
test('Panel conectado no contiene sección Agenda del deportista ni Operaciones',()=>{
 const code=readFileSync(new URL('../src/ui/connected.js',import.meta.url),'utf8');
 assert.match(code,/\['overview','Inicio'/);
 assert.match(code,/\['services',trainer\?'Citas y reservas':'Clases y reservas'/);
 assert.doesNotMatch(code,/\['operations'/);
 assert.doesNotMatch(code,/\['agenda'/);
 assert.match(code,/trial_ends_at/);
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
