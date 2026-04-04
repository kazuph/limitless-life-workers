// Cloudflare Vectorize API bindings

///|
/// VectorizeIndex - represents a Vectorize index binding
#external
pub type VectorizeIndex

///|
pub fn VectorizeIndex::as_any(self : VectorizeIndex) -> @core.Any = "%identity"

///|
/// Insert vectors into the index
/// Vectors with existing IDs will be ignored (use upsert to overwrite)
pub async fn VectorizeIndex::insert(
  self : VectorizeIndex,
  vectors : Array[VectorizeVector],
) -> VectorizeMutationResult {
  let vectors_js = @core.new_array()
  let mut i = 0
  while i < vectors.length() {
    @core.any(vectors_js)._call("push", [vectors[i].to_js()]) |> ignore
    i = i + 1
  }
  let promise : @core.Promise[VectorizeMutationResult] = self
    .as_any()
    ._call("insert", [@core.any(vectors_js)])
    .cast()
  promise.wait()
}

///|
/// Upsert vectors into the index
/// Vectors with existing IDs will be completely overwritten
pub async fn VectorizeIndex::upsert(
  self : VectorizeIndex,
  vectors : Array[VectorizeVector],
) -> VectorizeMutationResult {
  let vectors_js = @core.new_array()
  let mut i = 0
  while i < vectors.length() {
    @core.any(vectors_js)._call("push", [vectors[i].to_js()]) |> ignore
    i = i + 1
  }
  let promise : @core.Promise[VectorizeMutationResult] = self
    .as_any()
    ._call("upsert", [@core.any(vectors_js)])
    .cast()
  promise.wait()
}

///|
/// Delete vectors by their IDs
pub async fn VectorizeIndex::delete_by_ids(
  self : VectorizeIndex,
  ids : Array[String],
) -> VectorizeMutationResult {
  let ids_js = @core.new_array()
  let mut i = 0
  while i < ids.length() {
    @core.any(ids_js)._call("push", [@core.any(ids[i])]) |> ignore
    i = i + 1
  }
  let promise : @core.Promise[VectorizeMutationResult] = self
    .as_any()
    ._call("deleteByIds", [@core.any(ids_js)])
    .cast()
  promise.wait()
}

///|
/// Query the index with a vector
pub async fn VectorizeIndex::query(
  self : VectorizeIndex,
  vector : Array[Double],
  options : VectorizeQueryOptions,
) -> VectorizeMatches {
  let vector_js = @core.new_array()
  let mut i = 0
  while i < vector.length() {
    @core.any(vector_js)._call("push", [@core.any(vector[i])]) |> ignore
    i = i + 1
  }
  let promise : @core.Promise[VectorizeMatches] = self
    .as_any()
    ._call("query", [@core.any(vector_js), options.to_js()])
    .cast()
  promise.wait()
}

///|
/// Query the index with a vector (no options)
pub async fn VectorizeIndex::query_simple(
  self : VectorizeIndex,
  vector : Array[Double],
) -> VectorizeMatches {
  let vector_js = @core.new_array()
  let mut i = 0
  while i < vector.length() {
    @core.any(vector_js)._call("push", [@core.any(vector[i])]) |> ignore
    i = i + 1
  }
  let promise : @core.Promise[VectorizeMatches] = self
    .as_any()
    ._call("query", [@core.any(vector_js)])
    .cast()
  promise.wait()
}

///|
/// Get vectors by their IDs
pub async fn VectorizeIndex::get_by_ids(
  self : VectorizeIndex,
  ids : Array[String],
) -> Array[VectorizeVector] {
  let ids_js = @core.new_array()
  let mut i = 0
  while i < ids.length() {
    @core.any(ids_js)._call("push", [@core.any(ids[i])]) |> ignore
    i = i + 1
  }
  let promise : @core.Promise[@core.Any] = self
    .as_any()
    ._call("getByIds", [@core.any(ids_js)])
    .cast()
  let result = promise.wait()
  // Convert JS array to MoonBit array of VectorizeVector
  let len : Int = result["length"].cast()
  let vectors : Array[VectorizeVector] = []
  let mut j = 0
  while j < len {
    vectors.push(VectorizeVector::from_js(result[j.to_string()]))
    j = j + 1
  }
  vectors
}

///|
/// Describe the index configuration
pub async fn VectorizeIndex::describe(
  self : VectorizeIndex,
) -> VectorizeIndexInfo {
  let promise : @core.Promise[VectorizeIndexInfo] = self
    .as_any()
    ._call("describe", [])
    .cast()
  promise.wait()
}

///|
/// Vector representation for Vectorize
pub(all) struct VectorizeVector {
  id : String
  values : Array[Double]
  ns : String? // namespace - partition key for isolated segments
  metadata : @core.Any?
}

///|
/// Convert VectorizeVector to JavaScript object
pub fn VectorizeVector::to_js(self : VectorizeVector) -> @core.Any {
  let obj = @core.new_object()
  obj["id"] = @core.any(self.id)

  // Convert values array
  let values_js = @core.new_array()
  let mut i = 0
  while i < self.values.length() {
    @core.any(values_js)._call("push", [@core.any(self.values[i])]) |> ignore
    i = i + 1
  }
  obj["values"] = @core.any(values_js)
  if self.ns is Some(ns_val) {
    obj["namespace"] = @core.any(ns_val)
  }
  if self.metadata is Some(meta) {
    obj["metadata"] = meta
  }
  obj
}

///|
/// Create VectorizeVector from JavaScript object
pub fn VectorizeVector::from_js(js : @core.Any) -> VectorizeVector {
  let id : String = js["id"].cast()

  // Convert values
  let values_js = js["values"]
  let values_len : Int = values_js["length"].cast()
  let values : Array[Double] = []
  let mut i = 0
  while i < values_len {
    values.push(values_js[i.to_string()].cast())
    i = i + 1
  }

  // Handle optional namespace
  let ns_js = js["namespace"]
  let ns : String? = if @core.typeof_(ns_js) == "undefined" ||
    @core.is_null(ns_js) {
    None
  } else {
    Some(ns_js.cast())
  }

  // Handle optional metadata
  let meta_js = js["metadata"]
  let metadata = if @core.typeof_(meta_js) == "undefined" ||
    @core.is_null(meta_js) {
    None
  } else {
    Some(meta_js)
  }
  { id, values, ns, metadata }
}

///|
/// Query options for Vectorize
pub(all) struct VectorizeQueryOptions {
  topK : Int? // Max 100, or 20 if returnValues/returnMetadata is set
  returnValues : Bool?
  returnMetadata : VectorizeReturnMetadata?
  ns : String? // namespace - partition key
  filter : @core.Any? // Metadata filter
}

///|
/// Metadata return options
pub(all) enum VectorizeReturnMetadata {
  None_
  Indexed
  All
}

///|
pub fn VectorizeReturnMetadata::to_string(
  self : VectorizeReturnMetadata,
) -> String {
  match self {
    None_ => "none"
    Indexed => "indexed"
    All => "all"
  }
}

///|
/// Convert VectorizeQueryOptions to JavaScript object
pub fn VectorizeQueryOptions::to_js(self : VectorizeQueryOptions) -> @core.Any {
  let obj = @core.new_object()
  if self.topK is Some(k) {
    obj["topK"] = @core.any(k)
  }
  if self.returnValues is Some(v) {
    obj["returnValues"] = @core.any(v)
  }
  if self.returnMetadata is Some(rm) {
    obj["returnMetadata"] = @core.any(rm.to_string())
  }
  if self.ns is Some(ns_val) {
    obj["namespace"] = @core.any(ns_val)
  }
  if self.filter is Some(f) {
    obj["filter"] = f
  }
  obj
}

///|
/// Default query options
pub fn VectorizeQueryOptions::default() -> VectorizeQueryOptions {
  {
    topK: None,
    returnValues: None,
    returnMetadata: None,
    ns: None,
    filter: None,
  }
}

///|
/// Query result containing matched vectors
#external
pub type VectorizeMatches

///|
pub fn VectorizeMatches::as_any(self : VectorizeMatches) -> @core.Any = "%identity"

///|
/// Get the matched vectors
pub fn VectorizeMatches::matches(
  self : VectorizeMatches,
) -> Array[VectorizeMatch] {
  let matches_js = self.as_any()["matches"]
  let len : Int = matches_js["length"].cast()
  let matches : Array[VectorizeMatch] = []
  let mut i = 0
  while i < len {
    matches.push(matches_js[i.to_string()].cast())
    i = i + 1
  }
  matches
}

///|
/// Get the count of matches
pub fn VectorizeMatches::count(self : VectorizeMatches) -> Int {
  self.as_any()["count"].cast()
}

///|
/// A single match result
#external
pub type VectorizeMatch

///|
pub fn VectorizeMatch::as_any(self : VectorizeMatch) -> @core.Any = "%identity"

///|
/// Get the vector ID
pub fn VectorizeMatch::id(self : VectorizeMatch) -> String {
  self.as_any()["id"].cast()
}

///|
/// Get the similarity score
pub fn VectorizeMatch::score(self : VectorizeMatch) -> Double {
  self.as_any()["score"].cast()
}

///|
/// Get the vector values (if returnValues was true)
pub fn VectorizeMatch::values(self : VectorizeMatch) -> Array[Double]? {
  let values_js = self.as_any()["values"]
  if @core.typeof_(values_js) == "undefined" || @core.is_null(values_js) {
    None
  } else {
    let len : Int = values_js["length"].cast()
    let values : Array[Double] = []
    let mut i = 0
    while i < len {
      values.push(values_js[i.to_string()].cast())
      i = i + 1
    }
    Some(values)
  }
}

///|
/// Get the metadata (if returnMetadata was set)
pub fn VectorizeMatch::metadata(self : VectorizeMatch) -> @core.Any? {
  let meta_js = self.as_any()["metadata"]
  if @core.typeof_(meta_js) == "undefined" || @core.is_null(meta_js) {
    None
  } else {
    Some(meta_js)
  }
}

///|
/// Get the namespace
pub fn VectorizeMatch::ns(self : VectorizeMatch) -> String? {
  let ns_js = self.as_any()["namespace"]
  if @core.typeof_(ns_js) == "undefined" || @core.is_null(ns_js) {
    None
  } else {
    Some(ns_js.cast())
  }
}

///|
/// Result of mutation operations (insert, upsert, delete)
#external
pub type VectorizeMutationResult

///|
pub fn VectorizeMutationResult::as_any(
  self : VectorizeMutationResult,
) -> @core.Any = "%identity"

///|
/// Get the mutation ID
pub fn VectorizeMutationResult::mutation_id(
  self : VectorizeMutationResult,
) -> String {
  self.as_any()["mutationId"].cast()
}

///|
/// Get the count of affected vectors
pub fn VectorizeMutationResult::count(self : VectorizeMutationResult) -> Int {
  self.as_any()["count"].cast()
}

///|
/// Get the IDs of affected vectors
pub fn VectorizeMutationResult::ids(
  self : VectorizeMutationResult,
) -> Array[String] {
  let ids_js = self.as_any()["ids"]
  if @core.typeof_(ids_js) == "undefined" || @core.is_null(ids_js) {
    []
  } else {
    let len : Int = ids_js["length"].cast()
    let ids : Array[String] = []
    let mut i = 0
    while i < len {
      ids.push(ids_js[i.to_string()].cast())
      i = i + 1
    }
    ids
  }
}

///|
/// Index configuration information
#external
pub type VectorizeIndexInfo

///|
pub fn VectorizeIndexInfo::as_any(self : VectorizeIndexInfo) -> @core.Any = "%identity"

///|
/// Get the number of dimensions
pub fn VectorizeIndexInfo::dimensions(self : VectorizeIndexInfo) -> Int {
  self.as_any()["dimensions"].cast()
}

///|
/// Get the distance metric (e.g., "cosine", "euclidean", "dot-product")
pub fn VectorizeIndexInfo::metric(self : VectorizeIndexInfo) -> String {
  self.as_any()["metric"].cast()
}

///|
/// Get the total number of vectors in the index
pub fn VectorizeIndexInfo::vector_count(self : VectorizeIndexInfo) -> Int {
  let vc = self.as_any()["vectorCount"]
  if @core.typeof_(vc) == "undefined" || @core.is_null(vc) {
    0
  } else {
    vc.cast()
  }
}
