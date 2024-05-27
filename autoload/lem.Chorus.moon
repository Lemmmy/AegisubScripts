export script_name        = "Chorus"
export script_description = "Overlaps multiple identical lines at the same time, clipped vertically"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :pos, :rect, :clip, :clean_tags, :parse_pos, :remove_pos } = lem

chorus = (subs, selection) ->
  -- Prepare karaskel stuff
  meta, styles = karaskel.collect_head subs

  lines = {}
  x, y = nil, nil

  for i = 1, #selection
    line = subs[selection[i]]
    karaskel.preproc_line subs, meta, styles, line
    lines[i] = line

    -- If any line has a \pos tag, use this as the position for all lines
    x, y = parse_pos line.text if not x or not y

  first_line = lines[1]
  if not x or not y
    x = first_line.x
    y = first_line.y
  pos_tag = pos x, y

  -- If the line was repositioned, karaskel's assumed offsets will be wrong (it can't do collision detection), so check
  -- the first line's guessed position against our actual position, and use it as an offset against the other bounds
  y_off = y - first_line.y

  -- Get the width from the video and the height of the first line
  width = aegisub.video_size()
  height = first_line.height
  segment_height = height / #lines

  for i = 1, #selection
    line = lines[i]
    clip_t = first_line.top + y_off + (segment_height * (i - 1))
    clip_b = clip_t + segment_height
    clip_tag = clip 0, clip_t, width, clip_b
    line.text = "{#{pos_tag}#{clip_tag}}#{remove_pos line.text}"
    subs[selection[i]] = line

  aegisub.set_undo_point script_name

chorus_validation = (subs, selection, active) ->
  #selection >= 2

aegisub.register_macro script_dir .. script_name, script_description, chorus, chorus_validation
