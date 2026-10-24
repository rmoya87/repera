import { isMCPIdentity, validDirectoryURL, resourceMetadata, challenge, mcpResource, connectionCatalogEntry } from '../../supabase/functions/_shared/ai-oauth.ts';
const id='11111111-1111-4111-8111-111111111111';
const assert=(condition:unknown)=>{if(!condition)throw new Error('Assertion failed');};
Deno.test('Only isolated complete delegated identity is admissible',()=>{
 const identity={role:'repera_mcp',sub:id,client_id:id,session_id:id};
 assert(isMCPIdentity(identity));
 for(const key of ['sub','client_id','session_id'])assert(!isMCPIdentity({...identity,[key]:undefined}));
 assert(!isMCPIdentity({...identity,role:'authenticated'}));
 assert(!isMCPIdentity({...identity,sub:'invalid'}));
});
Deno.test('Directory links cannot exfiltrate through a lookalike host or embedded credentials',()=>{
 assert(validDirectoryURL('chatgpt','https://chatgpt.com/apps/repera'));
 assert(validDirectoryURL('claude','https://claude.ai/directory/repera'));
 for(const url of ['https://chatgpt.com.evil.test/apps/repera','https://evil.test/','http://chatgpt.com/apps/repera','https://user:password@chatgpt.com/apps/repera','https://chatgpt.com:8443/apps/repera','https://chatgpt.com/','javascript:alert(1)'])assert(validDirectoryURL('chatgpt',url)===null);
 assert(validDirectoryURL('grok','https://chatgpt.com/apps/repera')===null);
});
Deno.test('MCP discovers the project Auth server without a token',()=>{
 const metadata=resourceMetadata();
 assert(metadata.resource===mcpResource);
 assert(metadata.authorization_servers[0]==='https://uvzgujlrqohreoucirms.supabase.co/auth/v1');
 assert(challenge().includes('/.well-known/oauth-protected-resource'));
});
Deno.test('Claude setup is available only for an enabled registered client; no unrelated fields are published',()=>{
 const provider={id:'claude',name:'Claude',enabled:true,client_id:id,directory_url:null,client_secret:'do-not-publish'};
 const entry=connectionCatalogEntry(provider);
 assert(entry.setup?.clientID===id && entry.setup.kind==='claude_prompt');
 assert(entry.directoryURL===null);
 assert(!JSON.stringify(entry).includes('do-not-publish'));
 for(const patch of [{enabled:false},{client_id:null},{client_id:'not-a-client'},{id:'chatgpt'},{id:'unknown'}]) {
   assert(connectionCatalogEntry({...provider,...patch}).setup===null);
 }
});
