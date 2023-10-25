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

-- Define a test structure

local tstruct = {
    name= 'testd',
    perm_name= 'passwords',
    perm_value= '12'
}

-- Open port we have specified

modem.open(port)

-- Ensure port has been opened:

if (not modem.isOpen(port))
then
    -- Do something..
    print("Unable to open port!!!")
    os.exit()
end

-- Send structure to server

print("Sending message: " .. address .. " Port: " .. port)
modem.send(address, port, seri.serialize(tstruct))

-- Get response:

local _, _, from, port, _, message = event.pull("modem_message")

print("Got Message: " .. from .. " On Port: " .. port)
print(message)
