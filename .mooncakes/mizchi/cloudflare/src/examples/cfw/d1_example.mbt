///|
/// Cloudflare D1 Database example handler
/// This demonstrates D1 operations for a simple user management API

///|
/// Create JSON response (local to D1 handler)
extern "js" fn d1_json_response(body : String, status : Int) -> @http.Response =
  #| (body, status) => new Response(body, { status, headers: { "Content-Type": "application/json" } })

///|
/// Helper to get D1 database from env
fn get_d1(env : @cloudflare.CloudflareEnv) -> @cloudflare.D1Database? {
  let env_js : @core.Any = @core.identity(env)
  let db_js = env_js._get("TEST_DB")
  if @core.typeof_(db_js) == "undefined" {
    None
  } else {
    Some(@core.identity(db_js))
  }
}

///|
/// D1 handler that provides various database operations
pub fn get_d1_handler() -> @cloudflare.CloudflareFetchHandler {
  let async_handler = async fn(
    req : @cloudflare.CloudflareRequest,
    env : @cloudflare.CloudflareEnv,
    _ctx : @cloudflare.CloudflareContext,
  ) -> @http.Response {
    let url_str = req.url
    let url = @url.URL::new(url_str)
    let pathname = url.pathname

    // Get D1 database
    let db = match get_d1(env) {
      Some(d) => d
      None =>
        return d1_json_response(
          "{\"error\":\"D1 database not configured\"}", 500,
        )
    }

    // Route handling for D1 operations
    if pathname == "/d1/init" {
      // Initialize the users table
      let _ = db
        .prepare(
          "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT UNIQUE, age INTEGER)",
        )
        .run() catch {
          e =>
            return d1_json_response(
              "{\"error\":\"Failed to create table: " + e.to_string() + "\"}",
              500,
            )
        }
      d1_json_response("{\"success\":true,\"message\":\"Table created\"}", 200)
    } else if pathname == "/d1/users/create" {
      // Create a new user
      let name = url.searchParams().get("name")
      let email = url.searchParams().get("email")
      let age_str = url.searchParams().get("age")
      match (name, email) {
        (Some(n), Some(e)) => {
          let age = match age_str {
            Some(a) => @global.parse_int(a).unwrap_or(0)
            None => 0
          }
          let result = db
            .prepare("INSERT INTO users (name, email, age) VALUES (?, ?, ?)")
            .bind3(@core.any(n), @core.any(e), @core.any(age))
            .run() catch {
              err =>
                return d1_json_response(
                  "{\"error\":\"Failed to insert user: " +
                  err.to_string() +
                  "\"}",
                  500,
                )
            }
          if result.success() {
            let last_id = match result.meta() {
              Some(m) =>
                match m.last_row_id() {
                  Some(id) => id.to_string()
                  None => "null"
                }
              None => "null"
            }
            d1_json_response("{\"success\":true,\"id\":" + last_id + "}", 200)
          } else {
            d1_json_response("{\"error\":\"Insert failed\"}", 500)
          }
        }
        _ =>
          d1_json_response(
            "{\"error\":\"Missing name or email parameter\"}", 400,
          )
      }
    } else if pathname == "/d1/users/get" {
      // Get a user by ID
      let id = url.searchParams().get("id")
      match id {
        Some(i) => {
          let row = db
            .prepare("SELECT * FROM users WHERE id = ?")
            .bind1(@core.any(@global.parse_int(i).unwrap_or(0)))
            .first() catch {
              _ =>
                return d1_json_response(
                  "{\"error\":\"Failed to get user\"}", 500,
                )
            }
          match row {
            Some(r) => {
              let json_str = @js.JSON::stringify(r)
              d1_json_response(json_str, 200)
            }
            None => d1_json_response("{\"error\":\"User not found\"}", 404)
          }
        }
        None => d1_json_response("{\"error\":\"Missing id parameter\"}", 400)
      }
    } else if pathname == "/d1/users/list" {
      // List all users
      let result = db.prepare("SELECT * FROM users").all() catch {
          _ =>
            return d1_json_response("{\"error\":\"Failed to list users\"}", 500)
        }
      if result.success() {
        let results = result.get_results()
        let response = @core.new_object()
        response["users"] = @core.any(results)
        response["count"] = @core.any(results.length())
        let json_str = @js.JSON::stringify(response)
        d1_json_response(json_str, 200)
      } else {
        d1_json_response("{\"error\":\"Query failed\"}", 500)
      }
    } else if pathname == "/d1/users/update" {
      // Update a user
      let id = url.searchParams().get("id")
      let name = url.searchParams().get("name")
      let age_str = url.searchParams().get("age")
      match (id, name) {
        (Some(i), Some(n)) => {
          let age = match age_str {
            Some(a) => @global.parse_int(a).unwrap_or(0)
            None => 0
          }
          let result = db
            .prepare("UPDATE users SET name = ?, age = ? WHERE id = ?")
            .bind3(
              @core.any(n),
              @core.any(age),
              @core.any(@global.parse_int(i).unwrap_or(0)),
            )
            .run() catch {
              _ =>
                return d1_json_response(
                  "{\"error\":\"Failed to update user\"}", 500,
                )
            }
          if result.success() {
            let changes = match result.meta() {
              Some(m) =>
                match m.changes() {
                  Some(c) => c.to_string()
                  None => "0"
                }
              None => "0"
            }
            d1_json_response(
              "{\"success\":true,\"changes\":" + changes + "}",
              200,
            )
          } else {
            d1_json_response("{\"error\":\"Update failed\"}", 500)
          }
        }
        _ =>
          d1_json_response("{\"error\":\"Missing id or name parameter\"}", 400)
      }
    } else if pathname == "/d1/users/delete" {
      // Delete a user
      let id = url.searchParams().get("id")
      match id {
        Some(i) => {
          let result = db
            .prepare("DELETE FROM users WHERE id = ?")
            .bind1(@core.any(@global.parse_int(i).unwrap_or(0)))
            .run() catch {
              _ =>
                return d1_json_response(
                  "{\"error\":\"Failed to delete user\"}", 500,
                )
            }
          if result.success() {
            let changes = match result.meta() {
              Some(m) =>
                match m.changes() {
                  Some(c) => c.to_string()
                  None => "0"
                }
              None => "0"
            }
            d1_json_response(
              "{\"success\":true,\"changes\":" + changes + "}",
              200,
            )
          } else {
            d1_json_response("{\"error\":\"Delete failed\"}", 500)
          }
        }
        None => d1_json_response("{\"error\":\"Missing id parameter\"}", 400)
      }
    } else if pathname == "/d1/users/count" {
      // Count users
      let count_val = db
        .prepare("SELECT COUNT(*) as count FROM users")
        .first_col("count") catch {
          _ =>
            return d1_json_response(
              "{\"error\":\"Failed to count users\"}", 500,
            )
        }
      match count_val {
        Some(c) => {
          let count_str = @js.JSON::stringify(c)
          d1_json_response("{\"count\":" + count_str + "}", 200)
        }
        None => d1_json_response("{\"count\":0}", 200)
      }
    } else if pathname == "/d1/cleanup" {
      // Drop the users table
      let _ = db.prepare("DROP TABLE IF EXISTS users").run() catch {
          _ =>
            return d1_json_response("{\"error\":\"Failed to drop table\"}", 500)
        }
      d1_json_response("{\"success\":true,\"message\":\"Table dropped\"}", 200)
    } else {
      // Help/index page
      let help = "{\"endpoints\":[\"/d1/init\",\"/d1/users/create?name=x&email=y&age=z\",\"/d1/users/get?id=x\",\"/d1/users/list\",\"/d1/users/update?id=x&name=y&age=z\",\"/d1/users/delete?id=x\",\"/d1/users/count\",\"/d1/cleanup\"]}"
      d1_json_response(help, 200)
    }
  }
  promisify3(async_handler)
}
