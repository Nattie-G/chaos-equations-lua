function love.load()
  WIDTH, HEIGHT = love.graphics.getDimensions()
  my_func = make_function() -- string
 -- SCALE = 0.0015
  SCALE = 350
  STEP = 10 / 10
  t = -1.2
  -- possibly unnecessary global
  visible_points_total = 0
  history = {{}, {}, {}, {}, {}}
  n_points = 200
end

function love.keypressed(key)
  if love.keyboard.isDown('t') then
    t = -1.2
  elseif love.keyboard.isDown('r') then
    my_func = make_function()
    t = -1.2
  end
end

function love.update(dt)
  love.timer.sleep(1/200)
  table.insert(history, 1, solve(my_func, n_points))
  if #history > 5 then table.remove(history) end
  -- update time based on interest index
  local interest = interest_index(history[2], history[1])
  local next_t = t + (dt * STEP * interest)
  if love.keyboard.isDown('z') then
    t = t + (30 * dt * STEP * interest)
  elseif love.keyboard.isDown('x') then
    t = t + (0.1 * dt * STEP * interest)
  elseif love.keyboard.isDown('c') then
    t = t - (dt * STEP)
  else 
    t = t + (dt * STEP * interest)
  end
  -- do additional testing for new dots "blinking in" here
end

function love.draw()
  local length = #history
  local limit = #history[length]
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("time: " .. tostring(t))
  for i=1, limit do
    local p = plot_point(history[length - 3][i])
    local q = plot_point(history[1][i])
    --TODO avoid drawing lines off screen
    love.graphics.setColor(lerp_colour(i))
    if love.keyboard.isDown('q') then
      love.graphics.setLineWidth(3)
      love.graphics.line(p[1], p[2], q[1], q[2])
    end
    love.graphics.circle("fill", p[1], p[2], 3.5)
  end

end

function custom_solve(func, time, number)
  local q = {time, time}
  local Q = {}
  for i = 1, number do
    q = apply_f(func, q)
    Q[i] = q
  end
  return Q
end


function apply_f(f, q)
  x, y = q[1], q[2]
  local p = load(f)()
  x, y = nil, nil
  return p
end

function solve(f, n)
  local q = {t, t}
  local Q = {}
  for i = 1, n do
     q = apply_f(f, q)
    Q[i] = q
  end
  return Q
end

function is_on_screen(q)
  local p = plot_point(q)
  local tests = {math.min(p[1], p[2]) > 0, p[1] < WIDTH, p[2] < HEIGHT}
  return tests[1] and tests[2] and tests[3]
end

function distance(p, q)
  return math.sqrt((p[1] - q[1])^2 + (p[2] - q[1])^2)
end

function speed_fix(history)
  --[[  ideas
  1. look 10 frames ahead, identify any "jumps," fix "keyframes"
  and smoothe out speed transitions.
  2. if these N frames don't have high "interest" or high speed
  movement, adjust the step upwards
  3. In the case of sufficiently low-interest stetches, conduct
  an extended search to identify the next "hotspot" and smoothe
  fast-forward to there


  1. consider the whole period from -2 < t < 2 at a fine scale
  2. identify "hot," "cold" and "dead" stretches
  3. identify appropriate speed curve for each hot spot
  4. optimise each hot-spot's keyframes and fix pop-in?
  5. arrange "frames" as a table of t-values
    (reverse play order for better efficiency)
  6. generate "in-between" or skip existing frames based on user interaction


  1. just rewrite the "interest function" to be better
  2. clamp speed more aggressively where appropriate
  3. use rolling interest value that updates each frame?
  --]]
  --for p in history[1] do
  --end
  return nil
end


function interest_index(old_points, new_points)
  --[[ does this function garauntee a working output?
  speed is typically between .01 and 2
  maybe we should use seperate slow factors for speed
  and for number of dots.

  maybe use max speed instead of average speed?
  --]]
  local new = {}
  local old = {}
  local dists = {}
  for i=1, #old_points do
    --print("old_points[i] : new_points[i]", old_points[i], new_points[i])
    if is_on_screen(old_points[i]) and is_on_screen(new_points[i]) then
      table.insert(new, new_points[i])
      table.insert(old, old_points[i])
    end
  end
  local sum = 0
  for i=1, #new do
    dists[i] = distance(old[i], new[i])
    sum = sum + dists[i]
  end
  visible_points_total = #new -- visible_points_total is now accurate
  avg_distance_moved = sum / visible_points_total
  local index =
      (math.max(0.1, (n_points - visible_points_total)) / n_points) *
      (math.max(0.1, 15 / greatest(dists)))

  return math.min(10, index)
end

function greatest(tbl)
  local g = tbl[1]
  for i=1, #tbl do
    if tbl[i] > g then g = tbl[i] end
  end
  return g or 0
end

function plot_point(q)
  return {(q[1] * SCALE) + (WIDTH / 2), (q[2] * SCALE) + (HEIGHT / 2)}
end

function d3_string(c) -- int, string -> string OR nil
  -- string with positive or negative sign or remove the term
  -- 1 - negative term
  -- 2 - zero term
  -- 3 - positive term
  local ss = {'-' .. c, 0, c}
  return ss[love.math.random(1, 3)]
end

function d4_string(c, cc) -- int, string, table -> string
  -- string for term with (linear) coefficients
  -- 1 - coefficient 1 & 2
  -- 2 - coefficient 1 of 2
  -- 3 - coefficient 2 of 2
  -- 4 - no coefficient
  local ss = {
      cc[1] .. '*' .. cc[2] .. '*' .. c,
      cc[1] .. '*' .. c,
      cc[2] .. '*' .. c,
      c
    }
  return ss[love.math.random(1, 4)]
end

function make_function()
  local z = '0'
  local rules = {}
  local tx, ty, xy = {'t', 'x'}, {'t', 'y'}, {'x', 'y'}
  for i = 1, 2 do
    local xx = d3_string(d4_string('x^2', ty))
    -- y^2 term
    local yy = d3_string(d4_string('y^2', tx))
    -- t^2 term
    local tt = d3_string(d4_string('t^2', xy))
    -- x term
    local x = d3_string(d4_string('x', tx))
    -- y term
    local y = d3_string(d4_string('y', ty))
    -- t term
    local t = d3_string(d4_string('t', xy))
    rules[i] =  (xx .. ' + ' .. yy .. ' + ' .. tt
      .. ' + ' .. x  .. ' + ' .. y  .. ' + ' .. tt)
  end
  local func = 'return {' .. rules[1] .. ', ' .. rules[2] .. '}'
  --local func =  'return {t -t^2 - x*y, t -x*y + x*t + y}'
  --local func = 'return {x*t - (x^2 + t^2 + y*t + x), -x^2 + t^2 + x*t - x - y}'
  print("my_func", func)
  return func

end


function lerp_colour(n)
  local grads = n_points

  local red = n / grads
  local green = 0.5 - (0.5 * red)
  local blue = 0.2 + 0.8 * red
  return {red, green, blue}
end
