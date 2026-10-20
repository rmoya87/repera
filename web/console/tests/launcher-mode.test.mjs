import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const launcher=readFileSync(new URL('../../../Repera-Business.command',import.meta.url),'utf8');

test('Repera Business abre el login Supabase por defecto y ofrece demo explícita',()=>{
 assert.match(launcher,/MODE="connected"/);
 assert.match(launcher,/if \[\[ "\$\{1:-\}" == "--demo" \]\]; then MODE="demo"; fi/);
 assert.match(launcher,/exec python3 - "\$ROOT\/web" "\$MODE"/);
 assert.match(launcher,/path = "\/console\/\?demo=1" if mode == "demo" else "\/console\/"/);
 assert.doesNotMatch(launcher,/^url = f"[^\n]*\?demo=1"/m);
});
