import strutils, os
from times import DateTime, format, monthday, parse

proc html_escape*(s: string): string =
  result = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#x27;")

proc sanitize_html*(html: string): string =
  result = html
  # Remove script tags
  var start_pos = 0
  while true:
    let script_start = result.find("<script", start_pos)
    if script_start == -1: break
    let script_end = result.find("</script>", script_start)
    if script_end != -1:
      result.delete(script_start..script_end + 8)
      start_pos = script_start
    else:
      result.delete(script_start..result.len - 1)
      break
  # Remove dangerous event handlers
  for attr in @["onclick", "onload", "onerror", "onmouseover", "onfocus", "onblur", "onkeypress", "onsubmit", "onchange"]:
    result = result.replace(attr & "=", "data-removed-" & attr & "=")
  result = result.replace("javascript:", "data-removed-javascript:")
  result = result.replace("data:", "data-removed:")
  let allowed_tags = @["b", "i", "u", "strong", "em", "a", "h1", "h2", "h3", "h4", "h5", "h6", "blockquote", "cite", "ul", "ol", "li", "p", "br", "img"]
  var tag_start = 0
  while true:
    let open_bracket = result.find("<", tag_start)
    if open_bracket == -1: break
    let close_bracket = result.find(">", open_bracket)
    if close_bracket == -1: break
    let tag_content = result[open_bracket + 1..close_bracket - 1].strip()
    var tag_name = ""
    if tag_content.starts_with("/"):
      tag_name = tag_content[1..^1].split(" ")[0].split("\t")[0]
    else:
      tag_name = tag_content.split(" ")[0].split("\t")[0]
    if tag_name.to_lower_ascii() notin allowed_tags and tag_name != "":
      result.delete(open_bracket..close_bracket)
      tag_start = open_bracket
    else:
      if tag_name.to_lower_ascii() == "a":
        let href_start = tag_content.find("href=")
        if href_start != -1:
          result = result[0..open_bracket] & "a href=" & tag_content[href_start + 5..^1].split(" ")[0] & ">" & result[close_bracket + 1..^1]
        else:
          result = result[0..open_bracket] & "a>" & result[close_bracket + 1..^1]
      elif tag_name.to_lower_ascii() == "img":
        var new_attrs = ""
        let src_start = tag_content.find("src=")
        if src_start != -1:
          let src_value = tag_content[src_start + 4..^1].split(" ")[0]
          new_attrs.add("src=" & src_value)
        let alt_start = tag_content.find("alt=")
        if alt_start != -1:
          let alt_value = tag_content[alt_start + 4..^1].split(" ")[0]
          if new_attrs.len > 0: new_attrs.add(" ")
          new_attrs.add("alt=" & alt_value)
        result = result[0..open_bracket] & "img " & new_attrs & ">" & result[close_bracket + 1..^1]
      tag_start = close_bracket + 1

proc sanitize_filename*(filename: string): string =
  result = filename.replace("/", "").replace("\\", "").replace("..", "").replace(":", "").replace("*", "").replace("?", "").replace("\"", "").replace("<", "").replace(">", "").replace("|", "")
  if result.strip() == "": result = "unnamed_file"

proc validate_email*(email: string): bool =
  if email.len == 0 or email.len > 254: return false
  let at_pos = email.find('@')
  if at_pos == -1 or at_pos == 0 or at_pos == email.len - 1: return false
  let domain_part = email[at_pos + 1 .. ^1]
  let dot_pos = domain_part.rfind('.')
  if dot_pos == -1 or dot_pos == 0 or dot_pos == domain_part.len - 1: return false
  for c in email:
    if not (c.is_alpha_numeric() or c in "@.-_+"): return false
  return true

proc validate_name*(name: string): bool =
  if name.len == 0 or name.len > 100: return false
  for c in name:
    if not (c.is_alpha_numeric() or c in " -'"): return false
  return true

proc is_safe_file_extension*(filename: string): bool =
  let ext = filename.split_file().ext.to_lower_ascii()
  ext in @[".jpg", ".jpeg", ".png", ".gif", ".webp"]

proc fmt_miles*(miles: float): string =
  let s = format_float(miles, ff_decimal, 1)
  if s.ends_with(".0"): s[0 .. ^3] else: s

proc error_div*(msg: string): string =
  """<div class="error solid">""" & msg & "</div>"

proc success_div*(msg: string): string =
  """<div class="success solid">""" & msg & "</div>"

proc html_error*(msg: string): string =
  """<p class="text-muted">""" & msg & "</p>"

proc html_success*(msg: string): string =
  """<p class="text-muted">""" & msg & "</p>"

proc format_date_with_ordinal*(dt_str: string): string =
  # Parse "yyyy-MM-dd HH:mm:ss" string and format like "9:02pm, Dec 12th, 2025"
  try:
    let dt = parse(dt_str, "yyyy-MM-dd HH:mm:ss")
    let day = dt.monthday()
    let suffix = if day mod 10 == 1 and day != 11: "st"
                elif day mod 10 == 2 and day != 12: "nd"
                elif day mod 10 == 3 and day != 13: "rd"
                else: "th"
    var time_part = dt.format("h:mmtt, MMM ")
    return time_part & $day & suffix & dt.format(", yyyy")
  except:
    return dt_str
