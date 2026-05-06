import std/hashes, checksums/sha1
import strutils
from times import epoch_time

proc hash_password*(password: string): string =
  return $secure_hash(password)

proc verify_password*(password, hash: string): bool =
  return $secure_hash(password) == hash
