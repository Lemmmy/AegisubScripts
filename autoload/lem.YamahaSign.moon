export script_name        = "Yamaha sign"
export script_description = "Silly animated sign for a specific video"
export script_author      = "Lemmmy"
export script_version     = "1.0"

script_dir = ": Lemmmy :/"

import max from math
util = require "aegisub.util"
require "karaskel"

lem = require "lem.util"
{ :pos, :rect, :clip, :alpha_lerp, :clean_tags, :remove_pos, :make_basic_line } = lem

sign_x      = 97
sign_y      = 165
def_height  = 92
pad         = 16
blur        = 0.6
blur_t      = "\\blur(#{blur})"

swipe_time    = 1200
text_end_time = 1000
text_accel    = 0.4
text_move_n   = 10
text_x_off    = -3
text_y_off    = 3
scale         = 0.85
scale_time    = 500
scale_offset  = -2
bg2_offset    = 6
bg2_fade_f    = 5 -- number of frames to fade bg2 in/out for

ease_fn = lem.ease_yamaha

make_swipe_frames = (subs, f_start, f_end, sign_width, descent, clean_text, conf, reverse) ->
  frames = max f_end - f_start - 1, 1
  for i = 1, frames
    progress = (if reverse then frames - i else i) / frames
    i_start, i_end = aegisub.ms_from_frame(f_start + i), aegisub.ms_from_frame(f_start + i + 1)

    -- Background rectangle - width grows
    lerp_width = (ease_fn progress) * sign_width
    bg1_rect = rect sign_x, sign_y, sign_x + lerp_width, sign_y + conf.height
    bg1_text = "{#{blur_t}#{pos 0, 0}\\p1}#{bg1_rect}"
    subs.append with make_basic_line bg1_text, i_start, i_end, conf.bg1_style
      .layer = 1

    -- Text - slides in from 60% right to left, clipped by the rectangle's bounds
    text_start = sign_width * 0.6
    text_x = (sign_x + pad + text_start - (ease_fn progress) * text_start) + text_x_off
    text_y = sign_y + ((conf.height - descent) / 2) + text_y_off
    text_clip = clip sign_x, sign_y, sign_x + lerp_width, sign_y + conf.height
    main_text = "{#{blur_t}#{pos text_x, text_y}#{text_clip}}#{clean_text}"
    subs.append with make_basic_line main_text, i_start, i_end, conf.text_style
      .layer = 2

make_scale_frames = (subs, f_start, f_end, t_end, sign_width, descent, clean_text, conf, reverse) ->
  frames = max f_end - f_start - 1, 1
  for i = 1, frames
    progress = (if reverse then frames - i else i) / frames
    i_start = aegisub.ms_from_frame(f_start + i)
    i_end = if i >= frames and not reverse then t_end else aegisub.ms_from_frame(f_start + i + 1)

    -- Scale is interpolated from 1.0 to `scale` (0.85)
    lerp_scale = 1 - (ease_fn progress) * (1 - scale)

    -- When it scales, it also moves slightly to the left and up. Apply an offset
    all_eased_offset = scale_offset * (ease_fn progress)

    -- Background rectangle 2 (purple) - starts the same size as bg1, and shrinks to the same size, but also gains an
    -- offset of `bg2_offset` pixels to the bottom right.
    bg2_eased_offset = bg2_offset * (ease_fn progress)
    bg2_rect = rect(
      sign_x + all_eased_offset + bg2_eased_offset,
      sign_y + all_eased_offset + bg2_eased_offset,
      sign_x + (sign_width * lerp_scale) + all_eased_offset + bg2_eased_offset,
      sign_y + (conf.height * lerp_scale) + all_eased_offset + bg2_eased_offset
    )
    -- Also fade in/out the bg2 for a few frames, to hide small scaling artifacts
    bg2_alpha = if not reverse and i < bg2_fade_f then
      i / bg2_fade_f
    else if reverse and i >= frames - bg2_fade_f then
      (frames - i) / bg2_fade_f
    else 1
    bg2_text = "{#{blur_t}#{pos 0, 0}#{alpha_lerp bg2_alpha}\\p1}#{bg2_rect}"
    subs.append with make_basic_line bg2_text, i_start, i_end, conf.bg2_style
      .layer = 0

    -- Background rectangle 1 (white) - shrink from the top left.
    bg1_rect = rect(
      sign_x + all_eased_offset,
      sign_y + all_eased_offset,
      sign_x + (sign_width * lerp_scale) + all_eased_offset,
      sign_y + (conf.height * lerp_scale) + all_eased_offset
    )
    bg1_text = "{#{blur_t}#{pos 0, 0}\\p1}#{bg1_rect}"
    subs.append with make_basic_line bg1_text, i_start, i_end, conf.bg1_style
      .layer = 1

    -- Text - text is aligned with \an4, so use \fscx and \fscy to scale it, keeping it aligned to the new conf.height
    text_x = sign_x + pad + (text_x_off * lerp_scale) + all_eased_offset
    text_y = sign_y + (((conf.height - descent) * lerp_scale) / 2) + text_y_off + all_eased_offset
    text_scale = lerp_scale * 100
    main_text = "{#{blur_t}#{pos text_x, text_y}\\fscx#{text_scale}\\fscy#{text_scale}}#{clean_text}"
    subs.append with make_basic_line main_text, i_start, i_end, conf.text_style
      .layer = 2

make_yamaha_sign = (subs, selection) ->
  -- Config dialog
  conf = setup_yamaha_sign subs
  return if not conf

  -- Prepare karaskel stuff
  meta, styles = karaskel.collect_head subs

  -- Change the style of the line to the text style
  i = selection[1] + conf.ioff
  line = with subs[i]
    .style = conf.text_style

  -- Populate line size information
  karaskel.preproc_line subs, meta, styles, line

  text_height_base, descent = line.height - line.descent, line.descent
  sign_width = line.width + 2 * pad
  clean_text = remove_pos line.text

  t_start, t_end = line.start_time, line.end_time

  subs.delete i -- Remove the existing line

  -- Insert a comment line to mark the start of the sign, with fold data to easily hide it
  -- (folds require arch1t3cht's Aegisub fork)
  fold_id = lem.insert_fold_line subs, "Start Yamaha sign: #{clean_text}", t_start, t_end, conf.text_style

  -- Initial swipe-in animation
  f_start, f_end = aegisub.frame_from_ms(t_start), aegisub.frame_from_ms(t_start + swipe_time)
  make_swipe_frames subs, f_start, f_end, sign_width, descent, clean_text, conf

  -- The time that the swipe-out animation will play
  main_end = t_end - swipe_time - scale_time

  -- Shrink animation
  f_start, f_end = f_end - 1, aegisub.frame_from_ms(t_start + swipe_time + scale_time)
  make_scale_frames subs, f_start, f_end, main_end, sign_width, descent, clean_text, conf

  -- Expand animation
  f_start, f_end = aegisub.frame_from_ms(main_end) - 1, aegisub.frame_from_ms(main_end + scale_time)
  make_scale_frames subs, f_start, f_end, t_end, sign_width, descent, clean_text, conf, true

  -- Final swipe-out animation
  f_start, f_end = aegisub.frame_from_ms(t_end - swipe_time) - 1, aegisub.frame_from_ms(t_end)
  make_swipe_frames subs, f_start, f_end, sign_width, descent, clean_text, conf, true

  -- Insert a final comment line to mark the end of the sign, and the ending fold
  lem.insert_fold_line subs, "End Yamaha sign: #{clean_text}", t_end, t_end, conf.text_style, fold_id

  -- Done
  aegisub.set_undo_point script_name

make_yamaha_sign_validation = (subs, selection, active) ->
  #selection == 1

aegisub.register_macro script_dir .. script_name, script_description, make_yamaha_sign, make_yamaha_sign_validation
