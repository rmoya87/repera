import {clientAgenda} from './operations.js';

// Stable snake_case wire contract intended to be consumed by native Swift and Kotlin clients.
export function mobileAgendaResponse(state,orgId,clientId,from,to,cursor=null){
 const events=clientAgenda(state,orgId,clientId,from,to).map(ev=>({
  id:ev.id,kind:ev.kind,date:ev.date,title:ev.title,source:ev.source,
  assignment_id:ev.assignmentId??null,booking_id:ev.bookingId??null,
  exercise_text:ev.exerciseText??null,deep_link:ev.deepLink
 }));
 return {schema_version:1,org_id:orgId,client_id:clientId,events,cursor};
}
