-- Sets the EEPROM lable

-- Parse arguments

local shell = require("shell")
local args, ops = shell.parse(...)

-- Determine if we have arguments:

local lable = ''

if (#args < 1)
then
    -- Not enough arguments

    print("Error - Must provide label")
    os.exit()
else
    -- Define the path as the first argument

    lable = args[1]
end

print("Setting lable to: ", path)

-- Include the components:

local component = require("component")

-- Set the EERP Contents

component.eeprom.set(contents)
