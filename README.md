# chaos-equations-lua  
simple clone of hackerpoet's chaos equations https://github.com/HackerPoet/Chaos-Equations  
written in lua and love2d the entire program is about 500 lines of code  

## install/running  
install love2d from their website https://love2d.org/  
before running open up conf.lua and set the window size to something reasonable for your screen  
some options can be set in the options = {} section of main.lua  

clone this repo, cd into it and execute love in the folder  
`git clone https://github.com/Nattie-G/chaos-equations-lua.git`  
`cd chaos-equations-lua`  
`love .`  

## controls  

z (zoom) fast-forward: go faster (mulitplier configurable in options)  
x (slow) slow-forward: go slower (mulitplier configurable in options)  
c (rewind)     rewind: hold c down to play the visualisation backwards  
b (back)      history: go back to the previous equation in history
n (new)      equation: generate a new random equation and plays it 
t (time)   reset time: reset t to watch the same equation again
mouse wheel     scale: change the scale the equation is shown at

## options (configurable in source code / in game)
trails:     true/false  whether to display a trail behind each point  
colour:     true/false  when true generate a unique hue for each point. Otherwise use white  
number:     integer     how many points to calculate and display. (recommended < 1000)  
step:       float       multiplier to delta. higher values increase play speed (default 1 / 20)  
zoom_speed: float       multiplier to t while z is pressed (default 10)  
slow_speed: float       multiplier to t while x is pressed (default 0.2)  
point_size: float       radius to draw the point  
show_text:  true/false  display debug text  

interest_scaling: true/false attempt to optimise play speed based by estimating how intereseting the current configuration on screen is  
dynamic_scaling:  true/false optimise play speed based on the fastest moving point using a rolling multiplier
constant_time: ingame toggle for the above two settings. when off t will progress at a constant rate
