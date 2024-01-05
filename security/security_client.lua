-- Security client
-- We accept input from various security devices,
-- and check that the security server approves them

local comp = require("component")
local event = require("event")
local seri = require("serialization")
local shell = require("shell")

local modem = comp.modem

local args, ops = shell.parse(...)

local keypad = nil
local has_keyad = false

local rolldoor = nil

local redstone = nil
local sides_on = {255, 255, 255, 255, 255, 255}

local sides_off = {0,0,0,0,0,0}

local secdoor = nil
local sect

local keypadInput = ""

-- For now, we are just a test script

-- Port of server
local port = 5554

-- Address of server
local address = 'f69a6fa5-3f2d-463f-9e9c-8b003da81c1a'

-- Name of this device
local device_name = 'testd'

-- Define Permission Names:

local BIO_NAME = "bio"
local PASS_NAME = "passwords"
local RFID_NAME = "RFID"
local MAG_NAME = "MAG"

-- Parse args

if (#args > 0)
then
    -- Not enough arguments

    device_name = args[1]
    address = args[2]
end

----
-- Library Methods
----

function send_request(pname, pvalue)

    -- Construct the request:

    local req = {
        name=device_name,
        perm_name=pname,
        perm_value=pvalue,
    }

    -- Send to server:

    -- print("Sending request to server")
    modem.send(address, port, seri.serialize(req))
end

function got_pass()

    -- print("We are authenticated!")

    if (has_keyad == true)
    then
        
        -- We have a keypad, set the access granted:

        setAuth(true)
    end

    if (rolldoor ~= nil)
    then
        
        -- Handle the rolldoor:

        handle_rolldoor()
    end

    if (secdoor ~= nil)
    then
        
        -- Handle the secdoor:

        handle_securitydoor()
    end

    if (redstone ~= nil)
    then
        -- Handle the redstone IO

        handle_redstoneio()
    end

    if (has_keyad == true)
    then
        keypad.setDisplay("")
    end
end

function got_fail()

    -- print("We failed to authenticate!")

    if (has_keyad == true)
    then
        
        -- We have a keypad, set the access denied:

        setAuth(false)
    end
end

function updateDisplay()
    local displayString = ""
    for i = 1, #keypadInput do
        displayString = displayString .. "*"
    end

    keypad.setDisplay(displayString, 7)
end

function setAuth(auth)
    if auth == true then
        keypad.setDisplay("granted", 2)
    else
        keypad.setDisplay("denied", 4)
    end
    keypadInput = ""
    os.sleep(1)
end

function clear_players_term()

    -- Get list of players

    print("Clearing players")

    local players = sect.getAllowedUsers("pass")

    print("Got player list...")
    print(players)

    -- Determine if table is empty:

    if not next(players) then
        -- Table is empty, do nothing
        print("Table is empty")
    end

    print("After print")
    print(seri.serialization(players))
    print("After serialization")

    for i in string.gmatch(example, "%S+") do

        print(i)

        -- Remove the player from the terminal:

        sect.delUser(i)
     end
     print("Done iterating")
end

----
-- Network Handlers
----

function recieve_message(message_name, recieverAddress, senderAddress, port, distance, sdata)

    -- Ensure we can only accept messages from the server:

    print("Got message!")
    if (senderAddress ~= address)
    then
        -- Not valid, ignore
        -- print("Dropping packet, not from server!")
        return
    end

    -- Otherwise, determine if we have a pass:

    if (sdata == "pass")
    then
        -- We are authenticated! Do something!

        got_pass()
    end

    if (sdata == "fail")
    then
        -- We are not authenticated! Do something!

        got_fail()
    end

    -- Try to deserialize the data:

    local data = seri.unserialize(sdata)

    print("Data:")
    print(data)
    print(sdata)

    -- Clear the player list:

    clear_players_term()

    -- Add new players:

    print("ITerating players")

    for key, play in pairs(data) do
        
        -- Add user to terminal

        print("Adding User")
        print(play)
        sect.addUser("pass", play)
    end
end

function ask_terms()

    -- Ask the server for the player list:

    print("Asking server for perms")
    send_request("term", "none")
end

----
-- Device Handlers
----

function on_bio(address, reader_uuid, player_uuid)

    -- Just send the player UUID

    -- print("Scanned Player: " .. player_uuid)

    send_request(BIO_NAME, player_uuid)
end

function on_card(eventName, address, playerName, cardData, cardUniqueId, isCardLocked, side)

    -- Send card ID

    send_request(MAG_NAME, cardData)
end

function keypadEvent(eventName, address, button, button_label)
    -- print("button pressed: " .. button_label)

    if button_label == "*" then
        -- remove last character from input cache
        keypadInput = string.sub(keypadInput, 1, -2)
    elseif button_label == "#" then
        -- Send pin to server

        send_request(PASS_NAME, keypadInput)
    else
        -- add key to input cache if none of the above action apply
        keypadInput = keypadInput .. button_label
    end

    updateDisplay()
end

function handle_rolldoor()

    -- Opens and closes a rolldoor

    -- print("Opening rolldoor")

    rolldoor.open()

    -- Wait 3 seconds:

    os.sleep(3)

    -- print("Closing rolldoor")

    rolldoor.close()
end

function handle_securitydoor()

    -- Opens and closes a security door

    -- print("Opening security door")

    secdoor.open()

    -- Wait 2 seconds:

    os.sleep(2)

    -- print("Closing security door")

    secdoor.close()
end

function handle_redstoneio()

    -- Actiavtes and deactivates a redstone IO card

    -- Create signal:

    redstone.setOutput(sides_on)

    -- Wait for a time:

    os.sleep(2)

    -- Stop the signal:

    redstone.setOutput(sides_off)
end

-- Open port we have specified

modem.open(port)

-- Ensure port has been opened:

if (not modem.isOpen(port))
then
    -- Do something..
    -- print("Unable to open port!!!")
    os.exit()
end

----
-- Component Setup
----

-- message handler

event.listen("modem_message", recieve_message)

-- Determine if we have a security terminal:

if (comp.isAvailable("os_securityterminal"))
then
    -- Configure the terminal to allow myself:
    sect = comp.os_securityterminal

    -- Configure the password

    --sect.setPassword("pass")

    -- Set the range

    sect.setRange("pass", 4)

    -- Add myself to the list

    --sect.addUser("pass", "Trackercop")

    -- Ask for perms

    ask_terms()

    -- Enable the terminal

    sect.enable("pass")
end

-- Determine if we have a bioreader

if (comp.isAvailable("os_biometric"))
then
    -- Is present, add event handler

    -- print("Found BioReader!")

    event.listen("bioReader", on_bio)
end

if (comp.isAvailable("os_magreader"))
then

    -- Is present, add event handler

    -- print("Found MagReader!")

    event.listen("magData", on_card)
end

if (comp.isAvailable("os_keypad"))
then
    
    -- Get the keypad:
    keypad = comp.os_keypad

    has_keyad = true

    -- Add the event handler:

    event.listen("keypad", keypadEvent)

    -- Clear the keypad:

    keypad.setDisplay("")
end

if (comp.isAvailable("os_rolldoorcontroller"))
then
    
    -- Get the rolldoor:

    rolldoor = comp.os_rolldoorcontroller

    -- Close it initially:

    rolldoor.close()
end

if (comp.isAvailable("os_doorcontroller"))
then
    
    -- Get the securitydoor

    secdoor = comp.os_doorcontroller

    -- Close it initially:

    secdoor.close()
end

if (comp.isAvailable("redstone"))
then

    -- Get the redstone IO component:

    redstone = comp.redstone

    -- Ensure it is off by default:

    redstone.setOutput(sides_off)
end

-- Now, do nothing

-- while true do
--     local junk = io.read()

--     if (junk == 'q')
--     then
--         -- Break out of this loop
--         break
--     end
-- end

-- -- Unregister event handlers:

-- event.ignore("modem_message", recieve_message)

-- if (comp.isAvailable("os_biometric"))
-- then
--     -- Is present, remove event handler

--     print("Removing BioReader!")

--     event.ignore("bioReader", on_bio)
-- end

-- if (comp.isAvailable("os_magreader"))
-- then
--     -- Is present, remove event handler

--     print("Found MagReader!")

--     event.ignore("magData", on_card)
-- end

-- if (has_keyad)
-- then
--     -- Remove the event handler:

--     event.ignore("keypad", keypadEvent)

--     -- Set keypad to be inactive:

--     keypad.setDisplay("inactive", 6)
-- end
