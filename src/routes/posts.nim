import prologue
import std/[options, strutils, os]
import common
import ../database/[posts as db_posts]
import ../types, ../templates, ../utils

proc posts_page*(ctx: Context) {.async.} = gc_safe:
  let session = require_walker(ctx)
  if session.is_none: return
  const ps = 10
  let all_posts = get_posts_paginated(db_conn, ps + 1, 0)
  let has_more = all_posts.len > ps
  html_resp(ctx, render_posts_page(if has_more: all_posts[0 ..< ps] else: all_posts,
            session, has_more = has_more, next_page = 2))

proc do_create_post*(ctx: Context) {.async.} = gc_safe:
  let session = require_walker(ctx)
  if session.is_none: return
  let text_content = sanitize_html(ctx.get_form_params("text_content").strip())
  let image_filename = try_upload(ctx, "image", "pictures")
  if text_content.strip() == "" and image_filename == "":
    html_resp(ctx, html_error("Please provide text content or an image.")); return
  try:
    discard create_post(db_conn, session.get().walker_id, text_content, image_filename)
    hx_redirect(ctx, "/posts")
  except Exception as e:
    echo "Error creating post: ", e.msg
    html_resp(ctx, html_error("Failed to save your post."), Http500)

proc do_edit_post*(ctx: Context) {.async.} = gc_safe:
  let session = require_walker(ctx)
  if session.is_none: return
  try:
    let post_id = parse_biggest_int(ctx.get_form_params("post_id"))
    let post = get_post_by_id(db_conn, post_id)
    if post.walker.id != session.get().walker_id:
      html_resp(ctx, html_error("You can only edit your own posts"), Http403); return
    let text_content = sanitize_html(ctx.get_form_params("text_content").strip())
    var image_filename = post.image_filename
    if ctx.get_form_params("remove_image") == "1":
      if image_filename != "" and file_exists("pictures" / image_filename): remove_file("pictures" / image_filename)
      image_filename = ""
    let uploaded = try_upload(ctx, "image", "pictures")
    if uploaded != "":
      if post.image_filename != "" and file_exists("pictures" / post.image_filename): remove_file("pictures" / post.image_filename)
      image_filename = uploaded
    if text_content.strip() == "" and image_filename == "":
      html_resp(ctx, html_error("Please provide text content or an image.")); return
    update_post(db_conn, post_id, text_content, image_filename)
    hx_redirect(ctx, "/posts")
  except:
    html_resp(ctx, html_error("Invalid post"))

proc do_delete_post*(ctx: Context) {.async.} = gc_safe:
  let session = require_walker(ctx)
  if session.is_none: return
  try:
    let post_id = parse_biggest_int(ctx.get_post_params("post_id"))
    let post = get_post_by_id(db_conn, post_id)
    if post.walker.id != session.get().walker_id:
      html_resp(ctx, html_error("You can only delete your own posts"), Http403); return
    if post.image_filename != "" and file_exists("pictures" / post.image_filename): remove_file("pictures" / post.image_filename)
    delete_post(db_conn, post_id)
    hx_redirect(ctx, "/posts")
  except:
    html_resp(ctx, html_error("Invalid post"))

proc api_post_feed*(ctx: Context) {.async.} = gc_safe:
  let session = require_walker(ctx)
  if session.is_none: return
  const ps = 10
  var page = 1
  try: page = parse_int(ctx.get_query_params("page", "1"))
  except: discard
  let offset = (page - 1) * ps
  let all_posts = get_posts_paginated(db_conn, ps + 1, offset)
  let has_more = all_posts.len > ps
  let display = if has_more: all_posts[0 ..< ps] else: all_posts
  html_resp(ctx, render_post_feed(display, has_more = has_more, next_page = page + 1, session = session))
