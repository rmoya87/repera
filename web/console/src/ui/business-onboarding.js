import {priceLabel,visiblePlans,slugFromName,audienceForKind} from '../core/business-profile.js';
const e=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const input=(label,name,value='',type='text',extra='',cls='')=>
 `<label class="connected-field ${cls}">${label}<input name="${name}" type="${type}" value="${e(value)}" ${extra}></label>`;
const choices=(label,name,value,options,cls='')=>`<label class="connected-field ${cls}">${label}<select name="${name}">${options.map(([key,title])=>`<option value="${e(key)}" ${value===key?'selected':''}>${e(title)}</option>`).join('')}</select></label>`;
const group=(title,body,desc='')=>`<div class="business-onboarding-group"><div class="business-onboarding-heading"><h3>${title}</h3>${desc?`<p>${desc}</p>`:''}</div><div class="business-onboarding-fields">${body}</div></div>`;
export const kindOptions=[['personal_trainer','Entrenador personal'],['gym','Gimnasio']];
export function renderPlanOptions(plans,kind,selected=''){
 const options=visiblePlans(plans,kind).map(p=>`<option value="${e(p.plan_key)}" ${selected===p.plan_key?'selected':''}>${e(p.title)} · ${e(priceLabel(p.monthly_price_cents))}/mes${p.max_clients?` · ${p.max_clients} clientes`:' · sin límite'}</option>`).join('');
 return '<option value="">Elegir más adelante · prueba gratuita</option>'+options;
}
export function renderOrganizationFields({kind='personal_trainer',values={},legal={},plans=[],creation=false}={}){
 const category=kind==='personal_trainer'?'Foto del entrenador':'Logotipo del gimnasio';
 const file=`<label class="connected-field business-file-picker full"><span data-image-label>${category}</span>${/^https:\/\//.test(values.avatar_url||'')?`<img class="business-profile-preview" src="${e(values.avatar_url)}" alt="Imagen actual del negocio">`:''}<input name="avatarFile" type="file" accept="image/jpeg,image/png,image/webp" aria-describedby="business-image-hint"><small id="business-image-hint">JPG, PNG o WebP, hasta 8 MB. Se convertirá a JPG (1 MB máximo) y será visible en el directorio.</small></label>`;
 const publicFields=group('Perfil profesional',
  `${input('Nombre comercial','name',values.name||'','text','minlength="2" maxlength="120" required')}${creation?`<label class="connected-field">Identificador web<output data-generated-slug class="business-slug-preview">${values.name?e(slugFromName(values.name)):'Se generará automáticamente a partir del nombre'}</output></label>`:''}
  ${choices('Actividad','kind',kind,kindOptions,creation?'':'full')}${input('Correo de contacto','public_email',values.public_email||'','email','maxlength="180"')}${input('Teléfono de contacto','phone',values.phone||'','tel','maxlength="40"')}${input('Página web','website',values.website||'','url','maxlength="255" placeholder="https://..."')}${input('Dirección del negocio','address',values.address||'','text','maxlength="300"')}${file}
  ${input('Descripción profesional','description',values.description||'','text','maxlength="2000"','full')}`,
  'Los datos de contacto y la imagen del perfil podrán mostrarse a tus clientes.');
 const legalFields=group('Datos legales y de facturación',
  `${choices('Forma jurídica','entity_type',legal.entity_type||'self_employed',[['self_employed','Autónomo / persona física'],['company','Sociedad / empresa']])}
  ${input('Nombre completo o razón social','legal_name',legal.legal_name||'','text','maxlength="180"')}${input('NIF, NIE o CIF','tax_id',legal.tax_id||'','text','maxlength="24" autocomplete="off"')}${input('Representante legal','representative_name',legal.representative_name||'','text','maxlength="150"')}${input('Persona de contacto','contact_name',legal.contact_name||'','text','maxlength="150"')}${input('Email de facturación','billing_email',legal.billing_email||'','email','maxlength="180"')}${input('Domicilio fiscal','billing_address',legal.billing_address||'','text','maxlength="300"','full')}${input('Código postal','postal_code',legal.postal_code||'','text','maxlength="20"')}${input('Localidad','city',legal.city||'','text','maxlength="100"')}${input('Provincia','province',legal.province||'','text','maxlength="100"')}${input('País (ISO)','country',legal.country||'ES','text','maxlength="2" placeholder="ES"')}`,
 'Estos datos son privados: solo el propietario y los administradores autorizados pueden consultarlos.');
 const planFields=creation?group('Suscripción',
 `<label class="connected-field full">Plan de referencia<select name="planKey" data-business-plan-select>${renderPlanOptions(plans,kind)}</select></label><p class="business-form-help full">7 días de prueba gratuitos. Elegir un plan solo registra tu interés: no se realiza ningún cobro ni se activa una suscripción.</p>`):'';
 return publicFields+legalFields+planFields+(creation?'':'');
}
export function renderOrganizationCreateForm(plans=[],initial={}){
 return `<div class="business-onboarding"><span class="connected-tag">NUEVO PERFIL</span><h2>Añadir negocio</h2><p>Configura los datos una vez y podrás completar o editarlos desde Ajustes. El identificador web se crea automáticamente.</p><form data-connected="create" class="business-onboarding-form">${renderOrganizationFields({plans,creation:true,kind:['personal_trainer','gym'].includes(initial.kind)?initial.kind:'personal_trainer',values:{name:initial.name||''}})}<button class="connected-primary business-form-submit" type="submit">Crear negocio y comenzar prueba</button></form></div>`;
}
export function renderPlanAdministration(plans=[]){
 const rows=plans.map(p=>`<form class="business-plan-admin-form" data-connected="save-plan"><input type="hidden" name="plan_key" value="${e(p.plan_key)}"><h3>${e(p.title)} <small>${e(p.plan_key)}</small></h3><div class="business-onboarding-fields">
 ${input('Nombre','title',p.title,'text','required maxlength="70"')}${choices('Para','audience',p.audience,kindOptions)}
 ${input('Precio mensual, €','price',Number(p.monthly_price_cents)/100,'number','required min="0" max="100000" step="0.01"')}
 ${input('Máximo de clientes (vacío = ilimitado)','max_clients',p.max_clients??'','number','min="1" max="100000"')}
 ${input('Descripción','description',p.description,'text','maxlength="250"','full')}
 ${input('Descuento inicial, %','discount_percent',p.discount_percent,'number','min="0" max="90"')}
 ${input('Meses de descuento','discount_months',p.discount_months,'number','min="0" max="12"')}
 ${input('Orden','display_order',p.display_order,'number','min="-999" max="999"')}
 ${choices('Visibilidad','is_active',String(p.is_active),[['true','Visible'],['false','Oculto']])}
 </div><button class="connected-secondary" type="submit">Guardar plan</button></form>`).join('');
 const create=`<form data-connected="new-plan" class="business-plan-admin-form"><h3>Añadir nuevo plan</h3><div class="business-onboarding-fields">
 ${input('Clave interna (no editable)','plan_key','','text','required minlength="3" maxlength="40" pattern="[a-z][a-z0-9_]{2,39}"')}
 ${input('Nombre','title','','text','required minlength="2" maxlength="70"')}
 ${choices('Para','audience','personal_trainer',kindOptions)}
 ${input('Precio mensual, €','price','','number','required min="0" max="100000" step="0.01"')}
 ${input('Máximo de clientes (vacío = ilimitado)','max_clients','','number','min="1" max="100000"')}
 ${input('Descripción','description','','text','maxlength="250"','full')}
 </div><button class="connected-primary" type="submit">Añadir plan</button></form>`;
 return `<section class="connected-card business-plans-admin"><span class="connected-tag">CATÁLOGO CENTRAL</span><h2>Planes de Repera</h2><p>Configura los planes que verán entrenadores y gimnasios. Cambiar estos importes no genera cobros ni activa suscripciones. Los precios son mensuales, sin IVA.</p><div class="business-plan-admin-grid">${rows}${create}</div></section>`;
}
