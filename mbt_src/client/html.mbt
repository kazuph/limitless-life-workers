///|
/// HTML Builder utilities for Luna UI components
/// Provides type-safe HTML element creation and manipulation

///|
/// Create a div element with class and optional content
pub fn div(class_name : String, children : Array[@dom.Element]) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("div")
  el.setClassName(class_name)
  for child in children {
    el.append(child.as_node())
  }
  el
}

///|
/// Create a span element
pub fn span(class_name : String, text : String) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("span")
  el.setClassName(class_name)
  let text_node = doc.create_text_node(text)
  el.append(text_node.as_node())
  el
}

///|
/// Create a p element
pub fn p(class_name : String, text : String) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("p")
  el.setClassName(class_name)
  let text_node = doc.create_text_node(text)
  el.append(text_node.as_node())
  el
}

///|
/// Create a heading element
pub fn h1(class_name : String, text : String) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("h1")
  el.setClassName(class_name)
  let text_node = doc.create_text_node(text)
  el.append(text_node.as_node())
  el
}

///|
/// Create h2 element
pub fn h2(class_name : String, text : String) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("h2")
  el.setClassName(class_name)
  let text_node = doc.create_text_node(text)
  el.append(text_node.as_node())
  el
}

///|
/// Create a button element
pub fn button(
  class_name : String,
  text : String,
  on_click : (@core.Any) -> Unit
) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("button")
  el.setClassName(class_name)
  let text_node = doc.create_text_node(text)
  el.append(text_node.as_node())
  el.as_event_target().add_event_listener("click", on_click)
  el
}

///|
/// Create an anchor element
pub fn a(
  class_name : String,
  href : String,
  text : String
) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("a")
  el.setClassName(class_name)
  el.setAttribute("href", href)
  let text_node = doc.create_text_node(text)
  el.append(text_node.as_node())
  el
}

///|
/// Create an image element
pub fn img(
  class_name : String,
  src : String,
  alt : String
) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("img")
  el.setClassName(class_name)
  el.setAttribute("src", src)
  el.setAttribute("alt", alt)
  el.setAttribute("loading", "lazy")
  el
}

///|
/// Create an unordered list
pub fn ul(class_name : String, items : Array[@dom.Element]) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("ul")
  el.setClassName(class_name)
  for item in items {
    el.append(item.as_node())
  }
  el
}

///|
/// Create a list item
pub fn li(class_name : String, children : Array[@dom.Element]) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("li")
  el.setClassName(class_name)
  for child in children {
    el.append(child.as_node())
  }
  el
}

///|
/// Create a section element
pub fn section(class_name : String, children : Array[@dom.Element]) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("section")
  el.setClassName(class_name)
  for child in children {
    el.append(child.as_node())
  }
  el
}

///|
/// Create a header element
pub fn header(class_name : String, children : Array[@dom.Element]) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("header")
  el.setClassName(class_name)
  for child in children {
    el.append(child.as_node())
  }
  el
}

///|
/// Set innerHTML safely
pub fn set_html(el : @dom.Element, html : String) -> Unit {
  el.setInnerHTML(html)
}

///|
/// Set text content
pub fn set_text(el : @dom.Element, text : String) -> Unit {
  let doc = @dom.document()
  // Clear existing children
  el.setInnerHTML("")
  let text_node = doc.create_text_node(text)
  el.append(text_node.as_node())
}

///|
/// Add event listener
pub fn on(
  el : @dom.Element,
  event_type : String,
  handler : (@core.Any) -> Unit
) -> Unit {
  el.as_event_target().add_event_listener(event_type, handler)
}

///|
/// Remove element from DOM
pub fn remove(el : @dom.Element) -> Unit {
  el.remove()
}

///|
/// Query selector
pub fn query(selector : String) -> @dom.Element? {
  @dom.document().query_selector(selector)
}

///|
/// Query selector all
pub fn query_all(selector : String) -> Array[@dom.Element] {
  @dom.document().query_selector_all(selector)
}

///|
/// Get element by ID
pub fn get_by_id(id : String) -> @dom.Element? {
  @dom.document().get_element_by_id(id)
}

///|
/// Create an aside element
pub fn aside(class_name : String, children : Array[@dom.Element]) -> @dom.Element {
  let doc = @dom.document()
  let el = doc.create_element("aside")
  el.setClassName(class_name)
  for child in children {
    el.append(child.as_node())
  }
  el
}
