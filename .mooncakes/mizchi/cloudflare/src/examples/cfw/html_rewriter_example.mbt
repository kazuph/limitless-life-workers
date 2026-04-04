///|
/// Cloudflare HTMLRewriter example handler
/// This demonstrates HTMLRewriter operations for HTML transformation

///|
/// Create JSON response (local to HTMLRewriter handler)
extern "js" fn rewriter_json_response(
  body : String,
  status : Int,
) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "application/json" } })

///|
/// Simple string replace using JS
extern "js" fn js_string_replace(
  str : String,
  find : String,
  replace : String,
) -> String =
  #| (str, find, replace) => str.replaceAll(find, replace)

///|
/// Create HTML response
extern "js" fn rewriter_html_response(
  body : String,
  status : Int,
) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "text/html" } })

///|
fn handle_html_rewriter_request(
  req : @cloudflare.CloudflareRequest,
) -> @http.Response raise {
  let url_str = req.url
  let url = @url.URL::new(url_str)
  let pathname = url.pathname

  // Route handling for HTMLRewriter operations
  if pathname == "/rewrite/title" {
    // Rewrite title tag content
    let html = url.searchParams().get("html")
    let new_title = url.searchParams().get("title")
    match (html, new_title) {
      (Some(h), Some(t)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          "title",
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.set_inner_content_text(t) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html or title parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/add-class" {
    // Add a class to elements matching a selector
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let class_name = url.searchParams().get("class")
    match (html, selector, class_name) {
      (Some(h), Some(sel), Some(cls)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            let existing = el.get_attribute("class")
            let new_class = match existing {
              Some(c) => c + " " + cls
              None => cls
            }
            el.set_attribute("class", new_class) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, or class parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/remove" {
    // Remove elements matching a selector
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    match (html, selector) {
      (Some(h), Some(sel)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.remove() |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html or selector parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/replace" {
    // Replace element content
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let content = url.searchParams().get("content")
    match (html, selector, content) {
      (Some(h), Some(sel), Some(c)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.set_inner_content_text(c) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, or content parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/append" {
    // Append content to elements
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let content = url.searchParams().get("content")
    match (html, selector, content) {
      (Some(h), Some(sel), Some(c)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.append(c, @cloudflare.ContentOptions::html_mode()) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, or content parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/prepend" {
    // Prepend content to elements
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let content = url.searchParams().get("content")
    match (html, selector, content) {
      (Some(h), Some(sel), Some(c)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.prepend(c, @cloudflare.ContentOptions::html_mode()) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, or content parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/set-attribute" {
    // Set an attribute on elements
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let attr = url.searchParams().get("attr")
    let value = url.searchParams().get("value")
    match (html, selector, attr, value) {
      (Some(h), Some(sel), Some(a), Some(v)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.set_attribute(a, v) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, attr, or value parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/remove-attribute" {
    // Remove an attribute from elements
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let attr = url.searchParams().get("attr")
    match (html, selector, attr) {
      (Some(h), Some(sel), Some(a)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.remove_attribute(a) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, or attr parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/wrap" {
    // Wrap elements with before/after content
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let before = url.searchParams().get("before")
    let after = url.searchParams().get("after")
    match (html, selector, before, after) {
      (Some(h), Some(sel), Some(b), Some(a)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) {
            el.before(b, @cloudflare.ContentOptions::html_mode()) |> ignore
            el.after(a, @cloudflare.ContentOptions::html_mode()) |> ignore
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, before, or after parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/change-tag" {
    // Change the tag name of elements
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let new_tag = url.searchParams().get("tag")
    match (html, selector, new_tag) {
      (Some(h), Some(sel), Some(t)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::element_only(fn(el) { el.set_tag_name(t) }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, or tag parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/text" {
    // Rewrite text content
    let html = url.searchParams().get("html")
    let selector = url.searchParams().get("selector")
    let find = url.searchParams().get("find")
    let replace_with = url.searchParams().get("replace")
    match (html, selector, find, replace_with) {
      (Some(h), Some(sel), Some(f), Some(r)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on(
          sel,
          @cloudflare.ElementHandler::text_only(fn(text) {
            let content = text.text()
            if content.contains(f) {
              // Simple string replace using JS
              let replaced = js_string_replace(content, f, r)
              text.replace_text(replaced) |> ignore
            }
          }),
        )
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html, selector, find, or replace parameter\"}", 400,
        )
    }
  } else if pathname == "/rewrite/document-end" {
    // Append content at document end
    let html = url.searchParams().get("html")
    let content = url.searchParams().get("content")
    match (html, content) {
      (Some(h), Some(c)) => {
        let input_response = rewriter_html_response(h, 200)
        let rewriter = @cloudflare.HTMLRewriter::new().on_document({
          doctype: None,
          comments: None,
          text: None,
          end: Some(fn(doc_end) {
            doc_end.append(c, @cloudflare.ContentOptions::html_mode()) |> ignore
          }),
        })
        rewriter.transform(input_response)
      }
      _ =>
        rewriter_json_response(
          "{\"error\":\"Missing html or content parameter\"}", 400,
        )
    }
  } else {
    // Help/index page
    let help = "{\"endpoints\":[\"/rewrite/title?html=...&title=...\",\"/rewrite/add-class?html=...&selector=...&class=...\",\"/rewrite/remove?html=...&selector=...\",\"/rewrite/replace?html=...&selector=...&content=...\",\"/rewrite/append?html=...&selector=...&content=...\",\"/rewrite/prepend?html=...&selector=...&content=...\",\"/rewrite/set-attribute?html=...&selector=...&attr=...&value=...\",\"/rewrite/remove-attribute?html=...&selector=...&attr=...\",\"/rewrite/wrap?html=...&selector=...&before=...&after=...\",\"/rewrite/change-tag?html=...&selector=...&tag=...\",\"/rewrite/text?html=...&selector=...&find=...&replace=...\",\"/rewrite/document-end?html=...&content=...\"]}"
    rewriter_json_response(help, 200)
  }
}

///|
/// HTMLRewriter handler that provides various transformation operations
pub fn get_html_rewriter_handler() -> @cloudflare.CloudflareFetchHandler {
  fn(
    req : @cloudflare.CloudflareRequest,
    _env : @cloudflare.CloudflareEnv,
    _ctx : @cloudflare.CloudflareContext,
  ) -> @core.Promise[@http.Response] {
    let response = handle_html_rewriter_request(req) catch {
      _ => rewriter_json_response("{\"error\":\"Invalid URL\"}", 400)
    }
    @core.Promise::resolve(response)
  }
}
