import database/models
export Walker, Family, MileEntry

type
  SessionData* = object
    family_id*: int64
    walker_id*: int64
    email*: string
    name*: string
    avatar_filename*: string
    is_family_session*: bool

  Entry* = object
    walker*: Walker
    total_miles*: float
    progress_percent*: float

  PostView* = object
    id*: int64
    walker_id*: int64
    name*: string
    avatar_filename*: string
    text_content*: string
    image_filename*: string
    created_at*: string

const
  static_dir* = "static"
  port* = 8091
