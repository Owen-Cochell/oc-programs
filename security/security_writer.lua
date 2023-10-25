-- Security Writer
-- Allows for data to be added or removed from the security database

local comp = require("components")
local seri = require("serialization")
local event = require("event")
local uuid = require("uuid")

local BIO_NAME = "bio"
local PASS_NAME = "passwords"
local RFID_NAME = "RFID"
local MAG_NAME = "MAG"

local BAD_VALUE = "BAD_VALUE"

-- The credentials we have managed,
-- to be loaded from a file
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
    }
}

-- Device mappings, to be loaded from a file
local perm_map = {
    testd= {
        passwords= {'test'},
        RFID= {'test'},
        bio= {'test', 'owen'},
    }
}

-----
-- Alteration Function
-----

function add_card()

    -- Specify how to create data, are we making from scratch, or reading?

    print("How will we add a card?")
    print("1. Create new card")
    print("2. Add an existing card")
    
    local cchoice = io.input()

    if (cchoice == "1")
    then
        
        -- Create a new card...

        if (comp.isAvailable("os_cardwriter"))
        then
            
            print("Please enter a card display name:")
            local dname = io.input()

            print("Please enter a card color:")
            local color = io.input()

            local writer = comp.os_cardwriter

            -- Wait for a card to be entered...

            print("Please enter your card...")

            local event, address = event.pull("cardInsert")

            -- Get some random data

            local data = uuid.next()

            -- Write the data to the card:

            writer.write(data, dname, tonumber(color))

            -- Finally, return data:

            return data
        end

        print("Card writer not present!")
        return BAD_VALUE
    end

    if (cchoice == "2")
    then
        
        -- Read an exisiting card

        if (comp.isAvailable("os_magreader"))
        then
            
            -- Read a card:

            print("Please swipe your card...")

            local eventName, address, playerName, cardData, cardUniqueId, isCardLocked, side = event.pull("magData")

            -- Return data:

            return cardData
        end

        print("Card reader is not present!")
        return BAD_VALUE
    end

    -- otherwise, return bad valueL:

    return BAD_VALUE
end

function add_credential()

    -- Adds a credential to the system

    print("1. Add Raw")
    print("2. Add Password")
    print("3. Add Magnetic Card")
    print("4. Add Biosignature")
    print("5. Back")

    local inp = io.read()

    if (inp == '5')
    then
        -- Just quit
        return
    end

    local perm_name = ''
    local perm_value = ''

    -- Otherwise, ask for perm name:

    print("Please input a permission name:")
    local name = io.input()

    -- Determine the add method:

    if (inp == '1')
    then
        
        -- Add raw value, prompt

        print("Enter permission section:")
        perm_name = io.input()

        print("Enter Permission Value:")
        perm_value = io.input()
    end

    if (inp == '2')
    then
        
        -- Add a password

        perm_name = PASS_NAME

        print("Please enter password:")

        perm_value = op.input()
    end

    if (inp == '3')
    then
        
        -- Add a magnetic card

        perm_name = MAG_NAME

        -- Get value:

        local perm_value = add_card()
    end

    if (inp == '4')
    then
        
        -- Add a biosig

        parm_name = BIO_NAME

        -- Determine if we have a bioreader:

        if (comp.isAvailable(os_biometric))
        then

            -- Get a value from the reader:

            print("Please use the bioreader...")

            local address, reader_uuid, player_uuid = event.pull("bioReader")

            -- Add the value:

            local perm_value = player_uuid
        end
    end

    -- Determine if we have a bad value:

    if (perm_value == BAD_VALUE)
    then
        -- Bad, just return

        return
    end

    -- Otherwise, add cred to list!

    credentials[perm_name][name] = perm_value
end

function remove_credential()

    -- Remove a credential:

    print("Enter a permission type:")
    local ptype = io.input()

    print("Enter a permission name:")
    local pname = io.input()

    -- Determine if this exists:

    if (credentials[ptype][pname] ~= nil)
    then
        -- Remove the credential:

        credentials[ptype].remove(pname)
    end
end

-----
-- Output Functions
-----

function print_credentials()

    -- Print out the credentials

    print("+==================================================+")
    print("  --== [ Credential List ] ==--")
    print(seri.serialize(credentials, true))
end

function print_devicemaps()

    -- Print out the device mappings

    print("+==================================================+")
    print("  --== [ Device Map List ] ==--")
    print(seri.serialize(perm_map, true))
end

while (true) do
    
    -- Top Level Menu:

    print("+==================================================+")
    print("   --== [ Security Administration Terminal ] ==--")
    print("Owen Labs - Computronics Division")
    print("Welcome to the security administration program.")
    print("Please select a section to manage:")

    print("1. Manage Credentials")
    print("2. Manage Device Mappings")

    local inp = io.input()

    if (inp == "1")
    then

        -- Manage Credentials

        print("1. Add Credential")
        print("2. Remove Credential")
    end

    if (inp == "2")
    then
        
        -- Manage device mappings
    end
end