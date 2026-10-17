#!/usr/bin/env python3
"""Generate a self-contained canvas.html from progress.json (no network required)."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROGRESS = ROOT / "progress.json"
OUT = ROOT / "canvas.html"

STATUSES = ("pending", "in_progress", "in_review", "blocked", "completed")
STATUS_LABELS = {
    "pending": "Pendiente",
    "in_progress": "En curso",
    "in_review": "En revisión",
    "blocked": "Bloqueado",
    "completed": "Completado",
}


def recompute(data: dict) -> dict:
    tasks = data["tasks"]
    counts = {s: 0 for s in STATUSES}
    for t in tasks:
        st = t.get("status", "pending")
        if st not in counts:
            st = "pending"
            t["status"] = st
        counts[st] += 1
    total = len(tasks)
    completed = counts["completed"]
    data["global"] = {
        "total": total,
        "completed": completed,
        "inProgress": counts["in_progress"],
        "inReview": counts["in_review"],
        "blocked": counts["blocked"],
        "pending": counts["pending"],
        "percentComplete": round((completed / total) * 100, 1) if total else 0.0,
    }
    phases: dict[str, dict] = {}
    for p in ("P0", "P1", "P2", "P3", "P4"):
        pt = [t for t in tasks if t.get("phase") == p]
        pc = {s: sum(1 for t in pt if t.get("status") == s) for s in STATUSES}
        label = (data.get("phases") or {}).get(p, {}).get("label", p)
        phases[p] = {
            "label": label,
            "total": len(pt),
            "completed": pc["completed"],
            "inProgress": pc["in_progress"],
            "inReview": pc["in_review"],
            "blocked": pc["blocked"],
            "pending": pc["pending"],
        }
    data["phases"] = phases
    return data


def validate(data: dict) -> list[str]:
    errors: list[str] = []
    if data.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    ids = [t.get("id") for t in data.get("tasks", [])]
    if len(ids) != len(set(ids)):
        errors.append("duplicate task ids")
    for t in data.get("tasks", []):
        if t.get("status") not in STATUSES:
            errors.append(f"{t.get('id')}: invalid status {t.get('status')}")
        if t.get("phase") not in ("P0", "P1", "P2", "P3", "P4"):
            errors.append(f"{t.get('id')}: invalid phase")
        if t.get("status") == "completed":
            tests = t.get("tests") or []
            if not tests:
                errors.append(f"{t.get('id')}: completed without tests[] evidence")
            elif all(x.get("result") == "blocked" for x in tests if isinstance(x, dict)):
                # Allowed: completed implementation with blocked device validation noted
                pass
            elif any(
                isinstance(x, dict) and x.get("result") == "pass" for x in tests
            ):
                pass
            else:
                # Require at least one explicit result
                if not any(isinstance(x, dict) and "result" in x for x in tests):
                    errors.append(f"{t.get('id')}: completed tests need result field")
    return errors


HTML_TEMPLATE = r"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Gymbro · iOS 27 Modernization Canvas</title>
<style>
:root {
  --bg: #0b0f0c;
  --panel: #121a14;
  --panel2: #182019;
  --border: #243028;
  --text: #e8f0ea;
  --muted: #8fa396;
  --accent: #30d158;
  --accent-dim: rgba(48,209,88,0.15);
  --warn: #ffd60a;
  --danger: #ff453a;
  --blue: #64d2ff;
  --purple: #bf5af2;
  --radius: 14px;
  --font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
}
* { box-sizing: border-box; }
body {
  margin: 0; font-family: var(--font); background: var(--bg); color: var(--text);
  line-height: 1.45; min-height: 100vh;
}
a { color: var(--accent); }
header {
  position: sticky; top: 0; z-index: 20;
  background: rgba(11,15,12,0.92); backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border); padding: 14px 18px;
}
.header-row { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; justify-content: space-between; }
h1 { font-size: 1.15rem; margin: 0; font-weight: 700; letter-spacing: -0.02em; }
.meta { color: var(--muted); font-size: 0.8rem; }
.progress-wrap { margin-top: 10px; }
.bar {
  height: 10px; background: #1a2420; border-radius: 999px; overflow: hidden;
  border: 1px solid var(--border);
}
.bar > span {
  display: block; height: 100%; background: linear-gradient(90deg, #1f8f45, var(--accent));
  width: 0%; transition: width 0.35s ease;
}
.pct { font-variant-numeric: tabular-nums; color: var(--accent); font-weight: 600; }
main { padding: 16px 18px 48px; max-width: 1280px; margin: 0 auto; }
.grid { display: grid; gap: 14px; }
@media (min-width: 900px) {
  .grid-4 { grid-template-columns: repeat(4, 1fr); }
  .grid-5 { grid-template-columns: repeat(5, 1fr); }
  .layout { grid-template-columns: 1.4fr 1fr; align-items: start; }
}
.card {
  background: var(--panel); border: 1px solid var(--border); border-radius: var(--radius); padding: 14px;
}
.card h2 { margin: 0 0 10px; font-size: 0.95rem; }
.phase-pct { font-size: 1.4rem; font-weight: 700; color: var(--accent); }
.muted { color: var(--muted); font-size: 0.8rem; }
.filters { display: flex; flex-wrap: wrap; gap: 8px; margin: 14px 0; }
select, input[type="search"] {
  background: var(--panel2); color: var(--text); border: 1px solid var(--border);
  border-radius: 10px; padding: 8px 10px; font: inherit;
}
.kanban {
  display: grid; gap: 10px; grid-template-columns: 1fr;
}
@media (min-width: 1100px) {
  .kanban { grid-template-columns: repeat(5, 1fr); }
}
.col { background: var(--panel2); border-radius: var(--radius); border: 1px solid var(--border); min-height: 120px; }
.col-h {
  padding: 10px 12px; border-bottom: 1px solid var(--border); font-size: 0.78rem;
  text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); display: flex; justify-content: space-between;
}
.col-b { padding: 8px; display: flex; flex-direction: column; gap: 8px; }
.task {
  background: var(--panel); border: 1px solid var(--border); border-radius: 12px; padding: 10px;
  cursor: pointer; text-align: left; width: 100%; color: inherit; font: inherit;
}
.task:hover { border-color: var(--accent); }
.task .id { font-weight: 700; color: var(--accent); font-size: 0.78rem; }
.task .title { font-size: 0.88rem; margin-top: 2px; }
.badges { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 8px; }
.badge {
  font-size: 0.68rem; padding: 2px 7px; border-radius: 999px; border: 1px solid var(--border);
  color: var(--muted);
}
.badge.p0 { color: var(--danger); border-color: rgba(255,69,58,0.4); }
.badge.p1 { color: var(--warn); border-color: rgba(255,214,10,0.35); }
.badge.p2 { color: var(--blue); border-color: rgba(100,210,255,0.35); }
.badge.p3 { color: var(--purple); border-color: rgba(191,90,242,0.35); }
.badge.p4 { color: var(--muted); }
.badge.critical { background: rgba(255,69,58,0.12); color: var(--danger); }
.badge.high { background: rgba(255,214,10,0.1); color: var(--warn); }
.drawer {
  position: fixed; inset: 0; background: rgba(0,0,0,0.55); z-index: 40; display: none;
  justify-content: flex-end;
}
.drawer.open { display: flex; }
.drawer-panel {
  width: min(440px, 100%); background: var(--panel); border-left: 1px solid var(--border);
  padding: 18px; overflow: auto; height: 100%;
}
.drawer-panel h3 { margin-top: 0; }
.close { float: right; background: transparent; border: 0; color: var(--muted); font-size: 1.2rem; cursor: pointer; }
ul.compact { margin: 6px 0; padding-left: 18px; }
ul.compact li { margin: 2px 0; font-size: 0.85rem; }
.history { max-height: 280px; overflow: auto; }
.history li { border-bottom: 1px solid var(--border); padding: 8px 0; font-size: 0.82rem; }
code { font-size: 0.78rem; background: #0e1511; padding: 1px 5px; border-radius: 4px; }
</style>
</head>
<body>
<header>
  <div class="header-row">
    <div>
      <h1>Gymbro · Modernización iOS 27 / watchOS 27</h1>
      <div class="meta">
        Rama <code id="branch">—</code> · Base <code id="base">—</code> · HEAD <code id="head">—</code><br />
        Actualizado <span id="updated">—</span>
      </div>
    </div>
    <div class="pct" id="globalPct">0%</div>
  </div>
  <div class="progress-wrap">
    <div class="bar"><span id="globalBar"></span></div>
    <div class="meta" style="margin-top:6px" id="globalCounts"></div>
  </div>
</header>
<main>
  <section class="grid grid-5" id="phaseCards"></section>

  <div class="filters">
    <select id="filterPhase"><option value="">Todas las fases</option>
      <option>P0</option><option>P1</option><option>P2</option><option>P3</option><option>P4</option>
    </select>
    <select id="filterPriority"><option value="">Todas las prioridades</option>
      <option value="critical">critical</option><option value="high">high</option>
      <option value="medium">medium</option><option value="low">low</option>
    </select>
    <select id="filterStatus"><option value="">Todos los estados</option>
      <option value="pending">Pendiente</option>
      <option value="in_progress">En curso</option>
      <option value="in_review">En revisión</option>
      <option value="blocked">Bloqueado</option>
      <option value="completed">Completado</option>
    </select>
    <input type="search" id="filterText" placeholder="Buscar id o título…" style="min-width:180px;flex:1" />
  </div>

  <section class="kanban" id="kanban"></section>

  <div class="grid layout" style="margin-top:16px">
    <section class="card">
      <h2>Histórico</h2>
      <ul class="history" id="history"></ul>
    </section>
    <section class="card">
      <h2>Bloqueos y métricas</h2>
      <div id="blockers" class="muted">Sin bloqueos registrados.</div>
      <h2 style="margin-top:16px">Pull requests</h2>
      <div id="prs" class="muted">Ninguna aún.</div>
      <h2 style="margin-top:16px">Métricas</h2>
      <div id="metrics" class="muted">Sin mediciones verificables todavía.</div>
    </section>
  </div>
</main>

<div class="drawer" id="drawer">
  <div class="drawer-panel" id="drawerPanel"></div>
</div>

<script id="progress-data" type="application/json">__PROGRESS_JSON__</script>
<script>
const STATUS_LABELS = __STATUS_LABELS__;
const data = JSON.parse(document.getElementById('progress-data').textContent);

function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

function renderHeader() {
  document.getElementById('branch').textContent = data.branch || '—';
  document.getElementById('base').textContent = (data.baseCommit || '').slice(0, 7) || '—';
  document.getElementById('head').textContent = (data.headCommit || '').slice(0, 7) || '—';
  document.getElementById('updated').textContent = data.updatedAt || '—';
  const g = data.global || {};
  document.getElementById('globalPct').textContent = (g.percentComplete ?? 0) + '%';
  document.getElementById('globalBar').style.width = (g.percentComplete ?? 0) + '%';
  document.getElementById('globalCounts').textContent =
    `${g.completed||0} completadas · ${g.inProgress||0} en curso · ${g.inReview||0} revisión · ${g.blocked||0} bloqueadas · ${g.pending||0} pendientes · ${g.total||0} total`;
}

function renderPhases() {
  const el = document.getElementById('phaseCards');
  el.innerHTML = '';
  for (const [key, ph] of Object.entries(data.phases || {})) {
    const pct = ph.total ? Math.round((ph.completed / ph.total) * 100) : 0;
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `<h2>${esc(key)} · ${esc(ph.label||'')}</h2>
      <div class="phase-pct">${pct}%</div>
      <div class="muted">${ph.completed}/${ph.total} · ${ph.inProgress} en curso · ${ph.blocked} bloqueadas</div>
      <div class="bar" style="margin-top:8px"><span style="width:${pct}%"></span></div>`;
    el.appendChild(card);
  }
}

function filteredTasks() {
  const phase = document.getElementById('filterPhase').value;
  const pri = document.getElementById('filterPriority').value;
  const st = document.getElementById('filterStatus').value;
  const q = document.getElementById('filterText').value.trim().toLowerCase();
  return (data.tasks || []).filter(t => {
    if (phase && t.phase !== phase) return false;
    if (pri && t.priority !== pri) return false;
    if (st && t.status !== st) return false;
    if (q && !(String(t.id).toLowerCase().includes(q) || String(t.title).toLowerCase().includes(q))) return false;
    return true;
  });
}

function renderKanban() {
  const tasks = filteredTasks();
  const order = ['pending','in_progress','in_review','blocked','completed'];
  const root = document.getElementById('kanban');
  root.innerHTML = '';
  for (const st of order) {
    const colTasks = tasks.filter(t => t.status === st);
    const col = document.createElement('div');
    col.className = 'col';
    col.innerHTML = `<div class="col-h"><span>${STATUS_LABELS[st]}</span><span>${colTasks.length}</span></div>`;
    const body = document.createElement('div');
    body.className = 'col-b';
    for (const t of colTasks) {
      const btn = document.createElement('button');
      btn.className = 'task';
      btn.type = 'button';
      btn.innerHTML = `<div class="id">${esc(t.id)}</div>
        <div class="title">${esc(t.title)}</div>
        <div class="badges">
          <span class="badge ${esc(String(t.phase).toLowerCase())}">${esc(t.phase)}</span>
          <span class="badge ${esc(t.priority)}">${esc(t.priority)}</span>
        </div>`;
      btn.addEventListener('click', () => openTask(t.id));
      body.appendChild(btn);
    }
    col.appendChild(body);
    root.appendChild(col);
  }
}

function openTask(id) {
  const t = (data.tasks || []).find(x => x.id === id);
  if (!t) return;
  const panel = document.getElementById('drawerPanel');
  const ac = (t.acceptanceCriteria || []).map(x => `<li>${esc(x)}</li>`).join('') || '<li class="muted">—</li>';
  const files = (t.filesModified || []).map(x => `<li><code>${esc(x)}</code></li>`).join('') || '<li class="muted">Ninguno aún</li>';
  const deps = (t.dependsOn || []).map(x => `<code>${esc(x)}</code>`).join(' ') || '—';
  const commits = (t.commits || []).map(x => `<li><code>${esc(x)}</code></li>`).join('') || '<li class="muted">—</li>';
  const tests = (t.tests || []).map(x => {
    if (typeof x === 'string') return `<li>${esc(x)}</li>`;
    return `<li><strong>${esc(x.name||'test')}</strong>: ${esc(x.result||'?')} ${esc(x.detail||'')}</li>`;
  }).join('') || '<li class="muted">Sin pruebas registradas</li>';
  const risks = (t.risks || []).map(x => `<li>${esc(x)}</li>`).join('') || '<li class="muted">—</li>';
  panel.innerHTML = `
    <button class="close" type="button" aria-label="Cerrar" id="closeDrawer">×</button>
    <h3>${esc(t.id)} · ${esc(t.title)}</h3>
    <p class="muted">${esc(t.phase)} · ${esc(t.priority)} · ${esc(STATUS_LABELS[t.status]||t.status)}</p>
    <p>${esc(t.summary||'')}</p>
    <h4>Criterios de aceptación</h4><ul class="compact">${ac}</ul>
    <h4>Dependencias</h4><p>${deps}</p>
    <h4>Riesgos</h4><ul class="compact">${risks}</ul>
    <h4>Archivos modificados</h4><ul class="compact">${files}</ul>
    <h4>Commits</h4><ul class="compact">${commits}</ul>
    <h4>Pruebas</h4><ul class="compact">${tests}</ul>
    <h4>Notas</h4><p class="muted">${esc(t.notes||'—')}</p>
  `;
  document.getElementById('drawer').classList.add('open');
  document.getElementById('closeDrawer').onclick = closeDrawer;
  document.getElementById('drawer').onclick = (e) => { if (e.target.id === 'drawer') closeDrawer(); };
}

function closeDrawer() {
  document.getElementById('drawer').classList.remove('open');
}

function renderSide() {
  const hist = document.getElementById('history');
  hist.innerHTML = (data.history || []).slice().reverse().map(h =>
    `<li><span class="muted">${esc(h.at)}</span><br/>${esc(h.message)}</li>`
  ).join('') || '<li class="muted">Vacío</li>';

  const blockers = data.blockers || [];
  document.getElementById('blockers').innerHTML = blockers.length
    ? '<ul class="compact">' + blockers.map(b => `<li>${esc(typeof b==='string'?b:(b.message||JSON.stringify(b)))}</li>`).join('') + '</ul>'
    : '<span class="muted">Sin bloqueos registrados.</span>';

  const prs = data.pullRequests || [];
  document.getElementById('prs').innerHTML = prs.length
    ? '<ul class="compact">' + prs.map(p => `<li><a href="${esc(p.url||'#')}" target="_blank" rel="noopener">${esc(p.title||p.url)}</a></li>`).join('') + '</ul>'
    : '<span class="muted">Ninguna aún.</span>';

  const m = [...(data.metricsBaseline||[]), ...(data.metricsCurrent||[])];
  document.getElementById('metrics').innerHTML = m.length
    ? '<ul class="compact">' + m.map(x => `<li>${esc(JSON.stringify(x))}</li>`).join('') + '</ul>'
    : '<span class="muted">Sin mediciones verificables todavía.</span>';
}

function refresh() {
  renderHeader();
  renderPhases();
  renderKanban();
  renderSide();
}

['filterPhase','filterPriority','filterStatus','filterText'].forEach(id => {
  document.getElementById(id).addEventListener('input', renderKanban);
  document.getElementById(id).addEventListener('change', renderKanban);
});

refresh();
</script>
</body>
</html>
"""


def build_html(data: dict) -> str:
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    # Prevent </script> breakouts
    payload = payload.replace("<", "\\u003c")
    labels = json.dumps(STATUS_LABELS, ensure_ascii=False)
    return (
        HTML_TEMPLATE.replace("__PROGRESS_JSON__", payload).replace(
            "__STATUS_LABELS__", labels
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate/validate Gymbro iOS27 canvas")
    parser.add_argument("--check", action="store_true", help="Validate only")
    parser.add_argument("--write", action="store_true", help="Write canvas.html")
    args = parser.parse_args()
    if not args.check and not args.write:
        args.write = True

    raw = json.loads(PROGRESS.read_text(encoding="utf-8"))
    data = recompute(raw)
    errors = validate(data)
    if errors:
        print("VALIDATION FAILED:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    # Persist recomputed aggregates back into progress.json when writing
    if args.write:
        PROGRESS.write_text(
            json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        OUT.write_text(build_html(data), encoding="utf-8")
        print(f"OK wrote {OUT.relative_to(ROOT.parent.parent)}")
        print(
            f"progress {data['global']['percentComplete']}% "
            f"({data['global']['completed']}/{data['global']['total']})"
        )
    else:
        print("OK validation passed")
        print(
            f"progress {data['global']['percentComplete']}% "
            f"({data['global']['completed']}/{data['global']['total']})"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
