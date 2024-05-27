export script_name        = "Yamaha sign 2"
export script_description = "Silly animated sign for a specific video"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

import max from math
util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :pos, :rect, :clip, :alpha_lerp, :clean_tags, :remove_pos, :parse_pos, :make_basic_line } = lem

sign_x      = 97
sign_y      = 165
sign_height = 109
pad         = 24
blur        = 0.6
blur_t      = "\\blur(#{blur})"
fsp_start   = 50

bg_style   = "Top box bg1"
text_style = "Top box text"

swipe_time    = 1200
text_end_time = 1000
text_accel    = 0.4
text_move_n   = 10
text_x_off    = 0
text_y_off    = 3

ease_fn = lem.ease_yamaha

make_swipe_frames = (subs, f_start, f_end, t_end, sign_width, descent, clean_text, reverse) ->
  frames = max f_end - f_start - 1, 1
  for i = 1, frames
    progress = (if reverse then frames - i else i) / frames
    i_start = aegisub.ms_from_frame(f_start + i)
    i_end = if i >= frames and not reverse then t_end else aegisub.ms_from_frame(f_start + i + 1)

    -- Background rectangle - width grows, and moves to the left (centered horizontally)
    lerp_width = (ease_fn progress) * sign_width
    bg_x = sign_x - lerp_width / 2
    bg_rect = rect bg_x, sign_y, bg_x + lerp_width, sign_y + sign_height
    bg_text = "{#{blur_t}#{pos 0, 0}\\p1}#{bg_rect}"
    subs.append with make_basic_line bg_text, i_start, i_end, bg_style
      .layer = 1

    -- Text - fades in, centered with the sign, font spacing starts high and decreases
    lerp_fsp = fsp_start - (ease_fn progress) * fsp_start
    alpha = alpha_lerp (ease_fn progress)
    text_x = bg_x - (sign_width - lerp_width) + pad + text_x_off
    text_y = sign_y + ((sign_height - descent) / 2) + text_y_off
    text_clip = clip bg_x, sign_y, bg_x + lerp_width, sign_y + sign_height
    main_text = "{#{blur_t}#{pos text_x, text_y}#{text_clip}\\fsp#{lerp_fsp}#{alpha}}#{clean_text}"
    subs.append with make_basic_line main_text, i_start, i_end, text_style
      .layer = 2

make_yamaha_sign = (subs, selection) ->
  -- Prepare karaskel stuff
  meta, styles = karaskel.collect_head subs

  -- Change the style of the line to the text style if it isn't already
  i = selection[1]
  line = subs[selection[1]]

  if not line.style\match "^Top box "
    line.style = text_style
    subs[selection[1]] = line
  else
    text_style = line.style

  -- Populate line size information
  karaskel.preproc_line subs, meta, styles, line

  -- Get the x and y position of the sign based on the \pos() tag of the selected line
  sign_x, sign_y = parse_pos line.text
  if not sign_x or not sign_y
    aegisub.debug.out "No \\pos() tag found in the selected line, using default position\n"
    sign_x, sign_y = 97, 165

  text_height_base, descent = line.height - line.descent, line.descent
  sign_width = line.width + 2 * pad
  clean_text = remove_pos line.text

  t_start, t_end = line.start_time, line.end_time
  main_end = t_end - swipe_time -- The time that the swipe-out animation will play

  subs.delete i -- Remove the existing line

  -- Insert a comment line to mark the start of the sign, with fold data to easily hide it
  fold_id = lem.insert_fold_line subs, "Start Yamaha sign: #{clean_text}", t_start, t_end, text_style

  -- Initial swipe-in animation
  f_start, f_end = aegisub.frame_from_ms(t_start), aegisub.frame_from_ms(t_start + swipe_time)
  make_swipe_frames subs, f_start, f_end, main_end, sign_width, descent, clean_text

  -- Final swipe-out animation
  f_start, f_end = aegisub.frame_from_ms(t_end - swipe_time) - 1, aegisub.frame_from_ms(t_end)
  make_swipe_frames subs, f_start, f_end, t_end, sign_width, descent, clean_text, true

  -- Insert a final comment line to mark the end of the sign, and the ending fold
  lem.insert_fold_line subs, "End Yamaha sign: #{clean_text}", t_end, t_end, text_style, fold_id

  -- Done
  aegisub.set_undo_point script_name

make_yamaha_sign_validation = (subs, selection, active) ->
  #selection == 1

aegisub.register_macro script_dir .. script_name, script_description, make_yamaha_sign, make_yamaha_sign_validation
