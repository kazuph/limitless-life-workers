///| FFI bindings for remark-html compatibility testing

///| This file is JS-target only

///|
/// Call remark with remark-html to convert markdown to HTML
pub extern "js" fn remark_html(input : String) -> String =
  #| (input) => {
  #|   const { remark } = require('remark');
  #|   const remarkGfm = require('remark-gfm').default;
  #|   const remarkHtml = require('remark-html').default;
  #|   const result = remark().use(remarkGfm).use(remarkHtml).processSync(input);
  #|   return String(result);
  #| }
