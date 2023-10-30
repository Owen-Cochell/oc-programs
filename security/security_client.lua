-- Security client
-- We accept input from various security devices,
-- and check that the security server approves them

local comp = require("component")
local event = require("event")
local seri = require("serialization")
local modem = comp.modem

local keypad = nil
local has_keyad = false

local rolldoor = nil

local keypadInput = ""

-- For now, we are just a test script

-- Port of server
local port = 5554

-- Address of server
local address = '0ef4f9a4-6720-43a6-8b84-7a9d350ff700'

-- Name of this device
local device_name = 'testd'

-- Define Permission Names:

local BIO_NAME = "bio"
local PASS_NAME = "passwords"
local RFID_NAME = "RFID"
local MAG_NAME = "MAG"

local cred_path = "/home/cred"
local perm_path = "/home/perm"

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

    print("Sending request to server")
    modem.send(address, port, seri.serialize(req))
end

function got_pass()

    print("We are authenticated!")

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
end

function got_fail()

    print("We failed to authenticate!")

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
end

----
-- Network Handlers
----

function recieve_message(message_name, recieverAddress, senderAddress, port, distance, sdata)

    -- Ensure we can only accept messages from the server:

    if (senderAddress ~= address)
    then
        -- Not valid, ignore
        print("Dropping packet, not from server!")
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
end

----
-- Device Handlers
----

function on_bio(address, reader_uuid, player_uuid)

    -- Just send the player UUID

    print("Scanned Player: " .. player_uuid)

    send_request(BIO_NAME, player_uuid)
end

function on_card(eventName, address, playerName, cardData, cardUniqueId, isCardLocked, side)

    -- Send card ID

    send_request(MAG_NAME, cardData)
end

function keypadEvent(eventName, address, button, button_label)
    print("button pressed: " .. button_label)

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

    print("Opening rolldoor")

    rolldoor.open()

    -- Wait 3 seconds:

    os.sleep(3)

    print("Closing rolldoor")

    rolldoor.close()
end

-- Open port we have specified

modem.open(port)

-- Ensure port has been opened:

if (not modem.isOpen(port))
then
    -- Do something..
    print("Unable to open port!!!")
    os.exit()
end

----
-- Component Setup
----

-- message handler

event.listen("modem_message", recieve_message)

-- Determine if we have a bioreader

if (comp.isAvailable("os_biometric"))
then
    -- Is present, add event handler

    print("Found BioReader!")

    event.listen("bioReader", on_bio)
end

if (comp.isAvailable("os_magreader"))
then

    -- Is present, add event handler

    print("Found MagReader!")

    event.listen("magData", on_card)
end

if (comp.isAvailable("os_keypad"))
then
    
    -- Get the keypad:
    keypad = comp.os_keypad

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

-- Now, do nothing

while true do
    local junk = io.read()

    if (junk == 'q')
    then
        -- Break out of this loop
        break
    end
end

-- Unregister event handlers:

event.ignore("modem_message", recieve_message)

if (comp.isAvailable("os_biometric"))
then
    -- Is present, remove event handler

    print("Removing BioReader!")

    event.ignore("bioReader", on_bio)
end

if (comp.isAvailable("os_magreader"))
then
    -- Is present, remove event handler

    print("Found MagReader!")

    event.ignore("magData", on_card)
end

if (has_keyad)
then
    -- Remove the event handler:

    event.ignore("keypad", keypadEvent)

    -- Set keypad to be inactive:

    keypad.setDisplay("inactive", 6)
end
