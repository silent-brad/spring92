import db_connector/db_sqlite
import strutils, options
import models

proc to_family(row: Row): Family =
  Family(id: parse_biggest_int(row[0]), email: row[1],
         password_hash: row[2], created_at: row[3])

proc get_family_by_email*(db: DbConn, email: string): Option[Family] =
  let row = db.get_row(sql"SELECT id, email, password_hash, created_at FROM family WHERE email = ?", email)
  if row[0] == "": return none(Family)
  some(to_family(row))

proc get_family_by_id*(db: DbConn, family_id: int64): Option[Family] =
  let row = db.get_row(sql"SELECT id, email, password_hash, created_at FROM family WHERE id = ?", family_id)
  if row[0] == "": return none(Family)
  some(to_family(row))

proc create_family_account*(db: DbConn, email, password_hash: string): int64 =
  db.insert_id(sql"INSERT INTO family (email, password_hash) VALUES (?, ?)", email, password_hash)

proc update_family_password*(db: DbConn, family_id: int64, new_password_hash: string) =
  db.exec(sql"UPDATE family SET password_hash = ? WHERE id = ?", new_password_hash, family_id)
