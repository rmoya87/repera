import { z } from "npm:zod@4.3.6";
import type { McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.58.0";

const uuid=z.string().uuid(), revision=z.string().datetime({offset:true});
const result=(value:unknown)=>({content:[{type:"text" as const,text:JSON.stringify(value)}],
  structuredContent:{result:value}});
const fail=(code:string,field:string,message:string)=>({
  isError:true,content:[{type:"text" as const,text:JSON.stringify({error:{code,field,message}})}],
  structuredContent:{error:{code,field,message}},
});
const setPatch=z.strictObject({
  exerciseEntryId:uuid,loggedSetId:uuid,
  reps:z.number().int().min(0).max(50000).optional(),
  weightKg:z.number().finite().min(0).max(1200).nullable().optional(),
  rir:z.number().finite().min(0).max(10).nullable().optional(),
  clearWeight:z.boolean().optional(),
  clearRir:z.boolean().optional(),
}).refine(s=>s.reps!==undefined||s.weightKg!==undefined||s.rir!==undefined||s.clearWeight===true||s.clearRir===true,
  {message:"At least one value is required"})
  .refine(s=>!(s.weightKg!=null && s.clearWeight===true) && !(s.rir!=null && s.clearRir===true),
  {message:"Cannot both set and clear the same field"});
const exercise=z.strictObject({
  name:z.string().trim().min(2).max(120),
  muscleGroup:z.string().trim().min(2).max(80),
  equipment:z.string().trim().max(100).nullable().optional(),
  targetMuscle:z.string().trim().max(80).nullable().optional(),
  secondaryMuscles:z.array(z.string().trim().min(2).max(80)).max(12).optional(),
});
type Change="update_workout"|"delete_workout"|"create_exercise"|"update_exercise"|"delete_exercise";

export function registerAthleteChangeTools(
  server:McpServer, db:SupabaseClient, ownerId:string,tokenId:string,canWrite:boolean,
) {
  server.registerTool("get_custom_exercises", {
    description:"Read private, locally confirmed custom exercise catalog (not global curated exercises).",
    inputSchema:z.strictObject({limit:z.number().int().min(1).max(100).default(100),
      offset:z.number().int().min(0).max(100000).default(0)}),
    annotations:{readOnlyHint:true},
  },async({limit,offset})=>{
    const {data,error}=await db.from("athlete_custom_exercise_mirror")
      .select("exercise_id,name,muscle_group,equipment,target_muscle,secondary_muscles,updated_at")
      .eq("owner_id",ownerId).order("name").order("exercise_id")
      .range(offset,offset+limit);
    if(error)return fail("STORAGE_ERROR","ownerId","No se pudo consultar ejercicios personalizados");
    const rows=data??[],hasMore=rows.length>limit;
    return result({items:rows.slice(0,limit),hasMore,nextOffset:hasMore?offset+limit:null});
  });
  server.registerTool("get_athlete_change_requests",{
    description:"Inspect pending, applied, rejected or conflicted changes sent to iPhone for athlete consent.",
    inputSchema:z.strictObject({status:z.enum(["pending","applied","rejected","conflict"]).optional(),
      limit:z.number().int().min(1).max(100).default(50),
      offset:z.number().int().min(0).max(100000).default(0)}),
    annotations:{readOnlyHint:true},
  },async({status,limit,offset})=>{
    let q=db.from("ai_athlete_change_requests")
      .select("id,operation,target_id,payload,status,created_at,decided_at,decision_message")
      .eq("owner_id",ownerId).order("created_at",{ascending:false}).order("id")
      .range(offset,offset+limit);
    if(status) q=q.eq("status",status);
    const {data,error}=await q;
    if(error)return fail("STORAGE_ERROR","status","No se pudo consultar bandeja de cambios");
    const rows=data??[],hasMore=rows.length>limit;
    return result({items:rows.slice(0,limit),hasMore,nextOffset:hasMore?offset+limit:null});
  });
  if(!canWrite)return;
  async function stage(op:Change,targetId:string|null,payload:Record<string,unknown>,expectedUpdatedAt?:string) {
    const {data,error}=await db.from("ai_athlete_change_requests").insert({
      owner_id:ownerId,token_id:tokenId,operation:op,target_id:targetId,
      payload,expected_updated_at:expectedUpdatedAt??null,status:"pending",
    }).select("id,operation,target_id,status,created_at").single();
    if(error)return fail("STORAGE_ERROR","operation","No se pudo enviar solicitud");
    return result({request:data,delivery:"pending_athlete_approval",
      warning:"No se ha modificado todavía el iPhone ni el historial real. El usuario debe aceptar en Acceso IA."});
  }
  async function mirroredWorkout(id:string) {
    return db.from("athlete_workout_mirror").select("id,payload,updated_at,deleted_at")
      .eq("owner_id",ownerId).eq("id",id).maybeSingle();
  }
  server.registerTool("update_workout",{
    description:"Request a precise correction to a COMPLETED workout. Title and individual recorded sets only. No changes to HealthKit, notes or GPS. Requires explicit athlete approval on iPhone.",
    inputSchema:z.strictObject({
      workoutId:uuid,expectedUpdatedAt:revision,
      title:z.string().trim().min(2).max(200).optional(),
      setChanges:z.array(setPatch).min(1).max(100).optional(),
    }).refine(x=>x.title!==undefined||(x.setChanges?.length??0)>0,
      {message:"Provide title or at least one set correction"}),
    annotations:{readOnlyHint:false,destructiveHint:true},
  },async({workoutId,expectedUpdatedAt,title,setChanges})=>{
    const {data:row,error}=await mirroredWorkout(workoutId);
    if(error)return fail("STORAGE_ERROR","workoutId","No se pudo consultar entrenamiento");
    if(!row||row.deleted_at)return fail("NOT_FOUND","workoutId","Entrenamiento inexistente o eliminado");
    if(Date.parse(row.updated_at)!==Date.parse(expectedUpdatedAt))
      return fail("CONFLICT","expectedUpdatedAt","Historial modificado; vuelve a consultar get_workout_history");
    for(const change of setChanges??[]) {
      const exercise=(row.payload?.exercises??[]).find((e:{id:string})=>e.id===change.exerciseEntryId);
      if(!exercise?.loggedSets?.some((s:{id:string})=>s.id===change.loggedSetId))
        return fail("NOT_FOUND","setChanges","No existe el ID de serie en este entrenamiento");
    }
    const unique=new Set((setChanges??[]).map(s=>s.loggedSetId));
    if(unique.size!==(setChanges??[]).length)
      return fail("VALIDATION_ERROR","setChanges","No repitas una misma serie");
    return stage("update_workout",workoutId,{
      workoutTitle:row.payload?.title??"Entrenamiento",
      ...(title?{title}:{}),setChanges:setChanges??[],
    },row.updated_at);
  });
  server.registerTool("delete_workout",{
    description:"Request deletion of a completed workout, requiring explicit athlete confirmation on device. Deletion may also affect linked Apple Health workout, exactly as native Delete Workout does.",
    inputSchema:z.strictObject({workoutId:uuid,expectedUpdatedAt:revision}),
    annotations:{readOnlyHint:false,destructiveHint:true},
  },async({workoutId,expectedUpdatedAt})=>{
    const {data:row,error}=await mirroredWorkout(workoutId);
    if(error)return fail("STORAGE_ERROR","workoutId","No se pudo consultar entrenamiento");
    if(!row||row.deleted_at)return fail("NOT_FOUND","workoutId","Entrenamiento inexistente o eliminado");
    if(Date.parse(row.updated_at)!==Date.parse(expectedUpdatedAt))
      return fail("CONFLICT","expectedUpdatedAt","El entrenamiento ya cambió; recarga su revisión");
    return stage("delete_workout",workoutId,{
      workoutTitle:row.payload?.title??"Entrenamiento",
    },row.updated_at);
  });
  server.registerTool("create_custom_exercise",{
    description:"Propose a new PRIVATE exercise to athlete's iPhone catalog, subject to native subscription limits and confirmation.",
    inputSchema:exercise,
    annotations:{readOnlyHint:false,destructiveHint:false},
  },async(args)=>stage("create_exercise",null,args));
  server.registerTool("update_custom_exercise",{
    description:"Propose edits to a private custom exercise, never the shared professionally curated exercise library.",
    inputSchema:z.strictObject({exerciseId:uuid,exercise}),
    annotations:{readOnlyHint:false,destructiveHint:true},
  },async({exerciseId,exercise:patch})=>{
    const {data,error}=await db.from("athlete_custom_exercise_mirror")
      .select("exercise_id,name").eq("owner_id",ownerId).eq("exercise_id",exerciseId).maybeSingle();
    if(error)return fail("STORAGE_ERROR","exerciseId","Error consultando catálogo");
    if(!data)return fail("NOT_FOUND","exerciseId","Ejercicio personalizado no encontrado");
    return stage("update_exercise",exerciseId,patch);
  });
  server.registerTool("delete_custom_exercise",{
    description:"Propose deletion of a private custom exercise; app confirms before deletion. Never deletes global catalog or historic workout snapshots.",
    inputSchema:z.strictObject({exerciseId:uuid}),
    annotations:{readOnlyHint:false,destructiveHint:true},
  },async({exerciseId})=>{
    const {data,error}=await db.from("athlete_custom_exercise_mirror")
      .select("exercise_id,name").eq("owner_id",ownerId).eq("exercise_id",exerciseId).maybeSingle();
    if(error)return fail("STORAGE_ERROR","exerciseId","Error consultando catálogo");
    if(!data)return fail("NOT_FOUND","exerciseId","Ejercicio personalizado no encontrado");
    return stage("delete_exercise",exerciseId,{name:data.name});
  });
}
