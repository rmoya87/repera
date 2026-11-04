// Repera Business invitation delivery — verified JWT + scoped RPC, no public secret.
const project=Deno.env.get("SUPABASE_URL")||"";
const publicKey=Deno.env.get("SUPABASE_ANON_KEY")||"";
const resendKey=Deno.env.get("RESEND_API_KEY")||"";
const sender=Deno.env.get("REPERA_INVITE_FROM")||"";
const base=Deno.env.get("REPERA_PUBLIC_URL")||"";
const ios=Deno.env.get("REPERA_IOS_URL")||"";
const android=Deno.env.get("REPERA_ANDROID_URL")||"";
const esc=(value:string)=>String(value||"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]!));
// Comma-separated exact origins (e.g. add http://localhost:8080 only in a dev project).
const allowedOrigins=new Set((Deno.env.get("REPERA_BUSINESS_ORIGINS")||"https://repera.app,https://www.repera.app")
 .split(",").map(o=>o.trim()).filter(o=>/^https?:\/\/[a-z0-9.-]+(:\d+)?$/i.test(o)));
const cors=(origin:string|null):Record<string,string>=>origin&&allowedOrigins.has(origin)?{
 "Access-Control-Allow-Origin":origin,"Access-Control-Allow-Headers":"authorization,apikey,content-type",
 "Access-Control-Allow-Methods":"POST,OPTIONS","Access-Control-Max-Age":"600","Vary":"Origin"}:{"Vary":"Origin"};
const json=(obj:unknown,status:number,headers:Record<string,string>)=>new Response(JSON.stringify(obj),{
 status,headers:{"Content-Type":"application/json","Cache-Control":"no-store",...headers}});
const safeHttps=(url:string)=>{try{const u=new URL(url);return u.protocol==="https:"?u.toString():"";}catch{return ""}};
function emailHtml(payload:{org_name:string,recipient:string,org_type:string,mode?:string},url:string){
 const name=esc(payload.org_name),link=esc(url);
 const button=(label:string,target:string)=>`<a href="${esc(target)}" style="display:inline-block;background:#e8f8ee;color:#176934;border:1px solid #b9e4c7;border-radius:12px;text-decoration:none;font-size:13px;font-weight:700;padding:12px 16px;margin:4px">${label}</a>`;
 return `<!doctype html><html lang="es"><head><meta charset="UTF-8"></head><body style="background:#f4f8f5;margin:0;padding:30px 12px;font-family:-apple-system,BlinkMacSystemFont,Arial,sans-serif;color:#23422c">
 <main style="max-width:580px;margin:0 auto;background:white;border:1px solid #e1ece5;border-radius:22px;overflow:hidden">
 <div style="padding:26px 32px;background:#eaf7ef"><span style="font-size:26px;font-weight:900;color:#1c9245">repera</span><p style="font-size:13px;color:#5c8068;margin:2px 0">TU ENTRENAMIENTO, MEJOR CONECTADO</p></div>
 <div style="padding:27px 32px"><h1 style="font-size:27px;margin:0 0 14px">${payload.mode==="owner"?"Completa el registro de tu centro":"Tienes una invitación para entrenar juntos"}</h1>
 <p style="font-size:16px;line-height:1.6">${payload.mode==="owner"?
 "Te han preparado el espacio profesional de <strong>"+name+"</strong> en Repera. Solo tú podrás aceptarlo con este correo verificado.":
 "<strong>"+name+"</strong> quiere vincular tu cuenta Repera para planificar y gestionar tus entrenamientos."}</p>
 <p style="font-size:14px;line-height:1.6">${payload.mode==="owner"?
 "Inicia sesión o crea tu cuenta profesional con esta misma dirección, verifica el correo y activa el espacio que han preparado para ti.":
 "Si ya tienes cuenta, inicia sesión con este correo y acepta la invitación. Si todavía no la tienes, regístrate primero y verifica el correo."}</p>
 <div style="margin:24px 0">${button(payload.mode==="owner"?"Completar registro":"Aceptar invitación",url)}</div>
 <p style="font-size:13px;color:#527562">${payload.mode==="owner"?
 "El centro sigue sin propietario vinculado hasta que completes el registro con este correo.":
 "La vinculación solo se produce cuando tú aceptas. Tu historial deportivo privado no se comparte automáticamente."}</p>
 <div style="border-top:1px solid #e5eee7;padding-top:18px;margin-top:18px">
 <h3 style="font-size:14px">Consigue la aplicación</h3>
 ${safeHttps(ios)?button("App para iPhone",ios):'<p style="font-size:12px;color:#6d8573">iOS: acceso a la app disponible cuando el centro te facilite su enlace.</p>'}
 ${safeHttps(android)?button("App para Android",android):''}</div>
 <p style="font-size:11px;line-height:1.6;color:#819588">Si no conoces este centro o no quieres unirte, ignora este mensaje. La invitación caduca automáticamente.</p></div></main></body></html>`;
}
Deno.serve(async(request:Request)=>{
 const origin=request.headers.get("origin");
 const corsHeaders=cors(origin);
 const reply=(obj:unknown,status=200)=>json(obj,status,corsHeaders);
 if(request.method==="OPTIONS")return new Response(null,{status:origin&&allowedOrigins.has(origin)?204:403,headers:corsHeaders});
 if(origin&&!allowedOrigins.has(origin))return reply({error:"ORIGIN_NOT_ALLOWED"},403);
 if(request.method!=="POST")return reply({error:"METHOD_NOT_ALLOWED"},405);
 if(Number(request.headers.get("content-length")||0)>2048)return reply({error:"PAYLOAD_TOO_LARGE"},413);
 if(!project||!publicKey)return reply({error:"SERVICE_UNAVAILABLE"},503);
 if(!resendKey||!sender||!safeHttps(base))return reply({error:"EMAIL_PROVIDER_NOT_CONFIGURED"},503);
 const jwt=request.headers.get("authorization")||"";
 if(!/^Bearer\s+\S+$/i.test(jwt))return reply({error:"AUTH_REQUIRED"},401);
 const identity=await fetch(project+"/auth/v1/user",{headers:{Authorization:jwt,apikey:publicKey}});
 if(!identity.ok)return reply({error:"INVALID_SESSION"},401);
 let body:{invitationId?:string,provisioningId?:string};
 try{body=await request.json()}catch{return reply({error:"INVALID_BODY"},400)}
 const owner=typeof body.provisioningId==="string";
 const id=owner?body.provisioningId:body.invitationId;
 if(!/^[0-9a-f-]{36}$/i.test(id||""))return reply({error:"INVALID_INVITATION"},400);
 const auth=await fetch(project+"/rest/v1/rpc/"+
  (owner?"platform_admin_owner_email_payload":"business_invite_email_payload"),{
 method:"POST",headers:{Authorization:jwt,apikey:publicKey,"Content-Type":"application/json"},
 body:JSON.stringify(owner?{p_provision:id}:{p_invitation:id})});
 if(!auth.ok)return reply({error:auth.status===403?"NOT_AUTHORIZED":"INVITATION_UNAVAILABLE"},auth.status===403?403:400);
 const invitation=await auth.json();
 const target=new URL("/console/",safeHttps(base));
 if(!owner)target.searchParams.set("invitation",invitation.invitation_id);
 const response=await fetch("https://api.resend.com/emails",{
 method:"POST",headers:{Authorization:"Bearer "+resendKey,"Content-Type":"application/json"},
 body:JSON.stringify({from:sender,to:[invitation.recipient],
 subject:owner?"Completa tu registro de "+invitation.org_name+" en Repera":
  ""+invitation.org_name+" te invita a entrenar con Repera",
 html:emailHtml({...invitation,mode:owner?"owner":"athlete"},target.toString())})});
 if(!response.ok)return reply({error:"EMAIL_DELIVERY_FAILED"},502);
 return reply({sent:true});
});
