// Repera Business — deterministic domain operations for the OFFLINE DEMO.
// Production must implement every protected transition as a checked database transaction.
import {uuid,isoDate,ensureBelongs,assertOrg,requireText,isEmail,entitlements,getBalance,availablePlaces} from './domain.js';

const today=()=>new Date().toISOString();
const validDate=value=>/^\d{4}-\d{2}-\d{2}$/.test(value) && !Number.isNaN(Date.parse(`${value}T12:00:00Z`));
const dayAt=(start,offset)=>{const d=new Date(`${start}T12:00:00Z`);d.setUTCDate(d.getUTCDate()+offset);return d.toISOString().slice(0,10)};
const ensureArrays=s=>{s.notifications??=[];s.attendance??=[];s.invites??=[];s.schedules??=[];};

export function createGroup(state,orgId,name,clientIds=[]){
 assertOrg(state,orgId);const n=requireText(name,'Nombre del grupo');if(n.length>100)throw Error('Nombre de grupo demasiado largo');
 const ids=[...new Set(clientIds)];ids.forEach(id=>ensureBelongs(state,'clients',id,orgId));
 if(state.groups.some(g=>g.orgId===orgId&&g.name.toLocaleLowerCase('es')===n.toLocaleLowerCase('es')))throw Error('Ya hay un grupo con ese nombre');
 const row={id:uuid(),orgId,name:n,clientIds:ids};state.groups.push(row);return row;
}
export function updateGroupMembers(state,orgId,groupId,clientIds,name=null){
 const g=ensureBelongs(state,'groups',groupId,orgId);const ids=[...new Set(clientIds)];ids.forEach(id=>ensureBelongs(state,'clients',id,orgId));if(name!==null){const label=requireText(name,'Nombre del grupo');if(state.groups.some(x=>x.orgId===orgId&&x.id!==g.id&&x.name.toLowerCase()===label.toLowerCase()))throw Error('Grupo duplicado');g.name=label;}g.clientIds=ids;return g;
}
export function createStaff(state,orgId,{name,email,role}){
 assertOrg(state,orgId);const n=requireText(name,'Nombre');const mail=requireText(email,'Correo').toLowerCase();if(!isEmail(mail))throw Error('Correo no válido');
 if(!['manager','coach','reception','billing'].includes(role))throw Error('Función no válida');
 if(state.staff.some(p=>p.orgId===orgId&&p.email.toLowerCase()===mail))throw Error('Este profesional ya existe');
 const row={id:uuid(),orgId,name:n,email:mail,role,status:'invited'};state.staff.push(row);return row;
}
export function createLocation(state,orgId,{name,capacity}){
 assertOrg(state,orgId);const cap=Number(capacity);if(!Number.isInteger(cap)||cap<1||cap>1000)throw Error('Capacidad no válida');
 if(state.locations.some(l=>l.orgId===orgId&&l.name.toLowerCase()===String(name).trim().toLowerCase()))throw Error('Ya existe una sala con ese nombre');
 const row={id:uuid(),orgId,name:requireText(name,'Nombre de sala'),capacity:cap};state.locations.push(row);return row;
}
export function updateClient(state,orgId,clientId,values){
 const row=ensureBelongs(state,'clients',clientId,orgId);
 if(values.name!==undefined)row.name=requireText(values.name,'Nombre');
 if(values.email!==undefined){const mail=requireText(values.email,'Correo');if(!isEmail(mail))throw Error('Correo no válido');if(state.clients.some(c=>c.id!==clientId&&c.orgId===orgId&&c.email.toLowerCase()===mail.toLowerCase()))throw Error('Correo duplicado');row.email=mail;}
 if(values.status!==undefined){if(!['lead','trial','active','paused','cancelled'].includes(values.status))throw Error('Estado no válido');row.status=values.status;}
 if(values.notes!==undefined)row.notes=String(values.notes).slice(0,2000);
 return row;
}
export function pauseAssignment(state,orgId,assignmentId,paused){
 const a=ensureBelongs(state,'assignments',assignmentId,orgId);a.status=paused?'paused':'active';return a;
}
export function overrideAssignedDay(state,orgId,assignmentId,date,{title,exercises,skip=false}){
 const a=ensureBelongs(state,'assignments',assignmentId,orgId);if(!validDate(date))throw Error('Fecha no válida');
 const template=ensureBelongs(state,'templates',a.templateId,orgId);
 if(date<a.startsOn||dayAt(a.startsOn,template.weeks*7-1)<date)throw Error('Fuera del período de entrenamiento');
 if(!skip){requireText(title,'Título');requireText(exercises,'Ejercicios');}
 a.overrides??={};a.overrides[date]={skip:!!skip,title:skip?'':title.trim(),exercises:skip?'':exercises.trim(),changedAt:today()};return a.overrides[date];
}
export function plannedWorkoutWithOverrides(state,orgId,clientId,date){
 if(!validDate(date))throw Error('Fecha no válida');
 return state.assignments.filter(a=>a.orgId===orgId&&a.clientId===clientId&&a.status==='active'&&a.startsOn<=date&&(!a.endsOn||a.endsOn>=date)).flatMap(a=>{
  const t=ensureBelongs(state,'templates',a.templateId,orgId);const d0=new Date(`${a.startsOn}T12:00:00Z`),d1=new Date(`${date}T12:00:00Z`),offset=Math.round((d1-d0)/86400000);
  if(offset<0||offset>=t.weeks*7)return [];
  const override=a.overrides?.[date];if(override?.skip)return [];
  const wd=(d1.getUTCDay()+6)%7+1;
  if(override)return [{title:override.title,exercises:override.exercises,weekday:wd,assignmentId:a.id,clientId,date,templateName:t.name,source:'professional',modified:true}];
  return t.days.filter(d=>d.weekday===wd).map(d=>({...d,assignmentId:a.id,clientId,date,templateName:t.name,source:'professional',modified:false}));
 });
}
export function assignGroup(state,orgId,groupId,templateId,startsOn,assigner){
 const group=ensureBelongs(state,'groups',groupId,orgId);ensureBelongs(state,'templates',templateId,orgId);
 if(!validDate(startsOn))throw Error('Fecha no válida');
 const created=[];for(const clientId of group.clientIds){ensureBelongs(state,'clients',clientId,orgId);if(state.assignments.some(a=>a.orgId===orgId&&a.clientId===clientId&&a.templateId===templateId&&a.startsOn===startsOn&&a.status==='active'))continue;
 const a={id:uuid(),orgId,clientId,templateId,startsOn,endsOn:null,status:'active',overrides:{},groupId,assignedBy:assigner||null};state.assignments.push(a);created.push(a);
 }
 return created;
}
export function scheduleClassSeries(state,orgId,classDraft,{count=1,intervalDays=7,exclude=[]}={}){
 const n=Number(count),distance=Number(intervalDays);if(!Number.isInteger(n)||n<1||n>52||!Number.isInteger(distance)||distance<1||distance>30)throw Error('Recurrencia no válida');
 if(!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(classDraft.start))throw Error('Hora de inicio inválida');
 const created=[];const template=classDraft;
 for(let i=0;i<n;i++){
  const first=template.start.slice(0,10),time=template.start.slice(10);const start=`${dayAt(first,i*distance)}${time}`;
  if(exclude.includes(start.slice(0,10)))continue;
  const item={...template,start,id:uuid(),orgId};assertClassCapacity(state,orgId,item);state.classes.push(item);created.push(item);
 }
 return created;
}
function assertClassCapacity(state,orgId,draft,ignoreId=null){
 if(draft.locationId){const location=ensureBelongs(state,'locations',draft.locationId,orgId);if(draft.capacity>location.capacity)throw Error('Aforo superior a la capacidad de la sala');}
 const start=new Date(draft.start).getTime(),end=start+draft.duration*60000;
 if(Number.isNaN(start)||end<=start)throw Error('Horario inválido');
 for(const other of state.classes){if(other.orgId!==orgId||other.id===ignoreId||other.status!=='scheduled')continue;
  const a=new Date(other.start).getTime(),b=a+other.duration*60000;
  if(start<b&&end>a){if(draft.locationId&&draft.locationId===other.locationId)throw Error('La sala ya está ocupada en ese horario');if(draft.coachId&&draft.coachId===other.coachId)throw Error('El entrenador ya tiene otra sesión en ese horario');}
 }
}
export function checkClassConflicts(state,orgId,draft){assertOrg(state,orgId);assertClassCapacity(state,orgId,draft);return true;}
export function cancelClass(state,orgId,classId,{reason='Cancelada por el centro'}={}){
 const session=ensureBelongs(state,'classes',classId,orgId);if(session.status!=='scheduled')throw Error('La clase no está programada');
 session.status='cancelled';session.cancellationReason=reason;ensureArrays(state);
 for(const booking of state.bookings.filter(b=>b.orgId===orgId&&b.classId===classId&&['confirmed','waitlist'].includes(b.status))){
  const confirmed=booking.status==='confirmed';booking.status='cancelled';booking.cancelReason='class_cancelled';
  if(confirmed){const charged=state.credits.find(x=>x.orgId===orgId&&x.reason==='booking'&&x.referenceId===booking.id&&x.delta<0);const passId=booking.passId||charged?.passId;if(passId){const pass=ensureBelongs(state,'passes',passId,orgId),product=ensureBelongs(state,'products',pass.productId,orgId);if(product.mode==='credits'&&charged&&!state.credits.some(x=>x.referenceId===booking.id&&['class_cancel_refund','cancel_refund'].includes(x.reason)))state.credits.push({id:uuid(),orgId,passId:pass.id,delta:1,reason:'class_cancel_refund',referenceId:booking.id,createdAt:today()});}}
  queueNotification(state,orgId,booking.clientId,'class_cancelled',`La clase ${session.name} se ha cancelado`,`repera://classes/${session.id}`);
 }
 return session;
}
export function recordAttendance(state,orgId,bookingId,status){
 const b=ensureBelongs(state,'bookings',bookingId,orgId);if(b.status!=='confirmed'&&!['attended','no_show'].includes(b.status))throw Error('Reserva no confirmada');
 if(!['attended','no_show'].includes(status))throw Error('Asistencia inválida');
 b.status=status;return b;
}
export function confirmPendingPayment(state,orgId,paymentId){
 const p=ensureBelongs(state,'payments',paymentId,orgId);if(p.status!=='pending')throw Error('El cobro no está pendiente');
 const pass=state.passes.find(x=>x.orgId===orgId&&x.paymentId===paymentId);
 if(!pass)throw Error('El pago no tiene un bono pendiente enlazado');
 const product=ensureBelongs(state,'products',pass.productId,orgId);
 p.status='paid';p.confirmedAt=today();pass.status='active';
 if(product.mode==='credits'&&!state.credits.some(x=>x.passId===pass.id&&x.reason==='purchase'))state.credits.push({id:uuid(),orgId,passId:pass.id,delta:product.credits,reason:'purchase',referenceId:pass.id,createdAt:today()});
 return p;
}
export function queueNotification(state,orgId,clientId,type,message,deepLink){
 ensureArrays(state);ensureBelongs(state,'clients',clientId,orgId);
 if(!/^repera:\/\/(?:classes|diary|today|passes)\/[\w-]+$/.test(deepLink))throw Error('Enlace interno inválido');
 const notice={id:uuid(),orgId,clientId,type,message,deepLink,channel:'in_app_demo',status:'queued',createdAt:today()};state.notifications.push(notice);return notice;
}
export function publishProgramNotifications(state,orgId,assignmentIds){
 ensureArrays(state);let count=0;
 for(const id of new Set(assignmentIds)){const a=ensureBelongs(state,'assignments',id,orgId);queueNotification(state,orgId,a.clientId,'program_published','Tu entrenador ha actualizado tu planificación',`repera://diary/${a.id}`);count++;}
 return count;
}
export function clientAgenda(state,orgId,clientId,from,to){
 ensureBelongs(state,'clients',clientId,orgId);if(!validDate(from)||!validDate(to)||from>to)throw Error('Rango de fechas no válido');
 const total=Math.round((new Date(`${to}T12:00:00Z`)-new Date(`${from}T12:00:00Z`))/86400000);if(total>92)throw Error('Máximo 93 días por consulta');
 const entries=[];for(let i=0;i<=total;i++){const date=dayAt(from,i);for(const plan of plannedWorkoutWithOverrides(state,orgId,clientId,date))entries.push({id:`${plan.assignmentId}:${date}:${plan.title}`,kind:'training',date,source:'professional',title:plan.title,assignmentId:plan.assignmentId,exerciseText:plan.exercises,deepLink:`repera://diary/${plan.assignmentId}`});}
 for(const booking of state.bookings.filter(b=>b.orgId===orgId&&b.clientId===clientId&&['confirmed','attended','no_show'].includes(b.status))){const c=ensureBelongs(state,'classes',booking.classId,orgId),date=c.start.slice(0,10);if(date>=from&&date<=to)entries.push({id:booking.id,kind:'class',date,start:c.start,title:c.name,bookingId:booking.id,source:'professional',deepLink:`repera://classes/${c.id}`});}
 return entries.sort((a,b)=>a.date.localeCompare(b.date)||a.kind.localeCompare(b.kind)||a.id.localeCompare(b.id));
}
export const financialSnapshot=(state,orgId)=>{
 assertOrg(state,orgId);const payments=state.payments.filter(p=>p.orgId===orgId),paid=payments.filter(p=>p.status==='paid'),refunded=payments.filter(p=>p.status==='refunded');
 return {grossCents:paid.reduce((s,p)=>s+p.amountCents,0),pendingCents:payments.filter(p=>p.status==='pending').reduce((s,p)=>s+p.amountCents,0),refundedCents:refunded.reduce((s,p)=>s+p.amountCents,0),draftInvoices:state.invoices.filter(i=>i.orgId===orgId&&i.status==='draft').length};
};
