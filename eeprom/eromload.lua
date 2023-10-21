-- Loads content from a file to a ROM
-- The file MUST be provided on the command line

-- Parse arguments

local shell = require("shell")
local args, ops = shell.parse(...)

-- Determine if we have arguments:

local path = ''

if (#args < 1)
then
    -- Not enough arguments

    print("Error - Must provide path to ROM file to be loaded!")
    os.exit()
else
    -- Define the path as the first argument

    path = args[1]
end

-- Include the components:

local component = require("component")

-- Open file to save to

local file = io.open(path, "r")

-- Write file contents:

local contents = file:read(contents)

-- Close file contents

file:close()

-- Set the EERP Contents

component.eeprom.set(contents)
