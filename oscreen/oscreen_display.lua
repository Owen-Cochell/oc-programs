-- Displays arbitrary text to a screen.
-- We simply display the text, and change the viewport
-- to only display the given text.

-- Parse arguments

local shell = require("shell")
local args, ops = shell.parse(...)

-- Determine if we have arguments:

local text = ''

if (#args < 1)
then
    -- Not enough arguments

    print("Error - Must provide text to display!")
    os.exit()
else
    -- Define the path as the first argument

    text = args[1]
end

-- Get the terminal

local term = require("term")

-- Get the GPU

local gpu = term.gpu()

-- Reset the screen

term.clear()

-- Write some text

term.write(text, false)

-- get the current cursor position

local x, y = term.getCursor()

-- Set the viewpoint:

gpu.setViewport(x, y)

-- Read forever

io.read()
