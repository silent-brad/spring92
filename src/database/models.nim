import std/options

type
  Family* = object
    id*: int64
    email*: string
    password_hash*: string
    created_at*: string

  Walker* = object
    id*: int64
    family_id*: int64
    name*: string
    has_custom_avatar*: bool
    avatar_filename*: string
    created_at*: string

  MileEntry* = object
    id*: int64
    walker_id*: int64
    miles*: float
    logged_at*: string

  Post* = object
    id*: int64
    walker_id*: int64
    text_content*: string
    image_filename*: string
    created_at*: string
