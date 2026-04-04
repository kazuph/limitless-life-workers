// Cloudflare Workflows API bindings

///|
/// Workflow - represents a Workflow binding
#external
pub type Workflow

///|
pub fn Workflow::as_any(self : Workflow) -> @core.Any = "%identity"

///|
/// Create a new workflow instance
pub async fn Workflow::create(
  self : Workflow,
  options : WorkflowInstanceCreateOptions,
) -> WorkflowInstance {
  let promise : @core.Promise[WorkflowInstance] = self
    .as_any()
    ._call("create", [options.to_js()])
    .cast()
  promise.wait()
}

///|
/// Create a new workflow instance with just an ID
pub async fn Workflow::create_with_id(
  self : Workflow,
  id : String,
) -> WorkflowInstance {
  let opts = @core.new_object()
  opts["id"] = @core.any(id)
  let promise : @core.Promise[WorkflowInstance] = self
    .as_any()
    ._call("create", [opts])
    .cast()
  promise.wait()
}

///|
/// Create a new workflow instance with default options
pub async fn Workflow::create_default(self : Workflow) -> WorkflowInstance {
  let promise : @core.Promise[WorkflowInstance] = self
    .as_any()
    ._call("create", [])
    .cast()
  promise.wait()
}

///|
/// Create multiple workflow instances (up to 100)
pub async fn Workflow::create_batch(
  self : Workflow,
  batch : Array[WorkflowInstanceCreateOptions],
) -> Array[WorkflowInstance] {
  let batch_js = @core.new_array()
  let mut i = 0
  while i < batch.length() {
    @core.any(batch_js)._call("push", [batch[i].to_js()]) |> ignore
    i = i + 1
  }
  let promise : @core.Promise[@core.Any] = self
    .as_any()
    ._call("createBatch", [@core.any(batch_js)])
    .cast()
  let result = promise.wait()
  let len : Int = result["length"].cast()
  let instances : Array[WorkflowInstance] = []
  let mut j = 0
  while j < len {
    instances.push(result[j.to_string()].cast())
    j = j + 1
  }
  instances
}

///|
/// Get an existing workflow instance by ID
pub async fn Workflow::get(self : Workflow, id : String) -> WorkflowInstance {
  let promise : @core.Promise[WorkflowInstance] = self
    .as_any()
    ._call("get", [@core.any(id)])
    .cast()
  promise.wait()
}

///|
/// Options for creating a workflow instance
pub(all) struct WorkflowInstanceCreateOptions {
  id : String? // Unique identifier (up to 100 chars)
  params : @core.Any? // Event payload
}

///|
/// Convert WorkflowInstanceCreateOptions to JavaScript object
pub fn WorkflowInstanceCreateOptions::to_js(
  self : WorkflowInstanceCreateOptions,
) -> @core.Any {
  let obj = @core.new_object()
  if self.id is Some(id_val) {
    obj["id"] = @core.any(id_val)
  }
  if self.params is Some(p) {
    obj["params"] = p
  }
  obj
}

///|
/// Create options with just an ID
pub fn WorkflowInstanceCreateOptions::with_id(
  id : String,
) -> WorkflowInstanceCreateOptions {
  { id: Some(id), params: None }
}

///|
/// Create options with ID and params
pub fn WorkflowInstanceCreateOptions::with_id_and_params(
  id : String,
  params : @core.Any,
) -> WorkflowInstanceCreateOptions {
  { id: Some(id), params: Some(params) }
}

///|
/// Create options with just params (auto-generated ID)
pub fn WorkflowInstanceCreateOptions::with_params(
  params : @core.Any,
) -> WorkflowInstanceCreateOptions {
  { id: None, params: Some(params) }
}

///|
/// WorkflowInstance - represents a running workflow instance
#external
pub type WorkflowInstance

///|
pub fn WorkflowInstance::as_any(self : WorkflowInstance) -> @core.Any = "%identity"

///|
/// Get the instance ID
pub fn WorkflowInstance::id(self : WorkflowInstance) -> String {
  self.as_any()["id"].cast()
}

///|
/// Get the current status of the instance
pub async fn WorkflowInstance::status(
  self : WorkflowInstance,
) -> InstanceStatus {
  let promise : @core.Promise[InstanceStatus] = self
    .as_any()
    ._call("status", [])
    .cast()
  promise.wait()
}

///|
/// Pause the workflow instance
pub async fn WorkflowInstance::pause(self : WorkflowInstance) -> Unit {
  let promise : @core.Promise[Unit] = self.as_any()._call("pause", []).cast()
  promise.wait()
}

///|
/// Resume a paused workflow instance
pub async fn WorkflowInstance::resume_(self : WorkflowInstance) -> Unit {
  let promise : @core.Promise[Unit] = self.as_any()._call("resume", []).cast()
  promise.wait()
}

///|
/// Terminate the workflow instance
pub async fn WorkflowInstance::terminate(self : WorkflowInstance) -> Unit {
  let promise : @core.Promise[Unit] = self
    .as_any()
    ._call("terminate", [])
    .cast()
  promise.wait()
}

///|
/// Restart the workflow instance
pub async fn WorkflowInstance::restart(self : WorkflowInstance) -> Unit {
  let promise : @core.Promise[Unit] = self.as_any()._call("restart", []).cast()
  promise.wait()
}

///|
/// Send an event to the workflow instance
pub async fn WorkflowInstance::send_event(
  self : WorkflowInstance,
  event_type : String,
  payload : @core.Any,
) -> Unit {
  let opts = @core.new_object()
  opts["type"] = @core.any(event_type)
  opts["payload"] = payload
  let promise : @core.Promise[Unit] = self
    .as_any()
    ._call("sendEvent", [opts])
    .cast()
  promise.wait()
}

///|
/// Send an event without payload
pub async fn WorkflowInstance::send_event_simple(
  self : WorkflowInstance,
  event_type : String,
) -> Unit {
  let opts = @core.new_object()
  opts["type"] = @core.any(event_type)
  let promise : @core.Promise[Unit] = self
    .as_any()
    ._call("sendEvent", [opts])
    .cast()
  promise.wait()
}

///|
/// InstanceStatus - status information for a workflow instance
#external
pub type InstanceStatus

///|
pub fn InstanceStatus::as_any(self : InstanceStatus) -> @core.Any = "%identity"

///|
/// Get the status string
pub fn InstanceStatus::status(self : InstanceStatus) -> String {
  self.as_any()["status"].cast()
}

///|
/// Check if instance is queued
pub fn InstanceStatus::is_queued(self : InstanceStatus) -> Bool {
  self.status() == "queued"
}

///|
/// Check if instance is running
pub fn InstanceStatus::is_running(self : InstanceStatus) -> Bool {
  self.status() == "running"
}

///|
/// Check if instance is paused
pub fn InstanceStatus::is_paused(self : InstanceStatus) -> Bool {
  self.status() == "paused"
}

///|
/// Check if instance has errored
pub fn InstanceStatus::is_errored(self : InstanceStatus) -> Bool {
  self.status() == "errored"
}

///|
/// Check if instance is terminated
pub fn InstanceStatus::is_terminated(self : InstanceStatus) -> Bool {
  self.status() == "terminated"
}

///|
/// Check if instance is complete
pub fn InstanceStatus::is_complete(self : InstanceStatus) -> Bool {
  self.status() == "complete"
}

///|
/// Check if instance is waiting (sleeping or waiting for event)
pub fn InstanceStatus::is_waiting(self : InstanceStatus) -> Bool {
  self.status() == "waiting"
}

///|
/// Check if instance is waiting for pause
pub fn InstanceStatus::is_waiting_for_pause(self : InstanceStatus) -> Bool {
  self.status() == "waitingForPause"
}

///|
/// Get the error information if any
pub fn InstanceStatus::error(self : InstanceStatus) -> WorkflowError? {
  let err = self.as_any()["error"]
  if @core.is_null(err) || @core.typeof_(err) == "undefined" {
    None
  } else {
    Some(err.cast())
  }
}

///|
/// Get the output if complete
pub fn InstanceStatus::output(self : InstanceStatus) -> @core.Any? {
  let out = self.as_any()["output"]
  if @core.is_null(out) || @core.typeof_(out) == "undefined" {
    None
  } else {
    Some(out)
  }
}

///|
/// WorkflowError - error information from a workflow
#external
pub type WorkflowError

///|
pub fn WorkflowError::as_any(self : WorkflowError) -> @core.Any = "%identity"

///|
/// Get the error name
pub fn WorkflowError::name(self : WorkflowError) -> String {
  self.as_any()["name"].cast()
}

///|
/// Get the error message
pub fn WorkflowError::message(self : WorkflowError) -> String {
  self.as_any()["message"].cast()
}

// ============================================
// WorkflowStep - for use inside workflow run()
// ============================================

///|
/// WorkflowStep - provides step operations within a workflow
#external
pub type WorkflowStep

///|
pub fn WorkflowStep::as_any(self : WorkflowStep) -> @core.Any = "%identity"

///|
/// Execute a durable step with automatic retries
pub async fn WorkflowStep::do_(
  self : WorkflowStep,
  name : String,
  callback : async () -> @core.Any,
) -> @core.Any {
  let promise : @core.Promise[@core.Any] = self
    .as_any()
    ._call("do", [@core.any(name), @core.any(callback)])
    .cast()
  promise.wait()
}

///|
/// Execute a durable step with configuration
pub async fn WorkflowStep::do_with_config(
  self : WorkflowStep,
  name : String,
  config : WorkflowStepConfig,
  callback : async () -> @core.Any,
) -> @core.Any {
  let promise : @core.Promise[@core.Any] = self
    .as_any()
    ._call("do", [@core.any(name), config.to_js(), @core.any(callback)])
    .cast()
  promise.wait()
}

///|
/// Sleep for a specified duration
pub async fn WorkflowStep::sleep(
  self : WorkflowStep,
  name : String,
  duration : String,
) -> Unit {
  let promise : @core.Promise[Unit] = self
    .as_any()
    ._call("sleep", [@core.any(name), @core.any(duration)])
    .cast()
  promise.wait()
}

///|
/// Sleep until a specific timestamp
pub async fn WorkflowStep::sleep_until(
  self : WorkflowStep,
  name : String,
  timestamp : @core.Any, // Date object
) -> Unit {
  let promise : @core.Promise[Unit] = self
    .as_any()
    ._call("sleepUntil", [@core.any(name), timestamp])
    .cast()
  promise.wait()
}

///|
/// Wait for an external event
pub async fn WorkflowStep::wait_for_event(
  self : WorkflowStep,
  name : String,
  options : WaitForEventOptions,
) -> WorkflowEventPayload {
  let promise : @core.Promise[WorkflowEventPayload] = self
    .as_any()
    ._call("waitForEvent", [@core.any(name), options.to_js()])
    .cast()
  promise.wait()
}

///|
/// Options for waitForEvent
pub(all) struct WaitForEventOptions {
  event : String // Event type to wait for
  timeout : String? // Timeout duration (e.g., "24 hours")
}

///|
/// Convert WaitForEventOptions to JavaScript object
pub fn WaitForEventOptions::to_js(self : WaitForEventOptions) -> @core.Any {
  let obj = @core.new_object()
  obj["event"] = @core.any(self.event)
  if self.timeout is Some(t) {
    obj["timeout"] = @core.any(t)
  }
  obj
}

///|
/// Create wait options with just event type
pub fn WaitForEventOptions::new(event : String) -> WaitForEventOptions {
  { event, timeout: None }
}

///|
/// Create wait options with event and timeout
pub fn WaitForEventOptions::with_timeout(
  event : String,
  timeout : String,
) -> WaitForEventOptions {
  { event, timeout: Some(timeout) }
}

///|
/// WorkflowEventPayload - payload received from waitForEvent
#external
pub type WorkflowEventPayload

///|
pub fn WorkflowEventPayload::as_any(self : WorkflowEventPayload) -> @core.Any = "%identity"

///|
/// Get the event type
pub fn WorkflowEventPayload::event_type(self : WorkflowEventPayload) -> String {
  self.as_any()["type"].cast()
}

///|
/// Get the payload data
pub fn WorkflowEventPayload::payload(self : WorkflowEventPayload) -> @core.Any? {
  let p = self.as_any()["payload"]
  if @core.is_null(p) || @core.typeof_(p) == "undefined" {
    None
  } else {
    Some(p)
  }
}

///|
/// Get the timestamp
pub fn WorkflowEventPayload::timestamp(
  self : WorkflowEventPayload,
) -> @core.Any {
  self.as_any()["timestamp"]
}

///|
/// Configuration for workflow step retry behavior
pub(all) struct WorkflowStepConfig {
  retries : WorkflowRetryConfig?
  timeout : String? // e.g., "15 minutes"
}

///|
/// Convert WorkflowStepConfig to JavaScript object
pub fn WorkflowStepConfig::to_js(self : WorkflowStepConfig) -> @core.Any {
  let obj = @core.new_object()
  if self.retries is Some(r) {
    obj["retries"] = r.to_js()
  }
  if self.timeout is Some(t) {
    obj["timeout"] = @core.any(t)
  }
  obj
}

///|
/// Create step config with just timeout
pub fn WorkflowStepConfig::with_timeout(timeout : String) -> WorkflowStepConfig {
  { retries: None, timeout: Some(timeout) }
}

///|
/// Create step config with retries
pub fn WorkflowStepConfig::with_retries(
  retries : WorkflowRetryConfig,
) -> WorkflowStepConfig {
  { retries: Some(retries), timeout: None }
}

///|
/// Create step config with both retries and timeout
pub fn WorkflowStepConfig::new(
  retries : WorkflowRetryConfig,
  timeout : String,
) -> WorkflowStepConfig {
  { retries: Some(retries), timeout: Some(timeout) }
}

///|
/// Retry configuration for workflow steps
pub(all) struct WorkflowRetryConfig {
  limit : Int // Max number of retries
  delay : String // Delay between retries (e.g., "5 second")
  backoff : String // "constant" or "exponential"
}

///|
/// Convert WorkflowRetryConfig to JavaScript object
pub fn WorkflowRetryConfig::to_js(self : WorkflowRetryConfig) -> @core.Any {
  let obj = @core.new_object()
  obj["limit"] = @core.any(self.limit)
  obj["delay"] = @core.any(self.delay)
  obj["backoff"] = @core.any(self.backoff)
  obj
}

///|
/// Create constant backoff retry config
pub fn WorkflowRetryConfig::constant(
  limit : Int,
  delay : String,
) -> WorkflowRetryConfig {
  { limit, delay, backoff: "constant" }
}

///|
/// Create exponential backoff retry config
pub fn WorkflowRetryConfig::exponential(
  limit : Int,
  delay : String,
) -> WorkflowRetryConfig {
  { limit, delay, backoff: "exponential" }
}

// ============================================
// WorkflowEvent - event passed to workflow run()
// ============================================

///|
/// WorkflowEvent - the event object passed to a workflow's run method
#external
pub type WorkflowEvent

///|
pub fn WorkflowEvent::as_any(self : WorkflowEvent) -> @core.Any = "%identity"

///|
/// Get the payload data
pub fn WorkflowEvent::payload(self : WorkflowEvent) -> @core.Any {
  self.as_any()["payload"]
}

///|
/// Get the timestamp when the instance was created
pub fn WorkflowEvent::timestamp(self : WorkflowEvent) -> @core.Any {
  self.as_any()["timestamp"]
}

///|
/// Get the instance ID
pub fn WorkflowEvent::instance_id(self : WorkflowEvent) -> String {
  self.as_any()["instanceId"].cast()
}

// ============================================
// NonRetryableError - to stop retries
// ============================================

///|
/// Create a NonRetryableError to stop step retries
extern "js" fn create_non_retryable_error(message : String) -> @core.Any =
  #| (message) => new NonRetryableError(message)

///|
/// Create a NonRetryableError with a custom name
extern "js" fn create_non_retryable_error_with_name(
  message : String,
  name : String,
) -> @core.Any =
  #| (message, name) => new NonRetryableError(message, name)

///|
/// NonRetryableError - when thrown inside step.do(), stops retries
pub fn non_retryable_error(message : String) -> @core.Any {
  create_non_retryable_error(message)
}

///|
/// NonRetryableError with custom name
pub fn non_retryable_error_with_name(
  message : String,
  name : String,
) -> @core.Any {
  create_non_retryable_error_with_name(message, name)
}
