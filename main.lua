function love.load()
  WIDTH, HEIGHT = love.graphics.getDimensions()
  my_func = make_function() -- string
 -- SCALE = 0.0015
  SCALE = 450
  STEP = 1 / 10
  t = - 0.8
  -- possibly unnecessary global
  history = {}
  n_points = 200
  constant_time = false
  --love.graphics.setBackgroundColor(0.05, 0.15, 0.25, 0.50)
  canv1 = love.graphics.newCanvas()
  canvbg = love.graphics.newCanvas()
  love.graphics.setCanvas(canvbg)
  love.graphics.clear(0, 0, 0, 0.05)
  love.graphics.setCanvas()
end

function love.keypressed(key)
  if love.keyboard.isDown('t') then
    t = -0.8
  elseif love.keyboard.isDown('r') then
    my_func = make_function()
    t = -0.8
  end
end

function love.update(dt)
  --love.timer.sleep(1/200)
  table.insert(history, 1, solve(my_func, n_points))
  if #history > 30 then table.remove(history) end
  -- update time based on interest index
  --local interest = interest_index(history[2], history[1])
  interest = interest2(history)
  if constant_time == true then
    interest = 1
  end
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

function draw_text()
  love.graphics.setColor(1, 1, 1)
  local seperator = string.find(my_func, ',')
  local equation_1 = string.sub(my_func, 9, seperator)
  local equation_2 = string.sub(my_func, seperator + 2, -2)
  local interest_val = string.sub(tostring(interest), 1, 4)
  local t_text = string.sub(tostring(t), 1, 5)
  if t > 0 then
    t_text = string.sub(tostring(t), 1, 4)
  end
  love.graphics.print('x\' = ' .. equation_1, 60, 45, 0, 4, 4)
  love.graphics.print('y\' = ' .. equation_2, 60, 100, 0, 4, 4)
  love.graphics.print('t = '.. t_text, 60, 180, 0, 4, 4)
  love.graphics.print("interest " .. interest_val, 60, 300, 0, 4, 4)
end


function love.draw()

  love.graphics.setBlendMode("alpha", "alphamultiply")
  love.graphics.setCanvas(canv1)
  love.graphics.draw(canvbg)
  love.graphics.setBlendMode("add", "premultiplied")

  local length = #history
  local limit = #history[length]

  for i=1, limit do
    local p = plot_point(history[1][i])
    --local q = plot_point(history[2][i])
    --TODO avoid drawing lines off screen
    love.graphics.setColor(unique_colour(i))
    --love.graphics.setColor(1, 1, 1)
    if love.keyboard.isDown('q') then
      love.graphics.setLineWidth(2)
      --love.graphics.line(p[1], p[2], q[1], q[2])
    end
    love.graphics.circle("fill", p[1], p[2], 5.0)
  end

  love.graphics.setColor(1, 1, 1)

  love.graphics.setBlendMode("alpha", "alphamultiply")
  --love.graphics.setBlendMode("lighten", "premultiplied")
  love.graphics.setCanvas() -- send focus to the screen
  love.graphics.draw(canv1)
  --
  love.graphics.setBlendMode("alpha", "alphamultiply")
  draw_text()
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

  local tally = 0
  for _, p in ipairs(history[1]) do
    if is_on_screen(p) then
      tally = tally + 1
    end
  end
  local adjustment = 1
  if tally == 0 then
    adjustment = 0.01
  else
    desiredspeed = 200 --pixels per second
  end

  return nil
end

function interest2(history)
  local tally = 0

  if #history < 2 then
    --tally points on screen
    return 1
  end

  local on_screen = {}
  local last_frame = {}
  for index, point in ipairs(history[1]) do
    if is_on_screen(point) then
      tally = tally + 1
      on_screen[index] = point
      last_frame[index] = history[2][i]
    end
  end

  count_multiplier = math.max((600 - tally) / 500, 0.88)
  distances = {}
  biggest_dist = 0
  for i, p in pairs(on_screen) do
    q = history[2][i]
    d = distance(p, q)
    table.insert(distances, d)
    biggest_dist = (d < biggest_dist) and biggest_dist or d
  end

  local speed_fix = 1
  if biggest_dist > 15 then
    speed_fix = (15 / biggest_dist)
    return speed_fix * count_multiplier
  end

  local area_factor = 1
  local min_x, min_y = WIDTH, WIDTH
  local max_x, max_y = 0, 0
  local x_accum, y_accum = 0, 0
  for i, p in pairs(on_screen) do
    local screen_point = plot_point(p)
    x_accum = x_accum + p[1]
    y_accum = y_accum + p[2]
    min_x = (min_x < p[1]) and min_x or p[1]
    min_y = (min_y < p[2]) and min_y or p[2]
    max_x = (max_x > p[1]) and max_x or p[1]
    max_y = (max_y > p[2]) and max_y or p[2]
  end
  local mid_point = {x_accum / #on_screen, y_accum / #on_screen}
  local bbox = {min_x, min_y, max_x, max_y}
  local dx = math.max(max_x - min_x, 1)
  local dy = math.max(max_y - min_y, 1)
  local area = dx * dy
  local theo_max = math.sqrt(WIDTH * HEIGHT)
  local area_factor = theo_max / math.sqrt(area)
  local adjusted_area_factor = math.max((1.4 * area_factor) / theo_max, 0.4)

  return speed_fix * count_multiplier * adjusted_area_factor
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

function lerp_colour(n)
  local grads = n_points

  local red = n / grads
  local green = 0.75 - (0.5 * red)
  local blue = 0.2 + 0.8 * red
  return {red, green, blue}
end

function unique_colour(i) -- i <= 1000
  local grad = 29.5
  local r, g, b = HSV((i * grad) % 365, 100, 100)
  --print("r, g, b, i", r, g, b, i)
  return {r / 255, g / 255, b / 255}
end

-- Converts HSV to RGB. (input and output range: 0 - 255)
-- sourced from https://love2d.org/wiki/HSV_color
 
function HSV(h, s, v)
  --print("HSV func: h =", h)
  if s <= 0 then return v,v,v end
  h, s, v = h/256*6, s/255, v/255
  local c = v*s
  local x = (1-math.abs((h%2)-1))*c
  local m,r,g,b = (v-c), 0,0,0
  if h < 1     then r,g,b = c,x,0
  elseif h < 2 then r,g,b = x,c,0
  elseif h < 3 then r,g,b = 0,c,x
  elseif h < 4 then r,g,b = 0,x,c
  elseif h < 5 then r,g,b = x,0,c
  else              r,g,b = c,0,x
  end return (r+m)*255,(g+m)*255,(b+m)*255
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

