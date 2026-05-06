import prologue
import common
export common

import auth, walkers, miles, posts, settings

proc register_routes*(app: var Prologue) =
  # Public & Auth
  app.get("/", index_page)
  app.get("/about", about_page)
  app.get("/login", login_page)
  app.get("/signup", signup_page)
  app.post("/login", do_login)
  app.post("/signup", do_signup)
  app.get("/logout", do_logout)

  # Walkers
  app.get("/add-walker", add_walker_page)
  app.post("/create-walker", do_create_walker)
  app.get("/select-walker", select_walker_page)
  app.get("/switch-walker/{id}", switch_walker)
  app.get("/delete-walker", delete_walker_page)
  app.post("/delete-walker", do_delete_walker)

  # Dashboard & Miles
  app.get("/dashboard", dashboard_page)
  app.get("/log", log_page)
  app.post("/log", do_log_miles)
  app.post("/edit-miles", do_edit_miles)
  app.post("/delete-miles", do_delete_miles)
  app.get("/leaderboard", leaderboard_page)
  app.get("/api/leaderboard-table", api_leaderboard_table)
  app.get("/api/user-miles-data", api_user_miles_data)
  app.get("/api/user-miles-entries", api_user_miles_entries)

  # Posts
  app.get("/posts", posts_page)
  app.post("/post", do_create_post)
  app.post("/edit-post", do_edit_post)
  app.post("/delete-post", do_delete_post)
  app.get("/api/post-feed", api_post_feed)

  # Settings
  app.get("/settings", settings_page)
  app.post("/settings", do_settings)

  # 404
  app.register_error_handler(Http404, not_found)
