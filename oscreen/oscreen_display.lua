-- Displays arbitrary text to a screen.
-- We simply display the text, and change the viewport
-- to only display the given text.

-- Parse arguments

local shell = require("shell")
local args, ops = shell.parse(...)

-- Determine if we have arguments:

local text = ''
local foreground = 0xFFFFFF
local background = 0

if (#args < 1)
then
    -- Not enough arguments

    print("Error - Must provide text to display!")
    os.exit()
elseif (#args < 2)
then
    -- Define the path as the first argument

    text = args[1]
elseif (#args < 3)
then
    -- Define the foreground as the second argument

    text = args[1]
    foreground = tonumber(args[2])
else
    -- Define the text, foreground, and background
    
    text = args[1]
    foreground = tonumber(args[2])
    background = tonumber(args[3])
end

-- Get the terminal

local term = require("term")

-- Get the GPU

local gpu = term.gpu()

-- Set the foreground color, use a constant:

gpu.setForeground(foreground)
gpu.setBackground(background)

-- Reset the screen

term.clear()

-- Write some text

term.write(text)

-- get the current cursor position

local x, y = term.getCursor()

-- Set the viewpoint:

gpu.setViewport(x, y)

-- Read forever

io.read()
