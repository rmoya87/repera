import {SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY} from '../core/config.js';
import {ReperaAuthAPI} from '../core/auth.js';
const app=document.querySelector('#app');
const auth=new ReperaAuthAPI({baseUrl:SUPABASE_URL,publishableKey:SUPABASE_PUBLISHABLE_KEY});
const escapeHTML=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let user=null,organizations=[],memberships=[],invitations=[],clients=[],selectedOrg=null,view='login',busy=false,error='',notice='';
const kindLabel={gym:'Gimnasio',personal_trainer:'Entrenador independiente',sports_center:'Centro deportivo'};
const roleLabel={owner:'Propietario',admin:'Administrador',coach:'Entrenador',reception:'Recepción',athlete:'Deportista'};
const message=()=>`${error?`<p class="connected-error" role="alert">${escapeHTML(error)}</p>`:''}${notice?`<p class="connected-notice" role="status">${escapeHTML(notice)}</p>`:''}`;
const field=(label,name,type='text',extra='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" autocomplete="${name==='email'?'email':name==='password'?'current-password':'off'}" required ${extra}></label>`;
const redirectTo=()=>location.origin+location.pathname;
function render(){
 const common=`<header class="connected-header"><div class="brand"><span class="brand-symbol">R</span><span><strong>repera</strong><small>Business</small></span></div><a href="?demo=1" class="connected-demo">Abrir demostración local ↗</a></header>`;
 if(!user){
  const title={login:'Accede a tu negocio',register:'Crear cuenta profesional',recover:'Recuperar acceso',password:'Establecer nueva contraseña'}[view];
  const form=view==='login'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Entrar</button>`
   :view==='register'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Crear cuenta</button>`
   :view==='recover'
   ?`${field('Correo electrónico','email','email')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Enviar enlace</button>`
   :`${field('Nueva contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Actualizar contraseña</button>`;
  app.innerHTML=`<div class="connected-page">${common}<main class="connected-auth"><div class="connected-card"><span class="connected-tag">PLATAFORMA PROFESIONAL</span><h1>${title}</h1><p class="connected-intro">Gestión real de organizaciones mediante Supabase. Tus entrenamientos personales permanecen en la app nativa.</p>${message()}<form data-connected="${view}">${form}</form><div class="connected-links">${view!=='login'?'<button type="button" data-view="login">Volver a iniciar sesión</button>':''}${view==='login'?'<button type="button" data-view="register">Crear cuenta</button><button type="button" data-view="recover">Olvidé mi contraseña</button>':''}</div></div></main></div>`;
  return;
 }
 const pendingInvites=invitations.filter(i=>!i.accepted_at&&!i.cancelled_at&&new Date(i.expires_at).getTime()>Date.now());
 const ownInvites=pendingInvites.filter(i=>i.email===(user.email||'').trim().toLowerCase());
 const own=new Map(memberships.filter(m=>m.user_id===user.id&&m.status==='active').map(m=>[m.organization_id,m.role]));
 app.innerHTML=`<div class="connected-page">${common}<main class="connected-workspace"><div class="connected-heading"><div><span class="connected-tag">SESIÓN AUTENTICADA · SUPABASE REPERA</span><h1>Mis organizaciones</h1><p>${escapeHTML(user.email||'Cuenta Repera')} · Solo se muestran negocios autorizados por la base de datos.</p></div><button class="connected-secondary" data-action="logout" ${busy?'disabled':''}>Cerrar sesión</button></div>${message()}${ownInvites.length?`<section class="connected-card" style="margin-bottom:22px"><h2>Invitaciones para ti</h2><p>Solo se vinculará tu cuenta con el profesional al aceptarla. No se compartirán tus datos privados de entrenamientos.</p>${ownInvites.map(i=>`<article class="connected-org"><div><strong>Organización ${escapeHTML(i.organization_id.slice(0,8))}</strong><small>Invitación para ${escapeHTML(roleLabel[i.invited_role]||i.invited_role)} · vence ${escapeHTML(i.expires_at.slice(0,10))}</small></div><button class="connected-primary" data-action="accept-invitation" data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Aceptar</button></article>`).join('')}</section>`:''}<section class="connected-grid"><div class="connected-card"><h2>Espacios de trabajo</h2>${organizations.length?organizations.map(o=>`<article class="connected-org"><div><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(kindLabel[o.kind]||o.kind)} · ${escapeHTML(roleLabel[own.get(o.id)]||'Miembro')}</small><code>${escapeHTML(o.slug)}</code></div>${['owner','admin'].includes(own.get(o.id))?`<form data-connected="rename" class="connected-inline"><input type="hidden" name="id" value="${escapeHTML(o.id)}"><label>Nombre<input name="name" value="${escapeHTML(o.name)}" maxlength="120" required></label><button class="connected-secondary" ${busy?'disabled':''}>Guardar</button></form>`:''}</article>`).join(''):'<p class="connected-empty">Todavía no perteneces a ninguna organización. Crea tu primera empresa para comenzar.</p>'}</div><div class="connected-card"><h2>Añadir organización</h2><p>Al crearla, Supabase te asigna el rol de propietario de forma segura.</p><form data-connected="create">${field('Nombre comercial','name','text','minlength="2" maxlength="120"')}${field('Identificador URL (minúsculas y guiones)','slug','text','minlength="3" maxlength="63" pattern="[a-z0-9][a-z0-9-]{2,62}"')}<label class="connected-field">Tipo<select name="kind"><option value="personal_trainer">Entrenador personal</option><option value="gym">Gimnasio</option><option value="sports_center">Centro deportivo</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear organización</button></form></div></section><section class="connected-card" style="margin-top:22px"><h2>Clientes reales</h2><label class="connected-field">Organización<select id="connected-org-select"><option value="">Selecciona una organización</option>${organizations.map(o=>`<option value="${escapeHTML(o.id)}" ${selectedOrg===o.id?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select></label>${selectedOrg?`<div style="margin-top:20px">${clients.length?clients.map(c=>`<article class="connected-org"><div><strong>${escapeHTML(c.name)}</strong><small>${escapeHTML(c.email)} · ${escapeHTML(c.status)}</small></div></article>`).join(''):'<p>Sin clientes registrados en esta organización.</p>'}${['owner','admin'].includes(own.get(selectedOrg))?`<form data-connected="client">${field('Nombre del cliente','name','text','minlength="2" maxlength="120"')}${field('Correo electrónico','email','email')}<button class="connected-primary">Añadir cliente potencial</button></form>`:''}</div>`:''}</section>${selectedOrg&&["owner","admin"].includes(own.get(selectedOrg))?`<section class="connected-card" style="margin-top:22px"><h2>Invitar a mi organización</h2><p>La persona debe registrarse con el mismo correo verificado. Podrá aceptar la invitación al iniciar sesión. Aún no se envían correos automáticos.</p><form data-connected="invite">${field('Correo del invitado','email','email')}<label class="connected-field">Perfil<select name="role"><option value="athlete">Deportista</option><option value="coach">Entrenador</option><option value="reception">Recepción</option><option value="admin">Administrador</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear invitación</button></form>${pendingInvites.filter(i=>i.organization_id===selectedOrg).length?`<p>Invitaciones pendientes: ${pendingInvites.filter(i=>i.organization_id===selectedOrg).length}</p>`:''}</section>`:''}<section class="connected-next"><h2>Próximos módulos</h2><p>Asignación operativa de entrenadores, planificaciones, reservas y cobros aún no están conectados. No se muestran datos ficticios en este espacio autenticado.</p><a href="?demo=1">Explorar funciones en la demostración (sin datos reales)</a></section></main></div>`;
}
async function reload(){const [orgs,members,invites]=await Promise.all([auth.organizations(),auth.memberships(),auth.invitations()]);organizations=orgs||[];memberships=members||[];invitations=invites||[];if(!organizations.some(o=>o.id===selectedOrg))selectedOrg=null;clients=selectedOrg?await auth.clients(selectedOrg):[];}
app.addEventListener('click',async event=>{
 const mode=event.target.closest('[data-view]');if(mode){view=mode.dataset.view;error=notice='';render();return;}
 const actionable=event.target.closest('[data-action]');const action=actionable?.dataset.action;
 if(action==='accept-invitation'&&!busy){busy=true;error=notice='';render();try{await auth.acceptInvitation(actionable.dataset.id);await reload();notice='Invitación aceptada. Tu relación con el centro ya consta en Supabase.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='logout'){busy=true;render();try{await auth.signOut();user=null;organizations=[];memberships=[];invitations=[];view='login';notice='Sesión cerrada';}catch(e){user=null;organizations=[];memberships=[];view='login';notice='Sesión local cerrada. No se pudo confirmar el cierre remoto.';}finally{busy=false;render();}}
});
app.addEventListener('change',async event=>{if(event.target.id!=='connected-org-select')return;selectedOrg=event.target.value||null;error='';clients=[];if(selectedOrg){try{clients=await auth.clients(selectedOrg);}catch(e){error=e.message;}}render();});
app.addEventListener('submit',async event=>{
 const f=event.target.closest('form[data-connected]');if(!f)return;event.preventDefault();if(busy)return;
 const action=f.dataset.connected,data=new FormData(f);busy=true;error=notice='';render();
 try{
  if(action==='login'){user=await auth.signIn(data.get('email'),data.get('password'));await reload();}
  if(action==='register'){const result=await auth.signUp(data.get('email'),data.get('password'),redirectTo());if(result.confirmationRequired){view='login';notice='Consulta tu correo y confirma la cuenta antes de iniciar sesión.';}else{user=await auth.currentUser();await reload();}}
  if(action==='recover'){await auth.requestPasswordReset(data.get('email'),redirectTo());view='login';notice='Si la dirección existe, recibirás un enlace de recuperación.';}
  if(action==='password'){await auth.changePassword(data.get('password'));await auth.signOut();user=null;view='login';notice='Contraseña actualizada. Inicia sesión de nuevo.';}
  if(action==='create'){await auth.createOrganization({name:data.get('name'),slug:data.get('slug'),kind:data.get('kind'),userId:user.id});await reload();notice='Organización creada correctamente.';}
  if(action==='invite'){await auth.issueInvitation({orgId:selectedOrg,email:data.get('email'),role:data.get('role')});await reload();notice='Invitación creada. El destinatario podrá aceptarla desde su propia cuenta verificada.';}
  if(action==='client'){await auth.addClient({orgId:selectedOrg,name:data.get('name'),email:data.get('email'),userId:user.id});clients=await auth.clients(selectedOrg);notice='Cliente potencial registrado.';}
  if(action==='rename'){await auth.renameOrganization(data.get('id'),data.get('name'));await reload();notice='Nombre actualizado.';}
 }catch(e){error=e.message||'No se pudo completar la operación';}
 finally{busy=false;render();}
});
async function boot(){
 busy=true;render();
 try{
  if(await auth.acceptRecoveryFragment(globalThis.location?.hash||'')){
   history.replaceState(null,'',location.pathname+location.search);view='password';
   // Recovery JWT is valid; keep password screen rather than normal admin UI.
  }else{user=await auth.currentUser();if(user)await reload();}
 }catch(e){auth.clear();error='No se ha podido recuperar la sesión. Inicia sesión nuevamente.';}
 finally{busy=false;render();}
}
boot();
