local component = require("component")
local sg = component.stargate
local gpu = component.gpu
local rs = component.redstone
local term = require("term")
local fs1 = require("filesystem")
local srz = require("serialization")
local event = require("event")
local thread = require("thread")
local computer = require("computer")
local kb = require("keyboard")

symbols_list = {
    milkyway = {
        {name="Sculptor"},
        {name="Scorpius"},
        {name="Centaurus"},
        {name="Monoceros"},
        {name="Point of Origin"},
        {name="Pegasus"},
        {name="Andromeda"},
        {name="Serpens Caput"},
        {name="Aries"},
        {name="Libra"},
        {name="Eridanus"},
        {name="Leo Minor"},
        {name="Hydra"},
        {name="Sagittarius"},
        {name="Sextans"},
        {name="Scutum"},
        {name="Pisces"},
        {name="Virgo"},
        {name="Bootes"},
        {name="Auriga"},
        {name="Corona Australis"},
        {name="Gemini"},
        {name="Leo"},
        {name="Cetus"},
        {name="Triangulum"},
        {name="Aquarius"},
        {name="Microscopium"},
        {name="Equuleus"},
        {name="Crater"},
        {name="Perseus"},
        {name="Cancer"},
        {name="Norma"},
        {name="Taurus"},
        {name="Canis Minor"},
        {name="Capricornus"},
        {name="Lynx"},
        {name="Orion"},
        {name="Piscis Austrinus"}
    }
}

if not fs1.exists("/lib/nbt_lib.lua") then
    os.execute("wget -fQ https://raw.githubusercontent.com/JJS-Laboratories/Aunis-OC/main/nbt_lib.lua /lib/nbt_lib.lua")
    if not fs1.exists("/lib/nbt_lib.lua") then
        error("Unable to download nbt_lib.lua")
    else
        print("Downloaded nbt_lib.lua")
    end
end

if not fs1.exists("/lib/inflate-bwo.lua") then
    os.execute("wget -fQ https://raw.githubusercontent.com/zerkman/zzlib/master/inflate-bwo.lua /lib/inflate-bwo.lua")
    if not fs1.exists("/lib/inflate-bwo.lua") then
        error("Unable to download inflate-bwo.lua")
    else
        print("Downloaded inflate-bwo.lua")
    end
end

if not fs1.exists("/lib/zzlib.lua") then
    os.execute("wget -fQ https://raw.githubusercontent.com/zerkman/zzlib/master/zzlib.lua /lib/zzlib.lua")
    if not fs1.exists("/lib/zzlib.lua") then
        error("Unable to download zzlib.lua")
    else
        print("Downloaded zzlib.lua")
    end
end

local zzlib = require("zzlib")
local nbt = require("nbt_lib")
local inv = component.inventory_controller

local base_background = 0x002244
local buttons = {}

local screenX,screenY = gpu.maxResolution()
gpu.setResolution(screenY,screenY/2)

local finalX,finalY = gpu.getResolution()

gpu.setBackground(base_background)
gpu.fill(1,1,finalX,finalY," ")

local filter = {
    alphabet = function(x)
        if (x <= kb.keys.p and x >= kb.keys.q) or (x <= kb.keys.l and x >= kb.keys.a) or (x <= kb.keys.m and x >= kb.keys.z) then
            return true
        else
            return false
        end
    end
}

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

local function hideBox(box)
    local backup_buffer = box.backup_buffer
    gpu.bitblt(0, box.x,box.y, box.width+1, box.height+1, backup_buffer, 1,1)
    gpu.freeBuffer(backup_buffer)

    gpu.setBackground(base_background)
    gpu.fill(box.x,box.y,box.width+1,box.height+1," ")
end

local function inputBox(length,filter,allowSpace,fg,bg)
    local last_fg = gpu.getForeground()
    local last_bg = gpu.getBackground()
    local x,y = term.getCursor()
    local text = ""
    while true do
        local _, _, char, code, ply = event.pull("key_down")

        if filter(code) and text:len() < length then
            text = text..(kb.keys[code])
        elseif (code == kb.keys.space and allowSpace) then
            text = text.." "
        elseif code == kb.keys.back then
            text = text:sub(1,text:len()-1)
        elseif code == kb.keys.enter then
            return text
        end

        if fg then
            gpu.setForeground(fg)
        else
            gpu.setForeground(last_fg)
        end

        if bg then
            gpu.setBackground(bg)
        else
            gpu.setBackground(last_bg)
        end

        term.setCursor(x,y)
        term.write(string.rep(" ",length))
        term.setCursor(x,y)
        term.write(text)
    end
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
        width=width,
        height=height,
        boxType=boxType,
        text=txt,
        backup_buffer=backup_buffer,
        fg=fg or gpu.getForeground(),
        bg=bg or gpu.getBackground()
    }
end

local clickListener = thread.create(function()
    while true do
        local _, _, clickX, clickY, btn, player = event.pull("touch")
        local btn, name = checkButton(clickX,clickY)
        if btn then
            local stat, err = pcall(buttons[btn].func, name)
            if not stat then term.setCursor(1,finalY) term.write(err) end
        end
    end
end)

registerButton(1,1,8,3,"dial",function(name)
    local dial_box = drawFancyBox(1,4,18,13,"double_all",nil,0x44AAFF)
    computer.beep(400,0.2)
    local to_dial = {}
    for i1=1, 6 do
        local input_box = drawFancyBox(19,4,36,6,"double_hori_dot")
        term.setCursor(input_box.x+1,input_box.y+1)
        to_dial[#to_dial+1] = inputBox(16,filter.alphabet,true,0xDDEEFF)
        hideBox(input_box)
        term.setCursor(dial_box.x+1,dial_box.y+i1)
        gpu.setForeground(dial_box.fg)
        gpu.setBackground(dial_box.bg)
        term.write(to_dial[#to_dial])
    end

    for k,v in ipairs(to_dial) do
        if v:match("%a") then
            local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot",v,0x44AAFF)

            term.setCursor(dial_box.x+1,dial_box.y+k)
            gpu.setForeground(0xFFAA44)
            gpu.setBackground(dial_box.bg)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+k)
            term.write(v)

            sg.engageSymbol(v)
            event.pull("stargate_spin_chevron_engaged")

            term.setCursor(dial_box.x+1,dial_box.y+k)
            gpu.setForeground(0xDDEEFF)
            gpu.setBackground(dial_box.bg)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+k)
            term.write(v)


            hideBox(chevr_box)
        end
    end

    if to_dial[1]:match("%a") then
        local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot","Point of Origin",0x44AAFF)

        sg.engageSymbol("Point of Origin")
        event.pull("stargate_spin_chevron_engaged")

        hideBox(chevr_box)
        local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot","Connecting",0x44AAFF)

        sg.engageGate()
        event.pull(8,"stargate_wormhole_stabilized")

        hideBox(chevr_box)
    end
    hideBox(dial_box)
end)
drawFancyBox(1,1,8,3,"double_all","Dial")

registerButton(9,1,19,3,"autodial",function(name)
    local stack = inv.getStackInSlot(1,1)
    if stack then
        local dial_box = drawFancyBox(1,4,18,13,"double_all",nil,0x44AAFF)
        computer.beep(400,0.2)
        local to_dial = {}
        
        local nbt_data = nbt.decode(zzlib.gunzip(stack.tag))

        local symbols = nbt_data.values[1].values
        local address = {}

        local write_line = 1

        for k,v in ipairs(symbols) do
            if v.name:match("%d") then
                term.setCursor(dial_box.x+1,dial_box.y+write_line)
                gpu.setForeground(dial_box.fg)
                gpu.setBackground(dial_box.bg)
                term.write(v.name.." : "..v.value.." "..v.name:gsub("%D",""))
                address[#address+1] = {
                    symbol=v.value,
                    pos=v.name:gsub("%D",""),
                    name=symbols_list.milkyway[v.value+1].name
                }
                write_line = write_line+1
                os.sleep(0.25)
            end
        end

        local function address_sort(a,b)
            if tonumber(a.pos) < tonumber(b.pos) then return true end
        end

        table.sort(address,address_sort)

        for k,v in ipairs(address) do
            term.setCursor(dial_box.x+1,dial_box.y+k)
            gpu.setForeground(dial_box.fg)
            gpu.setBackground(dial_box.bg)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+k)
            term.write(v.name)
            os.sleep(0.125)
        end

        for k,v in ipairs(address) do
            local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot",v.name,0x44AAFF)

            term.setCursor(dial_box.x+1,dial_box.y+k)
            gpu.setForeground(0xFFAA44)
            gpu.setBackground(dial_box.bg)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+k)
            term.write(v.name)

            sg.engageSymbol(v.name)
            event.pull("stargate_spin_chevron_engaged")

            term.setCursor(dial_box.x+1,dial_box.y+k)
            gpu.setForeground(0xDDEEFF)
            gpu.setBackground(dial_box.bg)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+k)
            term.write(v.name)

            hideBox(chevr_box)
        end
        local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot","Point of Origin",0x44AAFF)
        sg.engageSymbol("Point of Origin")
        event.pull("stargate_spin_chevron_engaged")
        hideBox(chevr_box)
        local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot","Connecting",0x44AAFF)
        sg.engageGate()
        event.pull(8,"stargate_wormhole_stabilized")
        hideBox(chevr_box)
        hideBox(dial_box)
    end
end)
drawFancyBox(9,1,19,3,"double_all","Auto Dial")

registerButton(20,1,26,3,"close",function(name)
    local stat, err, desc = sg.disengageGate()
    if not stat then
        local closing_box = drawFancyBox(9,4,40,6,"double_hori_dot",err,0xFF6666)
        computer.beep(300,0.5)
        os.sleep(2)
        hideBox(closing_box)
    else
        local closing_box = drawFancyBox(9,4,25,6,"double_hori_dot","SUCCESS",0x66FF66)
        computer.beep(500,0.1)
        os.sleep(0.5)
        computer.beep(500,0.1)
        os.sleep(0.5)
        computer.beep(500,0.1)
        os.sleep(2)
        hideBox(closing_box)
    end
end)
drawFancyBox(20,1,26,3,"double_all","Close",0xFF6666)

registerButton(27,1,32,3,"engage",function(name)
    local stat, err, desc = sg.engageGate()
    if not stat then
        local closing_box = drawFancyBox(9,4,40,6,"double_hori_dot",err,0xFF6666)
        computer.beep(300,0.5)
        os.sleep(2)
        hideBox(closing_box)
    else
        local closing_box = drawFancyBox(9,4,25,6,"double_hori_dot","SUCCESS",0x66FF66)
        computer.beep(500,0.1)
        os.sleep(0.5)
        computer.beep(500,0.1)
        os.sleep(0.5)
        computer.beep(500,0.1)
        os.sleep(2)
        hideBox(closing_box)
    end
end)
drawFancyBox(27,1,32,3,"double_all","Open",0x66FF66)

