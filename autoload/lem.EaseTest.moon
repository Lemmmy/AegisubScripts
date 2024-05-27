export script_name        = "Easing functions"
export script_description = "Test easing functions"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

import max from math
util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :pos, :rect, :clean_tags, :remove_pos, :parse_pos, :make_basic_line } = lem

sign_x      = 97
sign_y      = 165
sign_height = 92
pad         = 24
blur        = 0.6
blur_t      = "\\blur(#{blur})"

bg_style   = "Top box bg1"
text_style = "Top box text"

swipe_time = 1200
text_x_off = -3.5
text_y_off = 3

make_ease = (subs, f_start, f_end, t_end, y, sign_width, descent, clean_text, ease_fn) ->
  frames = max f_end - f_start - 1, 1
  for i = 1, frames
    progress = i / frames
    i_start, i_end = aegisub.ms_from_frame(f_start + i), aegisub.ms_from_frame(f_start + i + 1)

    -- Background rectangle - width grows, and moves to the left (centered horizontally)
    lerp_width = (ease_fn progress) * sign_width
    bg_x = sign_x - lerp_width / 2
    bg_rect = rect bg_x, sign_y + y, bg_x + lerp_width, sign_y + sign_height + y
    bg_text = "{#{blur_t}#{pos 0, 0}\\p1}#{bg_rect}"
    subs.append with make_basic_line bg_text, i_start, i_end, bg_style
      .layer = 1

    -- Text - fades in, centered with the sign, font spacing starts high and decreases
    text_x = sign_x - (sign_width / 2) + pad + text_x_off
    text_y = sign_y + ((sign_height - descent) / 2) + text_y_off + y
    main_text = "{#{blur_t}#{pos text_x, text_y}\\fs32\\an4\\bord2\\3c&HFFFFFF&}#{clean_text}"
    subs.append with make_basic_line main_text, i_start, i_end, text_style
      .layer = 2

make_cubic = (subs, f_start, f_end, t_end, n, sign_width, descent, p0, p1, p2, p3) ->
  y = -((sign_height + 2) * n)
  ease_fn = lem.cubic_bezier p0, p1, p2, p3
  text = string.format "%.2f, %.2f, %.2f, %.2f", p0, p1, p2, p3
  make_ease subs, f_start, f_end, t_end, y, sign_width, descent, text, ease_fn

make_easing = (subs, selection) ->
  -- Prepare karaskel stuff
  meta, styles = karaskel.collect_head subs

  -- Populate line size information
  i = selection[1]
  line = subs[selection[1]]
  karaskel.preproc_line subs, meta, styles, line

  -- Get the x and y position of the sign based on the \pos() tag of the selected line
  sign_x, sign_y = parse_pos line.text
  if not sign_x or not sign_y
    aegisub.debug.out "No \\pos() tag found in the selected line, using default position\n"
    sign_x, sign_y = 97, 165

  text_height_base, descent = line.height - line.descent, line.descent
  sign_width = 332
  clean_text = remove_pos line.text

  t_start, t_end = line.start_time, line.end_time
  main_end = t_end - swipe_time -- The time that the swipe-out animation will play

  subs.delete i -- Remove the existing line

  -- Insert a comment line to mark the start of the sign, with fold data to easily hide it
  fold_id = lem.insert_fold_line subs, "Start Yamaha sign: #{clean_text}", t_start, t_end, text_style

  -- Initial swipe-in animation
  f_start, f_end = aegisub.frame_from_ms(t_start), aegisub.frame_from_ms(t_start + swipe_time)
  make_cubic subs, f_start, f_end, main_end, 0, sign_width, descent, 0.59, 0.13, 0.25, 0.81
  make_cubic subs, f_start, f_end, main_end, 1, sign_width, descent, 0.83, 0.20, 0.17, 0.80
  make_cubic subs, f_start, f_end, main_end, 2, sign_width, descent, 0.83, 0.10, 0.17, 0.90
  make_cubic subs, f_start, f_end, main_end, 3, sign_width, descent, 0.83, 0.00, 0.17, 1.00

  -- Insert a final comment line to mark the end of the sign, and the ending fold
  lem.insert_fold_line subs, "End Yamaha sign: #{clean_text}", t_end, t_end, text_style, fold_id

  -- Done
  aegisub.set_undo_point script_name

make_easing_validation = (subs, selection, active) ->
  #selection == 1

aegisub.register_macro script_dir .. script_name, script_description, make_easing, make_easing_validation
