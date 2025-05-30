import floor, pow, max, sin, cos, pi, sqrt from math

util = require "aegisub.util"
require "karaskel"
require "json"

--------------------------------------------------------------------------------
-- ASS tags
--------------------------------------------------------------------------------

pos = (x, y) ->
  "\\pos(#{x},#{y})"
rect = (x1, y1, x2, y2) ->
  "m #{x1} #{y1} l #{x2} #{y1} l #{x2} #{y2} l #{x1} #{y2} l #{x1} #{y1}"
clip = (x1, y1, x2, y2) ->
  "\\clip(#{x1},#{y1},#{x2},#{y2})"
alpha_lerp = (i) ->
  "\\alpha#{util.interpolate_alpha i, "&HFF&", "&H00&"}"

clean_tags = (text) ->
  text\gsub "{}", ""
remove_pos = (text) ->
  clean_tags text\gsub "\\pos%([%d%.]+,%s*[%d%.]+%)", ""

-- Get the X and Y position from the first available \pos tag, or nil if not found
parse_pos = (text) ->
  x, y = text\match "\\pos%(([%d%.]+),%s*([%d%.]+)%)"
  if x ~= nil and y ~= nil
    return tonumber(x), tonumber(y)
  else
    return nil, nil

-- Same as parse_pos, but returns 0, 0 if no \pos tag is found
parse_pos_zero = (text) ->
  x, y = parse_pos text
  return x or 0, y or 0

alignments = {
  bottom_left: 1
  bottom_center: 2
  bottom_right: 3
  center_left: 4
  center: 5
  center_right: 6
  top_left: 7
  top_center: 8
  top_right: 9
}

--------------------------------------------------------------------------------
-- Easing
--------------------------------------------------------------------------------

cubic_bezier = require "lem.cubic_bezier"
ease_in_out_sine  = (x) -> (1 - cos(x * pi)) / 2
ease_in_out_quad  = (x) -> if x < 0.5 then 2 * x^2 else 1 - (-2 * x + 2)^2 / 2
ease_in_out_cubic = (x) -> if x < 0.5 then 4 * x^3 else 1 - (-2 * x + 2)^3 / 2
ease_in_out_quart = (x) -> if x < 0.5 then 8 * x^4 else 1 - (-2 * x + 2)^4 / 2
ease_in_out_quint = (x) -> if x < 0.5 then 16 * x^5 else 1 - (-2 * x + 2)^5 / 2
ease_in_out_expo  = (x) -> if x == 0 then 0 else if x == 1 then 1 else if x < 0.5 then 2^(20 * x - 10) / 2 else (2 - 2^(-20 * x + 10)) / 2
ease_in_out_circ  = (x) -> if x < 0.5 then (1 - sqrt(1 - pow(2 * x, 2))) / 2 else (sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2
ease_yamaha = cubic_bezier 0.6, 0.11, 0.29, 0.81

remap_full = (in_min, in_max, out_min, out_max, x) -> (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
remap = (out_min, out_max, x) -> remap_full 0, 1, out_min, out_max, x

--------------------------------------------------------------------------------
-- Lines
--------------------------------------------------------------------------------

make_line = -> {
  actor: "",
  class: "dialogue",
  comment: false,
  effect: "",
  start_time: 0,
  end_time: 5000,
  layer: 0,
  margin_l: 0,
  margin_r: 0,
  margin_t: 0,
  margin_b: 0,
  margin_v: 0,
  section: "[Events]",
  style: "Default",
  text: "",
  extra: {}
}

make_basic_line = (text, start_time, end_time, style) ->
  with make_line!
    .text = text
    .start_time = start_time
    .end_time = end_time
    .style = style

make_style = -> {
  class: "style",
  section: "[V4+ Styles]",

  name: "Default",

  align: 5,
  relative_to: 2, -- unsupported

  angle: 0,     -- degrees
  scale_x: 100, -- percent
  scale_y: 100, -- percent

  color1: "&H00FFFFFF&", -- primary color
  color2: "&H000000FF&", -- secondary color (e.g. for karaoke)
  color3: "&H00000000&", -- outline color
  color4: "&HB4000000&", -- shadow color

  encoding: 1, -- Windows font encoding ID
  fontname: "Arial",
  fontsize: 48,

  margin_b: 0,
  margin_l: 0,
  margin_r: 0,
  margin_t: 0,

  borderstyle: 1, -- 1 for outline + shadow, 3 for opaque box behind subs
  outline: 0,     -- in pixels
  shadow: 0,      -- in pixels
  spacing: 0,     -- in pixels

  bold: false,
  italic: false,
  strikeout: false,
  underline: false,

  extra: {},
}

--------------------------------------------------------------------------------
-- Folds
--------------------------------------------------------------------------------

-- https://github.cocom/TypesettingTools/arch1t3cht-Aegisub-Scripts/blob/7eac78b382ae93e54e867a7bd95d2de9653c2936/macros/arch.ConvertFolds.moon#L21-L28
fold_key = "_aegi_folddata"
parse_line_fold = (line) ->
  return if not line.extra

  info = line.extra[fold_key]
  return if not info

  side, collapsed, id = info\match("^(%d+);(%d+);(%d+)$")
  return { :side, :collapsed, :id }

-- Parse the extradata section of the subtitle file to find the highest fold id, or return 0 if none is found
find_highest_fold_id = (subs) ->
  fold_id = 0

  for i, line in ipairs subs
    fold = parse_line_fold line
    fold_id = max fold_id, (fold.id or 0) if fold

  fold_id

insert_fold_line = (subs, text, t_start, t_end, style, fold_id) ->
  type_id = if fold_id then 1 else 0
  fold_id = fold_id or (find_highest_fold_id subs) + 1

  subs.append with make_basic_line text, t_start, t_end, style
    .comment = true
    .extra = { [fold_key]: "#{type_id};1;#{fold_id}" }

  fold_id

--------------------------------------------------------------------------------
-- Configs
--------------------------------------------------------------------------------
config_base = "?user/config"

load_config = (config_name) ->
  config = {}
  config_path = aegisub.decode_path "#{config_base}/#{config_name}.json"
  file = io.open config_path, "r"
  if file
    config = json.decode file\read "*a"
    file\close!
  config

save_config = (config_name, config) ->
  config_path = aegisub.decode_path "#{config_base}/#{config_name}.json"
  file = io.open config_path, "w"
  file\write json.encode config
  file\close!

--------------------------------------------------------------------------------
-- Returns
--------------------------------------------------------------------------------

{
  :pos, :rect, :clip, :alpha_lerp,

  :alignments,

  :clean_tags, :remove_pos, :parse_pos, :parse_pos_zero,

  :ease_in_out_sine, :ease_in_out_quad, :ease_in_out_cubic, :ease_in_out_quart, :ease_in_out_quint, :ease_in_out_expo,
  :ease_in_out_circ, :cubic_bezier, :ease_yamaha, :remap_full, :remap,

  :make_line, :make_basic_line, :make_style,

  :insert_fold_line,

  :load_config, :save_config,
}
