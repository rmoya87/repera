// Datos ficticios. Nunca se sincronizan con un servidor.
export function seedData(reference = new Date()) {
  const iso = d => new Date(d).toISOString().slice(0,10);
  const at = (offset, time='09:00') => {const d=new Date(reference);d.setDate(d.getDate()+offset);return `${iso(d)}T${time}`;};
  const orgs = [
    {id:'org-fit',name:'Estudio Norte',kind:'gym',email:'hola@estudionorte.example',taxId:'',address:'Las Rozas · Madrid',timezone:'Europe/Madrid',active:true},
    {id:'org-coach',name:'Entrena con Álex',kind:'coach',email:'alex@entrena.example',taxId:'',address:'Madrid y online',timezone:'Europe/Madrid',active:true}
  ];
  const clients = [
    {id:'c1',orgId:'org-fit',name:'Lucía Fernández',email:'lucia@example.com',phone:'',status:'active',joined:at(-70).slice(0,10),tags:['Fuerza'],consent:true,notes:'Prefiere sesiones por la mañana',appLinked:true},
    {id:'c2',orgId:'org-fit',name:'Marcos Ruiz',email:'marcos@example.com',phone:'',status:'active',joined:at(-41).slice(0,10),tags:['CrossFit'],consent:true,notes:'',appLinked:true},
    {id:'c3',orgId:'org-fit',name:'Inés Martín',email:'ines@example.com',phone:'',status:'trial',joined:at(-5).slice(0,10),tags:['Prueba'],consent:false,notes:'Invitación pendiente',appLinked:false},
    {id:'c4',orgId:'org-coach',name:'Diego López',email:'diego@example.com',phone:'',status:'active',joined:at(-90).slice(0,10),tags:['Fuerza'],consent:true,notes:'',appLinked:true},
    {id:'c5',orgId:'org-coach',name:'Paula García',email:'paula@example.com',phone:'',status:'active',joined:at(-28).slice(0,10),tags:['Movilidad'],consent:true,notes:'',appLinked:true}
  ];
  return {
    version:1, organizations:orgs,
    staff:[{id:'s1',orgId:'org-fit',name:'Sara Moreno',role:'owner',email:'sara@example.com'}, {id:'s2',orgId:'org-fit',name:'Carlos Vega',role:'coach',email:'carlos@example.com'}, {id:'s3',orgId:'org-coach',name:'Álex Pérez',role:'owner',email:'alex@example.com'}],
    locations:[{id:'l1',orgId:'org-fit',name:'Sala principal',capacity:12},{id:'l2',orgId:'org-fit',name:'Sala personal',capacity:2}],
    clients,
    groups:[{id:'g1',orgId:'org-fit',name:'Fuerza inicial',clientIds:['c1','c2']},{id:'g2',orgId:'org-coach',name:'Seguimiento online',clientIds:['c4','c5']}],
    templates:[{id:'t1',orgId:'org-fit',name:'Fuerza · 3 días',description:'Programa inicial reutilizable',weeks:4,days:[{weekday:1,title:'Tren inferior',exercises:'Sentadilla 3×8 · Peso muerto 3×8'}, {weekday:3,title:'Tren superior',exercises:'Press banca 3×8 · Remo 3×10'}, {weekday:5,title:'Cuerpo completo',exercises:'Sentadilla frontal 3×6 · Press militar 3×8'}]},
      {id:'t2',orgId:'org-coach',name:'Movilidad · 2 días',description:'Movilidad general',weeks:6,days:[{weekday:2,title:'Movilidad cadera',exercises:'Estiramientos 20 min'},{weekday:5,title:'Movilidad hombros',exercises:'Movilidad 20 min'}]}],
    assignments:[{id:'a1',orgId:'org-fit',clientId:'c1',templateId:'t1',startsOn:at(-6).slice(0,10),endsOn:null,status:'active',overrides:{}},{id:'a2',orgId:'org-fit',clientId:'c2',templateId:'t1',startsOn:at(-6).slice(0,10),endsOn:null,status:'active',overrides:{}}],
    classes:[{id:'cl1',orgId:'org-fit',name:'CrossFit de mañana',start:at(0,'09:00'),duration:60,capacity:3,coachId:'s2',locationId:'l1',status:'scheduled',description:'WOD y técnica'},
      {id:'cl2',orgId:'org-fit',name:'Fuerza funcional',start:at(1,'18:30'),duration:50,capacity:2,coachId:'s1',locationId:'l1',status:'scheduled',description:'Fuerza dirigida'},
      {id:'cl3',orgId:'org-coach',name:'Sesión personal online',start:at(2,'10:00'),duration:60,capacity:1,coachId:'s3',locationId:null,status:'scheduled',description:'Videollamada'}],
    bookings:[{id:'b1',orgId:'org-fit',classId:'cl1',clientId:'c1',status:'confirmed',createdAt:at(-1)},{id:'b2',orgId:'org-fit',classId:'cl1',clientId:'c2',status:'confirmed',createdAt:at(-1)},{id:'b3',orgId:'org-fit',classId:'cl2',clientId:'c2',status:'confirmed',createdAt:at(-1)}],
    products:[{id:'p1',orgId:'org-fit',name:'Bono 10 clases',mode:'credits',credits:10,priceCents:8500,validityDays:90,renewal:'none',active:true},
      {id:'p2',orgId:'org-fit',name:'Mensual ilimitado',mode:'unlimited',credits:null,priceCents:6900,validityDays:30,renewal:'manual',active:true},
      {id:'p3',orgId:'org-coach',name:'Pack personal 4 sesiones',mode:'credits',credits:4,priceCents:16000,validityDays:60,renewal:'none',active:true}],
    passes:[{id:'pass1',orgId:'org-fit',clientId:'c1',productId:'p1',startsOn:at(-4).slice(0,10),endsOn:at(86).slice(0,10),status:'active'},
      {id:'pass2',orgId:'org-fit',clientId:'c2',productId:'p2',startsOn:at(-4).slice(0,10),endsOn:at(26).slice(0,10),status:'active'}],
    credits:[{id:'tx1',orgId:'org-fit',passId:'pass1',delta:10,reason:'purchase',referenceId:'pass1',createdAt:at(-4)},{id:'tx2',orgId:'org-fit',passId:'pass1',delta:-1,reason:'booking',referenceId:'b1',createdAt:at(-1)}],
    payments:[{id:'pay1',orgId:'org-fit',clientId:'c1',amountCents:8500,currency:'EUR',status:'paid',method:'external',createdAt:at(-4),productId:'p1'},{id:'pay2',orgId:'org-fit',clientId:'c2',amountCents:6900,currency:'EUR',status:'paid',method:'cash',createdAt:at(-4),productId:'p2'}],
    invoices:[{id:'inv1',orgId:'org-fit',clientId:'c1',number:'BORRADOR-001',amountCents:8500,issuedOn:at(-4).slice(0,10),status:'draft',paymentId:'pay1'}],
    notifications:[], invites:[], attendance:[], events:[]
  };
}
