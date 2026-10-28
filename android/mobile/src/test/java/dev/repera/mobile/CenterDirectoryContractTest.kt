package dev.repera.mobile
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONObject
import org.junit.Test
import org.junit.Assert.*
class CenterDirectoryContractTest {
 @Test fun directoryRequestAndLeaveUseExactAppleRpcWithAuthenticatedScope() {
  val seen=mutableListOf<Pair<String,JSONObject>>()
  val http=OkHttpClient.Builder().addInterceptor {chain ->
   val request=chain.request();assertEquals("Bearer synthetic-only",request.header("Authorization"))
   val buffer=okio.Buffer();request.body!!.writeTo(buffer)
   seen.add(request.url.encodedPath.substringAfterLast('/') to JSONObject(buffer.readUtf8()))
   val body=if(request.url.encodedPath.endsWith("search_discoverable_organizations"))
    """[{"id":"org","name":"Centro sintético","kind":"gym","tagline":"Pruebas"}]""" else "[]"
   Response.Builder().request(request).protocol(Protocol.HTTP_1_1).code(200).message("OK")
    .body(body.toResponseBody("application/json".toMediaType())).build()
  }.build()
  val session=SupabaseIdentity.Session("user","synthetic-only","synthetic-refresh",3600,0)
  val store=BusinessCenterStore(http)
  val org=store.searchDirectory(session,"Box 'Madrid'").single()
  assertEquals("Centro sintético",org.name)
  store.requestLink(session,org,"appointment","Nota sintética")
  store.leave(session,org)
  assertEquals(listOf("search_discoverable_organizations","request_org_athlete_link","leave_org_as_athlete"),seen.map {it.first})
  assertEquals("Box 'Madrid'",seen[0].second.getString("p_query"))
  assertEquals("org",seen[1].second.getString("p_org"));assertEquals("appointment",seen[1].second.getString("p_pass_kind"))
  assertEquals("Nota sintética",seen[1].second.getString("p_note"));assertEquals(setOf("p_org"),seen[2].second.keys().asSequence().toSet())
 }
 @Test fun unsupportedPassKindNeverMakesRequest() {
  var called=false
  val store=BusinessCenterStore(OkHttpClient.Builder().addInterceptor {called=true;error("must not call")}.build())
  var rejected=false
  try {store.requestLink(SupabaseIdentity.Session("u","t","r",3600,0),BusinessCenterStore.Organization("o","O","gym",null,null,null),"invented",null)}
  catch (_:IllegalArgumentException) {rejected=true}
  assertTrue(rejected);assertFalse(called)
 }
}
