export const uuid = () => globalThis.crypto?.randomUUID?.() || `local-${Date.now()}-${Math.random().toString(36).slice(2)}`;
export const isoDate = (date = new Date()) => {const d=new Date(date);return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;};
export const money = cents => new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(Number(cents||0)/100);
export const shortDate = date => date ? new Intl.DateTimeFormat('es-ES',{dateStyle:'medium'}).format(new Date(`${String(date).slice(0,10)}T12:00:00`)) : '—';
export const isEmail = input => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(input||'').trim());
export const requireText = (input,name) => { const v=String(input||'').trim(); if(!v)throw Error(`${name} es obligatorio`);return v; };
export const assertOrg = (state,orgId) => {if(!state.organizations.some(o=>o.id===orgId))throw Error('Organización no encontrada');};
export const ensureBelongs = (state,table,id,orgId) => {const item=state[table].find(x=>x.id===id && x.orgId===orgId);if(!item)throw Error(`${table}: el registro no pertenece a esta organización`);return item;};
export const getBalance=(state,passId)=>state.credits.filter(x=>x.passId===passId).reduce((sum,x)=>sum+x.delta,0);
export const isActivePass = (pass,date=isoDate()) => pass.status==='active' && pass.startsOn<=date && pass.endsOn>=date;
export function entitlements(state,orgId,clientId,date=isoDate()) {
  return state.passes.filter(p=>p.orgId===orgId&&p.clientId===clientId&&isActivePass(p,date)).map(p=>({pass:p,product:ensureBelongs(state,'products',p.productId,orgId),balance:getBalance(state,p.id)})).filter(x=>x.product.mode==='unlimited'||x.balance>0);
}
export function availablePlaces(state,orgId,classId) {
  const row=ensureBelongs(state,'classes',classId,orgId);
  return row.capacity-state.bookings.filter(b=>b.orgId===orgId&&b.classId===classId&&b.status==='confirmed').length;
}
export function addClient(state,orgId,{name,email,phone='',status='trial',tags='',notes='',consent=false}) {
 assertOrg(state,orgId);const n=requireText(name,'Nombre');const mail=requireText(email,'Correo');if(!isEmail(mail))throw Error('Correo no válido');
 if(state.clients.some(x=>x.orgId===orgId&&x.email.toLowerCase()===mail.toLowerCase()))throw Error('Ya existe un cliente con ese correo en este negocio');
 const client={id:uuid(),orgId,name:n,email:mail,phone,status,joined:isoDate(),tags:String(tags).split(',').map(x=>x.trim()).filter(Boolean),notes,consent:!!consent,appLinked:false};state.clients.push(client);return client;
}
export function createTemplate(state,orgId,{name,weeks,days,description=''}) {
 assertOrg(state,orgId); const w=Number(weeks); if(!Number.isInteger(w)||w<1||w>52)throw Error('La duración debe ser de 1 a 52 semanas');
 if(!days?.length)throw Error('Añade al menos un día al programa');
 days.forEach(day=>{if(day.weekday<1||day.weekday>7||!day.title?.trim())throw Error('Hay un día sin configurar');});
 const row={id:uuid(),orgId,name:requireText(name,'Nombre'),weeks:w,description,days};state.templates.push(row);return row;
}
export function assignToClients(state,orgId,templateId,clientIds,startsOn) {
 const template=ensureBelongs(state,'templates',templateId,orgId);if(!/^\d{4}-\d{2}-\d{2}$/.test(startsOn))throw Error('Fecha no válida');
 const ids=[...new Set(clientIds)];if(!ids.length)throw Error('Selecciona al menos un cliente');ids.forEach(id=>ensureBelongs(state,'clients',id,orgId));
 const result=[];for(const clientId of ids){
  const duplicate=state.assignments.some(a=>a.orgId===orgId&&a.clientId===clientId&&a.templateId===templateId&&a.startsOn===startsOn&&a.status==='active');
  if(duplicate)continue;
  const row={id:uuid(),orgId,clientId,templateId,startsOn,endsOn:null,status:'active',overrides:{}};state.assignments.push(row);result.push(row);
 }return result;
}
// Sólo genera sesiones a partir de la plantilla; no modifica históricos ni otras asignaciones.
export function plannedForClient(state,orgId,clientId,date) {
 const target=new Date(`${date}T12:00:00`);
 return state.assignments.filter(a=>a.orgId===orgId&&a.clientId===clientId&&a.status==='active'&&a.startsOn<=date&&(!a.endsOn||a.endsOn>=date)).flatMap(a=>{
  const t=ensureBelongs(state,'templates',a.templateId,orgId);
  const start=new Date(`${a.startsOn}T12:00:00`);
  const diff=Math.round((target-start)/(24*3600*1000)); if(diff<0||diff>=t.weeks*7)return [];
  const weekday=(target.getDay()+6)%7+1;
  return t.days.filter(x=>x.weekday===weekday).map(x=>({...x,assignmentId:a.id,templateName:t.name,clientId,source:'professional',date}));
 });
}
export function createClass(state,orgId,values) {
 assertOrg(state,orgId);const cap=Number(values.capacity), duration=Number(values.duration);
 if(!Number.isInteger(cap)||cap<1||cap>1000)throw Error('Aforo entre 1 y 1000');
 if(!Number.isInteger(duration)||duration<10||duration>360)throw Error('Duración entre 10 y 360 minutos');
 if(!values.start||new Date(values.start).toString()==='Invalid Date')throw Error('Inicio no válido');
 if(values.coachId)ensureBelongs(state,'staff',values.coachId,orgId);
 if(values.locationId)ensureBelongs(state,'locations',values.locationId,orgId);
 const row={id:uuid(),orgId,name:requireText(values.name,'Clase'),start:values.start,duration,capacity:cap,coachId:values.coachId||null,locationId:values.locationId||null,status:'scheduled',description:values.description||''};state.classes.push(row);return row;
}
export function createProduct(state,orgId,values) {
 assertOrg(state,orgId);const priceCents=Math.round(Number(values.price)*100),validityDays=Number(values.validityDays); const credits=values.mode==='credits'?Number(values.credits):null;
 if(!Number.isInteger(priceCents)||priceCents<0)throw Error('Precio no válido');
 if(!Number.isInteger(validityDays)||validityDays<1||validityDays>1095)throw Error('Validez entre 1 y 1095 días');
 if(!['credits','unlimited'].includes(values.mode))throw Error('Modalidad no válida');
 if(values.mode==='credits'&&(!Number.isInteger(credits)||credits<1))throw Error('Sesiones debe ser positivo');
 const row={id:uuid(),orgId,name:requireText(values.name,'Tarifa'),mode:values.mode,credits,priceCents,validityDays,renewal:values.renewal||'none',active:true};state.products.push(row);return row;
}
export function sellPass(state,orgId,clientId,productId,{startsOn=isoDate(),method='external'}={}) {
 ensureBelongs(state,'clients',clientId,orgId); const p=ensureBelongs(state,'products',productId,orgId);if(!p.active)throw Error('Tarifa desactivada');
 const start=new Date(`${startsOn}T12:00:00`);if(Number.isNaN(start.getTime()))throw Error('Fecha de inicio inválida');const end=new Date(start);end.setDate(end.getDate()+p.validityDays);
 const pass={id:uuid(),orgId,clientId,productId,startsOn,endsOn:isoDate(end),status:method==='pending'?'pending':'active'};state.passes.push(pass);
 if(p.mode==='credits'&&method!=='pending')state.credits.push({id:uuid(),orgId,passId:pass.id,delta:p.credits,reason:'purchase',referenceId:pass.id,createdAt:new Date().toISOString()});
 const payment={id:uuid(),orgId,clientId,amountCents:p.priceCents,currency:'EUR',status:method==='pending'?'pending':'paid',method,createdAt:new Date().toISOString(),productId};state.payments.push(payment);pass.paymentId=payment.id;
 return {pass,payment};
}
export function reserveClass(state,orgId,classId,clientId) {
 const session=ensureBelongs(state,'classes',classId,orgId);ensureBelongs(state,'clients',clientId,orgId);if(session.status!=='scheduled')throw Error('Clase cancelada');
 if(state.bookings.some(b=>b.orgId===orgId&&b.classId===classId&&b.clientId===clientId&&['confirmed','waitlist'].includes(b.status)))throw Error('El cliente ya está apuntado');
 const when=session.start.slice(0,10);const entries=entitlements(state,orgId,clientId,when);if(!entries.length)throw Error('El cliente no tiene un bono o cuota válida');
 const preferred=entries[0];const confirmed=availablePlaces(state,orgId,classId)>0; const row={id:uuid(),orgId,classId,clientId,status:confirmed?'confirmed':'waitlist',createdAt:new Date().toISOString(),passId:preferred.pass.id};state.bookings.push(row);
 if(confirmed&&preferred.product.mode==='credits')state.credits.push({id:uuid(),orgId,passId:preferred.pass.id,delta:-1,reason:'booking',referenceId:row.id,createdAt:new Date().toISOString()});
 return row;
}
export function cancelBooking(state,orgId,bookingId) {
 const row=ensureBelongs(state,'bookings',bookingId,orgId);if(!['confirmed','waitlist'].includes(row.status))throw Error('Esta reserva ya no está activa');
 const wasConfirmed=row.status==='confirmed';row.status='cancelled';
 if(wasConfirmed&&row.passId){const pass=ensureBelongs(state,'passes',row.passId,orgId);const p=ensureBelongs(state,'products',pass.productId,orgId);if(p.mode==='credits')state.credits.push({id:uuid(),orgId,passId:pass.id,delta:1,reason:'cancel_refund',referenceId:row.id,createdAt:new Date().toISOString()});}
 const pending=state.bookings.filter(b=>b.orgId===orgId&&b.classId===row.classId&&b.status==='waitlist').sort((a,b)=>a.createdAt.localeCompare(b.createdAt));
 if(wasConfirmed&&pending.length){for(const n of pending){const rights=entitlements(state,orgId,n.clientId,ensureBelongs(state,'classes',n.classId,orgId).start.slice(0,10));if(!rights.length)continue;n.passId=rights[0].pass.id;n.status='confirmed';if(rights[0].product.mode==='credits')state.credits.push({id:uuid(),orgId,passId:n.passId,delta:-1,reason:'booking',referenceId:n.id,createdAt:new Date().toISOString()});break;}}
 return row;
}
export function recordPayment(state,orgId,{clientId,amount,method='external'}) {
 ensureBelongs(state,'clients',clientId,orgId);const amountCents=Math.round(Number(amount)*100);if(!Number.isInteger(amountCents)||amountCents<=0)throw Error('Importe debe ser positivo');
 const row={id:uuid(),orgId,clientId,amountCents,currency:'EUR',status:'paid',method,createdAt:new Date().toISOString(),productId:null};state.payments.push(row);return row;
}
// Las facturas de la demo son BORRADORES sin numeración fiscal ni validez tributaria.
export function draftInvoice(state,orgId,paymentId) {
 const pay=ensureBelongs(state,'payments',paymentId,orgId);if(pay.status!=='paid')throw Error('Sólo para cobros confirmados');if(state.invoices.some(i=>i.paymentId===paymentId))throw Error('Ya existe un borrador para este cobro');
 const row={id:uuid(),orgId,clientId:pay.clientId,number:`BORRADOR-${String(state.invoices.filter(i=>i.orgId===orgId).length+1).padStart(3,'0')}`,amountCents:pay.amountCents,issuedOn:isoDate(),status:'draft',paymentId};state.invoices.push(row);return row;
}
export function analytics(state,orgId){const clients=state.clients.filter(c=>c.orgId===orgId);const classes=state.classes.filter(c=>c.orgId===orgId);const pay=state.payments.filter(p=>p.orgId===orgId&&p.status==='paid');const bookings=state.bookings.filter(b=>b.orgId===orgId&&b.status==='confirmed');return {clients:clients.length,activeClients:clients.filter(c=>c.status==='active').length,classes:classes.length,reservations:bookings.length,paidCents:pay.reduce((s,p)=>s+p.amountCents,0),occupancy:classes.length?Math.round(bookings.length/classes.reduce((s,c)=>s+c.capacity,0)*100):0,programs:state.assignments.filter(a=>a.orgId===orgId&&a.status==='active').length};}
