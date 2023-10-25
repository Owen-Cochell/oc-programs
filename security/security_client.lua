-- Security client
-- We accept input from various security devices,
-- and check that the security server approves them

local comp = require("component")
local event = require("event")
local seri = require("serialization")
local modem = comp.modem

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

-- No, do nothing

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
    -- Is present, add event handler

    print("Removing BioReader!")

    event.ignore("bioReader", on_bio)
end
