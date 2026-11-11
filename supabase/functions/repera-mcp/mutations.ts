import { z } from "npm:zod@4.3.6";
import type { McpServer } from "npm:@modelcontextprotocol/server@2.0.0";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.58.0";
import { workout } from "./schema.ts";
import { scheduledInstant } from "./time.ts";

// All writes are reversible when possible and guard the AI-authored rows only.
// The iPhone remains authoritative for already applied workouts.
function output(data: unknown) {
  return { content:[{type:"text" as const,text:JSON.stringify(data)}],
    structuredContent: {result:data} };
}
function failure(code:string, field:string, message:string) {
  const error={code,field,message};
  return {isError:true,content:[{type:"text" as const,text:JSON.stringify({error})}],
    structuredContent:{error}};
}
const id=z.string().uuid(), rev=z.number().int().min(1).max(9999);
const phase=z.strictObject({
  title:z.string().trim().min(2).max(100),
  weeks:z.number().int().min(1).max(52),
  focus:z.string().trim().min(3).max(400),
  targetSessionsPerWeek:z.number().int().min(1).max(7),
  progressionRule:z.string().trim().min(3).max(400),
});
export function registerMutationTools(
  server:McpServer, db:SupabaseClient, ownerId:string,
  canWrite=true, canDelete=false,
) {
  if (canWrite) {
  server.registerTool("update_ai_training_plan", {
    description:"Edit an AI proposal (pending or already imported). Optimistic revision. Already-imported plans return to pending so the phone/watch replaces the local routine with the same id on next sync; does not rewrite completed workout history.",
    inputSchema:z.strictObject({
      planId:id,expectedRevision:rev,
      ...workout.shape,
    }),
    annotations:{readOnlyHint:false,destructiveHint:true,openWorldHint:false},
  },async({planId,expectedRevision,...candidate})=>{
    const {title,scheduledDate,scheduledTimeMinutes,scheduledTimeZone,scheduledUtcOffsetMinutes,blocks}=candidate;
    const valid=workout.safeParse(candidate);
    if(!valid.success) return failure("VALIDATION_ERROR","blocks",valid.error.issues.map(i=>i.path.join(".")+": "+i.message).join("; "));
    const day=new Date(scheduledDate+"T12:00:00Z");
    if(!Number.isFinite(day.valueOf())||day.toISOString().slice(0,10)!==scheduledDate)
      return failure("INVALID_DATE","scheduledDate","Fecha inválida");
    let instant:string|null;
    try {
      instant=scheduledInstant(scheduledDate,scheduledTimeMinutes,scheduledTimeZone,scheduledUtcOffsetMinutes);
    }catch(e){
      return failure("INVALID_LOCAL_TIME","scheduledTimeZone",String(e));
    }
    const {data:current,error:lookupError}=await db.from("ai_training_plans")
      .select("id,status,revision")
      .eq("id",planId).eq("owner_id",ownerId).maybeSingle();
    if(lookupError)return failure("STORAGE_ERROR","planId","No se pudo leer la propuesta");
    if(!current)return failure("NOT_FOUND","planId","Propuesta no encontrada");
    if(current.revision!==expectedRevision)
      return failure("CONFLICT","expectedRevision","Revisión antigua; recarga antes de editar");
    if(!["pending","applied"].includes(current.status))
      return failure("CONFLICT","planId","Solo se editan propuestas pendientes o ya importadas");
    // Re-queue applied plans as pending so the native inbox replaces the local routine (same UUID).
    const {data,error}=await db.from("ai_training_plans").update({
      title,scheduled_date:scheduledDate,scheduled_time_minutes:scheduledTimeMinutes??null,
      scheduled_time_zone:scheduledTimeZone??null,
      scheduled_utc_offset_minutes:scheduledUtcOffsetMinutes??null,
      scheduled_at:instant,
      payload:{schemaVersion:1,blocks},revision:expectedRevision+1,
      status:"pending",
      applied_at:null,
    }).eq("id",planId).eq("owner_id",ownerId).eq("revision",expectedRevision)
      .in("status",["pending","applied"])
      .select("id,title,scheduled_date,status,revision").maybeSingle();
    if(error)return failure("STORAGE_ERROR","planId","No se pudo editar la propuesta");
    if(!data)return failure("CONFLICT","expectedRevision","Propuesta archivada o modificada; recarga antes de editar");
    return output({
      proposal:data,
      requeued:current.status==="applied",
      notice:current.status==="applied"
        ?"Plan ya importado: vuelve a pending; la app sustituirá la rutina local con el mismo id al sincronizar."
        :"Propuesta pendiente actualizada.",
    });
  });
  }
  if (canDelete) {
  server.registerTool("archive_ai_training_plan", {
    description:"Soft-delete a pending or already-imported (applied) AI plan. The phone removes the local routine with the same id on sync. Cannot archive if a completed/registered workout already references that plan. Reversible with restore_ai_training_plan while no registered workout exists.",
    inputSchema:z.strictObject({planId:id,expectedRevision:rev}),
    annotations:{readOnlyHint:false,destructiveHint:true,openWorldHint:false},
  },async({planId,expectedRevision})=>{
    const {data:current,error:lookupError}=await db.from("ai_training_plans")
      .select("id,status,revision,applied_at")
      .eq("id",planId).eq("owner_id",ownerId).maybeSingle();
    if(lookupError)return failure("STORAGE_ERROR","planId","No se pudo leer la propuesta");
    if(!current)return failure("NOT_FOUND","planId","Propuesta no encontrada");
    if(current.revision!==expectedRevision)
      return failure("CONFLICT","expectedRevision","Revisión antigua; recarga antes de archivar");
    if(!["pending","applied"].includes(current.status))
      return failure("CONFLICT","planId","La propuesta ya está archivada");
    // Bloquear si el plan ya se registró como entrenamiento terminado (espejo).
    if(current.status==="applied"){
      const {data:registered,error:regError}=await db.from("athlete_workout_mirror")
        .select("id")
        .eq("owner_id",ownerId)
        .is("deleted_at",null)
        .not("finished_at","is",null)
        .contains("payload",{routineId:planId})
        .limit(1);
      if(regError)return failure("STORAGE_ERROR","planId","No se pudo comprobar entrenamientos registrados");
      if((registered?.length??0)>0)
        return failure("CONFLICT","planId","No se puede eliminar: hay un entrenamiento ya registrado a partir de este plan");
    }
    const {data,error}=await db.from("ai_training_plans").update({
      status:"dismissed",revision:expectedRevision+1,
    }).eq("id",planId).eq("owner_id",ownerId).eq("revision",expectedRevision)
      .in("status",["pending","applied"])
      .select("id,status,revision,applied_at").maybeSingle();
    if(error)return failure("STORAGE_ERROR","planId","No se pudo archivar");
    if(!data)return failure("CONFLICT","planId","Solo pueden archivarse propuestas pendientes o importadas con la revisión actual");
    return output({
      proposal:data,
      removedLocalRoutine:current.status==="applied",
      undo_tool:"restore_ai_training_plan",
      notice:current.status==="applied"
        ?"Plan importado archivado; la app borrará la rutina local (mismo id) al sincronizar si no hay registro completado."
        :"Propuesta pendiente archivada.",
    });
  });
  }
  if (canWrite) {
  server.registerTool("restore_ai_training_plan", {
    description:"Undo a previous archive. Re-publishes as pending so the phone imports or restores the routine. Does not recreate completed workout history.",
    inputSchema:z.strictObject({planId:id,expectedRevision:rev}),
    annotations:{readOnlyHint:false,destructiveHint:false,openWorldHint:false},
  },async({planId,expectedRevision})=>{
    const {data,error}=await db.from("ai_training_plans").update({
      status:"pending",revision:expectedRevision+1,applied_at:null,
    }).eq("id",planId).eq("owner_id",ownerId).eq("status","dismissed")
      .eq("revision",expectedRevision).select("id,status,revision").maybeSingle();
    if(error)return failure("STORAGE_ERROR","planId","No se pudo recuperar la propuesta");
    return data?output({proposal:data,warning:"Al regresar a pendiente, el iPhone la importará al sincronizar si la fecha está libre"}):
      failure("CONFLICT","planId","La propuesta no está archivada o la revisión cambió");
  });
  server.registerTool("update_training_program", {
    description:"Update the name/goal/phases of an existing active or proposed multiweek program; never changes sessions already queued or completed. Optimistic revision.",
    inputSchema:z.strictObject({programId:id,expectedRevision:rev,
      title:z.string().trim().min(2).max(120),primaryGoal:z.string().trim().min(2).max(500),
      phases:z.array(phase).min(1).max(12)}),
    annotations:{readOnlyHint:false,destructiveHint:true,openWorldHint:false},
  },async({programId,expectedRevision,title,primaryGoal,phases})=>{
    const {data:old,error:lookup}=await db.from("athlete_training_programs").select("duration_weeks,status")
      .eq("id",programId).eq("owner_id",ownerId).maybeSingle();
    if(lookup||!old)return failure("NOT_FOUND","programId","Programa no encontrado");
    if(["cancelled","completed"].includes(old.status))return failure("CONFLICT","programId","Programa cerrado");
    if(phases.reduce((s,p)=>s+p.weeks,0)!==old.duration_weeks)
      return failure("VALIDATION_ERROR","phases","La suma de las fases debe igualar durationWeeks");
    const {data,error}=await db.from("athlete_training_programs").update({
      title,primary_goal:primaryGoal,phases,revision:expectedRevision+1,updated_at:new Date().toISOString(),
    }).eq("id",programId).eq("owner_id",ownerId).eq("revision",expectedRevision)
      .select("id,title,revision,status,phases").maybeSingle();
    if(error)return failure("STORAGE_ERROR","programId","No se pudo guardar la revisión");
    return data?output({program:data,note:"Sesiones existentes intactas"}):
      failure("CONFLICT","expectedRevision","Revisión antigua; vuelve a leer el programa");
  });
  }
  if (canDelete) {
  server.registerTool("archive_training_program", {
    description:"Cancel/archive a program without deleting its audit history or its already applied workout sessions. Reversible only if it was proposed or paused.",
    inputSchema:z.strictObject({programId:id,expectedRevision:rev}),
    annotations:{readOnlyHint:false,destructiveHint:true,openWorldHint:false},
  },async({programId,expectedRevision})=>{
    const {data,error}=await db.from("athlete_training_programs").update({
      status:"cancelled",revision:expectedRevision+1,updated_at:new Date().toISOString(),
    }).eq("id",programId).eq("owner_id",ownerId).eq("revision",expectedRevision)
      .in("status",["proposed","paused","active"]).select("id,status,revision").maybeSingle();
    if(error)return failure("STORAGE_ERROR","programId","No se pudo archivar el programa");
    return data?output({program:data,undo_tool:"restore_training_program"}):
      failure("CONFLICT","programId","Programa ya cerrado o revisión antigua");
  });
  }
  if (canWrite) {
  server.registerTool("restore_training_program", {
    description:"Restore a cancelled program to proposed. Queued sessions and athlete workouts are not re-created or overwritten.",
    inputSchema:z.strictObject({programId:id,expectedRevision:rev}),
    annotations:{readOnlyHint:false,destructiveHint:false,openWorldHint:false},
  },async({programId,expectedRevision})=>{
    const {data,error}=await db.from("athlete_training_programs").update({
      status:"proposed",revision:expectedRevision+1,updated_at:new Date().toISOString(),
    }).eq("id",programId).eq("owner_id",ownerId).eq("revision",expectedRevision)
      .eq("status","cancelled").select("id,status,revision").maybeSingle();
    if(error)return failure("STORAGE_ERROR","programId","No se pudo recuperar");
    return data?output({program:data}):failure("CONFLICT","programId","Solo se restaura un programa cancelado con revisión actual");
  });
  }
}
