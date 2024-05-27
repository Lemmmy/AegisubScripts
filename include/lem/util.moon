util = require "aegisub.util"
require "karaskel"

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

--------------------------------------------------------------------------------
-- Folds
--------------------------------------------------------------------------------

-- https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts/blob/7eac78b382ae93e54e867a7bd95d2de9653c2936/macros/arch.ConvertFolds.moon#L21-L28
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
-- Returns
--------------------------------------------------------------------------------

{
  :pos, :rect, :clip, :alpha_lerp,

  :clean_tags, :remove_pos, :parse_pos,

  :ease_in_out_sine, :ease_in_out_quad, :ease_in_out_cubic, :ease_in_out_quart, :ease_in_out_quint, :ease_in_out_expo,
  :ease_in_out_circ, :cubic_bezier, :ease_yamaha,

  :make_line, :make_basic_line,

  :insert_fold_line
}
