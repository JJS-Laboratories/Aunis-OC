local component = require("component")
local sg = component.stargate
local gpu = component.gpu
local rs = component.redstone
local term = require("term")
local fs1 = require("filesystem")
local srz = require("serialization")
local event = require("event")
local thread = require("thread")

local base_background = 0x002244
local buttons = {}

local screenX,screenY = gpu.maxResolution()
gpu.setResolution(screenY,screenY/2)

local finalX,finalY = gpu.getResolution()

gpu.setBackground(base_background)
gpu.fill(1,1,finalX,finalY," ")

local function registerButton(x,y,x1,y1,name,func)
    buttons[#buttons+1] = {
        x=x,
        y=y,
        x1=x1,
        y1=y1,
        width=x1-x,
        height=y1-y,
        name=name,
        func=func
    }
end

local boxTypes = {
    double_all = {
        horizontal="═",
        vertical="║",
        corner = {
            top_left = "╔",
            top_right = "╗",
            bottom_left = "╚",
            bottom_right = "╝",
        }
    },
    double_vert = {
        horizontal="─",
        vertical="║",
        corner = {
            top_left = "╓",
            top_right = "╖",
            bottom_left = "╙",
            bottom_right = "╜",
        }
    },
    double_hori = {
        horizontal="═",
        vertical="│",
        corner = {
            top_left = "╒",
            top_right = "╕",
            bottom_left = "╘",
            bottom_right = "╛",
        }
    },
    double_hori_dot = {
        horizontal="═",
        vertical="┊",
        corner = {
            top_left = "╒",
            top_right = "╕",
            bottom_left = "╘",
            bottom_right = "╛",
        }
    }
}

local function checkButton(x,y)
    for k,v in pairs(buttons) do
        if x >= v.x and x <= v.x1 and y >= v.y and y <= v.y1 then
            return k, v.name
        end
    end
    return nil
end

local function restoreBuffer(box)
    local backup_buffer = box.backup_buffer
    gpu.bitblt(0, box.x,box.y, box.width+1, box.height+1, backup_buffer, 1,1)
    gpu.freeBuffer(backup_buffer)
end

local function drawFancyBox(x,y,x1,y1,boxType,txt,fg,bg,hollow)
    local box = boxTypes[boxType]
    local width = x1-x
    local height = y1-y

    local backup_buffer = gpu.allocateBuffer(width+1,height+1)
    gpu.bitblt(backup_buffer, 1,1, width+1, height+1, 0, x,y)

    if fg then
        gpu.setForeground(fg)
    end
    if bg then
        gpu.setBackground(bg)
    end

    gpu.fill(x,y,width,1,box.horizontal)
    gpu.fill(x,y,1,height,box.vertical)

    gpu.fill(x,y1,width,1,box.horizontal)
    gpu.fill(x1,y,1,height,box.vertical)

    gpu.set(x,y,box.corner.top_left)
    gpu.set(x1,y,box.corner.top_right)

    gpu.set(x,y1,box.corner.bottom_left)
    gpu.set(x1,y1,box.corner.bottom_right)

    if not hollow then
        gpu.fill(x+1,y+1,width-1,height-1," ")
    end
    if txt then
        local txtX = x+math.ceil((width)/2)-math.ceil(txt:len()/2)
        local txtY = y+math.ceil((height)/2)

        if txtX <= x then
            txtX = x+1
        end
        term.setCursor(txtX,txtY)
        term.write(txt)
    end
    return {
        x=x,
        y=y,
        x1=x1,
        y1=y1,
        boxType=boxType,
        text=txt,
        backup_buffer=backup_buffer
    }
end

local clickListener = thread.create(function()
    while true do
        local _, _, clickX, clickY, btn, player = event.pull("touch")
        local btn, name = checkButton(clickX,clickY)
        if btn then
            pcall(buttons[btn].func, name)
        end
    end
end)

registerButton(1,1,8,3,"dial",function(name)
    local box = drawFancyBox(9,4,13,8,"double_all","Hai")
    os.sleep(2)
    restoreBuffer(box)
end)
drawFancyBox(1,1,8,3,"double_all","Dial")
