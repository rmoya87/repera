// Enlace + QR de invitación (web console y deep link app) + WhatsApp implícito.
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

export function invitationWebUrl(invitationId,baseUrl){
 const loc=typeof location!=='undefined'?location:null;
 const base=baseUrl||(loc?(loc.origin+loc.pathname.replace(/\/$/,'')):'https://repera.app/console');
 return `${base}/?invitation=${encodeURIComponent(invitationId)}`;
}

/** Abre la app Repera → Ajustes / Centro para aceptar la vinculación. */
export function invitationDeepLink(invitationId){
 return `repera://invitation/${invitationId}`;
}

/** Enlace preferido para copiar/compartir: deep link de la app. */
export function invitationShareUrl(invitationId){
 return invitationDeepLink(invitationId);
}

/**
 * Normaliza a E.164 solo dígitos (sin +).
 * Acepta +34…, 0034…, espacios y, en España, el móvil local 6/7xxxxxxxx → 34…
 */
export function normalizeWhatsappDigits(raw){
 let s=String(raw||'').trim();
 if(!s)return '';
 if(s.startsWith('00'))s=s.slice(2);
 let digits=s.replace(/\D/g,'');
 // Móvil ES local (9 dígitos empezando por 6 o 7) → añadir país.
 if(/^[67]\d{8}$/.test(digits))digits='34'+digits;
 // Quitar ceros a la izquierda residuales (p. ej. 0346… tras pegar mal).
 digits=digits.replace(/^0+/,'');
 return digits;
}

/** Devuelve dígitos válidos o '' si el número no sirve para wa.me. */
export function parseWhatsappE164(raw){
 const digits=normalizeWhatsappDigits(raw);
 return /^[1-9][0-9]{7,14}$/.test(digits)?digits:'';
}

export function isWhatsappConnected(org){
 return Boolean(org?.whatsapp_e164&&/^[1-9][0-9]{7,14}$/.test(String(org.whatsapp_e164)));
}

/** Mensaje automático de invitación para WhatsApp. */
export function invitationWhatsappMessage({orgName='',clientName='',invitationId}={}){
 const appLink=invitationDeepLink(invitationId);
 const web=invitationWebUrl(invitationId);
 const who=clientName?` ${clientName}`:'';
 const from=orgName||'tu entrenador';
 return `Hola${who} 👋\n\nTe invito a unirte a *${from}* en Repera.\n\n1) Abre la app con este enlace:\n${appLink}\n\n2) En Ajustes verás el centro: acepta la vinculación.\n\nSi no tienes la app: ${web}`;
}

/** URL wa.me con mensaje precargado (al destinatario). */
export function invitationWhatsappUrl({toDigits,orgName,clientName,invitationId}){
 const digits=normalizeWhatsappDigits(toDigits);
 const text=invitationWhatsappMessage({orgName,clientName,invitationId});
 const q=`text=${encodeURIComponent(text)}`;
 return digits
  ?`https://wa.me/${digits}?${q}`
  :`https://wa.me/?${q}`;
}

/**
 * Abre la pestaña en el gesto del usuario (antes de awaits) para no perder el popup.
 * Luego llama a finishInvitationWhatsappPopup con el id de invitación.
 */
export function beginInvitationWhatsappPopup(org=null){
 if(!isWhatsappConnected(org)||typeof window==='undefined')return null;
 try{return window.open('about:blank','_blank');}catch{return null;}
}

/** Completa la pestaña abierta con wa.me + mensaje. */
export function finishInvitationWhatsappPopup(win,{org=null,clientName='',clientPhone='',invitationId}={}){
 if(!win)return false;
 if(!/^[0-9a-f-]{36}$/i.test(invitationId||'')){
  try{win.close();}catch{/* ignore */}
  return false;
 }
 const url=invitationWhatsappUrl({
  toDigits:clientPhone,
  orgName:org?.name||'',
  clientName,
  invitationId,
 });
 try{win.location=url;return true;}
 catch{
  try{win.close();}catch{/* ignore */}
  window.open(url,'_blank','noopener,noreferrer');
  return true;
 }
}

/** Atajo síncrono (solo si aún hay gesto de usuario). */
export function openInvitationWhatsappAuto({org=null,clientName='',clientPhone='',invitationId}={}){
 const win=beginInvitationWhatsappPopup(org);
 return finishInvitationWhatsappPopup(win,{org,clientName,clientPhone,invitationId});
}

/** QR vía API pública; sin secretos en cliente. */
export function invitationQrImg(url){
 const src=`https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(url)}`;
 return `<img class="business-invite-qr" src="${esc(src)}" width="180" height="180" alt="Código QR de invitación" loading="lazy">`;
}

/** Invitación athlete pendiente vigente para un correo en un org. */
export function pendingAthleteInvite({invitations=[],orgId='',email=''}={}){
 const mail=String(email||'').trim().toLowerCase();
 if(!mail||!orgId)return null;
 const now=Date.now();
 return (invitations||[]).find(i=>
  i.organization_id===orgId
  &&String(i.email||'').trim().toLowerCase()===mail
  &&(!i.invited_role||i.invited_role==='athlete')
  &&!i.accepted_at&&!i.cancelled_at
  &&new Date(i.expires_at).getTime()>now
 )||null;
}

/** Solo QR + copiar enlace mientras la invitación está pendiente (ficha Datos). */
export function renderInvitationShareCard({
 invitationId,email='',sent=false,reason='',compact=false,
}={}){
 if(!/^[0-9a-f-]{36}$/i.test(invitationId||''))return '';
 const web=invitationWebUrl(invitationId);
 const deep=invitationDeepLink(invitationId);
 return `<section class="connected-card business-invite-share ${sent?'is-sent':'is-pending'}" data-invite-id="${esc(invitationId)}" role="status">
  <div class="business-panel-head"><div>
   <span class="connected-eyebrow">Pendiente de aceptar</span>
   <h2>QR y enlace</h2>
   <p>${email?`Para ${esc(email)}. `:''}Abre la app → Ajustes → acepta el centro. Se oculta al vincular.${reason?` (${esc(reason)})`:''}</p>
  </div></div>
  <div class="business-invite-share-grid">
   <div>${invitationQrImg(deep)}
    <p class="business-invite-hint">Escanea para abrir Repera y aceptar en Ajustes.</p>
   </div>
   <div class="business-invite-links">
    <label class="connected-field">Enlace app (recomendado)
     <input readonly value="${esc(deep)}" data-invite-copy="deep" onclick="this.select()">
    </label>
    ${compact?'':`<label class="connected-field">Enlace web (sin app)
     <input readonly value="${esc(web)}" data-invite-copy="web" onclick="this.select()">
    </label>`}
    <div class="business-invite-actions">
     <button type="button" class="connected-primary" data-action="copy-invite-link" data-url="${esc(deep)}">Copiar enlace app</button>
     <button type="button" class="connected-secondary" data-action="copy-invite-deep" data-url="${esc(web)}">Copiar enlace web</button>
     <button type="button" class="connected-secondary" data-action="cancel-invitation" data-id="${esc(invitationId)}">Revocar</button>
    </div>
   </div>
  </div>
 </section>`;
}

/** @deprecated El sheet modal ya no se usa; la ficha muestra QR hasta aceptar. */
export function renderInviteShareDialog(){
 return '';
}

/** Panel Ajustes → Servicios: conectar WhatsApp del negocio. */
export function renderServicesSettings({org,manager=false,busy=false,trainer=false,draft=null}={}){
 const connected=isWhatsappConnected(org);
 const label=trainer?'entrenador':'gimnasio';
 const inputValue=draft!=null&&String(draft).length
  ?String(draft)
  :(org.whatsapp_e164?`+${org.whatsapp_e164}`:'');
 return `<section data-settings-panel="services" class="connected-card pt-settings-card">
  <h2>Servicios</h2>
  <p>Conecta canales para compartir invitaciones y avisos con tus ${trainer?'clientes':'socios'}.</p>
  <article class="pt-service-card ${connected?'is-connected':''}">
   <div class="pt-service-card-head">
   <div>
     <span class="connected-eyebrow">Mensajería</span>
     <h3>WhatsApp</h3>
     <p>${connected
      ?`Conectado · +${esc(org.whatsapp_e164)}. Al invitar, WhatsApp se abre solo con el mensaje listo.`
      :`Vincula el WhatsApp de tu ${label}. Al invitar se abrirá automáticamente con el mensaje de invitación.`}</p>
    </div>
    <span class="business-status-badge tone-${connected?'ok':'muted'}"><span class="business-status-dot" aria-hidden="true"></span>${connected?'Conectado':'Sin conectar'}</span>
   </div>
   ${manager?`
    <form data-connected="whatsapp-connect" class="business-form pt-service-form">
     <label class="connected-field">Número de WhatsApp Business (con prefijo país)
      <input name="whatsapp" type="tel" inputmode="tel" autocomplete="tel"
       value="${esc(inputValue)}"
       placeholder="+34 600 000 000" maxlength="24" required>
     </label>
     <p class="connected-hint">Ejemplo España: +34600111222 (también vale 600111222). Puedes cambiar el número cuando quieras; no guardamos la sesión de WhatsApp.</p>
     <div class="pt-day-tools">
      <button type="submit" class="connected-primary" ${busy?'disabled':''}>${connected?'Actualizar WhatsApp':'Conectar WhatsApp'}</button>
      ${connected?`<button type="button" class="connected-secondary" data-action="disconnect-whatsapp" ${busy?'disabled':''}>Desconectar</button>`:''}
     </div>
    </form>`:'<p class="connected-hint">Solo propietarios y administradores pueden conectar servicios.</p>'}
  </article>
  ${!trainer?`<article class="pt-service-card">
   <div class="pt-service-card-head">
    <div>
     <span class="connected-eyebrow">Clases</span>
     <h3>Antelación de inscripción</h3>
     <p>Define con cuánta antelación se abren las clases para que socios y socias puedan apuntarse desde la app.</p>
    </div>
   </div>
   ${manager?`<form data-connected="booking-window" class="business-form pt-service-form">
     <label class="connected-field">Abrir inscripción
      <select name="hours" required>
       ${[['24','1 día antes'],['48','2 días antes'],['72','3 días antes'],['168','1 semana antes'],['336','2 semanas antes'],['720','30 días antes']].map(([v,l])=>`<option value="${v}" ${Number(org.class_booking_open_hours||168)===Number(v)?'selected':''}>${l}</option>`).join('')}
      </select>
     </label>
     <p class="connected-hint">Antes de esa ventana la clase se ve en el calendario, pero el botón Apuntarme permanece desactivado.</p>
     <button type="submit" class="connected-primary" ${busy?'disabled':''}>Guardar antelación</button>
    </form>`:'<p class="connected-hint">Solo propietarios y administradores pueden cambiar esta opción.</p>'}
  </article>`:''}
 </section>`;
}
