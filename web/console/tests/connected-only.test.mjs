import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const here = new URL('../',import.meta.url);
const read = path => readFileSync(new URL(path,here),'utf8');

test('Business always uses authenticated Supabase; no seeded demo route',()=>{
 const main=read('src/main.js');
 assert.match(main,/import ['"]\.\/ui\/connected\.js['"]/);
 assert.doesNotMatch(main,/ui\/app\.js|demo=1/);
 const connected=read('src/ui/connected.js');
 assert.doesNotMatch(connected,/\?demo=1|Abrir demostración local|Explorar funciones en la demostración/);
});

test('Platform role is resolved before tenant membership query; admin without business still loads',()=>{
 const code=read('src/ui/connected.js');
 const start=code.indexOf('async function reload(){');
 const end=code.indexOf("\napp.addEventListener('click'",start);
 assert.ok(start>=0&&end>start,'Reload function exists');
 const reload=code.slice(start,end);
 assert.ok(reload.indexOf('await auth.myProfile()') < reload.indexOf('auth.memberships()'));
 assert.match(reload,/if\(platformRole==='platform_admin'\)/);
 assert.match(reload,/if\(!delegation\)/);
 assert.match(reload,/adminDirectory,adminFinances,adminPending,adminHistory/);
 assert.ok(reload.indexOf('await loadSelectedOrg();return;') < reload.indexOf('auth.memberships()'));
});

test('Mac launcher has no demo switch and opens live console only',()=>{
 const script=readFileSync(new URL('../../Repera-Business.command',here),'utf8');
 assert.doesNotMatch(script,/--demo|\?demo=1|MODE="demo"/);
 assert.match(script,/\/console\//);
 assert.match(script,/PANEL CONECTADO A SUPABASE/);
});
