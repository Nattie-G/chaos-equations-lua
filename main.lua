local slab = require 'Slab'
options = { trails      = true, colour      = true,
            number      = 200 , step        = 5/100,
            zoom_speed  = 10  , slow_speed  = 0.2 ,
            point_size  = 2   , show_text   = true,
            scale_factor = 1.0,
            interest_scaling  = true,
            dynamic_scaling   = true,
          }

function love.load()
  window_width, window_height = best_window_size()
  WIDTH  = window_width  / options.scale_factor
  HEIGHT = window_height / options.scale_factor
  love.window.setMode(best_window_size())

  text_fnt, slab_fnt = make_fonts()
  slab.Initialize()
  slab.PushFont(slab_fnt)

  cam_x = 0
  cam_y = 0
  mouse_x, mouse_y = love.mouse.getPosition()
  mouse_pressed = false

  SCALE = 300
  t = -1.2
  func_history = {}
  my_func = make_function()
  history = {}
  tally = 0
  canv1 = love.graphics.newCanvas(WIDTH, HEIGHT)
  canvbg = love.graphics.newCanvas(WIDTH, HEIGHT)
  love.graphics.setCanvas(canvbg)
  love.graphics.clear(0, 0, 0, 0.048)
  love.graphics.setCanvas()
  PAUSED = false
  dynamic_speed_factor = 1.0
end

function best_window_size()
  local screen_width, screen_height = love.window.getDesktopDimensions()
  return screen_width - 200, screen_height - 200
  --return 1400, 900
end

function make_fonts()
  local s1, s2
  if window_width < 1200 then
    s1 = 25
    s2 = 15
  elseif window_width < 1400 then
    s1 = 30
    s2 = 20
  elseif window_width < 1600 then
    s1 = 35
    s2 = 25
  elseif window_width < 2200 then
    s1 = 40
    s2 = 30
  else
    s1 = 50
    s2 = 40
  end
  local fnt1 = love.graphics.newFont('Roboto-Regular.ttf', s1)
  local fnt2 = love.graphics.newFont('Raleway-VariableFont_wght.ttf', s2)
  return fnt1, fnt2
end

function change_function(func)
  my_func = func
  t = -1.2
  dynamic_speed_factor = 1
  cam_x = 0
  cam_y = 0
end

function love.keypressed(key)
  if key == 't' then
    t = -1.2
    dynamic_speed_factor = 1
  elseif key == 'b' and #func_history > 1 then
    table.remove(func_history)
    change_function(func_history[#func_history])
  elseif key == 'n' then
    change_function(make_function())
  elseif key == 'p' then
    PAUSED = not PAUSED
  elseif key == 'space' then
    cam_x = 0
    cam_y = 0
  end
end

-- resizing doesn't quite work properly
function love.resize(w, h)
  WIDTH  = w  / options.scale_factor
  HEIGHT = h / options.scale_factor
end

-- adjust the scale of the graph with the mouse wheel
function love.wheelmoved(x, y)
  SCALE = math.max(SCALE + (y * 25), 1)
  if SCALE % 5 == 1 and SCALE > 1 then
    SCALE = SCALE - 1
  end
end

function drag_screen()
  if love.mouse.isDown(2) then
    if mouse_pressed then
      cam_x = cam_x + (love.mouse.getX() - mouse_x)
      cam_y = cam_y + (love.mouse.getY() - mouse_y)
      mouse_x, mouse_y = love.mouse.getPosition()
    else
      mouse_pressed = true
      mouse_x, mouse_y = love.mouse.getPosition()
    end
  else
    mouse_pressed = false
    mouse_x, mouse_y = love.mouse.getPosition()
  end
end

function love.update(dt)
  slab.Update(dt)
  create_options_window()
  love.timer.sleep(1/120)
  drag_screen()

  if PAUSED then
    return
  end
  table.insert(history, 1, solve(my_func, options.number))
  if #history > 30 then table.remove(history) end

  local tally = 0
  local on_screen = {}
  for index, point in ipairs(history[1]) do
    if is_on_screen(point) then
      tally = tally + 1
      on_screen[index] = point
    end
  end

  interest = interest2(history, on_screen, tally)
  adjust_dynamic_speed(on_screen, tally)
  local speed_mult = interest * dynamic_speed_factor

  local key_adjustment = 1
  if love.keyboard.isDown('z') then
    key_adjustment = key_adjustment * options.zoom_speed
  end
  if love.keyboard.isDown('x') then
    key_adjustment = key_adjustment * options.slow_speed
  end
  if love.keyboard.isDown('c') then
    key_adjustment = -1 * key_adjustment
  end

  t = t + (dt * options.step * dynamic_speed_factor * key_adjustment)

  if (t > 1.2) and interest >= 1 then
    change_function(make_function())
  end
end

function draw_text()
  if not options.show_text then
    return
  end
  love.graphics.setFont(text_fnt)
  love.graphics.setColor(1, 1, 1)
  local seperator = string.find(my_func, ',')
  local equation_1 = string.sub(my_func, 9, seperator)
  local equation_2 = string.sub(my_func, seperator + 2, -2)
  local interest_val = string.sub(tostring(interest), 1, 4)
  local speed_factor = string.sub(tostring(dynamic_speed_factor), 1, 4)
  local speed_text = string.sub(tostring(dynamic_speed_factor * interest), 1, 3)
  local t_text = string.sub(tostring(t), 1, 5)
  if t > 0 then
    t_text = string.sub(tostring(t), 1, 4)
  end
  love.graphics.print('x\' = ' .. equation_1, 60, 45, 0, 1)
  love.graphics.print('y\' = ' .. equation_2, 60, 100, 0, 1)
  love.graphics.print('t = '.. t_text .. '\t\t\t\t\t\t\tscale ' .. tostring(SCALE) .. 'x', 60, 180, 0, 1)
  --love.graphics.print("scale " .. tostring(SCALE) .. "x", 450, 180, 0, 1)
  love.graphics.print("speed " .. speed_text, 60, 250, 0, 1)
end

function create_options_window()
  local opts
  if window_width < 1200 then
    opts = {X = window_width * 0.75}
  else
    opts = {X = window_width * 0.85}
  end
  slab.BeginWindow('optionsWindow', opts)

  if slab.CheckBox(options.colour, 'colour', {Size = 40}) then
    options.colour = not options.colour
  end

  if slab.CheckBox(options.trails, 'trails', {Size = 40}) then
    options.trails = not options.trails
  end

  if slab.CheckBox(options.show_text, 'debug text', {Size = 40}) then
    options.show_text = not options.show_text
  end

  if slab.CheckBox(not options.dynamic_scaling, 'constant time', {Size = 40}) then
    options.interest_scaling = not options.dynamic_scaling
    options.dynamic_scaling  = not options.dynamic_scaling
  end

  slab.Text('point size')
  if slab.InputNumberSlider('pointSizeSlider', options.point_size, 1, 5, {Precision = 1}) then
    options.point_size = slab.GetInputText()
  end

  slab.Text('time step')
  if slab.InputNumberSlider('timeStepSlider', options.step * 100, 1, 10, {Precision = 0}) then
    options.step = slab.GetInputText() / 100
  end

  slab.Text('scale factor')
  if slab.InputNumberSlider('scaleSlider', options.scale_factor, 1, 3, {Precision = 1}) then
    options.scale_factor = slab.GetInputText()
    love.resize(window_width, window_height)
  end

  slab.EndWindow()
end

function love.draw()
  if PAUSED then
    love.graphics.translate(cam_x, cam_y)
    love.graphics.draw(canv1, 0, 0, 0, options.scale_factor)
    love.graphics.origin()
    draw_text()
    slab.Draw()
    return
  end


  love.graphics.setCanvas(canv1)
  love.graphics.setBlendMode("alpha", "alphamultiply")


  if options.trails then
    love.graphics.draw(canvbg, 0, 0, 0, options.scale_factor)
    love.graphics.setBlendMode("add", "premultiplied")
  else
    love.graphics.clear(0, 0, 0)
  end

  local length = #history
  local limit = #history[length]

  love.graphics.setColor(1, 1, 1)
  for i=1, limit do
    if is_on_screen(history[1][i]) then
      local p = plot_point(history[1][i])
      if options.colour then
        love.graphics.setColor(unique_colour(i))
      end
      love.graphics.circle("fill", p[1], p[2], options.point_size)
    end
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.setBlendMode("alpha", "alphamultiply")
  love.graphics.setCanvas() -- send focus to the screen
  love.graphics.translate(cam_x, cam_y)
  love.graphics.draw(canv1, 0, 0, 0, options.scale_factor)
  love.graphics.origin()

  draw_text()
  slab.Draw()
end

-- helper function for solve(f, n) uses globals so lua's load()
-- can read our function instead of having to parse it manually
function apply_f(f, q)
  x, y = q[1], q[2]
  local p = load(f)()
  x, y = nil, nil
  return p
end

-- this function was adapted from 
-- https://gist.github.com/jnez71/7105e3c2410fda1bef500ff8801a710f
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
  return math.sqrt((p[1] - q[1])^2 + (p[2] - q[2])^2)
end

function remap(i, low1, high1, low2, high2)
  local val = low2 + (i - low1) * (high2 - low2) / (high1 - low1)
  if (val > high2) and (val > low2) then return math.max(high2, low2) end
  if (val < low2) and (val < high2) then return math.min(high2, low2) end
  return val
end


function interest2(history, on_screen, tally)
--[[
the second iteration of my "interest" function attempts to optimize
play speed by evaluating how interesting the current state is.
currently, it relies on two metrics and maps them to multipliers
between 0.5 and 2.0. the product of the multiplier is used in the
update function to multiply delta time. the current factors used are
the fraction of points on the screen and the area of screen covered
--]]
  if not options.interest_scaling or (#history < 2) then
    return 1
  end

  count_multiplier = remap(tally, 0, options.number, 1.5, 0.5)

  local min_x, min_y = WIDTH, HEIGHT
  local max_x, max_y = 0, 0
  local x_accum, y_accum = 0, 0
  for i, p in pairs(on_screen) do
    local screen_coords = plot_point(p)
    x_accum = x_accum + screen_coords[1]
    y_accum = y_accum + screen_coords[2]
    min_x = (min_x < screen_coords[1]) and min_x or screen_coords[1]
    min_y = (min_y < screen_coords[2]) and min_y or screen_coords[2]
    max_x = (max_x > screen_coords[1]) and max_x or screen_coords[1]
    max_y = (max_y > screen_coords[2]) and max_y or screen_coords[2]
  end
  local dx = math.max(max_x - min_x, 1)
  local dy = math.max(max_y - min_y, 1)

  -- using cube roots to compare screen area diminishes
  -- the difference in order of magnitude for typical comparisons
  local area_root = (dx * dy)^(1/3)
  local screen_root = (WIDTH * HEIGHT)^(1/3)
  local area_factor = area_root / screen_root
  local adjusted_area_factor = remap(area_factor, 0, 1, 2.0, 0.5)
  return count_multiplier * adjusted_area_factor
end

function adjust_dynamic_speed(on_screen, tally)
--[[
this function could possibly replace the interest function approach
but currently operates alongside it. speed is adjusted in a rolling
fashion by using a multiplier to adjust away from extremes of low and
high speed. it actually works quite well
--]]
  if not options.dynamic_scaling or (#history < 2) then
    return 1
  end
  biggest_dist = #on_screen == 0 and 1 or 0
  --smallest_dist = 1000
  for i, point in pairs(on_screen) do
    p = plot_point(point)
    q = plot_point(history[2][i])
    d = distance(p, q)
    biggest_dist  = (d < biggest_dist) and biggest_dist or d
    --smallest_dist = (d > smallest_dist) and smallest_dist or d
  end

  local speed_fix = dynamic_speed_factor -- 1
  if biggest_dist < (options.step * 60) then
    speed_fix = math.min((options.step * 60) / biggest_dist, 10)
  elseif biggest_dist > (options.step * 1000) then
    speed_fix = math.max((options.step * 1600) / biggest_dist, 0.01)
  end
  dynamic_speed_factor = (dynamic_speed_factor * 0.95) + (speed_fix * 0.05)
  --print("biggest_dist", biggest_dist)
end

function plot_point(q) -- convert graph coords to screen coords
  return {(q[1] * SCALE) + (WIDTH / 2) + cam_x, (q[2] * SCALE) + (HEIGHT / 2) + cam_y}
end


function unique_colour(i) -- i <= 1000
  local grad = 49.5
  return HSV((i * grad) % 365, 100, 90)
end

 
function HSV(h, s, v)
  -- Converts HSV to RGB. (input and output range: 0 - 1)
  -- adapted from https://love2d.org/wiki/HSV_color
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
  end return {(r+m), (g+m), (b+m)}
end



function make_function()
  -- helper function
  function new_term(term, coefficients)
    local root = string.sub(tostring(term), 1, 1)
    local coefs = { root == 'x' and 'y' or 'x',
                    root == 't' and 'y' or 't'
      }
    local append_coefs = {
        coefs[1] .. '*' .. coefs[2] .. '*' .. term, -- coef 1 & 2
        coefs[1] .. '*' .. term,                    -- coef 1
        coefs[2] .. '*' .. term,                    -- coef 2
        term                                        -- no coef
      }

    local full_term = append_coefs[love.math.random(1, 4)]
    local sign_or_zero = {'-' .. full_term, '0' , full_term}
    local signed_full_term = sign_or_zero[love.math.random(1, 3)]
    return signed_full_term
  end

  local rules = {}
  local coefficients = {'t', 'x', 'y'}
  for i = 1, 2 do
    -- x^2 term
    local xx = new_term('x^2')
    -- y^2 term
    local yy = new_term('y^2')
    -- t^2 term
    local tt = new_term('t^2')
    -- x term
    local x = new_term('x')
    -- y term
    local y = new_term('y')
    -- t term
    local t = new_term('t')
    rules[i] =  (xx .. ' + ' .. yy .. ' + ' .. tt
      .. ' + ' .. x  .. ' + ' .. y  .. ' + ' .. t)
  end
  local func = 'return {' .. rules[1] .. ', ' .. rules[2] .. '}'
  --local func = 'return {custom x function, custom y function}'
  print("my_func", func)
  table.insert(func_history, func)
  return func
end
