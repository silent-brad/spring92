import norm/sqlite
import std/strutils
import models

proc create_post*(db: DbConn, walker_id: int64, text_content, image_filename: string): int64 =
  var walker = new_walker()
  db.select(walker, "id = ?", walker_id)
  var post = new_post(walker, text_content, image_filename, now_local())
  db.insert(post)
  post.id

proc get_posts_paginated*(db: DbConn, limit, offset: int): seq[Post] =
  var posts = @[new_post()]
  db.select(posts, "1 = 1 ORDER BY \"post\".created_at DESC LIMIT ? OFFSET ?", limit, offset)
  posts

proc get_post_by_id*(db: DbConn, post_id: int64): Post =
  var post = new_post()
  db.select(post, "\"post\".id = ?", post_id)
  post

proc update_post*(db: DbConn, post_id: int64, text_content, image_filename: string) =
  var post = new_post()
  db.select(post, "\"post\".id = ?", post_id)
  post.text_content = text_content
  post.image_filename = image_filename
  db.update(post)

proc delete_post*(db: DbConn, post_id: int64) =
  var post = new_post()
  post.id = post_id
  db.delete(post)
