CREATE OR REPLACE FUNCTION private.validate_professional_prescription(p jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare
 b jsonb; e jsonb; se jsonb;
begin
 if p is null or jsonb_typeof(p) is distinct from 'object'
    or p->'schemaVersion'<>'1'::jsonb or jsonb_typeof(p->'blocks') is distinct from 'array'
    or jsonb_array_length(p->'blocks') not between 1 and 30
    or octet_length(p::text)>100000 then return false; end if;
 for b in select value from jsonb_array_elements(p->'blocks') loop
  if jsonb_typeof(b) is distinct from 'object' or coalesce(b->>'kind','') not in ('strength','wod')
     or length(btrim(coalesce(b->>'title',''))) not between 2 and 120
     or coalesce(b->>'id','') !~* '^[0-9a-f-]{36}$' then return false; end if;
  if (b->>'kind')='wod' and coalesce(b->>'wodFormat','') not in
   ('amrap','emom','forTime','tabata','chipper','deathBy','strength',
    'afap','ladder','partner','buyInCashOut','roundsForQuality','circuit','maxEffort')
    then return false; end if;
  if b ? 'timeCapMinutes' and b->'timeCapMinutes'<>'null'::jsonb and
     (jsonb_typeof(b->'timeCapMinutes') is distinct from 'number' or
      ((b->>'timeCapMinutes')::numeric not between 1 and 300 or (b->>'timeCapMinutes')::numeric <> trunc((b->>'timeCapMinutes')::numeric))) then return false; end if;
  if b ? 'rounds' and b->'rounds'<>'null'::jsonb and
     (jsonb_typeof(b->'rounds') is distinct from 'number' or
      ((b->>'rounds')::numeric not between 1 and 300 or (b->>'rounds')::numeric <> trunc((b->>'rounds')::numeric))) then return false; end if;
  if jsonb_typeof(b->'exercises') is distinct from 'array'
     or jsonb_typeof(b->'movements') is distinct from 'array'
     or jsonb_array_length(b->'exercises')>50
     or jsonb_array_length(b->'movements')>50 then return false; end if;
  if (b->>'kind')='strength' and (jsonb_array_length(b->'exercises')=0 or jsonb_array_length(b->'movements')<>0)
    then return false; end if;
  if (b->>'kind')='wod' and (jsonb_array_length(b->'movements')=0 or jsonb_array_length(b->'exercises')<>0)
    then return false; end if;
  for e in select value from jsonb_array_elements(b->'exercises')
    union all select value from jsonb_array_elements(b->'movements') loop
   if jsonb_typeof(e) is distinct from 'object' or length(btrim(coalesce(e->>'name',''))) not between 2 and 150
      or coalesce(e->>'source','') not in ('catalog','free')
      or coalesce(e->>'id','') !~* '^[0-9a-f-]{36}$' then return false; end if;
   if e->>'source'='catalog' then
     if not exists(select 1 from public.business_exercise_catalog c
          where c.catalog_key=e->>'catalogKey' and c.name=e->>'name') then return false; end if;
   elsif e ? 'catalogKey' and e->'catalogKey'<>'null'::jsonb then return false;
   end if;
   if e ? 'reps' and e->'reps'<>'null'::jsonb and
      (jsonb_typeof(e->'reps') is distinct from 'number' or ((e->>'reps')::numeric not between 1 and 9999 or (e->>'reps')::numeric <> trunc((e->>'reps')::numeric)))
      then return false; end if;
   if e ? 'plannedSets' then
    if jsonb_typeof(e->'plannedSets') is distinct from 'array' or jsonb_array_length(e->'plannedSets') not between 1 and 30
       then return false; end if;
    for se in select value from jsonb_array_elements(e->'plannedSets') loop
     if jsonb_typeof(se) is distinct from 'object'
       or jsonb_typeof(se->'targetReps') is distinct from 'number'
       or ((se->>'targetReps')::numeric not between 1 and 9999 or (se->>'targetReps')::numeric <> trunc((se->>'targetReps')::numeric)) then return false; end if;
     if se ? 'targetRir' and se->'targetRir'<>'null'::jsonb and
        (jsonb_typeof(se->'targetRir') is distinct from 'number' or (se->>'targetRir')::numeric not between 0 and 10)
        then return false; end if;
     if se ? 'targetWeightKg' and se->'targetWeightKg'<>'null'::jsonb and
        (jsonb_typeof(se->'targetWeightKg') is distinct from 'number' or (se->>'targetWeightKg')::numeric not between 0 and 2000)
        then return false; end if;
    end loop;
   elsif (b->>'kind')='strength' then return false; end if;
  end loop;
 end loop;
 return true;
exception when others then
 return false;
end;
$function$

