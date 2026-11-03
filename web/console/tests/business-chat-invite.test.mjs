import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {renderClientChatThread,renderBroadcastPanel} from '../src/ui/business-chat.js';
import {invitationWebUrl,invitationDeepLink,renderInvitationShareCard,renderInviteShareDialog,pendingAthleteInvite} from '../src/ui/invitation-share.js';

const chatSql=readFileSync(new URL('../../../supabase/migrations/20261101140000_business_chat_and_decline.sql',import.meta.url),'utf8');
const quotaSql=readFileSync(new URL('../../../supabase/migrations/20261101150000_business_quotas_entitlements.sql',import.meta.url),'utf8');
const pushSql=readFileSync(new URL('../../../supabase/migrations/20261101160000_business_push_outbox.sql',import.meta.url),'utf8');
const pushEdge=readFileSync(new URL('../../../supabase/functions/repera-business-push/index.ts',import.meta.url),'utf8');

test('migración chat expone hilo, envío, broadcast y decline',()=>{
 for(const name of [
  'business_conversation_messages',
  'business_list_thread',
  'business_send_message',
  'business_send_broadcast',
  'business_mark_thread_read',
  'decline_org_invitation',
 ]) assert.ok(chatSql.includes(name),name);
});

test('migración cupos y entitlements sin Stripe',()=>{
 assert.ok(quotaSql.includes('count_commercially_active_clients'));
 assert.ok(quotaSql.includes('get_my_effective_entitlements'));
 assert.ok(quotaSql.includes('store_gate_pending'));
 assert.ok(quotaSql.includes("issuance_type='manual_offline'"));
});

test('migración push outbox + Edge sin fingir delivery',()=>{
 assert.ok(pushSql.includes('device_push_tokens'));
 assert.ok(pushSql.includes('notification_outbox'));
 assert.ok(pushSql.includes('register_push_device'));
 assert.ok(pushSql.includes('claim_due_reminders'));
 assert.ok(pushEdge.includes('FCM_SERVICE_ACCOUNT_JSON'));
 assert.ok(pushEdge.includes('skipped')||pushEdge.includes('no_secrets')||pushEdge.includes('without'));
});

test('UI chat burbujas staff/atleta y broadcast scopes',()=>{
 const html=renderClientChatThread({
  messages:[
   {sender_role:'staff',body:'Hola',created_at:'2026-11-01T10:00:00Z'},
   {sender_role:'athlete',body:'Ok',created_at:'2026-11-01T10:01:00Z',batch_id:null},
  ],
  clientId:'11111111-1111-1111-1111-111111111111',
 });
 assert.match(html,/is-staff/);
 assert.match(html,/is-athlete/);
 assert.match(html,/data-connected="chat-send"/);
 const broadcast=renderBroadcastPanel({
  clients:[{id:'c1',name:'Ana',status:'active',user_id:'u1'}],
  occurrences:[{id:'o1',title:'WOD',starts_at:'2026-11-02T08:00:00Z',status:'active'}],
  groups:[{id:'g1',name:'Mañanas'}],
  manager:true,
 });
 assert.match(broadcast,/value="all"/);
 assert.match(broadcast,/value="occurrence"/);
 assert.match(broadcast,/value="group"/);
 assert.match(broadcast,/value="selected"/);
});

test('tarjeta invitación con QR, web y deep link',()=>{
 const id='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
 assert.ok(invitationWebUrl(id,'https://example.test/console').includes('invitation='+id));
 assert.equal(invitationDeepLink(id),`repera://invitation/${id}`);
 const card=renderInvitationShareCard({invitationId:id,email:'a@b.com',sent:true});
 assert.match(card,/business-invite-qr/);
 assert.match(card,/data-action="copy-invite-link"/);
 assert.match(card,/data-action="cancel-invitation"/);
 assert.match(card,/repera:\/\/invitation\//);
 const dialog=renderInviteShareDialog({invitationId:id,email:'a@b.com',sent:false,reason:'sin correo'});
 assert.equal(dialog,''); // El modal obsoleto no duplica la tarjeta persistente.
 assert.match(card,/business-invite-qr/);
 assert.match(card,/data-action="copy-invite-link"/);
 assert.match(card,/data-action="cancel-invitation"/);
 const pending=pendingAthleteInvite({
  orgId:'org-1',email:'a@b.com',
  invitations:[{id,organization_id:'org-1',email:'a@b.com',invited_role:'athlete',
   expires_at:'2099-01-01T00:00:00Z',accepted_at:null,cancelled_at:null}],
 });
 assert.equal(pending?.id,id);
});
