/** Ajustes de operación del centro: perfil, salas, programa del día, open gym. */

export function profileDefaults(profile){
 const map={
  box:{use_rooms:false,day_program_enabled:true,day_program_scope:'activity_type',open_access_enabled:true,open_access_requires_booking:true,cancel_credit_hours:12},
  gym_multi:{use_rooms:true,day_program_enabled:true,day_program_scope:'activity_type',open_access_enabled:true,open_access_requires_booking:true,cancel_credit_hours:12},
  hybrid_rooms:{use_rooms:true,day_program_enabled:true,day_program_scope:'room',open_access_enabled:true,open_access_requires_booking:true,cancel_credit_hours:12},
  pt:{use_rooms:false,day_program_enabled:false,day_program_scope:'global',open_access_enabled:false,open_access_requires_booking:true,cancel_credit_hours:12},
 };
 return map[profile]||map.gym_multi;
}

export function renderOperationSettings({org,settings,rooms=[],activityTypes=[],manager,busy,esc}){
 const s=settings||profileDefaults(org?.kind==='personal_trainer'?'pt':'gym_multi');
 const profile=s.profile||(org?.kind==='personal_trainer'?'pt':'gym_multi');
 return `<section data-settings-panel="operation" class="connected-card pt-settings-card">
  <h2>Operación y agenda</h2>
  <p>Adapta salas, programa del día y acceso libre a tu tipo de centro. Las apps del atleta respetan estos ajustes.</p>
  <form data-connected="operation-settings" class="business-onboarding-form">
   <label class="connected-field">Perfil del centro
    <select name="profile" data-op-profile>
     ${[['box','Box / CrossFit'],['gym_multi','Gimnasio multi-actividad'],['hybrid_rooms','Híbrido multi-sala'],['pt','Entrenador personal']].map(([v,l])=>
      `<option value="${v}" ${profile===v?'selected':''}>${l}</option>`).join('')}
    </select>
   </label>
   <label class="connected-check"><input type="checkbox" name="use_rooms" ${s.use_rooms?'checked':''}> Usar salas / espacios</label>
   <label class="connected-check"><input type="checkbox" name="day_program_enabled" ${s.day_program_enabled!==false?'checked':''}> Programa del día (WOD compartido)</label>
   <label class="connected-field">Ámbito del programa
    <select name="day_program_scope">
     ${[['global','Todo el centro'],['activity_type','Por tipo de actividad'],['room','Por sala']].map(([v,l])=>
      `<option value="${v}" ${(s.day_program_scope||'activity_type')===v?'selected':''}>${l}</option>`).join('')}
    </select>
   </label>
   <label class="connected-check"><input type="checkbox" name="open_access_enabled" ${s.open_access_enabled?'checked':''}> Open gym / acceso libre con aforo</label>
   <label class="connected-check"><input type="checkbox" name="open_access_requires_booking" ${s.open_access_requires_booking!==false?'checked':''}> Open gym exige reserva previa</label>
   <label class="connected-field">Horas mínimas para devolver crédito al cancelar
    <input type="number" name="cancel_credit_hours" min="0" max="168" value="${Number(s.cancel_credit_hours??12)}">
   </label>
   <label class="connected-field">Ventana de inscripción (horas antes)
    <select name="class_booking_open_hours">
     ${[['24','1 día'],['48','2 días'],['72','3 días'],['168','1 semana'],['336','2 semanas'],['720','30 días']].map(([v,l])=>
      `<option value="${v}" ${Number(org.class_booking_open_hours||168)===Number(v)?'selected':''}>${l}</option>`).join('')}
    </select>
   </label>
   ${manager?`<button class="connected-primary business-form-submit" type="submit" ${busy?'disabled':''}>Guardar operación</button>`:''}
  </form>

  ${s.use_rooms?`<div class="pt-op-block">
   <h3>Salas</h3>
   <ul class="pt-op-list">${(rooms||[]).map(r=>`<li><strong>${esc(r.name)}</strong> · aforo ${r.capacity}${r.is_active?'':' · inactiva'}</li>`).join('')||'<li class="connected-hint">Sin salas todavía.</li>'}
   </ul>
   ${manager?`<form data-connected="upsert-room" class="business-form pt-inline-form">
    <input type="hidden" name="id" value="">
    <label class="connected-field">Nombre<input name="name" required maxlength="80" placeholder="Sala 1"></label>
    <label class="connected-field">Aforo<input name="capacity" type="number" min="1" max="500" value="20" required></label>
    <label class="connected-check"><input type="checkbox" name="is_active" checked> Activa</label>
    <button class="connected-secondary" type="submit" ${busy?'disabled':''}>Añadir sala</button>
   </form>`:''}
  </div>`:''}

  <div class="pt-op-block">
   <h3>Tipos de actividad</h3>
   <ul class="pt-op-list">${(activityTypes||[]).filter(t=>t.is_active!==false).map(t=>
    `<li><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${esc(t.color||'#22834d')}"></span> ${esc(t.name)}${t.is_open_access?' · open gym':''}</li>`
   ).join('')||'<li class="connected-hint">Sin tipos.</li>'}
   </ul>
   ${manager?`<form data-connected="upsert-activity-type" class="business-form pt-inline-form">
    <input type="hidden" name="id" value="">
    <label class="connected-field">Código<input name="code" required maxlength="40" placeholder="yoga"></label>
    <label class="connected-field">Nombre<input name="name" required maxlength="80" placeholder="Yoga"></label>
    <label class="connected-field">Color<input name="color" value="#22834d" maxlength="7"></label>
    <label class="connected-check"><input type="checkbox" name="supports_day_program" checked> Programa del día</label>
    <label class="connected-check"><input type="checkbox" name="is_open_access"> Open access</label>
    <button class="connected-secondary" type="submit" ${busy?'disabled':''}>Añadir tipo</button>
   </form>`:''}
  </div>
 </section>`;
}

export function renderDayProgramPanel({manager,activityTypes=[],rooms=[],settings,esc,day}){
 if(!settings?.day_program_enabled) return '';
 const scope=settings.day_program_scope||'activity_type';
 const d=day||new Date().toISOString().slice(0,10);
 return `<section class="connected-card pt-day-program-card">
  <h2>Programa del día</h2>
  <p>Se aplica a las clases del día salvo override en una clase concreta.</p>
  ${manager?`<form data-connected="upsert-day-program" class="business-form">
   <label class="connected-field">Fecha<input type="date" name="program_date" value="${esc(d)}" required></label>
   <input type="hidden" name="scope" value="${esc(scope)}">
   ${scope==='activity_type'?`<label class="connected-field">Tipo
    <select name="activity_type_id" required>
     ${(activityTypes||[]).filter(t=>t.supports_day_program!==false&&t.is_active!==false)
       .map(t=>`<option value="${esc(t.id)}">${esc(t.name)}</option>`).join('')}
    </select></label>`:''}
   ${scope==='room'?`<label class="connected-field">Sala
    <select name="room_id" required>
     ${(rooms||[]).filter(r=>r.is_active!==false).map(r=>`<option value="${esc(r.id)}">${esc(r.name)}</option>`).join('')}
    </select></label>`:''}
   <label class="connected-field">Título<input name="title" maxlength="120" placeholder="WOD del día"></label>
   <label class="connected-field">Notas<textarea name="instructions" rows="3" maxlength="4000"></textarea></label>
   <button class="connected-primary" type="submit">Guardar programa</button>
  </form>`:'<p class="connected-hint">Solo propietarios/coaches pueden editar el programa.</p>'}
 </section>`;
}
