import norm/sqlite
import std/options
import models

proc get_family_by_email*(db: DbConn, email: string): Option[Family] =
  var family = new_family()
  try:
    db.select(family, "email = ?", email)
    some(family)
  except NotFoundError:
    none(Family)

proc get_family_by_id*(db: DbConn, family_id: int64): Option[Family] =
  var family = new_family()
  try:
    db.select(family, "id = ?", family_id)
    some(family)
  except NotFoundError:
    none(Family)

proc create_family_account*(db: DbConn, email, password_hash: string): int64 =
  var family = new_family(email, password_hash)
  db.insert(family)
  family.id

proc update_family_password*(db: DbConn, family_id: int64, new_password_hash: string) =
  var family = new_family()
  db.select(family, "id = ?", family_id)
  family.password_hash = new_password_hash
  db.update(family)
