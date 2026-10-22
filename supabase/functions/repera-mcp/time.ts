/** Resolve a scheduled local wall-clock time to an absolute instant.
 * Caller supplies UTC offset (east-positive) to disambiguate fall DST folds.
 * Reject invalid/nonexistent spring forward local clock times and offset mismatch.
 */
export function scheduledInstant(
  scheduledDate:string, minutes:number|undefined,
  timeZone:string|undefined, offset:number|undefined,
): string|null {
  const date = new Date(scheduledDate+"T12:00:00Z");
  if(!Number.isFinite(+date)||date.toISOString().slice(0,10)!==scheduledDate)
    throw Error("INVALID_DATE: scheduledDate must be a real calendar day");
  if(minutes==null)return null;
  if(timeZone==null||offset==null)
    throw Error("TIME_ZONE_REQUIRED: scheduledTimeZone and scheduledUtcOffsetMinutes required");
  if(!Number.isInteger(offset)||offset < -840 || offset > 840)
    throw Error("INVALID_OFFSET: UTC offset minutes out of range");
  const instant = new Date(Date.parse(scheduledDate+"T00:00:00Z") + minutes*60000-offset*60000);
  let fmt:Intl.DateTimeFormat;
  try {
    fmt=new Intl.DateTimeFormat("en-GB",{timeZone,year:"numeric",month:"2-digit",
      day:"2-digit",hour:"2-digit",minute:"2-digit",hourCycle:"h23"});
  }catch { throw Error("INVALID_TIME_ZONE: unknown IANA timezone"); }
  const parts=Object.fromEntries(fmt.formatToParts(instant).map(x=>[x.type,x.value]));
  const wall=parts.year+"-"+parts.month+"-"+parts.day;
  if(wall!==scheduledDate||Number(parts.hour)*60+Number(parts.minute)!==minutes)
    throw Error("INVALID_LOCAL_TIME: UTC offset does not match zone/date or falls in DST gap");
  return instant.toISOString();
}
