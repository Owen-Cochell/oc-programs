-- Test file for OpenScreen
-- We simply display some text to the screen
-- And tries to set the resolution to fit the text on screen

-- Get the terminal

local term = require("term")

-- Get the GPU

local gpu = term.gpu()

-- Reset the screen

term.clear()

-- Write some text

term.write("This is a test!")

-- get the current cursor position

local x, y = term.getCursor()

-- Show the position:

term.write(tostring(x))
term.write(tostring(y))

-- Set the viewpoint:

gpu.setViewpoint(x, y)
