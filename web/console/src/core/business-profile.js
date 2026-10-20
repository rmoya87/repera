// Shared helpers for Repera Business identity forms; never grants paid access.
export const audienceForKind=kind=>kind==='personal_trainer'?'personal_trainer':'gym';
export function slugFromName(value){
 const stem=String(value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase()
   .replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'').slice(0,53).replace(/-$/,'');
 if(stem.length<2)throw Error('El nombre comercial debe contener letras o números.');
 return stem;
}
export function uniqueSlug(value,random=globalThis.crypto?.randomUUID?.()){
 const suffix=String(random||'').replace(/[^a-f0-9]/gi,'').slice(0,8).toLowerCase();
 if(suffix.length<6)throw Error('No se ha podido generar un identificador seguro.');
 return slugFromName(value)+'-'+suffix;
}
export function legalProfileValues(values){
 const str=(key,max)=>String(values[key]??'').trim().slice(0,max);
 const nullable=(key,max)=>str(key,max)||null;
 const taxId=str('tax_id',24).toUpperCase().replace(/\s+/g,'');
 if(taxId&&!/^[A-Z0-9-]{5,24}$/.test(taxId))throw Error('Revisa el NIF, NIE o CIF.');
 const country=(str('country',2)||'ES').toUpperCase();
 if(!/^[A-Z]{2}$/.test(country))throw Error('El país debe tener un código ISO de 2 letras.');
 const entityType=str('entity_type',20)||'self_employed';
 if(!['self_employed','company'].includes(entityType))throw Error('Forma jurídica incorrecta.');
 const billingEmail=nullable('billing_email',180);
 if(billingEmail&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(billingEmail))throw Error('Correo de facturación inválido.');
 return {entity_type:entityType,legal_name:nullable('legal_name',180),tax_id:taxId||null,
 representative_name:nullable('representative_name',150),contact_name:nullable('contact_name',150),
 billing_email:billingEmail,billing_address:nullable('billing_address',300),
 postal_code:nullable('postal_code',20),city:nullable('city',100),
 province:nullable('province',100),country};
}
export function publicBusinessValues(values){
 const str=(key,max)=>String(values[key]??'').trim().slice(0,max);
 const name=str('name',120);
 if(name.length<2)throw Error('Comprueba el nombre comercial.');
 const publicEmail=str('public_email',180),website=str('website',255);
 if(publicEmail&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(publicEmail))throw Error('Correo de contacto inválido.');
 if(website&&!/^https:\/\//i.test(website))throw Error('La web debe comenzar por https://');
 return {name,public_email:publicEmail||null,phone:str('phone',40)||null,
 website:website||null,address:str('address',300)||null,description:str('description',2000)||null,
 timezone:str('timezone',80)||'Europe/Madrid'};
}
export const priceLabel=cents=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format((Number(cents)||0)/100);
export function visiblePlans(plans,kind){
 return (plans||[]).filter(p=>p.is_active&&p.audience===audienceForKind(kind))
  .sort((a,b)=>a.display_order-b.display_order||a.monthly_price_cents-b.monthly_price_cents);
}
