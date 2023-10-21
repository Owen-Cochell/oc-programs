-- Dumps the current ROM to a file
-- The file can be provided on the command line,
-- otherwise we simply dump to errprom.dump

-- Determine if we have arguments:

if (#arg < 2):
then
    -- Define the path

    local path = 'errprom.dump'
else

    -- Define the path as the first argument

    local path = arg[1]

-- Include the components:

local component = require("component")

-- Get the EERP Contents

local contents = component.eeprom.get()

-- Open file to save to

local file = io.open(path, "w")

-- Write file contents:

file:write(contents)

-- Close file contents

file:close()
