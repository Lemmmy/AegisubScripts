import concat, insert from table
import floor, pow from math

util = require "aegisub.util"
require "karaskel"

export script_name        = "Yamaha sign"
export script_description = "Silly animated sign for a specific video"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

sign_x      = 97
sign_y      = 259
sign_height = 92
pad         = 15
blur        = 0.6
blur_pad    = blur * 2 -- Added onto all clips to ensure the blur is visible

br1_times = {
  { start_time: 0  , end_time: 200 , end_width: 0.05, accel: 2.0 },
  { start_time: 200, end_time: 700 , end_width: 0.85, accel: 1.2 },
  { start_time: 700, end_time: 1200, end_width: 1.00, accel: 0.7 }
}

text_end_time = 1000
text_accel = 0.4
text_move_n = 10
text_y_off = 3

pos = (x, y) ->
  "\\pos(#{x},#{y})"
rect = (x1, y1, x2, y2) ->
  "m #{x1} #{y1} l #{x2} #{y1} l #{x2} #{y2} l #{x1} #{y2} l #{x1} #{y1}"
clip = (x1, y1, x2, y2) ->
  "\\clip(#{x1},#{y1},#{x2},#{y2})"
temp_time = (t1, t2, accel, s) ->
  "\\temp_time(#{t1},#{t2},#{accel},#{s})"
time = (t1, t2, accel, s) ->
  "\\t(#{t1},#{t2},#{accel},#{s})"
anim_time = (tbl, x1, y1, x2, y2) ->
  temp_time tbl.start_time, tbl.end_time, tbl.accel, clip(x1, y1, interpolate(tbl.end_width, x1, x2), y2)
move = (x1, y1, x2, y2, t1, t2) ->
  "\\move(#{x1},#{y1},#{x2},#{y2},#{t1},#{t2})"

-- Replace \temp_time tags with \t tags, where the start and end times have been adjusted by `offset`
normalize_temp_times = (str, offset) ->
  str\gsub "\\temp_time%(([%d%.]+),%s*([%d%.]+),", (s1, s2) ->
    t1, t2 = tonumber(s1), tonumber(s2)
    t1 += offset
    t2 += offset
    "\\t(#{t1},#{t2},"

-- Accelerated move - split the line into `n` lines to simulate accelerated movement according to `accel`
-- `accel` follows `pow((t - t1) / (t2 - t1), accel)` where `t` is the current time
accel_move = (line, x1, y1, x2, y2, t1, t2, accel, n) ->
  line_start, line_end = line.start_time, line.end_time
  t_start, x = t1, x1

  lines = {}
  for i = 1, n
    t_end = interpolate i / n, t1, t2

    -- Calculate the new position
    factor = pow (t_end - t1) / (t2 - t1), accel
    new_x = interpolate factor, x1, x2

    -- Make the new line
    tag = move(x, y1, new_x, y2, 0, t_end - t_start)
    new_line = copy_line line
    new_line.text = "{#{tag}}#{normalize_temp_times line.text, -t_start}"
    new_line.start_time = line_start + t_start
    -- Keep the existing duration for the last line
    new_line.end_time = if i == n then line_end else line_start + t_end

    insert lines, new_line

    -- Prep for next iteration
    t_start = t_end
    x = new_x

  lines

make_yamaha_sign = (subtitles, selection) ->
  meta, styles = karaskel.collect_head subtitles

  i = selection[1]
  line = subtitles[selection[1]]
  karaskel.preproc_line subtitles, meta, styles, line

  text_height_base = line.height - line.descent

  sign_width = line.width + 2 * pad

  -- Background rectangle
  br1_path = rect 0, 0, sign_width, sign_height

  -- Largest bounding box for the clips - slightly larger than the rectangle itself to account for the blur
  br1_clip_x1, br1_clip_x2 = sign_x - blur_pad, sign_x + sign_width + blur_pad
  br1_clip_y1, br1_clip_y2 = sign_y - blur_pad, sign_y + sign_height + blur_pad

  br1_init_clip = clip br1_clip_x1, br1_clip_y1, br1_clip_x1, br1_clip_y2 -- Same x1, start at 0 width
  br1_time_strs = [anim_time(t, br1_clip_x1, br1_clip_y1, br1_clip_x2, br1_clip_y2) for t in *br1_times]
  br1_clips = "#{br1_init_clip}#{concat br1_time_strs, ""}"

  br1 = "{\\blur#{blur}\\p1#{pos sign_x, sign_y}#{normalize_temp_times br1_clips, 0}}#{br1_path}"

  -- Add the new line before the current one
  br1_line = copy_line line
  br1_line.text = br1
  br1_line.style = "Top box bg1"
  subtitles[-i] = br1_line
  i += 1

  -- Reposition the text: start it at 50% of the width of the sign, then move it to the left. Give the text the same
  -- clips as the background rectangle. Remove existing \pos(...) tags and remaining empty braces ({})
  text_start_x, text_end_x = sign_x + sign_width / 2, sign_x + pad
  text_y = sign_y + ((sign_height - line.descent) / 2) + text_y_off
  clean_text = (line.text\gsub "\\pos%([%d%.]+,%s*[%d%.]+%)", "")\gsub "{}", ""
  new_text = "{\\blur#{blur}#{br1_clips}}#{clean_text}"

  -- Put the new line text in, then call accel_move to generate multiple lines with the accelerated movement
  tmp_line = copy_line line
  tmp_line.text = new_text
  subtitles.delete(i) -- Remove the existing line

  new_lines = accel_move tmp_line, text_start_x, text_y, text_end_x, text_y, 0, text_end_time, text_accel, text_move_n
  subtitles.insert i, unpack(new_lines)

  -- Done
  aegisub.set_undo_point script_name

make_yamaha_sign_validation = (subtitles, selection, active) ->
  #selection == 1

aegisub.register_macro script_dir .. script_name, script_description, make_yamaha_sign, make_yamaha_sign_validation


