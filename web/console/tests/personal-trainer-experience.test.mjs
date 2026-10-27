import test from 'node:test';
import assert from 'node:assert/strict';
import {renderBusinessHome,renderClient360} from '../src/ui/management-360.js';
import {renderProfessionalPlanning} from '../src/ui/connected-planning.js';

const client={id:'client-1',name:'María Deportista',email:'maria@example.com',user_id:'user-1',status:'active',avatar_url:'https://example.com/avatar.png'};
const training={id:'training-1',client_id:'client-1',title:'Fuerza de tren inferior',scheduled_date:'2099-10-30',status:'scheduled',prescription:{version:1,blocks:[]}};
const occurrence={id:'occ-1',kind:'appointment',title:'Sesión individual',starts_at:'2099-10-30T10:00:00Z',ends_at:'2099-10-30T11:00:00Z',status:'active',capacity:1};

test('inicio de entrenador incluye solicitudes, citas, entrenamientos y agenda',()=>{
 const html=renderBusinessHome({org:{kind:'personal_trainer'},clients:[{...client,status:'lead'}],occurrences:[occurrence],bookings:[],sessions:[training],calendarMonth:'2099-10'});
 assert.match(html,/Quieren entrenar contigo/);
 assert.match(html,/Próximas citas/);
 assert.match(html,/Fuerza de tren inferior/);
 assert.match(html,/Entrenamiento · sin hora/);
 assert.match(html,/data-action="new-date-appointment"/);
 assert.match(html,/data-action="add-planning"/);
 assert.doesNotMatch(html,/Gestionar deportistas/);
});

test('ficha de entrenador ofrece avatar real, cancelar relación y eliminar entrenamientos',()=>{
 const html=renderClient360({clients:[client],selected:client.id,trainer:true,manager:true,passes:[{id:'pass-1',client_id:client.id,kind:'appointment',total_credits:10,remaining_credits:4,valid_until:'2099-11-30',status:'active'}],sessions:[training]});
 assert.match(html,/example.com\/avatar.png/);
 assert.match(html,/data-action="end-client"/);
 assert.match(html,/data-action="delete-session"/);
 assert.match(html,/4\/10 disponibles/);
 assert.doesNotMatch(html,/Inscripciones y clases/);
});

test('el editor individual no obliga a guardar el entrenamiento en biblioteca',()=>{
 const html=renderProfessionalPlanning({orgId:'org-1',role:'owner',sessions:[training],templates:[],clients:[client],memberships:[],escapeHTML:x=>String(x),clientId:client.id,embedded:true});
 assert.match(html,/client-workout-editor/);
 assert.match(html,/Publicar para deportista/);
 assert.doesNotMatch(html,/Biblioteca de plantillas <span>/);
});
