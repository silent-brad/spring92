import db_connector/db_sqlite
import strutils, options, httpclient, os
import ../upload
import models

proc to_walker(row: Row): Walker =
  Walker(id: parse_biggest_int(row[0]), family_id: parse_biggest_int(row[1]),
         name: row[2], has_custom_avatar: row[3] == "1",
         avatar_filename: row[4], created_at: row[5])

proc get_walker_by_id*(db: DbConn, walker_id: int64): Option[Walker] =
  let row = db.get_row(sql"SELECT id, family_id, name, has_custom_avatar, avatar_filename, created_at FROM walker WHERE id = ?", walker_id)
  if row[0] == "": return none(Walker)
  some(to_walker(row))

proc get_walkers_by_family*(db: DbConn, family_id: int64): seq[Walker] =
  for row in db.get_all_rows(sql"SELECT id, family_id, name, has_custom_avatar, avatar_filename, created_at FROM walker WHERE family_id = ? ORDER BY created_at ASC", family_id):
    result.add(to_walker(row))

proc create_generic_avatar(name: string): string =
  let client = new_http_client()
  defer: client.close()
  let avatar_data = client.get_content("https://ui-avatars.com/api/?background=random&name=" & name.replace(" ", "%20") & "&format=webp")
  avatar_data.save_uploaded_file("webp", "avatars")

proc create_walker_account*(db: DbConn, family_id: int64, name: string): (int64, string) =
  let avatar_filename = create_generic_avatar(name)
  let walker_id = db.insert_id(sql"INSERT INTO walker (family_id, name, has_custom_avatar, avatar_filename) VALUES (?, ?, ?, ?)", family_id, name, false, avatar_filename)
  (walker_id, avatar_filename)

proc update_walker_name*(db: DbConn, walker_id: int64, name: string) =
  let walker_opt = db.get_walker_by_id(walker_id)
  if walker_opt.is_some:
    db.exec(sql"UPDATE walker SET name = ? WHERE id = ?", name, walker_id)
    let walker = walker_opt.get()
    if not walker.has_custom_avatar:
      let old_avatar = walker.avatar_filename
      let new_avatar = create_generic_avatar(name)
      db.exec(sql"UPDATE walker SET avatar_filename = ? WHERE id = ?", new_avatar, walker_id)
      if old_avatar.len > 0 and file_exists("avatars/" & old_avatar):
        remove_file("avatars/" & old_avatar)

proc update_walker_avatar*(db: DbConn, avatar_filename: string, walker_id: int64) =
  db.exec(sql"UPDATE walker SET has_custom_avatar = true, avatar_filename = ? WHERE id = ?", avatar_filename, walker_id)

proc delete_walker_account*(db: DbConn, walker_id: int64) =
  let walker_opt = get_walker_by_id(db, walker_id)
  if walker_opt.is_some:
    let walker = walker_opt.get()
    if walker.avatar_filename.len > 0:
      let path = "avatars" / walker.avatar_filename
      if file_exists(path):
        try: remove_file(path)
        except: discard
    for row in db.get_all_rows(sql"SELECT image_filename FROM post WHERE walker_id = ? AND image_filename IS NOT NULL AND image_filename != ''", walker_id):
      if row[0].len > 0:
        let path = "pictures" / row[0]
        if file_exists(path):
          try: remove_file(path)
          except: discard
  db.exec(sql"DELETE FROM mile_entry WHERE walker_id = ?", walker_id)
  db.exec(sql"DELETE FROM post WHERE walker_id = ?", walker_id)
  db.exec(sql"DELETE FROM walker WHERE id = ?", walker_id)
