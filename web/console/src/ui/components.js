import {money,shortDate} from '../core/domain.js';
export const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export const e=esc;
export const option=(rows,current,field='name')=>rows.map(x=>`<option value="${esc(x.id)}" ${current===x.id?'selected':''}>${esc(x[field])}</option>`).join('');
export const empty=(title,detail)=>`<div class="empty"><div class="empty-icon">✧</div><h3>${esc(title)}</h3><p>${esc(detail)}</p></div>`;
export const pill=(s)=>`<span class="pill pill-${/^(active|paid|confirmed|scheduled)$/.test(s)?'ok':/^(cancelled|inactive|overdue)$/.test(s)?'bad':'muted'}">${esc(({active:'Activo',paid:'Pagado',confirmed:'Confirmada',waitlist:'En espera',cancelled:'Cancelada',scheduled:'Programada',trial:'Prueba',paused:'Pausado',draft:'Borrador',pending:'Pendiente',inactive:'Inactivo'}[s]||s))}</span>`;
export const card=(title,inside,extra='')=>`<section class="panel"><div class="panel-title"><h2>${esc(title)}</h2>${extra}</div>${inside}</section>`;
export const button=(action,label,css='btn')=>`<button type="button" class="${css}" data-action="${esc(action)}">${esc(label)}</button>`;
export const table=(heads,rows)=>`<div class="table-scroll"><table><thead><tr>${heads.map(h=>`<th>${esc(h)}</th>`).join('')}</tr></thead><tbody>${rows||`<tr><td colspan="${heads.length}" class="muted">Sin registros</td></tr>`}</tbody></table></div>`;
export const moneyCell=c=>`<strong class="money">${money(c)}</strong>`;
export const dateCell=d=>esc(shortDate(d));
export const field=(label,name,type='text',value='',extras='')=>`<label class="field"><span>${esc(label)}</span><input type="${esc(type)}" name="${esc(name)}" value="${esc(value)}" ${extras}></label>`;
export const selectField=(label,name,opts)=>`<label class="field"><span>${esc(label)}</span><select name="${esc(name)}">${opts}</select></label>`;
export const metric=(label,value,detail='')=>`<div class="metric"><span>${esc(label)}</span><strong>${esc(value)}</strong><small>${esc(detail)}</small></div>`;
export function modal(title,body,submit='Guardar',kind='save'){return `<div class="modal-backdrop" id="modalBackdrop"><form class="dialog" data-form="${kind}"><div class="dialog-header"><h2>${esc(title)}</h2><button type="button" class="icon-button" data-action="close-modal" aria-label="Cerrar">✕</button></div><div class="dialog-body">${body}</div><div class="dialog-footer"><button class="btn subtle" type="button" data-action="close-modal">Cancelar</button><button class="btn primary" type="submit">${esc(submit)}</button></div></form></div>`;}