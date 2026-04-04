///|
/// Cloudflare R2 Storage example handler
/// This demonstrates R2 operations for object storage

///|
/// Create JSON response (local to R2 handler)
extern "js" fn r2_json_response(body : String, status : Int) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "application/json" } })

///|
/// Helper to get R2 bucket from env
fn get_r2(env : @cloudflare.CloudflareEnv) -> @cloudflare.R2Bucket? {
  let env_js : @core.Any = @core.identity(env)
  let r2_js = env_js._get("TEST_R2")
  if @core.typeof_(r2_js) == "undefined" {
    None
  } else {
    Some(@core.identity(r2_js))
  }
}

///|
/// R2 handler that provides various storage operations
pub fn get_r2_handler() -> @cloudflare.CloudflareFetchHandler {
  let async_handler = async fn(
    req : @cloudflare.CloudflareRequest,
    env : @cloudflare.CloudflareEnv,
    _ctx : @cloudflare.CloudflareContext,
  ) -> @http.Response {
    let url_str = req.url
    let url = @url.URL::new(url_str)
    let pathname = url.pathname

    // Get R2 bucket
    let bucket = match get_r2(env) {
      Some(b) => b
      None =>
        return r2_json_response("{\"error\":\"R2 bucket not configured\"}", 500)
    }

    // Route handling for R2 operations
    if pathname == "/r2/put" {
      // Put an object
      let key = url.searchParams().get("key")
      let value = url.searchParams().get("value")
      match (key, value) {
        (Some(k), Some(v)) => {
          let obj = bucket.put(k, @core.any(v)) catch {
            e =>
              return r2_json_response(
                "{\"error\":\"Failed to put object: " + e.to_string() + "\"}",
                500,
              )
          }
          let response = @core.new_object()
          response["success"] = @core.any(true)
          response["key"] = @core.any(obj.key())
          response["size"] = @core.any(obj.size())
          response["etag"] = @core.any(obj.etag())
          r2_json_response(@js.JSON::stringify(response), 200)
        }
        _ =>
          r2_json_response(
            "{\"error\":\"Missing key or value parameter\"}", 400,
          )
      }
    } else if pathname == "/r2/get" {
      // Get an object
      let key = url.searchParams().get("key")
      match key {
        Some(k) => {
          let obj = bucket.get(k) catch {
            _ =>
              return r2_json_response(
                "{\"error\":\"Failed to get object\"}", 500,
              )
          }
          match obj {
            Some(o) => {
              let text = o.text() catch {
                _ =>
                  return r2_json_response(
                    "{\"error\":\"Failed to read object body\"}", 500,
                  )
              }
              let response = @core.new_object()
              response["key"] = @core.any(o.key())
              response["value"] = @core.any(text)
              response["size"] = @core.any(o.size())
              response["etag"] = @core.any(o.etag())
              r2_json_response(@js.JSON::stringify(response), 200)
            }
            None => r2_json_response("{\"error\":\"Object not found\"}", 404)
          }
        }
        None => r2_json_response("{\"error\":\"Missing key parameter\"}", 400)
      }
    } else if pathname == "/r2/head" {
      // Get object metadata
      let key = url.searchParams().get("key")
      match key {
        Some(k) => {
          let obj = bucket.head(k) catch {
            _ =>
              return r2_json_response(
                "{\"error\":\"Failed to get object metadata\"}", 500,
              )
          }
          match obj {
            Some(o) => {
              let response = @core.new_object()
              response["key"] = @core.any(o.key())
              response["size"] = @core.any(o.size())
              response["etag"] = @core.any(o.etag())
              response["version"] = @core.any(o.version())
              r2_json_response(@js.JSON::stringify(response), 200)
            }
            None => r2_json_response("{\"error\":\"Object not found\"}", 404)
          }
        }
        None => r2_json_response("{\"error\":\"Missing key parameter\"}", 400)
      }
    } else if pathname == "/r2/delete" {
      // Delete an object
      let key = url.searchParams().get("key")
      match key {
        Some(k) => {
          bucket.delete(k) catch {
            _ =>
              return r2_json_response(
                "{\"error\":\"Failed to delete object\"}", 500,
              )
          }
          r2_json_response("{\"success\":true}", 200)
        }
        None => r2_json_response("{\"error\":\"Missing key parameter\"}", 400)
      }
    } else if pathname == "/r2/list" {
      // List objects
      let prefix = url.searchParams().get("prefix")
      let result = match prefix {
        Some(p) =>
          bucket.list(prefix=p) catch {
            _ =>
              return r2_json_response(
                "{\"error\":\"Failed to list objects\"}", 500,
              )
          }
        None =>
          bucket.list() catch {
            _ =>
              return r2_json_response(
                "{\"error\":\"Failed to list objects\"}", 500,
              )
          }
      }
      let objects = result.objects()
      let keys = @core.new_array()
      let mut i = 0
      while i < objects.length() {
        let obj = objects[i]
        let obj_info = @core.new_object()
        obj_info["key"] = @core.any(obj.key())
        obj_info["size"] = @core.any(obj.size())
        @core.any(keys)._call("push", [@core.any(obj_info)]) |> ignore
        i = i + 1
      }
      let response = @core.new_object()
      response["objects"] = @core.any(keys)
      response["count"] = @core.any(objects.length())
      response["truncated"] = @core.any(result.truncated())
      r2_json_response(@js.JSON::stringify(response), 200)
    } else {
      // Help/index page
      let help = "{\"endpoints\":[\"/r2/put?key=x&value=y\",\"/r2/get?key=x\",\"/r2/head?key=x\",\"/r2/delete?key=x\",\"/r2/list\",\"/r2/list?prefix=x\"]}"
      r2_json_response(help, 200)
    }
  }
  promisify3(async_handler)
}
