-- Displays arbitrary text to a screen.
-- We simply display the text, and change the viewport
-- to only display the given text.

-- Parse arguments

local shell = require("shell")
local args, ops = shell.parse(...)

-- Determine if we have arguments:

local path = ''
local foreground = 0xFFFFFF
local background = 0

if (#args < 1)
then
    -- Not enough arguments

    print("Error - Must provide path to display file!")
    os.exit()
elseif (#args < 2)
then
    -- Define the path as the first argument

    path = args[1]
elseif (#args < 3)
then
    -- Define the foreground as the second argument

    path = args[1]
    foreground = tonumber(args[2])
else
    -- Define the text, foreground, and background
    
    path = args[1]
    foreground = tonumber(args[2])
    background = tonumber(args[3])
end

-- Create file

local file = io.open(path, "r")

-- Get the GPU

local gpu = require("component").gpu

-- Set the foreground color, use a constant:

gpu.setForeground(foreground)
gpu.setBackground(background)

-- Iterate over each line

local mwidth = 0
local row = 1

for line in file:lines() do

    -- Determine if this line has a larger width

    if (line:len() > mwidth)
    then
        -- Set the new width
        mwidth = line:len()
    end

    -- Write the line

    gpu.set(1, row, line)

    -- Increment row num
    row = row + 1
end

-- get the current cursor position

--local x, y = term.getCursor()

-- Move the cursor to zero position

--term.setCursor(1, 1)

-- Set the viewpoint:

gpu.setViewport(mwidth, row-1)

-- Read forever

io.read()
