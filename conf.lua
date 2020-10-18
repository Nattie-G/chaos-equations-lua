function love.conf(t)
    t.window.title = "chaos equations"
    t.window.width = 2400
    t.window.height = 1300

    t.modules.audio = false
    t.modules.graphics = true           -- Enable the graphics module (boolean)
    t.modules.image = false
    t.modules.joystick = false
    t.modules.mouse = false
    t.modules.physics = false
    t.window.resizable = false
    t.modules.sound = false
    t.modules.thread = false             -- Enable the thread module (boolean)
    t.modules.touch = false              -- Enable the touch module (boolean)
    t.modules.video = false              -- Enable the video module (boolean)
end
