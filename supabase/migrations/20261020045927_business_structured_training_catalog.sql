-- Repera: the same catalog and block data model used by mobile and professional management.
create table public.business_exercise_catalog (
 catalog_key text primary key,
 name text not null,
 category text not null,
 created_at timestamptz not null default now(),
 constraint catalog_key_valid check (catalog_key='catalog:'||name and length(name) between 2 and 150)
);
alter table public.business_exercise_catalog enable row level security;
create policy business_catalog_read on public.business_exercise_catalog
 for select to authenticated using(true);
revoke all on public.business_exercise_catalog from public,anon,authenticated;
grant select on public.business_exercise_catalog to authenticated;
insert into public.business_exercise_catalog(catalog_key,name,category) values
('catalog:Press banca','Press banca','Fuerza'),
('catalog:Press banca inclinada','Press banca inclinada','Fuerza'),
('catalog:Press mancuernas','Press mancuernas','Fuerza'),
('catalog:Aperturas','Aperturas','Fuerza'),
('catalog:Fondos','Fondos','Fuerza'),
('catalog:Dominadas','Dominadas','Fuerza'),
('catalog:Jalón al pecho','Jalón al pecho','Fuerza'),
('catalog:Remo con barra','Remo con barra','Fuerza'),
('catalog:Remo mancuerna','Remo mancuerna','Fuerza'),
('catalog:Peso muerto','Peso muerto','Fuerza'),
('catalog:Peso muerto rumano','Peso muerto rumano','Fuerza'),
('catalog:Sentadilla','Sentadilla','Fuerza'),
('catalog:Sentadilla frontal','Sentadilla frontal','Fuerza'),
('catalog:Prensa','Prensa','Fuerza'),
('catalog:Zancadas','Zancadas','Fuerza'),
('catalog:Extensión de cuádriceps','Extensión de cuádriceps','Fuerza'),
('catalog:Curl femoral','Curl femoral','Fuerza'),
('catalog:Elevación de gemelos','Elevación de gemelos','Fuerza'),
('catalog:Press militar','Press militar','Fuerza'),
('catalog:Elevaciones laterales','Elevaciones laterales','Fuerza'),
('catalog:Pájaros','Pájaros','Fuerza'),
('catalog:Curl barra','Curl barra','Fuerza'),
('catalog:Curl mancuernas','Curl mancuernas','Fuerza'),
('catalog:Curl martillo','Curl martillo','Fuerza'),
('catalog:Fondos en banco','Fondos en banco','Fuerza'),
('catalog:Extensión tríceps polea','Extensión tríceps polea','Fuerza'),
('catalog:Press cerrado','Press cerrado','Fuerza'),
('catalog:Plancha','Plancha','Fuerza'),
('catalog:Crunch','Crunch','Fuerza'),
('catalog:Elevación de piernas','Elevación de piernas','Fuerza'),
('catalog:Hip thrust','Hip thrust','Fuerza'),
('catalog:Face pull','Face pull','Fuerza'),
('catalog:Remo al mentón','Remo al mentón','Fuerza'),
('catalog:Buenos días','Buenos días','Fuerza'),
('catalog:Hack squat','Hack squat','Fuerza'),
('catalog:Pullover','Pullover','Fuerza'),
('catalog:Cinta / carrera','Cinta / carrera','Fuerza'),
('catalog:Bici estática','Bici estática','Fuerza'),
('catalog:Remo máquina','Remo máquina','Fuerza'),
('catalog:Farmer walk','Farmer walk','Fuerza'),
('catalog:Press banca declinado','Press banca declinado','Fuerza'),
('catalog:Cruce de poleas','Cruce de poleas','Fuerza'),
('catalog:Remo sentado','Remo sentado','Fuerza'),
('catalog:Peso muerto sumo','Peso muerto sumo','Fuerza'),
('catalog:Sentadilla búlgara','Sentadilla búlgara','Fuerza'),
('catalog:Curl predicador','Curl predicador','Fuerza'),
('catalog:Press francés','Press francés','Fuerza'),
('catalog:Elevaciones frontales','Elevaciones frontales','Fuerza'),
('catalog:Ab wheel','Ab wheel','Fuerza'),
('catalog:Paso lateral con banda','Paso lateral con banda','Fuerza'),
('catalog:Remo invertido','Remo invertido','Fuerza'),
('catalog:Press Arnold','Press Arnold','Fuerza'),
('catalog:Arrancada','Arrancada','Halterofilia'),
('catalog:Zancadas inversas con barra','Zancadas inversas con barra','Halterofilia'),
('catalog:Arrancada de potencia','Arrancada de potencia','Halterofilia'),
('catalog:Arrancada colgante','Arrancada colgante','Halterofilia'),
('catalog:Arrancada colgante completa','Arrancada colgante completa','Halterofilia'),
('catalog:Hang power snatch','Hang power snatch','Halterofilia'),
('catalog:Arrancada muscular','Arrancada muscular','Halterofilia'),
('catalog:Arrancada desde bloques','Arrancada desde bloques','Halterofilia'),
('catalog:Arrancada con pausa','Arrancada con pausa','Halterofilia'),
('catalog:Balance de arrancada','Balance de arrancada','Halterofilia'),
('catalog:Drop snatch','Drop snatch','Halterofilia'),
('catalog:Tall snatch','Tall snatch','Halterofilia'),
('catalog:Arrancada en split','Arrancada en split','Halterofilia'),
('catalog:Tirón de arrancada','Tirón de arrancada','Halterofilia'),
('catalog:Peso muerto agarre arrancada','Peso muerto agarre arrancada','Halterofilia'),
('catalog:Cargada','Cargada','Halterofilia'),
('catalog:Cargada de potencia','Cargada de potencia','Halterofilia'),
('catalog:Cargada colgante','Cargada colgante','Halterofilia'),
('catalog:Cargada colgante completa','Cargada colgante completa','Halterofilia'),
('catalog:Hang power clean','Hang power clean','Halterofilia'),
('catalog:Cargada muscular','Cargada muscular','Halterofilia'),
('catalog:Cargada desde bloques','Cargada desde bloques','Halterofilia'),
('catalog:Cargada con pausa','Cargada con pausa','Halterofilia'),
('catalog:Tall clean','Tall clean','Halterofilia'),
('catalog:Tirón de cargada','Tirón de cargada','Halterofilia'),
('catalog:Cargada y press','Cargada y press','Halterofilia'),
('catalog:Cargada y envión','Cargada y envión','Halterofilia'),
('catalog:Push press','Push press','Halterofilia'),
('catalog:Push jerk','Push jerk','Halterofilia'),
('catalog:Split jerk','Split jerk','Halterofilia'),
('catalog:Power jerk','Power jerk','Halterofilia'),
('catalog:Balance de envión','Balance de envión','Halterofilia'),
('catalog:Strict press','Strict press','Halterofilia'),
('catalog:Press detrás de nuca','Press detrás de nuca','Halterofilia'),
('catalog:Envión detrás de nuca','Envión detrás de nuca','Halterofilia'),
('catalog:Sots press','Sots press','Halterofilia'),
('catalog:Overhead squat','Overhead squat','Halterofilia'),
('catalog:Front rack lunge','Front rack lunge','Halterofilia'),
('catalog:Sentadilla frontal con pausa','Sentadilla frontal con pausa','Halterofilia'),
('catalog:Sumo high pull','Sumo high pull','Halterofilia'),
('catalog:Dominadas estrictas','Dominadas estrictas','Gimnasia'),
('catalog:Dominadas kipping','Dominadas kipping','Gimnasia'),
('catalog:Dominadas butterfly','Dominadas butterfly','Gimnasia'),
('catalog:Dominadas supinas','Dominadas supinas','Gimnasia'),
('catalog:Chest to bar','Chest to bar','Gimnasia'),
('catalog:Dominadas en anillas','Dominadas en anillas','Gimnasia'),
('catalog:Remo en anillas','Remo en anillas','Gimnasia'),
('catalog:Archer pull-up','Archer pull-up','Gimnasia'),
('catalog:Muscle-up barra','Muscle-up barra','Gimnasia'),
('catalog:Muscle-up anillas','Muscle-up anillas','Gimnasia'),
('catalog:Muscle-up estricto barra','Muscle-up estricto barra','Gimnasia'),
('catalog:Muscle-up estricto anillas','Muscle-up estricto anillas','Gimnasia'),
('catalog:Pull-over barra','Pull-over barra','Gimnasia'),
('catalog:Toes to bar','Toes to bar','Gimnasia'),
('catalog:Toes to bar estrictos','Toes to bar estrictos','Gimnasia'),
('catalog:Knees to elbows','Knees to elbows','Gimnasia'),
('catalog:Toes to rings','Toes to rings','Gimnasia'),
('catalog:Hip to bar','Hip to bar','Gimnasia'),
('catalog:Kip swing','Kip swing','Gimnasia'),
('catalog:HSPU','HSPU','Gimnasia'),
('catalog:HSPU deficit','HSPU deficit','Gimnasia'),
('catalog:HSPU libre','HSPU libre','Gimnasia'),
('catalog:Pike push-up','Pike push-up','Gimnasia'),
('catalog:Handstand hold','Handstand hold','Gimnasia'),
('catalog:Handstand walk','Handstand walk','Gimnasia'),
('catalog:Wall walk','Wall walk','Gimnasia'),
('catalog:Press to handstand','Press to handstand','Gimnasia'),
('catalog:Fondos en anillas','Fondos en anillas','Gimnasia'),
('catalog:Fondos en paralelas','Fondos en paralelas','Gimnasia'),
('catalog:Soporte en anillas','Soporte en anillas','Gimnasia'),
('catalog:False grip hang','False grip hang','Gimnasia'),
('catalog:Skin the cat','Skin the cat','Gimnasia'),
('catalog:German hang','German hang','Gimnasia'),
('catalog:Front lever tuck','Front lever tuck','Gimnasia'),
('catalog:Back lever tuck','Back lever tuck','Gimnasia'),
('catalog:Planche tuck','Planche tuck','Gimnasia'),
('catalog:L-sit','L-sit','Gimnasia'),
('catalog:V-sit','V-sit','Gimnasia'),
('catalog:Hollow hold','Hollow hold','Gimnasia'),
('catalog:Hollow rock','Hollow rock','Gimnasia'),
('catalog:Arch hold','Arch hold','Gimnasia'),
('catalog:Candlestick','Candlestick','Gimnasia'),
('catalog:Pistol squat','Pistol squat','Gimnasia'),
('catalog:Shrimp squat','Shrimp squat','Gimnasia'),
('catalog:Cossack squat','Cossack squat','Gimnasia'),
('catalog:Air squat','Air squat','Gimnasia'),
('catalog:Jumping squat','Jumping squat','Gimnasia'),
('catalog:Jumping lunge','Jumping lunge','Gimnasia'),
('catalog:GHD sit-up','GHD sit-up','Gimnasia'),
('catalog:GHD back extension','GHD back extension','Gimnasia'),
('catalog:Sit-up','Sit-up','Gimnasia'),
('catalog:V-up','V-up','Gimnasia'),
('catalog:Rope climb','Rope climb','Gimnasia'),
('catalog:Rope climb legless','Rope climb legless','Gimnasia'),
('catalog:Pegboard','Pegboard','Gimnasia'),
('catalog:Thruster','Thruster','CrossFit'),
('catalog:Thruster mancuernas','Thruster mancuernas','CrossFit'),
('catalog:Thruster kettlebell','Thruster kettlebell','CrossFit'),
('catalog:Cluster','Cluster','CrossFit'),
('catalog:Ground to overhead','Ground to overhead','CrossFit'),
('catalog:Plate ground to overhead','Plate ground to overhead','CrossFit'),
('catalog:Burpee','Burpee','CrossFit'),
('catalog:Burpee al cajón','Burpee al cajón','CrossFit'),
('catalog:Bar facing burpee','Bar facing burpee','CrossFit'),
('catalog:Burpee pull-up','Burpee pull-up','CrossFit'),
('catalog:Salto al cajón','Salto al cajón','CrossFit'),
('catalog:Step-up al cajón','Step-up al cajón','CrossFit'),
('catalog:Box jump over','Box jump over','CrossFit'),
('catalog:Broad jump','Broad jump','CrossFit'),
('catalog:Walking lunge','Walking lunge','CrossFit'),
('catalog:Bear crawl','Bear crawl','CrossFit'),
('catalog:Swing kettlebell','Swing kettlebell','CrossFit'),
('catalog:Swing americano','Swing americano','CrossFit'),
('catalog:Snatch kettlebell','Snatch kettlebell','CrossFit'),
('catalog:Clean kettlebell','Clean kettlebell','CrossFit'),
('catalog:Turkish get-up','Turkish get-up','CrossFit'),
('catalog:Goblet squat','Goblet squat','CrossFit'),
('catalog:Devil press','Devil press','CrossFit'),
('catalog:Man maker','Man maker','CrossFit'),
('catalog:Snatch mancuerna','Snatch mancuerna','CrossFit'),
('catalog:Clean mancuerna','Clean mancuerna','CrossFit'),
('catalog:Wall ball','Wall ball','CrossFit'),
('catalog:Ball slam','Ball slam','CrossFit'),
('catalog:Medball clean','Medball clean','CrossFit'),
('catalog:Sandbag clean','Sandbag clean','CrossFit'),
('catalog:Sandbag over shoulder','Sandbag over shoulder','CrossFit'),
('catalog:Yoke carry','Yoke carry','CrossFit'),
('catalog:Dobles de comba','Dobles de comba','CrossFit'),
('catalog:Simples de comba','Simples de comba','CrossFit'),
('catalog:Triples de comba','Triples de comba','CrossFit'),
('catalog:Air bike','Air bike','CrossFit'),
('catalog:Echo bike','Echo bike','CrossFit'),
('catalog:SkiErg','SkiErg','CrossFit'),
('catalog:Shuttle run','Shuttle run','CrossFit'),
('catalog:Sled push','Sled push','CrossFit'),
('catalog:Sled pull','Sled pull','CrossFit'),
('catalog:Farmer carry','Farmer carry','CrossFit');

-- Validation runs server side: client-side validation is not an authorization boundary.
create function private.validate_professional_prescription(p jsonb)
returns boolean language plpgsql stable security invoker set search_path=''
as $$
declare
 b jsonb; e jsonb; se jsonb; rows jsonb; part jsonb;
begin
 if p is null or jsonb_typeof(p)<>'object'
    or p->'schemaVersion'<>'1'::jsonb or jsonb_typeof(p->'blocks')<>'array'
    or jsonb_array_length(p->'blocks') not between 1 and 30
    or octet_length(p::text)>100000 then return false; end if;
 for b in select value from jsonb_array_elements(p->'blocks') loop
  if jsonb_typeof(b)<>'object' or coalesce(b->>'kind','') not in ('strength','wod')
     or length(btrim(coalesce(b->>'title',''))) not between 2 and 120
     or coalesce(b->>'id','') !~* '^[0-9a-f-]{36}$' then return false; end if;
  if (b->>'kind')='wod' and coalesce(b->>'wodFormat','') not in
   ('amrap','emom','forTime','tabata','chipper','deathBy','strength',
    'afap','ladder','partner','buyInCashOut','roundsForQuality','circuit','maxEffort')
    then return false; end if;
  if b ? 'timeCapMinutes' and b->'timeCapMinutes'<>'null'::jsonb and
     (jsonb_typeof(b->'timeCapMinutes')<>'number' or
      (b->>'timeCapMinutes')::numeric not between 1 and 300) then return false; end if;
  if b ? 'rounds' and b->'rounds'<>'null'::jsonb and
     (jsonb_typeof(b->'rounds')<>'number' or
      (b->>'rounds')::numeric not between 1 and 300) then return false; end if;
  if jsonb_typeof(b->'exercises')<>'array'
     or jsonb_typeof(b->'movements')<>'array'
     or jsonb_array_length(b->'exercises')>50
     or jsonb_array_length(b->'movements')>50 then return false; end if;
  if (b->>'kind')='strength' and (jsonb_array_length(b->'exercises')=0 or jsonb_array_length(b->'movements')<>0)
    then return false; end if;
  if (b->>'kind')='wod' and (jsonb_array_length(b->'movements')=0 or jsonb_array_length(b->'exercises')<>0)
    then return false; end if;
  for e in select value from jsonb_array_elements(b->'exercises')
    union all select value from jsonb_array_elements(b->'movements') loop
   if jsonb_typeof(e)<>'object' or length(btrim(coalesce(e->>'name',''))) not between 2 and 150
      or coalesce(e->>'source','') not in ('catalog','free')
      or coalesce(e->>'id','') !~* '^[0-9a-f-]{36}$' then return false; end if;
   if e->>'source'='catalog' then
     if not exists(select 1 from public.business_exercise_catalog c
          where c.catalog_key=e->>'catalogKey' and c.name=e->>'name') then return false; end if;
   elsif e ? 'catalogKey' and e->'catalogKey'<>'null'::jsonb then return false;
   end if;
   if e ? 'reps' and e->'reps'<>'null'::jsonb and
      (jsonb_typeof(e->'reps')<>'number' or (e->>'reps')::numeric not between 1 and 9999)
      then return false; end if;
   if e ? 'plannedSets' then
    if jsonb_typeof(e->'plannedSets')<>'array' or jsonb_array_length(e->'plannedSets')>30
       then return false; end if;
    for se in select value from jsonb_array_elements(e->'plannedSets') loop
     if jsonb_typeof(se)<>'object'
       or jsonb_typeof(se->'targetReps')<>'number'
       or (se->>'targetReps')::numeric not between 1 and 9999 then return false; end if;
     if se ? 'targetRir' and se->'targetRir'<>'null'::jsonb and
        (jsonb_typeof(se->'targetRir')<>'number' or (se->>'targetRir')::numeric not between 0 and 10)
        then return false; end if;
     if se ? 'targetWeightKg' and se->'targetWeightKg'<>'null'::jsonb and
        (jsonb_typeof(se->'targetWeightKg')<>'number' or (se->>'targetWeightKg')::numeric not between 0 and 2000)
        then return false; end if;
    end loop;
   elsif (b->>'kind')='strength' then return false; end if;
  end loop;
 end loop;
 return true;
exception when others then
 return false;
end;
$$;
revoke all on function private.validate_professional_prescription(jsonb) from public,anon;
grant execute on function private.validate_professional_prescription(jsonb) to authenticated;

create function private.publish_structured_professional_session(
 p_org uuid,p_client uuid,p_day date,p_title text,p_instructions text,p_request uuid,p_prescription jsonb
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid; v_old jsonb; v_exists boolean;
begin
 if auth.uid() is null then raise exception 'NOT_AUTHORIZED' using errcode='42501'; end if;
 if not private.validate_professional_prescription(p_prescription) then
   raise exception 'INVALID_PRESCRIPTION' using errcode='22023'; end if;
 -- Original RPC performs ownership/coach check, target linkage, request fingerprint
 -- and idempotent advisory locking. No direct table INSERT grants are added.
 v_id:=private.publish_professional_session(
    p_org,p_client,p_day,p_title,p_instructions,p_request);
 select prescription into v_old from public.professional_training_sessions where id=v_id for update;
 if v_old<>'{"blocks":[]}'::jsonb and v_old<>p_prescription then
    raise exception 'REQUEST_ID_REUSED' using errcode='23505'; end if;
 if v_old='{"blocks":[]}'::jsonb then
    update public.professional_training_sessions set prescription=p_prescription, updated_at=now() where id=v_id;
 end if;
 return v_id;
end;
$$;
revoke all on function private.publish_structured_professional_session(uuid,uuid,date,text,text,uuid,jsonb) from public,anon;
grant execute on function private.publish_structured_professional_session(uuid,uuid,date,text,text,uuid,jsonb) to authenticated;

create function public.publish_structured_professional_session(
 p_org uuid,p_client uuid,p_day date,p_title text,p_instructions text,p_request uuid,p_prescription jsonb
) returns uuid language sql security invoker set search_path=''
as $$ select private.publish_structured_professional_session(p_org,p_client,p_day,p_title,p_instructions,p_request,p_prescription) $$;
revoke all on function public.publish_structured_professional_session(uuid,uuid,date,text,text,uuid,jsonb) from public,anon;
grant execute on function public.publish_structured_professional_session(uuid,uuid,date,text,text,uuid,jsonb) to authenticated;

