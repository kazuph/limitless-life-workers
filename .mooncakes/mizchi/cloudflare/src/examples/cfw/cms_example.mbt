///|
/// Simple CMS API example
/// Demonstrates D1 (articles), R2 (images), and HTMLRewriter (rendering)

///|
/// Create JSON response
extern "js" fn cms_json_response(body : String, status : Int) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "application/json" } })

///|
/// Create HTML response
extern "js" fn cms_html_response(body : String, status : Int) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "text/html; charset=utf-8" } })

///|
/// Get current timestamp
extern "js" fn get_timestamp() -> Int =
  #| () => Date.now()

///|
/// Get request method
extern "js" fn get_request_method(
  req : @cloudflare.CloudflareRequest,
) -> String =
  #| (req) => req.method

///|
/// Helper to get D1 database from env
fn get_cms_db(env : @cloudflare.CloudflareEnv) -> @cloudflare.D1Database? {
  let env_js : @core.Any = @core.identity(env)
  let db_js = env_js._get("CMS_DB")
  if @core.typeof_(db_js) == "undefined" {
    None
  } else {
    Some(@core.identity(db_js))
  }
}

///|
/// Helper to get R2 bucket from env
fn get_cms_r2(env : @cloudflare.CloudflareEnv) -> @cloudflare.R2Bucket? {
  let env_js : @core.Any = @core.identity(env)
  let r2_js = env_js._get("CMS_R2")
  if @core.typeof_(r2_js) == "undefined" {
    None
  } else {
    Some(@core.identity(r2_js))
  }
}

///|
/// Parse request body as text
extern "js" fn get_request_body(
  req : @cloudflare.CloudflareRequest,
) -> @core.Promise[String] =
  #| (req) => req.text()

///|
/// Parse JSON string
extern "js" fn parse_json(s : String) -> @core.Any =
  #| (s) => JSON.parse(s)

///|
/// Create Response from ReadableStream
extern "js" fn create_stream_response(
  stream : @streams.ReadableStream,
) -> @http.Response =
  #| (stream) => new Response(stream)

///|
/// CMS API handler
pub fn get_cms_handler() -> @cloudflare.CloudflareFetchHandler {
  let async_handler = async fn(
    req : @cloudflare.CloudflareRequest,
    env : @cloudflare.CloudflareEnv,
    _ctx : @cloudflare.CloudflareContext,
  ) -> @http.Response {
    let url_str = req.url
    let url = @url.URL::new(url_str)
    let pathname = url.pathname
    let req_method = get_request_method(req)

    // Get bindings
    let db = match get_cms_db(env) {
      Some(d) => d
      None =>
        return cms_json_response("{\"error\":\"Database not configured\"}", 500)
    }
    let r2 = match get_cms_r2(env) {
      Some(r) => r
      None =>
        return cms_json_response(
          "{\"error\":\"R2 bucket not configured\"}", 500,
        )
    }

    // Initialize database schema if needed
    if pathname == "/cms/init" {
      let _ = db.exec(
        "CREATE TABLE IF NOT EXISTS articles (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT NOT NULL, slug TEXT UNIQUE NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)",
      ) catch {
        e =>
          return cms_json_response("{\"error\":\"" + e.to_string() + "\"}", 500)
      }
      return cms_json_response(
        "{\"success\":true,\"message\":\"Schema initialized\"}", 200,
      )
    }

    // Articles CRUD
    if pathname == "/cms/articles" && req_method == "GET" {
      // List all articles
      let stmt = db.prepare(
        "SELECT id, title, slug, created_at, updated_at FROM articles ORDER BY created_at DESC",
      )
      let result = stmt.all() catch {
        e =>
          return cms_json_response("{\"error\":\"" + e.to_string() + "\"}", 500)
      }
      let rows = result.get_results()
      let articles = @core.new_array()
      let mut i = 0
      while i < rows.length() {
        let row = rows[i]
        let article = @core.new_object()
        article["id"] = row["id"]
        article["title"] = row["title"]
        article["slug"] = row["slug"]
        article["created_at"] = row["created_at"]
        article["updated_at"] = row["updated_at"]
        @core.any(articles)._call("push", [@core.any(article)]) |> ignore
        i = i + 1
      }
      let response = @core.new_object()
      response["articles"] = @core.any(articles)
      response["count"] = @core.any(rows.length())
      return cms_json_response(@js.JSON::stringify(response), 200)
    }
    if pathname == "/cms/articles" && req_method == "POST" {
      // Create article
      let body_promise : @core.Promise[String] = get_request_body(req)
      let body = body_promise.wait()
      let data = parse_json(body)
      let title : String = data["title"].cast()
      let content : String = data["content"].cast()
      let slug : String = data["slug"].cast()
      let now = get_timestamp()
      let stmt = db
        .prepare(
          "INSERT INTO articles (title, content, slug, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
        )
        .bind([
          @core.any(title),
          @core.any(content),
          @core.any(slug),
          @core.any(now),
          @core.any(now),
        ])
      let result = stmt.run() catch {
        e =>
          return cms_json_response("{\"error\":\"" + e.to_string() + "\"}", 500)
      }
      let response = @core.new_object()
      response["success"] = @core.any(result.success())
      response["slug"] = @core.any(slug)
      return cms_json_response(@js.JSON::stringify(response), 201)
    }

    // Single article operations
    if pathname.has_prefix("/cms/articles/") {
      let slug = pathname[14:].to_string() // Remove "/cms/articles/"
      if req_method == "GET" {
        // Get single article
        let stmt = db
          .prepare(
            "SELECT id, title, content, slug, created_at, updated_at FROM articles WHERE slug = ?",
          )
          .bind([@core.any(slug)])
        let row = stmt.first() catch {
          e =>
            return cms_json_response(
              "{\"error\":\"" + e.to_string() + "\"}",
              500,
            )
        }
        match row {
          Some(r) => {
            let article = @core.new_object()
            article["id"] = r["id"]
            article["title"] = r["title"]
            article["content"] = r["content"]
            article["slug"] = r["slug"]
            article["created_at"] = r["created_at"]
            article["updated_at"] = r["updated_at"]
            return cms_json_response(@js.JSON::stringify(article), 200)
          }
          None =>
            return cms_json_response("{\"error\":\"Article not found\"}", 404)
        }
      }
      if req_method == "PUT" {
        // Update article
        let body_promise : @core.Promise[String] = get_request_body(req)
        let body = body_promise.wait()
        let data = parse_json(body)
        let title : String = data["title"].cast()
        let content : String = data["content"].cast()
        let now = get_timestamp()
        let stmt = db
          .prepare(
            "UPDATE articles SET title = ?, content = ?, updated_at = ? WHERE slug = ?",
          )
          .bind([
            @core.any(title),
            @core.any(content),
            @core.any(now),
            @core.any(slug),
          ])
        let result = stmt.run() catch {
          e =>
            return cms_json_response(
              "{\"error\":\"" + e.to_string() + "\"}",
              500,
            )
        }
        let meta = result.meta()
        let changed = match meta {
          Some(m) => m.changes().unwrap_or(0)
          None => 0
        }
        if changed == 0 {
          return cms_json_response("{\"error\":\"Article not found\"}", 404)
        }
        let response = @core.new_object()
        response["success"] = @core.any(true)
        response["slug"] = @core.any(slug)
        return cms_json_response(@js.JSON::stringify(response), 200)
      }
      if req_method == "DELETE" {
        // Delete article
        let stmt = db
          .prepare("DELETE FROM articles WHERE slug = ?")
          .bind([@core.any(slug)])
        let result = stmt.run() catch {
          e =>
            return cms_json_response(
              "{\"error\":\"" + e.to_string() + "\"}",
              500,
            )
        }
        let meta = result.meta()
        let changed = match meta {
          Some(m) => m.changes().unwrap_or(0)
          None => 0
        }
        if changed == 0 {
          return cms_json_response("{\"error\":\"Article not found\"}", 404)
        }
        return cms_json_response("{\"success\":true}", 200)
      }
    }

    // Image operations with R2
    if pathname == "/cms/images" && req_method == "POST" {
      // Upload image
      let key = url.searchParams().get("key")
      match key {
        Some(k) => {
          let body_promise : @core.Promise[String] = get_request_body(req)
          let body = body_promise.wait()
          let obj = r2.put(k, @core.any(body)) catch {
            e =>
              return cms_json_response(
                "{\"error\":\"" + e.to_string() + "\"}",
                500,
              )
          }
          let response = @core.new_object()
          response["success"] = @core.any(true)
          response["key"] = @core.any(obj.key())
          response["size"] = @core.any(obj.size())
          return cms_json_response(@js.JSON::stringify(response), 201)
        }
        None =>
          return cms_json_response("{\"error\":\"Missing key parameter\"}", 400)
      }
    }
    if pathname.has_prefix("/cms/images/") && req_method == "GET" {
      // Get image
      let key = pathname[12:].to_string() // Remove "/cms/images/"
      let obj = r2.get(key) catch {
        e =>
          return cms_json_response("{\"error\":\"" + e.to_string() + "\"}", 500)
      }
      match obj {
        Some(o) => {
          let body = o.body()
          return create_stream_response(body)
        }
        None => return cms_json_response("{\"error\":\"Image not found\"}", 404)
      }
    }
    if pathname.has_prefix("/cms/images/") && req_method == "DELETE" {
      // Delete image
      let key = pathname[12:].to_string()
      r2.delete(key) catch {
        _ =>
          return cms_json_response(
            "{\"error\":\"Failed to delete image\"}", 500,
          )
      }
      return cms_json_response("{\"success\":true}", 200)
    }

    // Render article with HTMLRewriter
    if pathname.has_prefix("/cms/render/") && req_method == "GET" {
      let slug = pathname[12:].to_string()

      // Get article from D1
      let stmt = db
        .prepare("SELECT title, content FROM articles WHERE slug = ?")
        .bind([@core.any(slug)])
      let row = stmt.first() catch {
        e =>
          return cms_json_response("{\"error\":\"" + e.to_string() + "\"}", 500)
      }
      match row {
        Some(r) => {
          let title : String = r["title"].cast()
          let content : String = r["content"].cast()

          // HTML template
          let template = "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>Article</title></head><body><article><h1 class=\"title\"></h1><div class=\"content\"></div></article></body></html>"
          let input_response = cms_html_response(template, 200)

          // Use HTMLRewriter to inject content
          let rewriter = @cloudflare.HTMLRewriter::new()
            .on(
              "title",
              @cloudflare.ElementHandler::element_only(fn(el) {
                el.set_inner_content_text(title + " - CMS") |> ignore
              }),
            )
            .on(
              "h1.title",
              @cloudflare.ElementHandler::element_only(fn(el) {
                el.set_inner_content_text(title) |> ignore
              }),
            )
            .on(
              "div.content",
              @cloudflare.ElementHandler::element_only(fn(el) {
                el.set_inner_content(
                  content,
                  @cloudflare.ContentOptions::html_mode(),
                )
                |> ignore
              }),
            )
          return rewriter.transform(input_response)
        }
        None =>
          return cms_json_response("{\"error\":\"Article not found\"}", 404)
      }
    }

    // List images
    if pathname == "/cms/images" && req_method == "GET" {
      let result = r2.list() catch {
        e =>
          return cms_json_response("{\"error\":\"" + e.to_string() + "\"}", 500)
      }
      let objects = result.objects()
      let images = @core.new_array()
      let mut i = 0
      while i < objects.length() {
        let obj = objects[i]
        let img = @core.new_object()
        img["key"] = @core.any(obj.key())
        img["size"] = @core.any(obj.size())
        @core.any(images)._call("push", [@core.any(img)]) |> ignore
        i = i + 1
      }
      let response = @core.new_object()
      response["images"] = @core.any(images)
      response["count"] = @core.any(objects.length())
      return cms_json_response(@js.JSON::stringify(response), 200)
    }

    // Help/index page
    let help = "{\"endpoints\":{\"init\":\"POST /cms/init\",\"articles\":{\"list\":\"GET /cms/articles\",\"create\":\"POST /cms/articles\",\"get\":\"GET /cms/articles/:slug\",\"update\":\"PUT /cms/articles/:slug\",\"delete\":\"DELETE /cms/articles/:slug\"},\"images\":{\"list\":\"GET /cms/images\",\"upload\":\"POST /cms/images?key=...\",\"get\":\"GET /cms/images/:key\",\"delete\":\"DELETE /cms/images/:key\"},\"render\":\"GET /cms/render/:slug\"}}"
    cms_json_response(help, 200)
  }
  @js.promisify3(async_handler)
}
