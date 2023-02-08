local component = require("component")
local ring = component.transportrings
local gpu = component.gpu
local rs = component.redstone
local term = require("term")
local fs1 = require("filesystem")
local srz = require("serialization")
local event = require("event")

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function fs_text(txt,fg,bg)
    term.clear()
    term.setCursor(1,1)
    gpu.setResolution(txt:len(),1)
    gpu.setForeground(fg or 0xFFFFFF)
    gpu.setBackground(bg or 0x000000)
    term.write(txt)
end

local config = {}

if not fs1.exists("/home/rs_ring.txt") then
    print("Config Mode..")
    print("Type of Ring? (GOAULD, ORI)")
    config.type = tonumber(io.read())
    if config.type == "GOAULD" then config.type = 0 end
    if config.type == "ORI" then config.type = 1 end
    print("Target Address?")
    config.target = {}
    for i1=1, 4 do
        config.target[i1] = io.read()
    end
    local config_file = io.open("/home/rs_ring.txt","w")
    config_file:write(srz.serialize(config))
    config_file:close()
else
    print("Loading Config..")
    local config_file = io.open("/home/rs_ring.txt","r")
    config = srz.unserialize(config_file:read("*a"))
    config_file:close()
end

local stat, err = pcall(function()
    while true do
        fs_text("Idle")
        local _, _, _, old, new = event.pull("redstone_changed")
        if old == 0 and new > 0 then
            fs_text("Starting!",0xFFAA00)
            os.sleep(2)
            for k,v in ipairs(config.target) do
                if v:match("%a") then
                    fs_text(v)
                    ring.addSymbolToAddress(config.type,v)
                end
                os.sleep(0.5)
            end
            fs_text("Dialing",0x44FF66)
            ring.addSymbolToAddress(config.type,6)
            event.pull(10,"transportrings_teleport_finished")
        end
    end
end)

if not stat then component.gpu.setResolution(component.gpu.maxResolution()) print(err) end

component.gpu.setResolution(component.gpu.maxResolution())