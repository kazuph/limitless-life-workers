///|
/// Server routes for Life Log application
/// Uses Sol framework for SSR

///|
/// Root page HTML template
const ROOT_TEMPLATE : String =
  #|<!DOCTYPE html>
  #|<html lang="ja">
  #|<head>
  #|  <meta charset="UTF-8">
  #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  #|  <title>__LUNA_TITLE__</title>
  #|  __LUNA_HEAD__
  #|</head>
  #|<body class="min-h-screen bg-background text-foreground">
  #|  <div id="sol-outlet" data-sol-outlet="main">__LUNA_MAIN__</div>
  #|</body>
  #|</html>

///|
/// Default head content (CSS, scripts)
/// Note: In development, Vite serves from /src/; in production from /static/
const DEFAULT_HEAD : String =
  #|<link rel="stylesheet" href="/src/client/globals.css">
  #|<script type="module" src="/src/client/main.ts"></script>

///|
/// Home page handler - renders the main timeline view
async fn home_page(_props : @router.PageProps) -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(
    @luna.fragment([
      @luna.h(
        "div",
        [("id", @luna.attr_static("root")), ("class", @luna.attr_static("min-h-screen"))],
        [],
      ),
      @luna.h(
        "noscript",
        [],
        [@luna.text("Enable JavaScript to view the dashboard.")],
      ),
    ]),
  )
}

///|
/// Define routes for the application
pub fn routes() -> Array[@router.SolRoutes] {
  [
    @router.SolRoutes::Page(
      path="/",
      handler=@router.PageHandler(home_page),
      title="Life Log",
      meta=[],
      revalidate=None,
      cache=None,
    ),
  ]
}

///|
/// Configure Hono app with Sol routes
pub fn configure_app(app : @router.App) -> @router.App {
  let config = @router.RouterConfig::default()
    .with_default_head(DEFAULT_HEAD)
    .with_root_template(ROOT_TEMPLATE)
    .with_default_title("Life Log")
  @router.register_sol_routes(app, routes(), config=config)
}

///|
/// Main function (required for is-main package)
fn main {
  ()
}
