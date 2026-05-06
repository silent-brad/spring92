import asyncdispatch
import asynchttpserver
import strutils
import strformat
import tables
import os
import sequtils
import ../utils

type
  MultipartData* = object
    fields*: Table[string, string]
    files*: Table[string, (string, string, int)] # (filename, contentType, size)
    error*: string

proc parse_multipart*(req: Request): Future[MultipartData] {.async.} =
  result = MultipartData(fields: init_table[string, string](), files: init_table[
      string, (string, string, int)](), error: "")

  if not req.headers.has_key("content-type"):
    result.error = "Missing Content-Type"
    return

  let ct_header = req.headers["content-type"]
  let content_type = ct_header
  if not content_type.starts_with("multipart/form-data"):
    result.error = "Invalid Content-Type"
    return

  # Extract boundary more robustly by parsing parameters
  let params = content_type.split(';').map_it(it.strip())
  var boundary = ""
  for param in params:
    if param.starts_with("boundary="):
      let boundary_raw = param[9 .. ^1].strip()
      boundary = if boundary_raw.starts_with('"') and boundary_raw.ends_with(
          '"'): boundary_raw[1 .. ^2] else: boundary_raw
      break
  if boundary == "":
    result.error = "Missing boundary"
    return

  let full_boundary = "--" & boundary

  # Get full body (already available as string)
  let body = req.body

  # Split into parts (parts[0] is preamble, last is epilogue)
  let parts = body.split(full_boundary)
  if parts.len < 3 or not parts[^1].starts_with(
      "--"): # At least preamble, one part, epilogue; check final '--' for validity
    result.error = "Malformed multipart body"
    return

  for i in 1 ..< parts.len - 1:
    var part = parts[i].strip(leading = true, chars = {'\r', '\n'})
    if part.len == 0: continue

    # Find end of headers (\r\n\r\n)
    let header_end = part.find("\r\n\r\n")
    if header_end == -1: continue

    let header_str = part[0 ..< header_end]
    var part_body = part[header_end + 4 .. ^1].strip(trailing = true, chars = {
        '\r', '\n'})

    # Parse part headers
    var part_headers = new_table[string, string]()
    for line in header_str.split("\r\n"):
      if line.len == 0: continue
      let colon_pos = line.find(':')
      if colon_pos != -1:
        let key = line[0 ..< colon_pos].strip().to_lower_ascii()
        let val = line[colon_pos + 1 .. ^1].strip()
        part_headers[key] = val

    # Parse Content-Disposition
    if not part_headers.has_key("content-disposition"): continue
    let disp = part_headers["content-disposition"]
    if not disp.starts_with("form-data"): continue

    let disp_params = disp.split(';').map_it(it.strip())
    var name = ""
    var filename = ""
    for param in disp_params[1 .. ^1]:
      let kv = param.split('=', 1)
      if kv.len != 2: continue
      let pkey = kv[0].strip()
      let pval = kv[1].strip(chars = {'"'})
      if pkey == "name": name = pval
      elif pkey == "filename": filename = pval

    if name.len == 0: continue

    let ctype = part_headers.get_or_default("content-type", "application/octet-stream")

    if filename.len > 0:
      # File upload - save to disk with proper security checks
      let upload_dir = "uploads"
      if not dir_exists(upload_dir): create_dir(upload_dir)

      # Sanitize filename and validate file extension
      let safe_filename = sanitize_filename(filename)
      if not is_safe_file_extension(safe_filename):
        result.error = "File type not allowed"
        return

      # Limit file size (10MB)
      if part_body.len > 10_485_760:
        result.error = "File too large"
        return

      let path = upload_dir / safe_filename
      write_file(path, part_body)
      result.files[name] = (safe_filename, ctype, part_body.len)
    else:
      # Regular field
      result.fields[name] = part_body
