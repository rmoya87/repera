import {navIcon} from './nav-icons.js';

const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const euros=v=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(Number(v||0)/100);
const date=v=>v?new Date(v).toLocaleDateString('es-ES'):'—';
const type=v=>v==='personal_trainer'?'Entrenador personal':v==='sports_center'?'Centro deportivo':'Gimnasio';
const safeImage=url=>typeof url==='string'&&/^https:\/\//i.test(url)?esc(url):'';
const initials=name=>String(name||'?').trim().split(/\s+/).slice(0,2).map(s=>s[0]||'').join('').toUpperCase();
const photo=(url,name,size='')=>safeImage(url)
 ?`<img class="pa-photo ${size}" src="${safeImage(url)}" alt="" loading="lazy" referrerpolicy="no-referrer">`
 :`<span class="pa-photo pa-photo-fallback ${size}" aria-hidden="true">${esc(initials(name))}</span>`;
const validNumber=v=>Number.isFinite(Number(v))?Number(v):0;
const tabs=[
 ['home','Inicio','dashboard'],['centers','Centros','team'],['athletes','Atletas','clients'],
 ['payments','Pagos','billing'],['plans','Planes y precios','products'],
 ['support','Soporte','notifications'],['audit','Auditoría','calendar'],
 ['admin-settings','Configuración','settings']
];
const button=(label,action,more='')=>`<button type="button" class="pa-button" data-admin-action="${action}" ${more}>${label}</button>`;
const stat=(label,value,help='')=>`<article class="pa-stat"><small>${esc(label)}</small><strong>${esc(value)}</strong><span>${esc(help)}</span></article>`;
const label=(v)=>v==='active'?'Activo':v==='suspended'?'Suspendido':v==='paid'?'Pagado':v==='failed'?'Fallido':v==='pending'?'Pendiente':v==='refunded'?'Reembolsado':v;
function statusPill(status){return `<span class="pa-pill ${status==='active'||status==='paid'?'good':status==='suspended'||status==='failed'?'bad':''}">${esc(label(status||'active'))}</span>`;}
const empty=(title,text)=>`<div class="pa-empty"><strong>${esc(title)}</strong><p>${esc(text)}</p></div>`;
const table=(heads,rows)=>`<div class="pa-table-wrap"><table class="pa-table"><thead><tr>${heads.map(h=>`<th scope="col">${esc(h)}</th>`).join('')}</tr></thead><tbody>${rows||`<tr><td colspan="${heads.length}">Sin registros</td></tr>`}</tbody></table></div>`;
const orgRow=o=>`<tr><td><div class="pa-identity">${photo(o.avatar_url,o.name)}<div><button type="button" class="pa-text-button" data-admin-action="view-org" data-id="${esc(o.id)}">${esc(o.name)}</button><small>${esc(o.public_email||o.email||o.slug||'')}</small></div></div></td><td><span class="pa-kind">${esc(type(o.kind))}</span></td><td>${validNumber(o.client_count)}</td><td>${validNumber(o.active_clients)}</td><td>${esc(o.paid_plan||'Sin plan confirmado')}</td><td>${statusPill(o.status)}</td><td>${date(o.created_at)}</td><td>${button('Abrir','view-org',`data-id="${esc(o.id)}"`)}</td></tr>`;
const orgTable=orgs=>table(['Centro','Tipo','Clientes','Activos','Plan','Estado','Alta','Acción'],orgs.map(orgRow).join(''));
function heading(title,description,action=''){return `<div class="pa-heading"><div><h1>${title}</h1><p>${description}</p></div>${action}</div>`;}
const field=(name,title,value='',type='text',extra='')=>`<label class="pa-field"><span>${title}</span><input name="${name}" type="${type}" value="${esc(value)}" ${extra}></label>`;
const currencyTotal=payments=>payments.filter(p=>p.status==='paid'&&p.currency==='EUR').reduce((sum,p)=>sum+validNumber(p.amount_cents),0);
function filteredPayments(finance,filter={}){
 const scope=filter.paymentScope==='b2c'?'client_payments':'payments';
 return (finance[scope]||[]).filter(p=>
   (!filter.org||filter.org==='all'||p.org_id===filter.org)&&
   (!filter.paymentStatus||filter.paymentStatus==='all'||p.status===filter.paymentStatus)&&
   (!filter.dateFrom||String(p.created_at).slice(0,10)>=filter.dateFrom)&&
   (!filter.dateTo||String(p.created_at).slice(0,10)<=filter.dateTo));
}
function formattedMoney(cents,currency='EUR'){
 try{return new Intl.NumberFormat('es-ES',{style:'currency',currency}).format(Number(cents||0)/100);}
 catch{return String(Number(cents||0)/100)+' '+String(currency);}
}
function organizationDetail(o,opts){
 const {plans}=opts;
 const suspend=o.status==='suspended';
 return `${heading(esc(o.name),'Ficha global del negocio · '+esc(type(o.kind)),button('Volver a centros','back-org'))}
 <div class="pa-metrics">${stat('Clientes registrados',o.client_count||0)}${stat('Clientes activos',o.active_clients||0)}${stat('Miembros del equipo',o.member_count||0)}${stat('Sesiones registradas',o.sessions||0)}</div>
 <div class="pa-layout">
 <section class="pa-panel"><div class="pa-identity pa-detail-identity">${photo(o.avatar_url,o.name,'large')}<h2>Perfil y configuración</h2></div>
 <dl class="pa-details"><dt>Nombre comercial</dt><dd>${esc(o.name)}</dd><dt>Identificador</dt><dd>${esc(o.slug)}</dd><dt>Actividad</dt><dd>${esc(type(o.kind))}</dd><dt>Correo público</dt><dd>${esc(o.email||'—')}</dd><dt>Teléfono</dt><dd>${esc(o.phone||'—')}</dd><dt>Web</dt><dd>${esc(o.website||'—')}</dd><dt>Dirección</dt><dd>${esc(o.address||'—')}</dd><dt>Zona horaria</dt><dd>${esc(o.timezone||'Europe/Madrid')}</dd><dt>Descripción</dt><dd>${esc(o.description||'—')}</dd></dl>
 <p class="pa-muted">Para editar todos los ajustes del negocio utiliza el acceso delegado y el menú Configuración. Los datos fiscales privados no se exponen en el listado global.</p>
 </section>
 <section class="pa-panel"><h2>Suscripción y situación</h2>
 <div class="pa-inline"><strong>${statusPill(o.status)}</strong><span>${esc(o.status_reason||'')}</span></div>
 <dl class="pa-details"><dt>Plan</dt><dd>${esc(plans.find(p=>p.plan_key===o.paid_plan)?.title||o.paid_plan||'Sin suscripción confirmada')}</dd><dt>Fin de prueba</dt><dd>${date(o.trial_ends_at)}</dd><dt>Pagado hasta</dt><dd>${date(o.paid_until)}</dd><dt>Última reserva</dt><dd>${date(o.last_activity)}</dd></dl>
 <p class="pa-muted">Los cambios de plan y su renovación requieren confirmación del proveedor de pago. No se activa una suscripción desde el panel.</p>
 <form data-admin-form="status" class="pa-form"><input type="hidden" name="org_id" value="${esc(o.id)}">
 <input type="hidden" name="status" value="${suspend?'active':'suspended'}">
 ${field('reason',suspend?'Motivo de reactivación':'Motivo de suspensión','','text','minlength="8" maxlength="300" required')}
 <button type="submit" class="pa-button ${suspend?'':'danger'}">${suspend?'Reactivar negocio':'Suspender negocio'}</button></form>
 </section></div>
 <section class="pa-panel"><h2>Gestionar como este negocio</h2>
 <p>Acceso temporal de 30 minutos, con motivo obligatorio y registro de entrada y salida. Se mantienen las restricciones sobre datos privados del deportista.</p>
 <form data-admin-form="delegate" class="pa-form pa-delegate-form"><input type="hidden" name="org_id" value="${esc(o.id)}">
 <label class="pa-field"><span>Motivo del acceso delegado</span><textarea name="reason" required minlength="12" maxlength="300" rows="2" placeholder="Por ejemplo: revisar un problema de reservas comunicado por el propietario"></textarea></label>
 <button class="pa-button primary" type="submit">Acceder como administrador del negocio</button></form></section>
 `;
}
function overview(orgs,financial,history){
 const gyms=orgs.filter(o=>o.kind!=='personal_trainer');
 const trainers=orgs.filter(o=>o.kind==='personal_trainer');
 const paid=(financial.payments||[]).filter(p=>p.status==='paid');
 return `${heading('Centro de control','Situación real de Repera y accesos directos a la gestión de plataforma.')}
 <div class="pa-metrics">
 ${stat('Gimnasios',gyms.length)}${stat('Entrenadores',trainers.length)}
 ${stat('Clientes activos',orgs.reduce((x,o)=>x+validNumber(o.active_clients),0),'Por organización; una persona puede pertenecer a varias')}
 ${stat('Ingresos B2B verificados',euros(currencyTotal(paid)),'Solo transacciones confirmadas en EUR')}
 ${stat('Negocios suspendidos',orgs.filter(o=>o.status==='suspended').length)}
 ${stat('Pruebas vigentes',orgs.filter(o=>!o.paid_plan&&o.trial_ends_at&&new Date(o.trial_ends_at)>new Date()).length)}
 </div>
 <div class="pa-layout"><section class="pa-panel"><h2>Acciones rápidas</h2>
 <div class="pa-actions">${button('Gestionar centros','go-centers')}${button('Ver atletas','go-athletes')}${button('Consultar pagos','go-payments')}${button('Dar de alta un negocio','go-provision')}</div></section>
 <section class="pa-panel"><h2>Últimos eventos</h2>${history.length?history.slice(0,6).map(e=>`<div class="pa-event"><b>${esc(e.action)}</b><small>${date(e.created_at)}</small></div>`).join(''):empty('Sin eventos','Aquí aparecerán las operaciones administrativas auditadas.')}</section></div>
 `;
}
function directory(orgs,filter){
 const needle=String(filter.search||'').trim().toLocaleLowerCase('es-ES');
 let list=orgs.filter(o=>(!needle||[o.name,o.email,o.slug].some(s=>String(s||'').toLocaleLowerCase('es-ES').includes(needle)))
   &&(!filter.status||filter.status==='all'||o.status===filter.status)
   &&(!filter.kind||filter.kind==='all'||(filter.kind==='gym'?o.kind!=='personal_trainer':o.kind==='personal_trainer')));
 return `${heading('Centros','Gimnasios, centros deportivos y entrenadores personales en un solo listado.',button('Añadir centro','go-provision'))}
 <section class="pa-panel"><div class="pa-filters">
 ${field('search','Buscar centro',filter.search,'search','data-admin-filter="search" placeholder="Nombre, correo o identificador"')}
 <label class="pa-field"><span>Tipo de centro</span><select data-admin-filter="kind">
 <option value="all" ${!filter.kind||filter.kind==='all'?'selected':''}>Todos los tipos</option>
 <option value="gym" ${filter.kind==='gym'?'selected':''}>Gimnasios y centros</option>
 <option value="personal_trainer" ${filter.kind==='personal_trainer'?'selected':''}>Entrenadores personales</option></select></label>
 <label class="pa-field"><span>Estado</span><select data-admin-filter="status">
 <option value="all" ${filter.status==='all'?'selected':''}>Todos</option>
 <option value="active" ${filter.status==='active'?'selected':''}>Activos</option>
 <option value="suspended" ${filter.status==='suspended'?'selected':''}>Suspendidos</option></select></label>
 <span class="pa-filter-count">${list.length} resultados</span></div>
 ${list.length?orgTable(list):empty('No hay centros con esos filtros','Prueba otra búsqueda o añade un centro nuevo.')}</section>`;
}
function paymentsPage(orgs,finance,filter){
 const intents=finance.intents||[];
 const rows=filteredPayments(finance,filter);
 const b2c=filter.paymentScope==='b2c';
 const names=new Map(orgs.map(o=>[o.id,o.name]));
 return `${heading('Pagos globales','Consulta separada de suscripciones a Repera (B2B) y cobros de los negocios a sus clientes (B2C). Solo movimientos verificados por backend.',button('Exportar CSV','export-payments'))}
 <div class="pa-metrics">${stat('Cobrado en EUR y verificado',euros(currencyTotal(rows)))}${stat('Pagos confirmados',rows.filter(p=>p.status==='paid').length)}
 ${stat('Fallidos',rows.filter(p=>p.status==='failed').length)}${stat('Solicitudes de plan B2B',intents.length,'No equivalen a cobros')}</div>
 <section class="pa-panel"><div class="pa-filters"><label class="pa-field"><span>Tipo de operación</span><select data-admin-filter="paymentScope"><option value="b2b" ${!b2c?'selected':''}>Suscripciones a Repera · B2B</option><option value="b2c" ${b2c?'selected':''}>Cobros de negocios · B2C</option></select></label><label class="pa-field"><span>Organización</span><select data-admin-filter="org"><option value="all">Todas las organizaciones</option>${orgs.map(o=>`<option value="${esc(o.id)}" ${filter.org===o.id?'selected':''}>${esc(o.name)}</option>`).join('')}</select></label>
 <label class="pa-field"><span>Estado de cobro</span><select data-admin-filter="paymentStatus">${['all','paid','pending','failed','refunded','partially_refunded'].map(s=>`<option value="${s}" ${filter.paymentStatus===s?'selected':''}>${s==='all'?'Todos':esc(label(s))}</option>`).join('')}</select></label>
 ${field('dateFrom','Desde',filter.dateFrom||'','date','data-admin-filter="dateFrom"')}
 ${field('dateTo','Hasta',filter.dateTo||'','date','data-admin-filter="dateTo"')}</div>
 ${rows.length?table(['Fecha','Negocio','Importe','Divisa','Estado','Proveedor'],rows.map(p=>`<tr><td>${date(p.created_at)}</td><td>${esc(names.get(p.org_id)||'—')}</td><td>${esc(formattedMoney(p.amount_cents,p.currency))}</td><td>${esc(p.currency)}</td><td>${statusPill(p.status)}</td><td>${esc(p.provider)}</td></tr>`).join('')):empty('No hay cobros verificados',b2c?'Stripe Connect o el cobro externo verificado aún no ha registrado transacciones.':'Stripe Billing aún no ha registrado transacciones.')}

 </section>
 <section class="pa-panel"><h2>Solicitudes de suscripción (sin cargo)</h2>${intents.length?table(['Fecha','Negocio','Plan solicitado','Estado'],intents.map(i=>`<tr><td>${date(i.created_at)}</td><td>${esc(names.get(i.org_id)||'—')}</td><td>${esc(i.plan_key)}</td><td>${esc(i.status)}</td></tr>`).join('')):empty('Ninguna solicitud','Los nuevos intereses de contratación aparecerán aquí.')}</section>`;
}
function provisioning(pending,plans){
 return `${heading('Añadir centro','Prepara un gimnasio, centro deportivo o entrenador personal y asígnalo a su futuro propietario.')}
 <div class="pa-layout"><section class="pa-panel"><h2>Datos del centro</h2>
 <form class="pa-form" data-admin-form="provision">
 <div class="pa-brand-picker"><div class="pa-brand-preview">${photo(null,'Centro','large')}<img class="pa-brand-upload-preview" data-admin-image-preview hidden alt="Vista previa del logo o foto"></div>
 <div><strong>Logo o fotografía</strong><p>JPG, PNG o WebP · máximo 8 MB. La imagen se optimiza y se sube a Supabase.</p>
 <label class="pa-file-label">Seleccionar imagen<input type="file" name="avatarFile" accept="image/jpeg,image/png,image/webp" data-admin-image-file></label></div></div>
 ${field('name','Nombre comercial','','text','required minlength="2" maxlength="120"')}
 <label class="pa-field"><span>Tipo de centro</span><select name="kind" required data-provision-kind>
 <option value="gym">Gimnasio</option><option value="personal_trainer">Entrenador personal</option></select></label>
 ${field('email','Correo del futuro propietario','','email','required maxlength="180"')}
 <label class="pa-field"><span>Plan de referencia</span><select name="plan">
 <option value="">Sin plan · prueba gratuita</option>
 ${plans.filter(p=>p.is_active).map(p=>`<option data-audience="${esc(p.audience)}" value="${esc(p.plan_key)}">${esc(p.title)} · ${esc(type(p.audience))} · ${euros(p.monthly_price_cents)}/mes</option>`).join('')}
 </select></label>
 <p class="pa-muted">Se prepara la ficha. El propietario debe confirmar su correo e iniciar sesión para activarla. Los planes no generan cobros automáticamente.</p>
 <button type="submit" class="pa-button primary">Preparar alta</button></form></section>
 <section class="pa-panel"><h2>Altas preparadas</h2>
 ${pending.length?pending.map(p=>`<div class="pa-event pa-pending-event"><div class="pa-identity">${photo(p.avatar_url,p.name)}<div><strong>${esc(p.name)}</strong><small>${esc(p.email)} · ${esc(type(p.kind))}</small></div></div>${statusPill(p.status)}</div>`).join(''):empty('Aún no hay altas','Los centros creados aparecerán aquí hasta que el propietario complete su registro.')}</section></div>`;
}
function support(orgs,pending){
 return `${heading('Soporte y operaciones','Punto de entrada para incidencias, acceso delegado y altas pendientes.')}
 <div class="pa-layout"><section class="pa-panel"><h2>Atender un negocio</h2><p>Selecciona una organización y utiliza «Gestionar como este negocio» indicando el motivo. El acceso dura 30 minutos y puedes salir cuando quieras.</p>
 ${orgs.slice(0,15).map(o=>`<div class="pa-event"><strong>${esc(o.name)}</strong>${button('Abrir ficha','view-org',`data-id="${esc(o.id)}"`)}</div>`).join('')||empty('Sin organizaciones','No hay negocios registrados.')}
 </section><section class="pa-panel"><h2>Altas que requieren registro</h2>${pending.filter(p=>p.status==='pending').length?pending.filter(p=>p.status==='pending').map(p=>`<div class="pa-event"><strong>${esc(p.name)}</strong><small>${esc(p.email)}</small></div>`).join(''):empty('Sin pendientes','Todas las solicitudes han sido reclamadas o aún no hay solicitudes.')}</section></div>`;
}
export function renderPlatformAdmin({tab='home',orgs=[],finance={},pending=[],history=[],plans=[],selectedOrg='',filter={},busy=false,error='',notice='',email=''}) {
 const o=orgs.find(o=>o.id===selectedOrg);
 const headings={home:'Inicio',gyms:'Gimnasios',trainers:'Entrenadores',users:'Usuarios y clientes',payments:'Pagos',plans:'Planes y precios',support:'Soporte',audit:'Auditoría','admin-settings':'Configuración',provision:'Nuevo negocio'};
 let body='';
 if(o)body=organizationDetail(o,{plans});
 else if(tab==='home')body=overview(orgs,finance,history);
 else if(tab==='gyms'||tab==='trainers')body=directory(orgs,tab==='gyms'?'gym':'trainer',filter);
 else if(tab==='payments')body=paymentsPage(orgs,finance,filter);
 else if(tab==='provision')body=provisioning(pending,plans);
 else if(tab==='plans')body=`${heading('Planes y precios','Edita el catálogo comercial. Estos cambios no crean pagos ni activan suscripciones.')}${renderPlanAdministration(plans)}`;
 else if(tab==='users')body=`${heading('Usuarios y clientes','Recuentos por negocio sin exposición global de fichas personales.')}
 <div class="pa-metrics">${stat('Relaciones comerciales',orgs.reduce((s,o)=>s+validNumber(o.client_count),0),'No es un recuento de personas únicas')}${stat('Miembros de organizaciones',orgs.reduce((s,o)=>s+validNumber(o.member_count),0))}</div>
 <section class="pa-panel"><h2>Clientes por negocio</h2>${orgTable(orgs)}<p class="pa-muted">Para gestionar fichas identificables, utiliza el acceso delegado y los permisos y consentimientos correspondientes.</p></section>`;
 else if(tab==='support')body=support(orgs,pending);
 else if(tab==='audit')body=`${heading('Auditoría de plataforma','Acciones de administración y accesos delegados, con fecha y negocio asociado.')}<section class="pa-panel">${history.length?table(['Fecha','Acción','Negocio','Detalle'],history.map(h=>`<tr><td>${date(h.created_at)}</td><td>${esc(h.action)}</td><td>${esc(orgs.find(o=>o.id===h.org_id)?.name||'—')}</td><td>${esc(h.details?.reason||h.details?.status||'—')}</td></tr>`).join('')):empty('Sin operaciones','Las acciones administrativas aparecerán aquí.')}</section>`;
 else body=`${heading('Configuración global','Acceso restringido al administrador verificado de Repera.')}<section class="pa-panel"><h2>Integraciones y control</h2><p>Autenticación y permisos verificados por Supabase. Para pagos reales se requiere configurar Stripe Billing, webhooks firmados y emisión fiscal.</p><p>Los datos privados de atletas no forman parte de la visión general.</p></section>`;
 return `<div class="pa-shell"><aside class="pa-sidebar"><div class="pa-brand"><span class="pa-brand-symbol">R</span><div><strong>repera</strong><small>ADMINISTRACIÓN</small></div></div>
 <div class="pa-sidebar-label">PLATAFORMA</div><nav aria-label="Administración Repera">
 ${tabs.map(([id,name,icon])=>`<button type="button" data-admin-tab="${id}" class="${tab===id&&!o?'active':''}" aria-current="${tab===id&&!o?'page':'false'}">${navIcon(icon)}<span>${name}</span></button>`).join('')}</nav>
 <div class="pa-sidebar-bottom"><span>Cuenta de plataforma</span><small>${esc(email)}</small><button type="button" data-action="logout">Cerrar sesión</button></div></aside>
 <div class="pa-main"><header class="pa-top"><div><span>Repera</span> / ${esc(o?o.name:(headings[tab]||'Inicio'))}</div><div class="pa-top-right"><span class="pa-live">Supabase conectado</span>${button('Nuevo negocio','go-provision')}<span class="pa-avatar">AD</span></div></header>
 <main class="pa-content" id="platform-main">${error?`<div role="alert" class="pa-error">${esc(error)}</div>`:''}${notice?`<div role="status" class="pa-notice">${esc(notice)}</div>`:''}
 ${body}</main></div></div>`;
}
export function paymentCSV(orgs,finance,filter={}){
 const names=new Map(orgs.map(o=>[o.id,o.name]));
 const data=filteredPayments(finance,filter);
 const csv=x=>{const raw=String(x??'');const safe=/^\s*[=+@-]/.test(raw)?"'"+raw:raw;return '"'+safe.replace(/"/g,'""')+'"';};
 return [['Fecha','Negocio','Importe_centimos','Divisa','Estado','Proveedor'].join(';'),...data.map(p=>[p.created_at,names.get(p.org_id)||'',p.amount_cents,p.currency,p.status,p.provider].map(csv).join(';'))].join('\r\n');
}
