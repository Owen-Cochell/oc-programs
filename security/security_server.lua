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
        test='test',
        owen= 'c37c5c47-8927-4e7c-a324-bd3844e75110'
    },
    MAG={
        test='test',
    },
    term={
        {"Trackercop",}
    }
}

-- This strucutre defines the permission map,
-- Which allows you to map certain permissions to certain devices.
local perm_map = {
    testd= {
        passwords= {'test'},
        RFID= {'test'},
        bio= {'test', 'owen'},
    }
}

-- Port number to utilze
local port = 5554

local cred_path = "/home/cred"
local perm_path = "/home/perm"

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

local function send_fail(add, port)

    print("Sending fail code!")
    print(add)
    -- Send fail code:
    modem.send(add, port, "fail")
end

local function send_pass(add, port)

    print("Sending pass code!")
    print(add)
    -- Send pass code:
    modem.send(add, port, "pass")
end

local function send_players(add, port)
    print("Sending pass code")
    print(add)
    -- Send player list
    modem.send(add, port, seri.serialize(perm_map['term']))
end

function load_data(cpath, dpath)

    -- De-serialize:

    local cfile = io.open(cpath, "r")
    local dfile = io.open(dpath, "r")

    -- Load contents:

    local ccont = cfile:read("*all")
    local dfile = dfile:read("*all")

    -- De-serialize:

    credentials = seri.unserialize(ccont)
    perm_map = seri.unserialize(dfile)

    if (credentials == nil)
    then
        print("Did not find credentials")
        credentials = {}
    end

    if (perm_map == nil)
    then
        print("Did not find device map")
        perm_map = {}
    end
end

------
-- Event Handlers
------

-- This handler takes in permission data from devices,
-- and determines if the device is allowed to open
function handle_network(message_name, recieverAddress, senderAddress, port, distance, sdata)

    print("Got message from: " .. senderAddress .. " Sender Port: " .. port)

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
        send_fail(senderAddress, port)
        return
    end

    -- Grab the device permission map:

    print("Got Permap!")

    -- Determine if the given permission name is valid:

    if (not set_contains(perm_map[name], perm_name))
    then

        print("Perm not present, sending fail code!")

        -- Perm is not present, send fail code!
        send_fail(senderAddress, port)
        return
    end

    -- Get the device permission name:

    -- Determine if permission is for security terminals:

    if (perm_name == "term")
    then

        print("Got terminal perm map...")

        -- Determine if value is present

        send_players(senderAddress, port)
    end

    -- Permission name is valid, ensure permission value is in the permission set

    for key, val in pairs(perm_map[name][perm_name]) do

        print("Key: " .. key)
        print("Val: " .. val)

        -- We have a alias, get the original value

        local known_good = credentials[perm_name][val]

        print("Known Good: " .. known_good)

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

load_data(cred_path, perm_path)

-- Register event handlers

event.listen("modem_message", handle_network)

-- Enter event loop

while (true) do
    -- Just do nothing:
    local junk = io.read()

    if (junk == 'q')
    then
        -- Break out of this loop
        break
    end

end

-- Unregister event handlers

event.ignore("modem_message", handle_network)
