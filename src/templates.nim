import options
import nimja/parser
import os
import types, utils
import database/models

const base_dir = get_script_dir() & "/../templates/"

proc render_template*(template_name: static string, session: Option[SessionData] = none(SessionData),
    error_message: Option[string] = none(string), success_message: Option[string] = none(string),
    name: Option[string] = none(string), miles: Option[string] = none(string),
    current_total: Option[float] = none(float), progress_percent: Option[float] = none(float),
    walker_id: Option[int64] = none(int64), email: Option[string] = none(string),
    entries_html: string = ""): string {.gcsafe.} =
  compile_template_file(template_name, base_dir)

proc render_leaderboard*(session: Option[SessionData] = none(SessionData),
    success_message: Option[string] = none(string),
    user_stats: seq[Entry] = @[], has_more: bool = false,
    next_page: int = 2, offset: int = 0, current_page: int = 1): string {.gcsafe.} =
  compile_template_file("leaderboard.jinja", base_dir)

proc render_leaderboard_table*(user_stats: seq[Entry] = @[],
    has_more: bool = false, next_page: int = 2, offset: int = 0,
    current_page: int = 1): string {.gcsafe.} =
  compile_template_file("leaderboard_table.jinja", base_dir)

proc render_settings*(walker: Option[Walker], session: Option[SessionData] = none(SessionData),
    error_message: Option[string] = none(string),
    success_message: Option[string] = none(string)): string {.gcsafe.} =
  compile_template_file("settings.jinja", base_dir)

proc render_posts_page*(posts: seq[PostView], session: Option[SessionData] = none(SessionData),
    has_more: bool = false, next_page: int = 2): string {.gcsafe.} =
  compile_template_file("posts.jinja", base_dir)

proc render_post_feed*(posts: seq[PostView], has_more: bool = false,
    next_page: int = 2, session: Option[SessionData] = none(SessionData)): string {.gcsafe.} =
  compile_template_file("post_feed.jinja", base_dir)

proc render_mile_entries_table*(entries: seq[MileEntry], has_more: bool = false,
    next_page: int = 2): string {.gcsafe.} =
  compile_template_file("mile_entries_table.jinja", base_dir)

proc render_walker_selection*(walkers: seq[Walker], session: Option[SessionData] = none(SessionData),
    success_message: Option[string] = none(string),
    error_message: Option[string] = none(string)): string {.gcsafe.} =
  compile_template_file("select-walker.jinja", base_dir)
