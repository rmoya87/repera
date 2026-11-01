// Enlace + QR de invitación (web console y deep link app).
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

export function invitationWebUrl(invitationId,baseUrl){
 const loc=typeof location!=='undefined'?location:null;
 const base=baseUrl||(loc?(loc.origin+loc.pathname.replace(/\/$/,'')):'https://business.repera.app/console');
 return `${base}/?invitation=${encodeURIComponent(invitationId)}`;
}

export function invitationDeepLink(invitationId){
 return `repera://invitation/${invitationId}`;
}

/** QR SVG offline vía API pública de fallback; sin secretos. */
export function invitationQrImg(url){
 const src=`https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(url)}`;
 return `<img class="business-invite-qr" src="${esc(src)}" width="160" height="160" alt="Código QR de invitación" loading="lazy">`;
}

export function renderInvitationShareCard({invitationId,email='',sent=false,reason=''}){
 if(!/^[0-9a-f-]{36}$/i.test(invitationId||''))return '';
 const web=invitationWebUrl(invitationId);
 const deep=invitationDeepLink(invitationId);
 return `<section class="connected-card business-invite-share" data-invite-id="${esc(invitationId)}">
  <div class="business-panel-head"><div>
   <h2>Invitación lista</h2>
   <p>${sent?'Correo enviado.':'Correo no confirmado'}${email?` · ${esc(email)}`:''}${reason&&!sent?` · ${esc(reason)}`:''}</p>
  </div></div>
  <div class="business-invite-share-grid">
   <div>${invitationQrImg(web)}
    <p class="business-invite-hint">Escanea para abrir el enlace web. La app usa el deep link si está instalada.</p>
   </div>
   <div class="business-invite-links">
    <label class="connected-field">Enlace web
     <input readonly value="${esc(web)}" data-invite-copy="web">
    </label>
    <label class="connected-field">Deep link app
     <input readonly value="${esc(deep)}" data-invite-copy="deep">
    </label>
    <div class="business-invite-actions">
     <button type="button" class="connected-secondary" data-action="copy-invite-link" data-url="${esc(web)}">Copiar enlace</button>
     <button type="button" class="connected-secondary" data-action="copy-invite-deep" data-url="${esc(deep)}">Copiar deep link</button>
     <button type="button" class="connected-secondary" data-action="cancel-invitation" data-id="${esc(invitationId)}">Revocar</button>
    </div>
   </div>
  </div>
 </section>`;
}
