-- Security Writer
-- Allows for data to be added or removed from the security database

local comp = require("component")
local seri = require("serialization")
local event = require("event")
local uuid = require("uuid")

local cred_path = "/home/cred"
local perm_path = "/home/perm"

local BIO_NAME = "bio"
local PASS_NAME = "passwords"
local RFID_NAME = "RFID"
local MAG_NAME = "MAG"
local TERM_NAME = "term"

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
    term={
        {"Trackercop"}
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

-- Return the first index with the given value (or nil if not found).
function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
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
        credentials = {}
    end

    if (perm_map == nil)
    then
        perm_map = {}
    end
end

function dump_data(cpath, dpath)
    
    -- load file

    local cfile = io.open(cpath, "w")
    local dfile = io.open(dpath, "w")

    -- Serialize

    local ccont = seri.serialize(credentials)
    local dcont = seri.serialize(perm_map)

    -- Save to file

    cfile:write(ccont)
    dfile:write(dcont)
end

-----
-- Alteration Function
-----

function add_card()

    -- Specify how to create data, are we making from scratch, or reading?

    print("How will we add a card?")
    print("1. Create new card")
    print("2. Add an existing card")
    print("3. Manual Card Data")
    
    local cchoice = io.read()

    if (cchoice == "1")
    then
        
        -- Create a new card...

        if (comp.isAvailable("os_cardwriter"))
        then
            
            print("Please enter a card display name:")
            local dname = io.read()

            print("Please enter a card color:")
            local color = io.read()

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

    if (cchoice == "3")
    then

        -- Just take an input:

        print("Please enter card data:")

        local cardData = io.read()

        return cardData
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
    local name = io.read()

    -- Determine the add method:

    if (inp == '1')
    then
        
        -- Add raw value, prompt

        print("Enter permission section:")
        perm_name = io.read()

        print("Enter Permission Value:")
        perm_value = io.read()
    end

    if (inp == '2')
    then
        
        -- Add a password

        perm_name = PASS_NAME

        print("Please enter password:")

        perm_value = io.read()
    end

    if (inp == '3')
    then
        
        -- Add a magnetic card

        perm_name = MAG_NAME

        -- Get value:

        perm_value = add_card()
    end

    if (inp == '4')
    then
        
        -- Add a biosig

        perm_name = BIO_NAME

        -- Determine if we have a bioreader:

        if (comp.isAvailable("os_biometric"))
        then

            -- Get a value from the reader:

            print("Please use the bioreader...")

            local address, reader_uuid, player_uuid = event.pull("bioReader")

            -- Add the value:

            perm_value = player_uuid
        
        else

            -- No bioreader, just prompt:

            print("Please enter a player uuid:")
            perm_value = io.read()
        end
    end

    -- Determine if we have a bad value:

    if (perm_value == BAD_VALUE)
    then
        -- Bad, just return

        return
    end

    -- Otherwise, add cred to list!

    local table = credentials[perm_name]

    if (table == nil)
    then
        table = {}
    end

    table[name] = perm_value

    credentials[perm_name] = table
end

function remove_credential()

    -- Remove a credential:

    print("Enter a permission type:")
    local ptype = io.read()

    print("Enter a permission name:")
    local pname = io.read()

    -- Determine if this exists:

    if (credentials[ptype][pname] ~= nil)
    then
        -- Remove the credential:

        print("Removing credential...")

        credentials[ptype][pname] = nil

        return
    end

    print("Credential does not exist!")
end

function add_dev_map()

    -- Adds a device mapping

    print("Enter a device name:")

    local dname = io.read()

    -- Ensure device exists

    if (perm_map[dname] == nil)
    then
        
        -- Create the device:

        perm_map[dname] = {}
    end

    -- As for permission type

    print("Enter a permission type:")

    local ptype = io.read()

    -- Ensure permission type exists:

    if (credentials[ptype] == nil)
    then

        -- Not found, raise a problem

        print("Permission type does not exist!")

        return
    end

    -- Ask for permission name:

    print("Enter a permission name:")

    local pname = io.read()

    -- Ensure permission exists:

    if (credentials[ptype][pname] == nil)
    then
        
        -- Not found, raise a problem

        print("Permission does not exist!")

        return
    end

    -- Otherwise, add the permission to the device:

    local table = perm_map[dname]

    if (table == nil)
    then
        table = {}
    end

    local array = table[ptype]

    if (array == nil)
    then
        array = {}
    end

    array[#array+1] = pname

    table[ptype] = array

    perm_map[dname] = table

end

function remove_dev_map()

    -- Get device name

    print("Enter a device name:")

    local dname = io.read()

    -- Ensure deivce exists

    if (perm_map[dname] == nil)
    then
        
        -- Not found, raise a problem

        print("Device does not exist!")

        return
    end

    -- Ask for permission type

    print("Enter a permission type:")

    local ptype = io.read()

    -- Ensure permission exists

    if (perm_map[dname][ptype] == nil)
    then
        
        -- Not found, raise a problem

        print("Permission type does not exist!")

        return
    end

    -- Ask for permission name

    print("Enter a permission name:")

    local pname = io.read()

    -- Ensure permission exists

    local index = indexOf(perm_map[dname][ptype], pname)

    if (index ~= nil)
    then
        
        -- Found, remove permission

        perm_map[dname][ptype][index] = nil

        return
    end

    print("Permission does not exist!")
end

function remove_device()

    -- Ask for device name:

    print("Enter a device name:")

    local dname = io.read()

    -- Ensure device exists

    if (perm_map[dname] == nil)
    then
        
        -- Not found, raise a problem

        print("Device does not exist!")

        return
    end

    -- Otherwise, remove device and all data:

    perm_map[dname] = nil
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

-- Load content:

load_data(cred_path, perm_path)

while (true) do
    
    -- Top Level Menu:

    print("+==================================================+")
    print("   --== [ Security Administration Terminal ] ==--")
    print("Owen Labs - Computronics Division")
    print("Welcome to the security administration program.")
    print("Please select a section to manage:")

    print("1. Manage Credentials")
    print("2. Manage Device Mappings")
    print("3. Save")
    print("4. Exit")

    local inp = io.read()

    if (inp == "1")
    then

        print_credentials()

        -- Manage Credentials

        print("1. Add Credential")
        print("2. Remove Credential")

        local inp = io.read()

        if (inp == "1")
        then
            
            -- Add a credential

            add_credential()
        end

        if (inp == "2")
        then
            
            -- Remove a credential

            remove_credential()
        end
    end

    if (inp == "2")
    then
        
        print_devicemaps()

        -- Manage device mappings

        print("1. Add Device Mapping")
        print("2. Remove Device Mapping")
        print("3. Remove Device")

        local inp = io.read()

        if (inp == "1")
        then
            
            -- Add a device mapping

            add_dev_map()
        elseif (inp == "2")
        then
            
            -- Remove a device mapping

            remove_dev_map()
        elseif (inp == "3")
        then
            
            -- Remove a device

            remove_device()
        end
    end

    if (inp == "3")
    then
        -- Save contents

        dump_data(cred_path, perm_path)
    end

    if (inp == "4")
    then
        -- Just quit

        break
    end
end
