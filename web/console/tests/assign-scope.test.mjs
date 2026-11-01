import test from 'node:test';
import assert from 'node:assert/strict';
import {seriesOccurrenceTargets,dayOccurrenceTargets,resolveAssignScopeIds} from '../src/ui/assign-scope.js';

const base={
 id:'a',org_id:'o1',title:'WOD AM',kind:'class',status:'active',
 starts_at:'2099-03-03T18:00:00.000Z', // martes
};
const seriesMate={
 id:'b',org_id:'o1',title:'WOD AM',kind:'class',status:'active',
 starts_at:'2099-03-10T18:00:00.000Z',
};
const otherDay={
 id:'c',org_id:'o1',title:'WOD AM',kind:'class',status:'active',
 starts_at:'2099-03-04T18:00:00.000Z',
};
const sameDayOther={
 id:'d',org_id:'o1',title:'Open',kind:'class',status:'active',
 starts_at:'2099-03-03T19:00:00.000Z',
};

test('serie futuras: mismo título, DOW y hora',()=>{
 const ids=seriesOccurrenceTargets(base,[base,seriesMate,otherDay,sameDayOther]).map(o=>o.id);
 assert.deepEqual(ids.sort(),['a','b']);
});

test('día: todas las clases futuras del día local',()=>{
 const day=new Date(base.starts_at).toLocaleDateString('sv-SE');
 const ids=dayOccurrenceTargets(day,[base,seriesMate,sameDayOther]).map(o=>o.id);
 assert.ok(ids.includes('a'));
 assert.ok(ids.includes('d'));
 assert.ok(!ids.includes('b'));
});

test('resolveAssignScopeIds one / series / day',()=>{
 const all=[base,seriesMate,otherDay,sameDayOther];
 assert.deepEqual(resolveAssignScopeIds({scope:'one',baseId:'a',occurrences:all,selectedIds:['a']}),['a']);
 assert.deepEqual(resolveAssignScopeIds({scope:'series',baseId:'a',occurrences:all}).sort(),['a','b']);
 const day=new Date(base.starts_at).toLocaleDateString('sv-SE');
 const dayIds=resolveAssignScopeIds({scope:'day',baseId:'a',day,occurrences:all});
 assert.ok(dayIds.includes('a')&&dayIds.includes('d'));
});
