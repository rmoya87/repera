import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const launcher=readFileSync(new URL('../../../Repera-Business.command',import.meta.url),'utf8');

test('Repera Business inicia únicamente un panel conectado por loopback, sin datos ficticios',()=>{
 assert.match(launcher,/PANEL CONECTADO A SUPABASE/);
 assert.match(launcher,/set -euo pipefail/);
 assert.match(launcher,/if \[\[ \$# -ne 0 \]\]/);
 assert.match(launcher,/no dispone de modo demostración/);
 assert.match(launcher,/server = LoopbackServer/);
 assert.match(launcher,/127\.0\.0\.1/);
 assert.match(launcher,/\/console\//);
 assert.doesNotMatch(launcher,/\?demo=1/);
});
