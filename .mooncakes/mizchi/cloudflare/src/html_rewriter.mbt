// Cloudflare HTMLRewriter API bindings

///|
/// HTMLRewriter - enables HTML parsing and transformation
#external
pub type HTMLRewriter

///|
pub fn HTMLRewriter::as_any(self : HTMLRewriter) -> @core.Any = "%identity"

///|
/// Create a new HTMLRewriter instance
extern "js" fn create_html_rewriter() -> HTMLRewriter =
  #| () => new HTMLRewriter()

///|
/// Create a new HTMLRewriter
pub fn HTMLRewriter::new() -> HTMLRewriter {
  create_html_rewriter()
}

///|
/// Attach an element handler to matching CSS selector
pub fn HTMLRewriter::on(
  self : HTMLRewriter,
  selector : String,
  handler : ElementHandler,
) -> HTMLRewriter {
  self.as_any()._call("on", [@core.any(selector), handler.to_js()]).cast()
}

///|
/// Attach a document handler
pub fn HTMLRewriter::on_document(
  self : HTMLRewriter,
  handler : DocumentHandler,
) -> HTMLRewriter {
  self.as_any()._call("onDocument", [handler.to_js()]).cast()
}

///|
/// Transform a Response
pub fn HTMLRewriter::transform(
  self : HTMLRewriter,
  response : @http.Response,
) -> @http.Response {
  self.as_any()._call("transform", [@core.any(response)]).cast()
}

///|
/// Element handler callbacks
pub(all) struct ElementHandler {
  element : ((Element) -> Unit)?
  comments : ((HTMLComment) -> Unit)?
  text : ((TextChunk) -> Unit)?
}

///|
/// Convert ElementHandler to JavaScript object
pub fn ElementHandler::to_js(self : ElementHandler) -> @core.Any {
  let obj = @core.new_object()
  if self.element is Some(f) {
    obj["element"] = @core.any(f)
  }
  if self.comments is Some(f) {
    obj["comments"] = @core.any(f)
  }
  if self.text is Some(f) {
    obj["text"] = @core.any(f)
  }
  obj
}

///|
/// Create an element-only handler
pub fn ElementHandler::element_only(f : (Element) -> Unit) -> ElementHandler {
  { element: Some(f), comments: None, text: None }
}

///|
/// Create a text-only handler
pub fn ElementHandler::text_only(f : (TextChunk) -> Unit) -> ElementHandler {
  { element: None, comments: None, text: Some(f) }
}

///|
/// Create a comments-only handler
pub fn ElementHandler::comments_only(
  f : (HTMLComment) -> Unit,
) -> ElementHandler {
  { element: None, comments: Some(f), text: None }
}

///|
/// Document handler callbacks
pub(all) struct DocumentHandler {
  doctype : ((Doctype) -> Unit)?
  comments : ((HTMLComment) -> Unit)?
  text : ((TextChunk) -> Unit)?
  end : ((DocumentEnd) -> Unit)?
}

///|
/// Convert DocumentHandler to JavaScript object
pub fn DocumentHandler::to_js(self : DocumentHandler) -> @core.Any {
  let obj = @core.new_object()
  if self.doctype is Some(f) {
    obj["doctype"] = @core.any(f)
  }
  if self.comments is Some(f) {
    obj["comments"] = @core.any(f)
  }
  if self.text is Some(f) {
    obj["text"] = @core.any(f)
  }
  if self.end is Some(f) {
    obj["end"] = @core.any(f)
  }
  obj
}

///|
/// Content options for HTML insertion
pub(all) struct ContentOptions {
  html : Bool // If true, content is treated as raw HTML
}

///|
/// Convert ContentOptions to JavaScript object
pub fn ContentOptions::to_js(self : ContentOptions) -> @core.Any {
  let obj = @core.new_object()
  obj["html"] = @core.any(self.html)
  obj
}

///|
/// Default content options (text mode)
pub fn ContentOptions::text() -> ContentOptions {
  { html: false }
}

///|
/// HTML content options
pub fn ContentOptions::html_mode() -> ContentOptions {
  { html: true }
}

// ============================================
// Element
// ============================================

///|
/// Element - represents an HTML element
#external
pub type Element

///|
pub fn Element::as_any(self : Element) -> @core.Any = "%identity"

///|
/// Get the tag name
pub fn Element::tag_name(self : Element) -> String {
  self.as_any()["tagName"].cast()
}

///|
/// Set the tag name
pub fn Element::set_tag_name(self : Element, name : String) -> Unit {
  self.as_any()["tagName"] = @core.any(name)
}

///|
/// Check if element was removed
pub fn Element::removed(self : Element) -> Bool {
  self.as_any()["removed"].cast()
}

///|
/// Get the namespace URI
pub fn Element::namespace_uri(self : Element) -> String {
  self.as_any()["namespaceURI"].cast()
}

///|
/// Get an attribute value
pub fn Element::get_attribute(self : Element, name : String) -> String? {
  let result = self.as_any()._call("getAttribute", [@core.any(name)])
  if @core.is_null(result) || @core.typeof_(result) == "undefined" {
    None
  } else {
    Some(result.cast())
  }
}

///|
/// Check if element has an attribute
pub fn Element::has_attribute(self : Element, name : String) -> Bool {
  self.as_any()._call("hasAttribute", [@core.any(name)]).cast()
}

///|
/// Set an attribute
pub fn Element::set_attribute(
  self : Element,
  name : String,
  value : String,
) -> Element {
  self
  .as_any()
  ._call("setAttribute", [@core.any(name), @core.any(value)])
  .cast()
}

///|
/// Remove an attribute
pub fn Element::remove_attribute(self : Element, name : String) -> Element {
  self.as_any()._call("removeAttribute", [@core.any(name)]).cast()
}

///|
/// Insert content before the element
pub fn Element::before(
  self : Element,
  content : String,
  options : ContentOptions,
) -> Element {
  self.as_any()._call("before", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content before the element (text mode)
pub fn Element::before_text(self : Element, content : String) -> Element {
  self.as_any()._call("before", [@core.any(content)]).cast()
}

///|
/// Insert content after the element
pub fn Element::after(
  self : Element,
  content : String,
  options : ContentOptions,
) -> Element {
  self.as_any()._call("after", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content after the element (text mode)
pub fn Element::after_text(self : Element, content : String) -> Element {
  self.as_any()._call("after", [@core.any(content)]).cast()
}

///|
/// Prepend content to the element
pub fn Element::prepend(
  self : Element,
  content : String,
  options : ContentOptions,
) -> Element {
  self.as_any()._call("prepend", [@core.any(content), options.to_js()]).cast()
}

///|
/// Prepend content to the element (text mode)
pub fn Element::prepend_text(self : Element, content : String) -> Element {
  self.as_any()._call("prepend", [@core.any(content)]).cast()
}

///|
/// Append content to the element
pub fn Element::append(
  self : Element,
  content : String,
  options : ContentOptions,
) -> Element {
  self.as_any()._call("append", [@core.any(content), options.to_js()]).cast()
}

///|
/// Append content to the element (text mode)
pub fn Element::append_text(self : Element, content : String) -> Element {
  self.as_any()._call("append", [@core.any(content)]).cast()
}

///|
/// Replace the element with content
pub fn Element::replace(
  self : Element,
  content : String,
  options : ContentOptions,
) -> Element {
  self.as_any()._call("replace", [@core.any(content), options.to_js()]).cast()
}

///|
/// Replace the element with content (text mode)
pub fn Element::replace_text(self : Element, content : String) -> Element {
  self.as_any()._call("replace", [@core.any(content)]).cast()
}

///|
/// Set the inner content of the element
pub fn Element::set_inner_content(
  self : Element,
  content : String,
  options : ContentOptions,
) -> Element {
  self
  .as_any()
  ._call("setInnerContent", [@core.any(content), options.to_js()])
  .cast()
}

///|
/// Set the inner content of the element (text mode)
pub fn Element::set_inner_content_text(
  self : Element,
  content : String,
) -> Element {
  self.as_any()._call("setInnerContent", [@core.any(content)]).cast()
}

///|
/// Remove the element and its content
pub fn Element::remove(self : Element) -> Element {
  self.as_any()._call("remove", []).cast()
}

///|
/// Remove the element but keep its content
pub fn Element::remove_and_keep_content(self : Element) -> Element {
  self.as_any()._call("removeAndKeepContent", []).cast()
}

///|
/// Register a handler for the end tag
pub fn Element::on_end_tag(self : Element, handler : (EndTag) -> Unit) -> Unit {
  self.as_any()._call("onEndTag", [@core.any(handler)]) |> ignore
}

// ============================================
// TextChunk
// ============================================

///|
/// TextChunk - represents a text node chunk
#external
pub type TextChunk

///|
pub fn TextChunk::as_any(self : TextChunk) -> @core.Any = "%identity"

///|
/// Get the text content
pub fn TextChunk::text(self : TextChunk) -> String {
  self.as_any()["text"].cast()
}

///|
/// Check if this is the last chunk in the text node
pub fn TextChunk::last_in_text_node(self : TextChunk) -> Bool {
  self.as_any()["lastInTextNode"].cast()
}

///|
/// Check if text was removed
pub fn TextChunk::removed(self : TextChunk) -> Bool {
  self.as_any()["removed"].cast()
}

///|
/// Insert content before the text
pub fn TextChunk::before(
  self : TextChunk,
  content : String,
  options : ContentOptions,
) -> TextChunk {
  self.as_any()._call("before", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content before the text (text mode)
pub fn TextChunk::before_text(self : TextChunk, content : String) -> TextChunk {
  self.as_any()._call("before", [@core.any(content)]).cast()
}

///|
/// Insert content after the text
pub fn TextChunk::after(
  self : TextChunk,
  content : String,
  options : ContentOptions,
) -> TextChunk {
  self.as_any()._call("after", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content after the text (text mode)
pub fn TextChunk::after_text(self : TextChunk, content : String) -> TextChunk {
  self.as_any()._call("after", [@core.any(content)]).cast()
}

///|
/// Replace the text with content
pub fn TextChunk::replace(
  self : TextChunk,
  content : String,
  options : ContentOptions,
) -> TextChunk {
  self.as_any()._call("replace", [@core.any(content), options.to_js()]).cast()
}

///|
/// Replace the text with content (text mode)
pub fn TextChunk::replace_text(self : TextChunk, content : String) -> TextChunk {
  self.as_any()._call("replace", [@core.any(content)]).cast()
}

///|
/// Remove the text
pub fn TextChunk::remove(self : TextChunk) -> TextChunk {
  self.as_any()._call("remove", []).cast()
}

// ============================================
// HTMLComment
// ============================================

///|
/// HTMLComment - represents an HTML comment
#external
pub type HTMLComment

///|
pub fn HTMLComment::as_any(self : HTMLComment) -> @core.Any = "%identity"

///|
/// Get the comment text
pub fn HTMLComment::text(self : HTMLComment) -> String {
  self.as_any()["text"].cast()
}

///|
/// Set the comment text
pub fn HTMLComment::set_text(self : HTMLComment, text : String) -> Unit {
  self.as_any()["text"] = @core.any(text)
}

///|
/// Check if comment was removed
pub fn HTMLComment::removed(self : HTMLComment) -> Bool {
  self.as_any()["removed"].cast()
}

///|
/// Insert content before the comment
pub fn HTMLComment::before(
  self : HTMLComment,
  content : String,
  options : ContentOptions,
) -> HTMLComment {
  self.as_any()._call("before", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content before the comment (text mode)
pub fn HTMLComment::before_text(
  self : HTMLComment,
  content : String,
) -> HTMLComment {
  self.as_any()._call("before", [@core.any(content)]).cast()
}

///|
/// Insert content after the comment
pub fn HTMLComment::after(
  self : HTMLComment,
  content : String,
  options : ContentOptions,
) -> HTMLComment {
  self.as_any()._call("after", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content after the comment (text mode)
pub fn HTMLComment::after_text(
  self : HTMLComment,
  content : String,
) -> HTMLComment {
  self.as_any()._call("after", [@core.any(content)]).cast()
}

///|
/// Replace the comment with content
pub fn HTMLComment::replace(
  self : HTMLComment,
  content : String,
  options : ContentOptions,
) -> HTMLComment {
  self.as_any()._call("replace", [@core.any(content), options.to_js()]).cast()
}

///|
/// Replace the comment with content (text mode)
pub fn HTMLComment::replace_text(
  self : HTMLComment,
  content : String,
) -> HTMLComment {
  self.as_any()._call("replace", [@core.any(content)]).cast()
}

///|
/// Remove the comment
pub fn HTMLComment::remove(self : HTMLComment) -> HTMLComment {
  self.as_any()._call("remove", []).cast()
}

// ============================================
// Doctype
// ============================================

///|
/// Doctype - represents the DOCTYPE declaration
#external
pub type Doctype

///|
pub fn Doctype::as_any(self : Doctype) -> @core.Any = "%identity"

///|
/// Get the doctype name (e.g., "html")
pub fn Doctype::name(self : Doctype) -> String? {
  let result = self.as_any()["name"]
  if @core.is_null(result) || @core.typeof_(result) == "undefined" {
    None
  } else {
    Some(result.cast())
  }
}

///|
/// Get the public ID
pub fn Doctype::public_id(self : Doctype) -> String? {
  let result = self.as_any()["publicId"]
  if @core.is_null(result) || @core.typeof_(result) == "undefined" {
    None
  } else {
    Some(result.cast())
  }
}

///|
/// Get the system ID
pub fn Doctype::system_id(self : Doctype) -> String? {
  let result = self.as_any()["systemId"]
  if @core.is_null(result) || @core.typeof_(result) == "undefined" {
    None
  } else {
    Some(result.cast())
  }
}

// ============================================
// DocumentEnd
// ============================================

///|
/// DocumentEnd - represents the end of the document
#external
pub type DocumentEnd

///|
pub fn DocumentEnd::as_any(self : DocumentEnd) -> @core.Any = "%identity"

///|
/// Append content at the end of the document
pub fn DocumentEnd::append(
  self : DocumentEnd,
  content : String,
  options : ContentOptions,
) -> DocumentEnd {
  self.as_any()._call("append", [@core.any(content), options.to_js()]).cast()
}

///|
/// Append content at the end of the document (text mode)
pub fn DocumentEnd::append_text(
  self : DocumentEnd,
  content : String,
) -> DocumentEnd {
  self.as_any()._call("append", [@core.any(content)]).cast()
}

// ============================================
// EndTag
// ============================================

///|
/// EndTag - represents an element's end tag
#external
pub type EndTag

///|
pub fn EndTag::as_any(self : EndTag) -> @core.Any = "%identity"

///|
/// Get the tag name
pub fn EndTag::name(self : EndTag) -> String {
  self.as_any()["name"].cast()
}

///|
/// Set the tag name
pub fn EndTag::set_name(self : EndTag, name : String) -> Unit {
  self.as_any()["name"] = @core.any(name)
}

///|
/// Insert content before the end tag
pub fn EndTag::before(
  self : EndTag,
  content : String,
  options : ContentOptions,
) -> EndTag {
  self.as_any()._call("before", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content before the end tag (text mode)
pub fn EndTag::before_text(self : EndTag, content : String) -> EndTag {
  self.as_any()._call("before", [@core.any(content)]).cast()
}

///|
/// Insert content after the end tag
pub fn EndTag::after(
  self : EndTag,
  content : String,
  options : ContentOptions,
) -> EndTag {
  self.as_any()._call("after", [@core.any(content), options.to_js()]).cast()
}

///|
/// Insert content after the end tag (text mode)
pub fn EndTag::after_text(self : EndTag, content : String) -> EndTag {
  self.as_any()._call("after", [@core.any(content)]).cast()
}

///|
/// Remove the end tag
pub fn EndTag::remove(self : EndTag) -> EndTag {
  self.as_any()._call("remove", []).cast()
}
