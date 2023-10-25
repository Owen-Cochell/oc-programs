-- Security server
-- We define what is allowed for clients,
-- and the type of security devices to enable

local comp = require("component")
local event = require("event")
local seri = require("serialization")
local modem = comp.modem

-- This strucutre defines the credentials for diffrent devices.
-- Passwords, RFID cards, and biosignatures are supported.
-- Each credential has a name associated with it,
-- which can be used to tie certain devices to certain permissions.
local credentials = {
    passwords= {
        test= '123456'
    },
    RFID= {
        test= 'test'
    },
    bio= {
        test= 'test'
    },
}

-- This strucutre defines the permission map,
-- Which allows you to map certain permissions to certain devices.
local perm_map = {
    testd= {
        passwords= {{'test'}},
        RFID= {{'test'}},
        bio= {{'test'}},
    }
}

-- Port number to utilze
local port = 5554

----
-- Server Setup
----

-- Open port we have specified

modem.open(port)

-- Ensure port has been opened:

if (not modem.isOpen(port))
then
    -- Do something..
    print("Unable to open port!!!")
    os.exit()
end

------
-- Misc. Library methods
------

function set_contains(set, key)
    return set[key] ~= nil
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function send_fail(add, port)

    -- Send fail code:
    modem.send(add, port, "fail")
end

local function send_pass(add, port)

    -- Send pass code:
    modem.send(add, port, "pass")
end

------
-- Event Handlers
------

-- Network open requests look something like this:

-- local ttttt = {
--     'name': 'dev_name',  -- Name of device we recieved
--     'perm_name': 'perm_name'  -- Name of permission
--     'perm_value': 'perm_value'  -- Value of the permission 
-- }

-- This handler takes in permission data from devices,
-- and determines if the device is allowed to open
function handle_network(message_name, senderAddress, recieverAddress, port, distance, sdata)

    print("Got message from: " .. senderAddress .. " Sender Port: " .. port)

    print("Perm Map: " .. perm_map)

    -- Deserialize the data:

    data = seri.unserialize(sdata)

    print("Done unserializing")

    -- Determine the deivce name

    local name = data['name']

    print("Data Name: " .. name)

    -- Determine the permission name

    local perm_name = data['perm_name']

    print("Permission Name: " .. perm_name)

    -- Determine the permission value

    local perm_value = data['perm_value']

    print("Permission Value: " .. perm_value)

    -- Determine if name is in perm_map:

    if (not set_contains(perm_map, name))
    then
        -- Event name not found, log and return
        print("parmissions not found for device: " .. name)
        return
    end

    -- Grab the device permission map:

    local d_permmap = perm_map[name]

    print("Permission Map: " .. d_permmap)

    -- Determine if the given permission name is valid:

    if (not set_contains(d_permmap, perm_name))
    then

        print("Perm not present, sending fail code!")

        -- Perm is not present, send fail code!
        send_fail(senderAddress, port)
        return
    end

    -- Get the device permission name:

    local d_permname = d_permmap[perm_name]

    -- Permission name is valid, ensure permission value is in the permission set

    for val in d_permname do

        -- We have a alias, get the original value

        local known_good = credentials[perm_name][val]

        -- Determine if this value matches sent:

        if (known_good == perm_value)
        then

            print("Perm present, sending pass code!")
            -- We have a known good value, return pass
            send_pass(senderAddress, port)
            return
        end
    end

    -- Could not find anything, send fail

    print("Could not find perm, send fail code!")
    send_fail(senderAddress, port)
end

-- Register event handlers

--event.listen("modem_message", handle_network)

-- Enter event loop

while (true) do

    -- Pull an event:

    local one, two, three, four, five, six = event.pull("modem_message")
    handle_network(one, two, three, four, five, six)

    -- Just do nothing:
    io.read()
end
