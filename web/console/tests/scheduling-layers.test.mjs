import test from 'node:test';
import assert from 'node:assert/strict';
import {profileDefaults,renderOperationSettings,renderDayProgramPanel} from '../src/ui/operation-settings.js';

test('profileDefaults box disables rooms and enables day program',()=>{
 const d=profileDefaults('box');
 assert.equal(d.use_rooms,false);
 assert.equal(d.day_program_enabled,true);
 assert.equal(d.open_access_enabled,true);
});

test('profileDefaults gym_multi enables rooms and open gym',()=>{
 const d=profileDefaults('gym_multi');
 assert.equal(d.use_rooms,true);
 assert.equal(d.open_access_enabled,true);
});

test('renderOperationSettings includes Operación controls',()=>{
 const html=renderOperationSettings({
  org:{class_booking_open_hours:168},
  settings:profileDefaults('hybrid_rooms'),
  rooms:[{id:'r1',name:'Sala A',capacity:20,is_active:true}],
  activityTypes:[{id:'t1',name:'Yoga',color:'#22834d',is_active:true}],
  manager:true,busy:false,esc:s=>String(s??''),
 });
 assert.match(html,/Operación y agenda/);
 assert.match(html,/Usar salas/);
 assert.match(html,/Open gym/);
 assert.match(html,/data-connected="operation-settings"/);
 assert.match(html,/Sala A/);
});

test('renderDayProgramPanel empty when day program disabled',()=>{
 const html=renderDayProgramPanel({
  manager:true,settings:{day_program_enabled:false},esc:s=>String(s??''),
 });
 assert.equal(html,'');
});

test('renderDayProgramPanel shows form when enabled',()=>{
 const html=renderDayProgramPanel({
  manager:true,
  settings:{day_program_enabled:true,day_program_scope:'global'},
  activityTypes:[],rooms:[],esc:s=>String(s??''),day:'2026-11-02',
 });
 assert.match(html,/Programa del día/);
 assert.match(html,/data-connected="upsert-day-program"/);
});
