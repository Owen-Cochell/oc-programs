-- Dumps the current ROM to a file
-- The file can be provided on the command line,
-- otherwise we simply dump to errprom.dump

-- Parse arguments

local shell = require("shell")
local args, ops = shell.parse(...)

-- Determine if we have arguments:

local path = ''

if (#args < 1)
then
    -- Define the path

    path = 'errprom.dump'
else
    -- Define the path as the first argument

    path = args[1]
end

print("Saving contentsd to: ", path)

-- Include the components:

local component = require("component")

-- Get the EERP Contents

print("Getting content from: ", component.eeprom.getLabel())

local contents = component.eeprom.get()

-- Open file to save to

local file = io.open(path, "w")

-- Write file contents:

file:write(contents)

-- Close file contents

file:close()
