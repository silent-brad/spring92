import prologue
import prologue/middlewares/staticfile
import prologue/middlewares/sessions/memorysession
import os, strutils
import database/init
import routes/handlers
import types

proc main() =
  if not file_exists(".PASSKEY.txt"):
    echo "No passkey provided"
    quit(1)
  PASSKEY = read_file(".PASSKEY.txt").strip()

  echo "Initializing database..."
  db_conn = init_database()
  echo "Database initialized."

  let settings = new_settings(
    app_name = "Spring92",
    port = Port(types.port),
    debug = false,
    secret_key = PASSKEY & "spring92-session-key"
  )

  var app = new_app(settings = settings)
  app.use(static_file_middleware("static", "pictures", "avatars"))
  app.use(session_middleware(settings, max_age = 30 * 24 * 3600))
  register_routes(app)

  echo "Starting Spring92 server on port ", types.port
  app.run()

when is_main_module:
  main()
