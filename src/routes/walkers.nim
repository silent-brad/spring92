import prologue
import std/[options, strutils]
import common
import ../database/[models, walkers as db_walkers]
import ../types, ../templates, ../utils

proc add_walker_page*(ctx: Context) {.async.} = gc_safe:
  let session = require_login(ctx)
  if session.is_none: return
  var msg = none(string)
  if "success=signup" in ctx.request.query:
    msg = some("Family account created successfully! Now create your first walker.")
  html_resp(ctx, render_template("add-walker.jinja", session, none(string), msg))

proc do_create_walker*(ctx: Context) {.async.} = gc_safe:
  let session = require_login(ctx)
  if session.is_none: return
  let name = ctx.get_post_params("name").strip()
  if name == "": html_resp(ctx, error_div("Name is required")); return
  if not validate_name(name): html_resp(ctx, error_div("Invalid name format")); return
  try:
    let (walker_id, avatar_filename) = create_walker_account(db_conn, session.get().family_id, name)
    set_walker_session(ctx, session.get().family_id, session.get().email,
                       Walker(id: walker_id, name: name, avatar_filename: avatar_filename))
    hx_redirect(ctx, "/dashboard?success=walker-created")
  except Exception as e:
    echo "Error creating walker: ", e.msg
    html_resp(ctx, error_div("Error creating walker account"))

proc select_walker_page*(ctx: Context) {.async.} = gc_safe:
  let session = require_login(ctx)
  if session.is_none: return
  let w = get_walkers_by_family(db_conn, session.get().family_id)
  var msg = none(string)
  if "success=login" in ctx.request.query:
    msg = some("Login successful! Choose a walker to continue.")
  html_resp(ctx, render_walker_selection(w, session, success_message = msg))

proc switch_walker*(ctx: Context) {.async.} = gc_safe:
  let session = require_login(ctx)
  if session.is_none: return
  try:
    let walker_id = parse_biggest_int(ctx.get_path_params("id"))
    let walker_opt = get_walker_by_id(db_conn, walker_id)
    if walker_opt.is_none or walker_opt.get().family_id != session.get().family_id:
      redirect_resp(ctx, "/select-walker?error=invalid-walker"); return
    set_walker_session(ctx, session.get().family_id, session.get().email, walker_opt.get())
    redirect_resp(ctx, "/dashboard")
  except:
    redirect_resp(ctx, "/select-walker?error=invalid-walker")

proc delete_walker_page*(ctx: Context) {.async.} = gc_safe:
  let session = require_walker(ctx)
  if session.is_none: return
  html_resp(ctx, render_template("delete_walker.jinja", session, none(string)))

proc do_delete_walker*(ctx: Context) {.async.} = gc_safe:
  let session = require_walker(ctx)
  if session.is_none: return
  try:
    delete_walker_account(db_conn, session.get().walker_id)
    ctx.session.clear()
    hx_redirect(ctx, "/?success=account-deleted")
  except Exception as e:
    echo "Error deleting walker: ", e.msg
    html_resp(ctx, html_error("Error deleting account"))
