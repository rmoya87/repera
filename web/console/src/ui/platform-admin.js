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
 ['support','Soporte','notifications'],
 ['admin-settings','Configuración','settings']
];
const button=(label,action,more='')=>`<button type="button" class="pa-button" data-admin-action="${action}" ${more}>${label}</button>`;
const stat=(label,value,help='')=>`<article class="pa-stat"><small>${esc(label)}</small><strong>${esc(value)}</strong><span>${esc(help)}</span></article>`;
const label=(v)=>v==='active'?'Activo':v==='suspended'?'Suspendido':v==='paid'?'Pagado':v==='failed'?'Fallido':v==='pending'?'Pendiente de registro':v==='claimed'?'Registrado':v==='refunded'?'Reembolsado':v;
function statusPill(status){return `<span class="pa-pill ${status==='active'||status==='paid'?'good':status==='suspended'||status==='failed'?'bad':''}">${esc(label(status||'active'))}</span>`;}
const empty=(title,text)=>`<div class="pa-empty"><strong>${esc(title)}</strong><p>${esc(text)}</p></div>`;
const table=(heads,rows)=>`<div class="pa-table-wrap"><table class="pa-table"><thead><tr>${heads.map(h=>`<th scope="col">${esc(h)}</th>`).join('')}</tr></thead><tbody>${rows||`<tr><td colspan="${heads.length}">Sin registros</td></tr>`}</tbody></table></div>`;
const orgRow=o=>`<tr><td><div class="pa-identity">${photo(o.avatar_url,o.name)}<div><button type="button" class="pa-text-button" data-admin-action="view-org" data-id="${esc(o.id)}">${esc(o.name)}</button><small>${esc(o.owner_email||o.email||o.slug||'')}</small></div></div></td><td><span class="pa-kind">${esc(type(o.kind))}</span></td><td>${validNumber(o.client_count)}</td><td>${validNumber(o.active_clients)}</td><td>${esc(o.paid_plan||'Sin plan confirmado')}</td><td>${statusPill(o.status)}</td><td>${date(o.created_at)}</td><td>${button('Abrir','view-org',`data-id="${esc(o.id)}"`)}</td></tr>`;
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
const stamp=v=>v?new Date(v).toLocaleString('es-ES',{dateStyle:'medium',timeStyle:'short'}):'—';
const readable=(v)=>v==null||v===''?'—':v===true?'Sí':v===false?'No':typeof v==='object'?JSON.stringify(v):String(v);
const details=(pairs)=>`<dl class="pa-details">${pairs.map(([key,val])=>`<dt>${esc(key)}</dt><dd>${esc(readable(val))}</dd>`).join('')}</dl>`;
const moneyRow=p=>`<tr><td>${stamp(p.paid_at)}</td><td>${esc(formattedMoney(p.amount_cents,p.currency))}</td><td>${statusPill(p.status)}</td><td>${esc(p.provider)}</td></tr>`;
const formatListing=(rows)=>rows?.length||0;
function organizationDetail(o,opts){
 const {plans,detail}=opts;const d=detail||{};
 const suspended=o.status==='suspended';
 const actionLabel=suspended?'Reactivar centro':'Suspender centro';
 return `${heading(esc(o.name),'Ficha completa · '+esc(type(o.kind)),button('Volver a centros','back-org'))}
 <div class="pa-metrics pa-center-metrics">${stat('Clientes registrados',o.client_count||0)}
 ${stat('Clientes activos',o.active_clients||0)}${stat('Equipo',o.member_count||0)}
 ${stat('Sesiones y clases',o.sessions||0)}</div>
 <div class="pa-panel pa-center-hero">
 <div class="pa-identity">${photo(o.avatar_url,o.name,'large')}<div><h2>${esc(o.name)}</h2>
 <p>${esc(type(o.kind))} · ${statusPill(o.status)}
 ${o.registration_status==='pending'?'<span class="pa-pill">Pendiente de aceptación del propietario</span>':''}</p></div></div>
 <div class="pa-center-hero-actions"><button type="button" class="pa-button primary" data-admin-action="access-center" data-id="${esc(o.id)}">Entrar como administrador del centro</button></div>
 </div>
 <div class="pa-layout"><section class="pa-panel"><h2>Datos del centro</h2>
 ${details([['Nombre',o.name],['Tipo',type(o.kind)],['Código',o.slug],
 ['Correo público',o.email],['Teléfono',o.phone],['Sitio web',o.website],['Dirección',o.address],
 ['Zona horaria',o.timezone],['Descripción',o.description],
 ['Visibilidad',d.center?.is_discoverable?'Publicado':'No publicado'],
 ['Creado',stamp(d.center?.created_at||o.created_at)],
 ['Última actualización',stamp(d.center?.updated_at)]])}
 </section><section class="pa-panel"><h2>Estado y suscripción</h2>
 ${details([['Registro del propietario',o.registration_status==='pending'?'Pendiente':'Completado'],
 ['Correo del futuro propietario',o.owner_email],['Plan',plans.find(p=>p.plan_key===o.paid_plan)?.title||o.paid_plan||'Sin plan de pago'],
 ['Prueba hasta',date(o.trial_ends_at)],['Pagado hasta',date(o.paid_until)],
 ['Última reserva',stamp(o.last_activity)],['Motivo de suspensión',o.status_reason]])}
 <form class="pa-status-inline" data-admin-form="status"><input type="hidden" name="org_id" value="${esc(o.id)}">
 <label class="pa-field"><span>Estado operativo</span><select name="status">
 <option value="active" ${!suspended?'selected':''}>Activo${o.registration_status==='pending'?' · registro pendiente':''}</option>
 <option value="suspended" ${suspended?'selected':''}>Suspendido</option>
 </select></label><button class="pa-button primary" type="submit">Guardar estado</button></form>
 <p class="pa-muted">El estado operativo es independiente de la aceptación del propietario. El cambio queda registrado automáticamente.</p></section></div>
 ${!detail?'<section class="pa-panel"><h2>Personas, fiscalidad y operaciones</h2><p>Cargando información del centro...</p></section>':`
 <div class="pa-layout">
 <section class="pa-panel"><h2>Datos fiscales</h2>${d.legal?details([
 ['Tipo de entidad',d.legal.entity_type],['Razón social',d.legal.legal_name],['NIF/CIF',d.legal.tax_id],
 ['Representante',d.legal.representative_name],['Contacto',d.legal.contact_name],
 ['Email de facturación',d.legal.billing_email],['Dirección fiscal',d.legal.billing_address],
 ['Código postal',d.legal.postal_code],['Población',d.legal.city],
 ['Provincia',d.legal.province],['País',d.legal.country]]):empty('Sin datos fiscales','El centro aún no ha completado sus datos legales.')}</section>
 <section class="pa-panel"><h2>Equipo y accesos (${formatListing(d.team)})</h2>
 ${d.team?.length?table(['Persona','Correo','Rol','Estado'],d.team.map(m=>`<tr>
 <td><div class="pa-identity">${photo(m.avatar_url,m.name)}<span>${esc(m.name)}</span></div></td>
 <td>${esc(m.email||'—')}</td><td>${esc(m.role)}</td><td>${statusPill(m.status)}</td></tr>`).join('')):
 empty('Sin equipo asignado','Este centro puede estar pendiente de aceptación.')}</section></div>
 <section class="pa-panel"><h2>Atletas y clientes vinculados (${formatListing(d.clients)})</h2>
 ${d.clients?.length?table(['Persona','Correo','Teléfono','Estado','Cuenta Repera'],d.clients.map(c=>`<tr>
 <td><div class="pa-identity">${photo(c.avatar_url,c.name)}<strong>${esc(c.name)}</strong></div></td>
 <td>${esc(c.email||'—')}</td><td>${esc(c.phone||'—')}</td><td>${statusPill(c.status)}</td><td>
 ${c.user_id?button('Ver atleta','view-athlete',`data-id="${esc(c.user_id)}"`):'<span class="pa-muted">Sin cuenta asociada</span>'}
 </td></tr>`).join('')):empty('Sin clientes','No hay personas vinculadas todavía.')}</section>
 <div class="pa-layout"><section class="pa-panel"><h2>Grupos (${formatListing(d.groups)})</h2>
 ${d.groups?.length?table(['Grupo','Descripción','Fecha'],d.groups.map(g=>`<tr><td>${esc(g.name)}</td>
 <td>${esc(g.description||'—')}</td><td>${date(g.created_at)}</td></tr>`).join('')):
 empty('Sin grupos','Todavía no se han creado grupos.')}</section>
 <section class="pa-panel"><h2>Actividad del centro</h2>
 ${details([['Reservas totales',d.booking_count||0],
 ['Entrenamientos profesionales programados',d.training_count||0],
 ['Clientes con ficha',d.client_count||0]])}
 <h3>Clases y citas recientes</h3>
 ${d.services?.length?table(['Actividad','Inicio','Estado'],d.services.map(x=>`<tr><td>${esc(x.title)}</td>
 <td>${stamp(x.starts_at)}</td><td>${statusPill(x.status)}</td></tr>`).join('')):
 empty('Sin actividades','No existen citas o clases programadas.')}</section></div>
 <section class="pa-panel"><h2>Últimos pagos de la plataforma</h2>
 ${d.payments?.length?table(['Fecha','Importe','Estado','Proveedor'],d.payments.map(moneyRow).join('')):
 empty('Sin pagos registrados','No hay cobros B2B confirmados asociados a este centro.')}</section>`}
 <p class="pa-muted">Los datos se leen de Supabase y su consulta queda auditada. Los entrenamientos individuales solo se muestran en fichas de atleta con acceso administrativo autorizado.</p>
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
 <option value="pending" ${filter.status==='pending'?'selected':''}>Pendientes de registro</option>
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
 <div class="pa-metrics pa-payments-metrics">${stat('Cobrado en EUR y verificado',euros(currencyTotal(rows)))}${stat('Pagos confirmados',rows.filter(p=>p.status==='paid').length)}
 ${stat('Fallidos',rows.filter(p=>p.status==='failed').length)}${stat('Solicitudes de plan B2B',intents.length,'No equivalen a cobros')}</div>
 <section class="pa-panel"><div class="pa-filters pa-payments-filters"><label class="pa-field"><span>Tipo de operación</span><select data-admin-filter="paymentScope"><option value="b2b" ${!b2c?'selected':''}>Suscripciones a Repera · B2B</option><option value="b2c" ${b2c?'selected':''}>Cobros de negocios · B2C</option></select></label><label class="pa-field"><span>Organización</span><select data-admin-filter="org"><option value="all">Todas las organizaciones</option>${orgs.map(o=>`<option value="${esc(o.id)}" ${filter.org===o.id?'selected':''}>${esc(o.name)}</option>`).join('')}</select></label>
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
 ${plans.filter(p=>p.is_active).map(p=>`<option data-audience="${esc(p.audience)}" value="${esc(p.plan_key)}" ${p.audience!=='gym'?'hidden':''}>${esc(p.title)} · ${esc(type(p.audience))} · ${euros(p.monthly_price_cents)}/mes</option>`).join('')}
 </select></label>
 <p class="pa-muted">Se prepara la ficha. El propietario debe confirmar su correo e iniciar sesión para activarla. Los planes no generan cobros automáticamente.</p>
 <button type="submit" class="pa-button primary">Preparar alta</button></form></section>
 <section class="pa-panel"><h2>Altas preparadas</h2>
 ${pending.length?pending.map(p=>`<div class="pa-event pa-pending-event"><div class="pa-identity">${photo(p.avatar_url,p.name)}<div><strong>${esc(p.name)}</strong><small>${esc(p.email)} · ${esc(type(p.kind))}</small></div></div><div class="pa-actions">${statusPill(p.status)}${p.claimed_org_id?button('Abrir centro','view-org',`data-id="${esc(p.claimed_org_id)}"`):''}</div></div>`).join(''):empty('Aún no hay altas','Los centros creados aparecerán aquí hasta que el propietario complete su registro.')}</section></div>`;
}
function support(orgs,pending){
 return `${heading('Soporte y operaciones','Punto de entrada para incidencias, acceso delegado y altas pendientes.')}
 <div class="pa-layout"><section class="pa-panel"><h2>Atender un negocio</h2><p>Selecciona una organización y utiliza «Gestionar como este negocio» indicando el motivo. El acceso dura 30 minutos y puedes salir cuando quieras.</p>
 ${orgs.slice(0,15).map(o=>`<div class="pa-event"><strong>${esc(o.name)}</strong>${button('Abrir ficha','view-org',`data-id="${esc(o.id)}"`)}</div>`).join('')||empty('Sin organizaciones','No hay negocios registrados.')}
 </section><section class="pa-panel"><h2>Altas que requieren registro</h2>${pending.filter(p=>p.status==='pending').length?pending.filter(p=>p.status==='pending').map(p=>`<div class="pa-event"><strong>${esc(p.name)}</strong><small>${esc(p.email)}</small></div>`).join(''):empty('Sin pendientes','Todas las solicitudes han sido reclamadas o aún no hay solicitudes.')}</section></div>`;
}
function athletesPage(athletes,filter){
 const query=String(filter.athleteSearch||'').toLocaleLowerCase('es-ES').trim();
 const list=athletes.filter(a=>!query||[a.name,a.email].some(v=>String(v||'').toLocaleLowerCase('es-ES').includes(query)));
 return `${heading('Atletas','Todas las cuentas registradas en Repera, también las que no tienen gimnasio ni entrenador personal.')}
 <div class="pa-metrics">${stat('Cuentas registradas',athletes.length)}
 ${stat('Sin centro asociado',athletes.filter(a=>!validNumber(a.center_count)).length)}
 ${stat('Cuentas verificadas',athletes.filter(a=>a.confirmed).length)}</div>
 <section class="pa-panel"><div class="pa-athlete-search">
 <input type="search" aria-label="Buscar atleta" data-admin-filter="athleteSearch" value="${esc(filter.athleteSearch||'')}" placeholder="Buscar por nombre o correo" autocomplete="off">
 </div>
 ${list.length?table(['Atleta','Email','Centros asociados','Estado','Registro'],
 list.map(a=>`<tr class="pa-athlete-row" tabindex="0" role="link" aria-label="Ver ficha de ${esc(a.name)}" data-admin-action="view-athlete" data-id="${esc(a.id)}"><td><div class="pa-identity">${photo(a.avatar_url,a.name)}
 <div><strong>${esc(a.name)}</strong>${a.platform_role==='platform_admin'?'<small>Administrador de plataforma</small>':''}</div></div></td>
 <td>${esc(a.email||'—')}</td><td>${validNumber(a.center_count)?validNumber(a.center_count):'<span class="pa-muted">Sin centro</span>'}</td>
 <td>${a.confirmed?'<span class="pa-pill good">Verificado</span>':'<span class="pa-pill">Sin verificar</span>'}</td><td>${date(a.created_at)}</td></tr>`).join('')):
 empty('No hay atletas con esos filtros','La lista incluye cuentas autenticadas incluso sin centros vinculados.')}</section>`;
}
const fieldName=k=>({'reps':'Repeticiones','weight':'Peso','sets':'Series',
 'duration':'Duración','distance':'Distancia','result':'Resultado','name':'Ejercicio',
 'exercise':'Ejercicio','rest':'Descanso','time':'Tiempo','score':'Marca',
 'rounds':'Rondas','notes':'Notas','type':'Tipo','value':'Valor','unit':'Unidad',
 'target':'Objetivo','actual':'Realizado','prescription':'Prescripción',
 'completed':'Completado','load':'Carga','unit':'Unidad'})[k]||String(k).replace(/_/g,' ');
function nested(value,level=0){
 if(value==null)return '<span class="pa-muted">Sin datos</span>';
 if(Array.isArray(value)){
  if(!value.length)return '<span class="pa-muted">Sin registros</span>';
  return `<div class="pa-nested-list">${value.slice(0,150).map((item,i)=>`<div class="pa-nested-item">
  ${typeof item==='object'&&item!==null?nested(item,level+1):`<span class="pa-muted">${i+1}. </span>${esc(readable(item))}`}
  </div>`).join('')}</div>`;
 }
 if(typeof value==='object'){
  if(level>6)return '<span class="pa-muted">Detalle anidado</span>';
  return `<dl class="pa-nested-details">${Object.entries(value).slice(0,75).map(([k,v])=>`<dt>${esc(fieldName(k))}</dt>
   <dd>${typeof v==='object'&&v!==null?nested(v,level+1):esc(readable(v))}</dd>`).join('')}</dl>`;
 }
 return esc(readable(value));
}
function athleteDetail(person,detail,workouts=[],busy=false){
 const a=detail?.account||person;const rows=detail||{};
 return `${heading('Ficha de atleta','Cuenta, actividad y relaciones con centros',button('Volver a atletas','back-athletes'))}
 <div class="pa-panel pa-center-hero"><div class="pa-identity">${photo(a.avatar_url,a.name,'large')}
 <div><h2>${esc(a.name||'Atleta')}</h2><p>${esc(a.email||'—')} · ${esc(a.role==='platform_admin'?'Administrador Repera':'Atleta')}</p></div></div></div>
 ${!detail?'<section class="pa-panel"><h2>Cargando ficha desde Supabase...</h2></section>':`
 <div class="pa-metrics pa-center-metrics">
 ${stat('Entrenamientos',rows.workout_count||0)}
 ${stat('Reservas',rows.booking_count||0)}
 ${stat('Sesiones profesionales',rows.training_count||0)}
 ${stat('Centros vinculados',(rows.memberships||[]).length)}</div>
 <div class="pa-layout">
 <section class="pa-panel"><h2>Identidad y cuenta</h2>
 ${details([['Nombre',a.name],['Correo',a.email],['Rol',a.role==='platform_admin'?'Administrador de plataforma':a.role||'Atleta'],
 ['Creación de cuenta',stamp(a.created_at)],['Última modificación del perfil',stamp(a.profile_updated_at)],
 ['Correo confirmado',stamp(a.email_confirmed_at)]])}</section>
 <section class="pa-panel"><h2>Accesos y autenticación</h2>
 ${details([['Último inicio de sesión',stamp(a.last_sign_in_at)],
 ['Proveedores de acceso',(rows.providers||[]).join(', ')||'Sin proveedores registrados'],
 ['Email verificado',!!a.email_confirmed_at]])}
 <p class="pa-muted">Por seguridad no se exponen contraseñas, sesiones, tokens, IP ni credenciales de terceros.</p>
 </section></div>
 <div class="pa-layout"><section class="pa-panel"><h2>Centros y roles</h2>
 ${rows.memberships?.length?table(['Centro','Rol','Estado','Acción'],rows.memberships.map(m=>`<tr>
 <td>${esc(m.center_name)}</td><td>${esc(m.role)}</td><td>${statusPill(m.status)}</td>
 <td>${button('Abrir centro','view-org',`data-id="${esc(m.center_id)}"`)}</td></tr>`).join('')):
 empty('Sin centros asociados','Este atleta puede utilizar Repera de forma independiente.')}</section>
 <section class="pa-panel"><h2>Fichas en centros</h2>
 ${rows.client_profiles?.length?table(['Centro','Ficha','Estado'],rows.client_profiles.map(c=>`<tr>
 <td>${esc(c.center_name)}</td><td>${esc(c.name)}</td><td>${statusPill(c.status)}</td></tr>`).join('')):
 empty('Sin fichas de clientes','Ningún centro tiene asociada su cuenta.')}</section></div>
 <div class="pa-layout"><section class="pa-panel"><h2>Perfil de entrenamiento</h2>
 ${rows.training_profile?details([['Objetivo',rows.training_profile.primary_goal],
 ['Nivel',rows.training_profile.experience_level],
 ['Días de entrenamiento/semana',rows.training_profile.training_days_per_week],
 ['Duración por sesión (min)',rows.training_profile.session_minutes],
 ['Coaching habilitado',rows.training_profile.coaching_enabled],
 ['Última actualización',stamp(rows.training_profile.updated_at)]]):
 empty('Sin perfil de entrenamiento','El atleta no ha configurado este apartado.')}</section>
 <section class="pa-panel"><h2>Programas (${formatListing(rows.programs)})</h2>
 ${rows.programs?.length?table(['Programa','Inicio','Estado'],rows.programs.map(p=>`<tr>
 <td>${esc(p.title)}</td><td>${date(p.start_date)}</td><td>${statusPill(p.status)}</td></tr>`).join('')):
 empty('Sin programas','No hay programas guardados.')}</section></div>
 <div class="pa-layout">
 <section class="pa-panel"><h2>Sesiones profesionales recientes</h2>
 ${rows.professional_sessions?.length?table(['Sesión','Centro','Fecha','Estado'],rows.professional_sessions.map(t=>`<tr>
 <td>${esc(t.title)}</td><td>${esc(t.center_name)}</td><td>${date(t.scheduled_date)}</td><td>${statusPill(t.status)}</td></tr>`).join('')):
 empty('Sin sesiones profesionales','No existen sesiones asignadas.')}</section>
 <section class="pa-panel"><h2>Reservas recientes</h2>
 ${rows.reservations?.length?table(['Centro','Fecha','Estado'],rows.reservations.map(t=>`<tr>
 <td>${esc(t.center_name)}</td><td>${stamp(t.booked_at)}</td><td>${statusPill(t.status)}</td></tr>`).join('')):
 empty('Sin reservas','No constan reservas asociadas.')}</section></div>
 <section class="pa-panel"><div class="pa-panel-title"><h2>Entrenamientos registrados (${validNumber(rows.workout_count)})</h2>
 <span class="pa-muted">Fuente: atleta en Supabase, no métricas de HealthKit</span></div>
 ${workouts.length?workouts.map((w,i)=>`<details class="pa-workout-detail">
 <summary><span><strong>${esc(w.title||'Entrenamiento '+(i+1))}</strong><small>
 ${stamp(w.started_at)}${w.finished_at?' · Terminado '+stamp(w.finished_at):''}</small></span>
 <span class="pa-muted">Ver ejercicios y resultados</span></summary>
 <div class="pa-layout"><div><h3>Ejercicios y series</h3>${nested(w.exercises)}</div>
 <div><h3>Resultados WOD</h3>${nested(w.wod_results)}</div></div>
 </details>`).join(''):empty('Sin entrenamientos visibles','Este atleta todavía no ha sincronizado entrenamientos a esta fuente.')}
 ${workouts.length<validNumber(rows.workout_count)?`<div class="pa-load-more">
 <button type="button" class="pa-button" data-admin-action="more-athlete-workouts" ${busy?'disabled':''}>
 ${busy?'Cargando...':'Cargar más entrenamientos'} (${workouts.length}/${rows.workout_count})</button></div>`:''}
 <p class="pa-muted">Esta ficha no muestra información médica privada, secretos de sesión ni otros datos protegidos. Las consultas quedan auditadas.</p>
 </section>`}
 `;
}
function planForm(plan,newPlan=false){
 const p=plan||{},key=esc(p.plan_key||''),audience=p.audience||'personal_trainer';
 return `<form class="pa-plan-edit-form" data-connected="${newPlan?'new-plan':'save-plan'}">
 <div class="pa-form-grid">
 ${newPlan?field('plan_key','Clave interna única','','text','required minlength="3" maxlength="40" pattern="[a-z][a-z0-9_]{2,39}"'): `<input type="hidden" name="plan_key" value="${key}">`}
 ${field('title','Nombre comercial',p.title||'','text','required minlength="2" maxlength="70"')}
 <label class="pa-field"><span>Dirigido a</span><select name="audience">
 <option value="personal_trainer" ${audience==='personal_trainer'?'selected':''}>Entrenador personal</option>
 <option value="gym" ${audience==='gym'?'selected':''}>Gimnasio</option></select></label>
 ${field('price','Precio mensual (€)',p.monthly_price_cents==null?'':Number(p.monthly_price_cents)/100,'number','required min="0" max="100000" step="0.01"')}
 ${field('max_clients','Clientes máximos (vacío = sin límite)',p.max_clients??'','number','min="1" max="100000"')}
 ${field('description','Descripción',p.description||'','text','maxlength="250"')}
 ${field('discount_percent','Descuento inicial (%)',p.discount_percent??0,'number','min="0" max="90"')}
 ${field('discount_months','Meses con descuento',p.discount_months??0,'number','min="0" max="12"')}
 ${field('display_order','Orden de aparición',p.display_order??0,'number','min="-999" max="999"')}
 <label class="pa-field"><span>Disponibilidad</span><select name="is_active">
 <option value="true" ${p.is_active!==false?'selected':''}>Visible</option>
 <option value="false" ${p.is_active===false?'selected':''}>Oculto</option></select></label></div>
 <div class="pa-actions"><button class="pa-button primary" type="submit">${newPlan?'Crear plan':'Guardar cambios'}</button>
 ${button('Cancelar','cancel-plan-edit')}</div></form>`;
}
function plansPage(plans,editingKey){
 const sections=[['personal_trainer','Entrenadores personales'],['gym','Gimnasios y centros']];
 return `${heading('Planes y precios','Catálogo real agrupado por tipo de centro. Los cambios afectan a las futuras ofertas, no generan cobros.',button('Añadir plan','new-plan'))}
 ${editingKey==='new'? `<section class="pa-panel"><h2>Nuevo plan</h2>${planForm(null,true)}</section>`:''}
 ${sections.map(([audience,title])=>`<section class="pa-panel"><div class="pa-panel-title"><h2>${title}</h2><span class="pa-muted">${plans.filter(p=>p.audience===audience).length} planes</span></div>
 <div class="pa-plan-list">${plans.filter(p=>p.audience===audience).sort((a,b)=>a.display_order-b.display_order).map(p=>`
 <article class="pa-plan-item"><div class="pa-plan-summary"><div class="pa-plan-main"><strong>${esc(p.title)}</strong>
 <small>${esc(p.description||'Sin descripción')}</small><span>${p.max_clients?`Hasta ${validNumber(p.max_clients)} clientes`:'Clientes ilimitados'}
 ${p.discount_percent&&p.discount_months?` · ${p.discount_percent}% durante ${p.discount_months} meses`:''}</span></div>
 <div class="pa-plan-side"><strong>${euros(p.monthly_price_cents)}<small>/mes</small></strong>
 ${statusPill(p.is_active?'active':'suspended')}
 ${button(editingKey===p.plan_key?'Cerrar':'Editar','edit-plan',`data-id="${esc(p.plan_key)}"`)}</div></div>
 ${editingKey===p.plan_key?planForm(p):''}</article>`).join('')||empty('Sin planes','Añade un plan para este tipo de centro.')}</div></section>`).join('')}
 <p class="pa-muted">Precios mensuales sin IVA. Stripe y la activación de suscripciones reales siguen pendientes de integración.</p>`;
}
function settingsPage(settings,orgs,plans){
 return `${heading('Configuración','Ajustes operativos de Repera y situación de las integraciones de plataforma.')}
 <div class="pa-layout">
 <section class="pa-panel"><h2>Atención, facturación y textos legales</h2>
 <p>Estos datos se guardan en Supabase y pueden actualizarse desde la consola.</p>
 <form class="pa-form" data-admin-form="platform-settings">
 ${field('support_email','Correo de soporte',settings.support_email||'','email','maxlength="180"')}
 ${field('support_url','Centro de ayuda (URL)',settings.support_url||'','url','maxlength="500" placeholder="https://..."')}
 ${field('billing_email','Correo de facturación',settings.billing_email||'','email','maxlength="180"')}
 ${field('privacy_url','Política de privacidad',settings.privacy_url||'','url','maxlength="500"')}
 ${field('terms_url','Términos y condiciones',settings.terms_url||'','url','maxlength="500"')}
 <button type="submit" class="pa-button primary">Guardar contactos y enlaces</button></form>
 </section>
 <section class="pa-panel"><h2>Altas y pruebas gratuitas</h2>
 <p>Configura cuánto dura la prueba cuando un usuario crea o reclama un centro. No altera pruebas ya iniciadas.</p>
 <form class="pa-form" data-admin-form="platform-trial">
 ${field('trial_days','Días de prueba gratuita',settings.trial_days??7,'number','required min="1" max="60" step="1"')}
 <button type="submit" class="pa-button primary">Guardar periodo de prueba</button>
 </form>
 <h3>Estado de la plataforma</h3>
 ${details([['Centros registrados',orgs.length],
 ['Planes disponibles',plans.filter(p=>p.is_active).length],
 ['Autenticación','Supabase Auth'],
 ['Acceso de administración','Delegación temporal auditada'],
 ['Control de permisos','Roles y políticas RLS'],
 ['Estado de los pagos reales','Sin conexión operativa a Stripe']])}
 ${button('Configurar mi cuenta','open-account')}</section></div>
 <section class="pa-panel"><h2>Integraciones y preparación para producción</h2>
 <p>El sistema distingue lo que ya gestiona desde la consola de las integraciones que necesitan credenciales, backend o procedimientos adicionales.</p>
 <div class="pa-settings-readiness">
 <div><strong>Identidad, roles y seguridad</strong><p>Inicio de sesión, políticas RLS, acceso administrativo temporal y registro técnico de operaciones.</p>
 <span class="pa-pill good">Configurado</span></div>
 <div><strong>Planes y pruebas</strong><p>Catálogo comercial y duración de prueba configurables. No se cobran automáticamente las suscripciones.</p>
 <span class="pa-pill good">Configurado</span></div>
 <div><strong>Stripe Billing / Connect</strong><p>Faltan pasarela, webhooks firmados, conciliación, reembolsos y suscripciones reales.</p>
 <span class="pa-pill">Integración pendiente</span></div>
 <div><strong>Emails y notificaciones</strong><p>Faltan plantillas transaccionales y validación del proveedor para comunicaciones automáticas de negocio.</p>
 <span class="pa-pill">Integración pendiente</span></div>
 <div><strong>Facturas, privacidad y retención</strong><p>Los enlaces legales son configurables; el ciclo fiscal, solicitudes RGPD y reglas de conservación requieren workflows completos.</p>
 <span class="pa-pill">Integración pendiente</span></div>
 <div><strong>Monitorización y continuidad</strong><p>Requiere alertas de errores, métricas de disponibilidad y verificación de backups y restauración.</p>
 <span class="pa-pill">Integración pendiente</span></div>
 </div></section>
 <p class="pa-muted">Los eventos de auditoría siguen guardándose automáticamente en Supabase aunque no tengan un apartado independiente en el menú.</p>`;
}
function accountPage(account,email){
 const name=account?.display_name||email.split('@')[0]||'Administrador';
 return `${heading('Mi cuenta','Identidad, fotografía y seguridad de tu cuenta de administrador.')}
 <div class="pa-layout"><section class="pa-panel"><h2>Perfil personal</h2>
 <div class="pa-account-photo">${photo(account?.avatar_url,name,'large')}
 <p>Tu imagen se utilizará en la consola y en el directorio de atletas.</p></div>
 <form class="pa-form" data-admin-form="account-profile">
 ${field('display_name','Nombre que aparece en Repera',account?.display_name||'','text','required minlength="2" maxlength="100"')}
 <label class="pa-field"><span>Foto de perfil</span><input name="avatarFile" type="file" accept="image/jpeg,image/png,image/webp"></label>
 <p class="pa-muted">Si no subes una fotografía propia, se utiliza tu imagen de acceso de Google cuando esté disponible.</p>
 <button type="submit" class="pa-button primary">Guardar mi perfil</button></form></section>
 <section class="pa-panel"><h2>Acceso y seguridad</h2>
 <label class="pa-field"><span>Correo actual</span><input value="${esc(email)}" readonly aria-label="Correo actual"></label>
 <form class="pa-form" data-admin-form="account-email">
 ${field('email','Cambiar correo electrónico','','email','required maxlength="180" placeholder="Nuevo correo"')}
 <button type="submit" class="pa-button">Solicitar cambio de correo</button></form>
 <p class="pa-muted">Supabase podría solicitar confirmar el cambio mediante correo.</p>
 <form class="pa-form" data-admin-form="account-password">
 ${field('password','Nueva contraseña','','password','required minlength="8" autocomplete="new-password"')}
 <button type="submit" class="pa-button">Cambiar contraseña</button></form>
 <div class="pa-account-signout">${button('Cerrar sesión','logout-admin')}</div>
 </section></div>`;
}
export function renderPlatformAdmin({
 tab='home',orgs=[],athletes=[],finance={},pending=[],history=[],plans=[],
 selectedOrg='',selectedAthlete='',centerDetail=null,athleteData=null,athleteWorkouts=[],
 collapsed=false,filter={},settings={},account={},editingPlan='',busy=false,error='',notice='',email=''
}={}) {
 const o=orgs.find(o=>o.id===selectedOrg);
 const a=athletes.find(a=>a.id===selectedAthlete);
 const headings={home:'Inicio',centers:'Centros',athletes:'Atletas',payments:'Pagos',
 plans:'Planes y precios',support:'Soporte',audit:'Auditoría',
 'admin-settings':'Configuración',account:'Mi cuenta',provision:'Añadir centro'};
 const displayName=account.display_name||email.split('@')[0]||'Administrador';
 let body='';
 if(a)body=athleteDetail(a,athleteData,athleteWorkouts,busy);
 else if(o)body=organizationDetail(o,{plans,detail:centerDetail});
 else if(tab==='home')body=overview(orgs,finance,history);
 else if(tab==='centers')body=directory(orgs,filter);
 else if(tab==='athletes')body=athletesPage(athletes,filter);
 else if(tab==='payments')body=paymentsPage(orgs,finance,filter);
 else if(tab==='provision')body=provisioning(pending,plans);
 else if(tab==='plans')body=plansPage(plans,editingPlan);
 else if(tab==='support')body=support(orgs,pending);
 else if(tab==='audit')body=`${heading('Auditoría de plataforma','Registro de acciones administrativas y accesos delegados.')}
 <section class="pa-panel">${history.length?table(['Fecha','Acción','Centro','Detalle'],
 history.map(h=>`<tr><td>${date(h.created_at)}</td><td>${esc(h.action)}</td>
 <td>${esc(orgs.find(o=>o.id===h.org_id)?.name||'—')}</td>
 <td>${esc(h.details?.reason||h.details?.status||'—')}</td></tr>`).join('')):
 empty('Todavía no hay eventos','Las acciones administrativas se registrarán aquí.')}</section>`;
 else if(tab==='admin-settings')body=settingsPage(settings,orgs,plans);
 else if(tab==='account')body=accountPage(account,email);
 return `<div class="pa-shell ${collapsed?'is-collapsed':''}"><aside class="pa-sidebar">
 <button type="button" class="pa-menu-collapse" data-admin-action="toggle-sidebar"
  aria-label="${collapsed?'Expandir menú':'Contraer menú'}" title="${collapsed?'Expandir menú':'Contraer menú'}"
  aria-expanded="${collapsed?'false':'true'}">
  <svg viewBox="0 0 24 24" width="19" height="19" fill="none" stroke="currentColor" stroke-width="1.8"
   stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
   <rect x="3" y="3" width="18" height="18" rx="3"/><path d="M9 3v18"/></svg>
  <span>${collapsed?'Expandir menú':'Contraer menú'}</span></button>
 <nav aria-label="Administración Repera">
 ${tabs.map(([id,name,icon])=>`<button type="button" data-admin-tab="${id}" title="${esc(name)}"
 class="${tab===id&&!o&&!a?'active':''}" aria-current="${tab===id&&!o&&!a?'page':'false'}">${navIcon(icon)}<span>${name}</span></button>`).join('')}</nav>
 <div class="pa-sidebar-bottom">
 <button type="button" class="pa-account-entry ${tab==='account'?'active':''}" data-admin-tab="account"
 aria-label="Configurar mi cuenta"><span class="pa-account-thumb">${photo(account.avatar_url,displayName)}</span>
 <span class="pa-account-copy"><strong>${esc(displayName)}</strong><small>${esc(email)}</small><small>Cuenta de plataforma</small></span>
 ${navIcon('settings')}</button>
 <button type="button" class="pa-sidebar-logout" data-action="logout">Cerrar sesión</button></div></aside>
 <div class="pa-main"><main class="pa-content" id="platform-main">
 ${error?`<div role="alert" class="pa-error">${esc(error)}</div>`:''}
 ${notice?`<div role="status" class="pa-notice">${esc(notice)}</div>`:''}
 ${body}</main></div></div>`;
}
export function paymentCSV(orgs,finance,filter={}){
 const names=new Map(orgs.map(o=>[o.id,o.name]));
 const data=filteredPayments(finance,filter);
 const csv=x=>{const raw=String(x??'');const safe=/^\s*[=+@-]/.test(raw)?"'"+raw:raw;return '"'+safe.replace(/"/g,'""')+'"';};
 return [['Fecha','Negocio','Importe_centimos','Divisa','Estado','Proveedor'].join(';'),...data.map(p=>[p.created_at,names.get(p.org_id)||'',p.amount_cents,p.currency,p.status,p.provider].map(csv).join(';'))].join('\r\n');
}
