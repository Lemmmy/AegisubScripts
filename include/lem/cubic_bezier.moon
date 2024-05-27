NEWTON_ITERATIONS = 4
NEWTON_MIN_SLOPE = 0.001
SUBDIVISION_PRECISION = 0.0000001
SUBDIVISION_MAX_ITERATIONS = 10

k_spline_table_size = 11
k_sample_step_size = 1.0 / (k_spline_table_size - 1.0)

A = (aA1, aA2) -> 1.0 - 3.0 * aA2 + 3.0 * aA1
B = (aA1, aA2) -> 3.0 * aA2 - 6.0 * aA1
C = (aA1) -> 3.0 * aA1

-- Returns x(t) given t, x1, and x2, or y(t) given t, y1, and y2.
calc_bezier = (aT, aA1, aA2) ->
  ((A(aA1, aA2) * aT + B(aA1, aA2)) * aT + C(aA1)) * aT

-- Returns dx/dt given t, x1, and x2, or dy/dt given t, y1, and y2.
get_slope = (aT, aA1, aA2) ->
  3.0 * A(aA1, aA2) * aT * aT + 2.0 * B(aA1, aA2) * aT + C(aA1)

binary_subdivide = (aX, aA, aB, mX1, mX2) ->
  current_x, current_t, i = 0, 0, 0
  while i < SUBDIVISION_MAX_ITERATIONS
    i += 1
    current_t = aA + (aB - aA) / 2.0
    current_x = calc_bezier(current_t, mX1, mX2) - aX
    if current_x > 0.0
      aB = current_t
    else
      aA = current_t
    if Math.abs(current_x) < SUBDIVISION_PRECISION
      break
  current_t

newton_raphson_iterate = (aX, aGuessT, mX1, mX2) ->
  current_slope, current_x = 0, 0
  for i = 0, NEWTON_ITERATIONS do
    current_slope = get_slope(aGuessT, mX1, mX2)
    if current_slope == 0.0
      return aGuessT
    current_x = calc_bezier(aGuessT, mX1, mX2) - aX
    aGuessT -= current_x / current_slope
  aGuessT

cubic_bezier = (mX1, mY1, mX2, mY2) ->
  if not (0 <= mX1 and mX1 <= 1 and 0 <= mX2 and mX2 <= 1)
    error "bezier x values must be in [0, 1] range"
  if mX1 == mY1 and mX2 == mY2
    return (aX) -> aX

  -- Precompute samples table
  sample_values = {}
  for i = 0, k_spline_table_size do
    sample_values[i] = calc_bezier(i * k_sample_step_size, mX1, mX2)

  get_t_for_x = (aX) ->
    interval_start, current_sample = 0, 1
    last_sample = k_spline_table_size - 1

    dist = 0
    while current_sample ~= last_sample and sample_values[current_sample] <= aX
      interval_start += k_sample_step_size
      current_sample += 1
    current_sample -= 1

    -- Interpolate to provide an initial guess for t
    dist = (aX - sample_values[current_sample]) / (sample_values[current_sample + 1] - sample_values[current_sample])
    current_sample * k_sample_step_size + dist

    -- Perform a sequence of invocations of newtonRaphsonIterate to refine the root.
    initial_slope = get_slope(interval_start, mX1, mX2)
    if initial_slope >= NEWTON_MIN_SLOPE
      newton_raphson_iterate(aX, interval_start, mX1, mX2)
    else if initial_slope == 0.0
      interval_start
    else
      binary_subdivide(aX, interval_start, interval_start + k_sample_step_size, mX1, mX2)

  (x) -> calc_bezier(get_t_for_x(x), mY1, mY2)

cubic_bezier
