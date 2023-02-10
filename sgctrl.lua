local component = require("component")
local sg = component.stargate
local gpu = component.gpu
local term = require("term")
local fs1 = require("filesystem")
local srz = require("serialization")
local event = require("event")
local thread = require("thread")
local computer = require("computer")
local kb = require("keyboard")

local function debug_cb_msg(txt)
    if component.isAvailable("chat_box") then
        component.chat_box.setName("SG Ctrl Debug")
        component.chat_box.say(txt)
    end
end

local function speak(txt)
    if component.isAvailable("speech_box") then
        component.speech_box.say(txt)
    end
end

local symbols_list = {
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
        {name="Piscis Austrinus"},
        origin="Point of Origin"
    },
    pegasus={
        {name="Danami"},
        {name="Arami"},
        {name="Setas"},
        {name="Aldeni"},
        {name="Aaxel"},
        {name="Bydo"},
        {name="Avoniv"},
        {name="Ecrumig"},
        {name="Laylox"},
        {name="Ca Po"},
        {name="Alura"},
        {name="Lenchan"},
        {name="Acjesis"},
        {name="Dawnre"},
        {name="Subido"}, -- origin
        {name="Zamilloz"},
        {name="Recktic"},
        {name="Robandus"},
        {name="Unknow1"},
        {name="Zeo"},
        {name="Tahnan"},
        {name="Elenami"},
        {name="Hamlinto"},
        {name="Salma"},
        {name="Abrin"},
        {name="Poco Re"},
        {name="Hacemill"},
        {name="Olavii"},
        {name="Ramnon"},
        {name="Unknow2"},
        {name="Gilltin"},
        {name="Sibbron"},
        {name="Amiwill"},
        {name="Illume"},
        {name="Sandovi"},
        {name="Baselai"},
        {name="Once El"},
        {name="Roehi"},
        origin="Subido"
    },
    universe={
        {name="TOP_CHEVRON"},
        {name="G1"},
        {name="G2"},
        {name="G3"},
        {name="G4"},
        {name="G5"},
        {name="G6"},
        {name="G7"},
        {name="G8"},
        {name="G9"},
        {name="G10"},
        {name="G11"},
        {name="G12"},
        {name="G13"},
        {name="G14"},
        {name="G15"},
        {name="G16"},
        {name="G17"},
        {name="G18"},
        {name="G19"},
        {name="G20"},
        {name="G21"},
        {name="G22"},
        {name="G23"},
        {name="G24"},
        {name="G25"},
        {name="G26"},
        {name="G27"},
        {name="G28"},
        {name="G29"},
        {name="G30"},
        {name="G31"},
        {name="G32"},
        {name="G33"},
        {name="G34"},
        {name="G35"},
        {name="G36"},
        origin="G17"
    },
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

local gates_lib = {}

if not fs1.exists("/home/sgctrl_lib.txt") then
    local file = io.open("/home/sgctrl_lib.txt","w")
    file:write(srz.serialize({}))
    file:close()

    gates_lib = {}
else
    local file = io.open("/home/sgctrl_lib.txt","r")
    gates_lib = srz.unserialize(file:read("*a"))
    file:close()
end

local function save_gates_lib()
    local file = io.open("/home/sgctrl_lib.txt","w")
    file:write(srz.serialize(gates_lib))
    file:close()
end

local function symbol_to_id(type,symbol)
    for k,v in ipairs(symbols_list[type]) do
        if v.name:lower() == symbol:lower() then
            return k
        end
    end
    return nil
end

local function getData(key)
    if fs1.exists("/home/sgctrl_data.txt") then
        local file = io.open("/home/sgctrl_data.txt","r")
        local data = srz.unserialize(file:read("*a"))
        file:close()

        return data[key] or nil
    else
        return nil
    end
end

local function setData(key,value)
    if fs1.exists("/home/sgctrl_data.txt") then
        local file = io.open("/home/sgctrl_data.txt","r")
        local data = srz.unserialize(file:read("*a"))
        file:close()

        data[key] = value

        local file_w = io.open("/home/sgctrl_data.txt","w")
        file_w:write(srz.serialize(data))
        file_w:close()

        return true
    else
        local new_data = {}

        new_data[key] = value

        local file_w = io.open("/home/sgctrl_data.txt","w")
        file_w:write(srz.serialize(new_data))
        file_w:close()
    end
end

local function checkClick(x,y,pos,equal)
    if equal == nil or equal == true then
        if x >= pos.x and x <= pos.x1 and y >= pos.y and y <= pos.y1 then
            return true
        end
    elseif equal == true then
        if x > pos.x and x < pos.x1 and y > pos.y and y < pos.y1 then
            return true
        end
   end
   return false
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
    end,
    alphanumeric = function(x)
        if (x <= kb.keys.p and x >= kb.keys.q) or (x <= kb.keys.l and x >= kb.keys.a) or (x <= kb.keys.m and x >= kb.keys.z) or (x >= kb.keys["1"] and x <= kb.keys["0"]) then
            return true
        elseif kb.keys[x] ~= nil and string.sub(kb.keys[x],1,6) == "numpad" and string.sub(kb.keys[x],7,7):match("%d") then
            return true, string.sub(kb.keys[x],7,7)
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

        local filter_res, filter_output = filter(code)

        if filter_res and text:len() < length then
            if filter_output then
                text = text..filter_output
            else
                text = text..(kb.keys[code])
            end
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

local function quickWrite(x,y,txt,fg,bg,clearLength)
    local old_fg = gpu.getForeground()
    local old_bg = gpu.getBackground()

    gpu.setForeground(fg or old_fg)
    gpu.setBackground(bg or old_bg)

    if clearLength then
        term.setCursor(x,y)
        term.write(string.rep(" ",clearLength))
    end

    term.setCursor(x,y)
    term.write(txt)

    gpu.setForeground(old_fg)
    gpu.setBackground(old_bg)
end

local threads = {}

threads.clickListener = thread.create(function()
    while true do
        local _, _, clickX, clickY, btn, player = event.pull("touch")
        local btn, name = checkButton(clickX,clickY)
        if btn then
            local stat, err = pcall(buttons[btn].func, name)
            if not stat then term.setCursor(1,finalY) term.write(err) end
        end
    end
end)

threads.gateOpening = thread.create(function()
    while true do
        local _, _, _, isOutgoing = event.pull("stargate_open")
        local connect_box
        if isOutgoing then
            speak("Warning! Outgoing star gate connection!")
            quickWrite(1,finalY,"Outgoing: "..table.concat(getData("last_address"),"-"),0x44AAFF, base_background, 33)
        else
            speak("Warning! Incoming star gate connection!")
            quickWrite(1,finalY,"Incoming!",0xFF2222, base_background, 33)
        end
        event.pull("stargate_wormhole_closed_fully")
        quickWrite(1,finalY," ",0xFF2222, base_background, 33)

        speak("Star gate connection lost.")
    end
end)

threads.failedListener = thread.create(function()
    while true do
        local _, _, _, reason = event.pull("stargate_failed")

        local err_box = drawFancyBox(1,14,31,16,"double_hori_dot",reason,0xFF6666)
        computer.beep(300,0.5)
        os.sleep(2)

        hideBox(err_box)
    end
end)

registerButton(finalX-2,1,finalX,3,"power",function(name)
    local box = drawFancyBox(finalX-9,1+3,finalX,5+3,"double_hori_dot",nil,0xFF6666)
    quickWrite(box.x+1,box.y+1,"Shutdown",0xFF8888)
    quickWrite(box.x+1,box.y+2,"Reboot",0xFF8888)
    quickWrite(box.x+1,box.y+3,"Exit",0xFF8888)
    local _, _, clickX, clickY, btn, player = event.pull("touch")

    if clickX >= box.x and clickX <= box.x1 and clickY > box.y and clickY < box.y1 then
        if clickY == box.y+1 then
            computer.shutdown()
        elseif clickY == box.y+2 then
            computer.shutdown(true)
        elseif clickY == box.y+3 then
            for k,v in pairs(threads) do
                v:kill()
            end
            gpu.setBackground(0x000000)
            gpu.setForeground(0xFFFFFF)
            gpu.setResolution(screenX,screenY)
            gpu.fill(1,1,screenX,screenY," ")
            term.setCursor(1,1)
            return
        end
    else
        hideBox(box)
    end
end)
drawFancyBox(finalX-2,1,finalX,3,"double_hori_dot","X",0xFF4444)

registerButton(1,1,8,3,"dial",function(name)
    local dial_box = drawFancyBox(1,4,18,13,"double_all",nil,0x44AAFF)
    local tip_box = drawFancyBox(19,7,36,13,"double_hori_dot",nil,0x44AAFF)

    local tip_list = {
        "cancel",
        "last"
    }

    for k,v in ipairs(tip_list) do
        quickWrite(tip_box.x+1, tip_box.y+k, v, 0x0088DD,base_background)
    end

    local symbol_type = sg.getGateType():lower()

    computer.beep(400,0.2)
    local to_dial = {}

    local outcoming_address = {}
    local freeze_last_address = false

    for i1=1, 8 do
        local input_box = drawFancyBox(19,4,36,6,"double_hori_dot")
        quickWrite(input_box.x+1, input_box.y, "Input", 0x44AAFF)
        term.setCursor(input_box.x+1,input_box.y+1)
        gpu.fill(dial_box.x+1,dial_box.y+i1,1,1,">")
        local input = inputBox(16,filter.alphanumeric,true,0xDDEEFF)
        
        if input == "last" then
            speak("Dialing last address.")
            freeze_last_address = true
            gpu.fill(dial_box.x+1,dial_box.y+1,1,8,">")
            hideBox(input_box)
            for i1=1, 8 do
                local last_address = getData("last_address")
                to_dial[#to_dial+1] = symbols_list[symbol_type][last_address[i1]+1].name
                outcoming_address[#outcoming_address+1] = last_address[i1]
                term.setCursor(input_box.x+1,input_box.y+1)
                term.setCursor(dial_box.x+1,dial_box.y+i1)
                gpu.setForeground(dial_box.fg)
                gpu.setBackground(dial_box.bg)
                term.write(to_dial[#to_dial])
            end
            break
        elseif input == "cancel" or not symbol_to_id(symbol_type,input) then
            hideBox(input_box)
            hideBox(dial_box)
            hideBox(tip_box)
            return
        end
        
        to_dial[#to_dial+1] = input
        outcoming_address[#outcoming_address+1] = symbol_to_id(symbol_type,input)
        hideBox(input_box)
        term.setCursor(dial_box.x+1,dial_box.y+i1)
        gpu.setForeground(dial_box.fg)
        gpu.setBackground(dial_box.bg)
        term.write(to_dial[#to_dial])
    end

    hideBox(tip_box)

    debug_cb_msg("dial: "..table.concat(outcoming_address,"-"))

    if not freeze_last_address then
        setData("last_address",outcoming_address)
        speak("Dialing input address.")
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
            debug_cb_msg("Engaging "..v)
            os.sleep(0.5)
            event.pull(15,"stargate_spin_chevron_engaged")

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
        local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot",symbols_list[symbol_type].origin,0x44AAFF)

        sg.engageSymbol(symbols_list[symbol_type].origin)
        event.pull(20,"stargate_spin_chevron_engaged")

        hideBox(chevr_box)
        local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot","Connecting",0x44AAFF)

        os.sleep(1)

        sg.engageGate()
        event.pull(8,"stargate_wormhole_stabilized")

        hideBox(chevr_box)
    end
    hideBox(dial_box)
end)
drawFancyBox(1,1,8,3,"double_all","Dial",0x44AAFF)

registerButton(9,1,19,3,"autodial",function(name)
    local stack = inv.getStackInSlot(1,1)
    if stack then
        local dial_box = drawFancyBox(1,4,18,13,"double_all",nil,0x44AAFF)
        computer.beep(400,0.2)

        speak("Auto dial activated.")
        
        local nbt_data = nbt.decode(zzlib.gunzip(stack.tag))

        local symbols = nbt_data.values[1].values
        local address = {}
        local symbol_type = ""

        local has_upgrade = (nbt_data.values[5].value == 1)

        local write_line = 1

        for k,v in ipairs(symbols) do
            if v.name == "symbolType" then
                if v.value == 0 then
                    symbol_type = "milkyway"
                elseif v.value == 1 then
                    symbol_type = "pegasus"
                elseif v.value == 2 then
                    symbol_type = "universe"
                end
                break
            end 
        end

        local type_box = drawFancyBox(19,7,36,9,"double_hori_dot",symbol_type,0x44AAFF)

        local outcoming_address = {}

        for k,v in ipairs(symbols) do
            if v.name:match("%d") then
                term.setCursor(dial_box.x+1,dial_box.y+write_line)
                gpu.setForeground(dial_box.fg)
                gpu.setBackground(dial_box.bg)
                term.write(v.name.." : "..v.value.." "..v.name:gsub("%D",""))
                address[#address+1] = {
                    symbol=v.value,
                    pos=v.name:gsub("%D",""),
                    name=symbols_list[symbol_type][v.value+1].name
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
            outcoming_address[#outcoming_address+1] = v.symbol
        end

        if not has_upgrade then
            gpu.setBackground(dial_box.bg)
            gpu.setForeground(0x0066BB)

            term.setCursor(dial_box.x+1,dial_box.y+7)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+7)
            term.write(address[7].name)

            term.setCursor(dial_box.x+1,dial_box.y+8)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+8)
            term.write(address[8].name)

            address[#address] = nil
            address[#address] = nil
        end

        debug_cb_msg("autodial: "..table.concat(outcoming_address,"-"))
        setData("last_address",outcoming_address)
        speak("Calling auto dial address.")

        for k,v in ipairs(address) do
            local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot",v.name,0x44AAFF)

            term.setCursor(dial_box.x+1,dial_box.y+k)
            gpu.setForeground(0xFFAA44)
            gpu.setBackground(dial_box.bg)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+k)
            term.write(v.name)

            sg.engageSymbol(v.name)
            debug_cb_msg("Engaging "..v.symbol.." / "..v.name)
            os.sleep(0.5)
            event.pull(15,"stargate_spin_chevron_engaged")

            term.setCursor(dial_box.x+1,dial_box.y+k)
            gpu.setForeground(0xDDEEFF)
            gpu.setBackground(dial_box.bg)
            term.write(string.rep(" ",16))
            term.setCursor(dial_box.x+1,dial_box.y+k)
            term.write(v.name)

            hideBox(chevr_box)
        end
        local chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot",symbols_list[symbol_type].origin,0x44AAFF)

        sg.engageSymbol(symbols_list[symbol_type].origin)
        event.pull(20,"stargate_spin_chevron_engaged")
        hideBox(chevr_box)

        os.sleep(1)
        
        sg.engageGate()

        chevr_box = drawFancyBox(19,4,36,6,"double_hori_dot","Connecting",0x44AAFF)
        event.pull(8,"stargate_wormhole_stabilized")

        hideBox(chevr_box)
        hideBox(dial_box)
        hideBox(type_box)
    end
end)
drawFancyBox(9,1,19,3,"double_all","Auto Dial",0x44AAFF)

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

registerButton(36,1,44,3,"library",function(name)
    local lib_box = drawFancyBox(1,4,25,11,"double_vert",nil,0x44AAFF)
    local buttons = {
        exit={
            txt = "X",
            x = lib_box.x+1,
            y = lib_box.y,
            x1 = lib_box.x+1,
            y1 = lib_box.y,
            color = 0xFF0000
        },
        add={
            txt = "Add",
            x = lib_box.x+1,
            y = lib_box.y1-1,
            x1 = lib_box.x+3,
            y1 = lib_box.y1-1,
            color = 0x66FF66
        },
        edit={
            txt = "Edit",
            x = lib_box.x+5,
            y = lib_box.y1-1,
            x1 = lib_box.x+8,
            y1 = lib_box.y1-1,
            color = 0xFF8822
        },
        del={
            txt = "Del",
            x = lib_box.x1-9,
            y = lib_box.y1-1,
            x1 = lib_box.x1-6,
            y1 = lib_box.y1-1,
            color = 0xFF4444
        },
        dial={
            txt = "Dial",
            x = lib_box.x1-5,
            y = lib_box.y1-1,
            x1 = lib_box.x1-2,
            y1 = lib_box.y1-1,
            color = 0xDDEEFF
        }
    }

    quickWrite(buttons.exit.x, buttons.exit.y, buttons.exit.txt, buttons.exit.color)

    quickWrite(buttons.add.x, buttons.add.y, buttons.add.txt, buttons.add.color)
    quickWrite(buttons.edit.x, buttons.edit.y, buttons.edit.txt, buttons.edit.color)
    quickWrite(buttons.del.x, buttons.del.y, buttons.del.txt, buttons.del.color)
    quickWrite(buttons.dial.x, buttons.dial.y, buttons.dial.txt, buttons.dial.color)

    local scroll_pos = 0

    if gates_lib[scroll_pos+1] ~= nil then
        quickWrite(lib_box.x+1, lib_box.y+2, gates_lib[scroll_pos+1].name or "Empty", 0xDDEEFF, 0x001122, 23)
    else
        quickWrite(lib_box.x+1, lib_box.y+2, "Empty", 0xDDEEFF, 0x001122, 23)
    end

    quickWrite(lib_box.x+2, lib_box.y+1, (scroll_pos+1).."/"..#gates_lib, 0xDDEEFF, base_background, 7)

    local show_address = false

    while true do
        local event_dat = {event.pull()}
        if event_dat[1] == "scroll" then
            if event_dat[5] < 0 then -- Scrolling Downward
                if scroll_pos >= #gates_lib-1 then
                    scroll_pos = 0
                else
                    scroll_pos = scroll_pos+1
                end
            elseif event_dat[5] > 0 then -- Scrolling Upward
                if scroll_pos > 0 then
                    scroll_pos = scroll_pos-1
                elseif scroll_pos <= 0 then
                    if #gates_lib > 0 then
                        scroll_pos = #gates_lib-1
                    else
                        scroll_pos = 0
                    end
                end
            end

            
            if gates_lib[scroll_pos+1] ~= nil then
                if show_address then
                    quickWrite(lib_box.x+1, lib_box.y+2, table.concat(gates_lib[scroll_pos+1].address, "-") or "Empty", 0xDDEEFF, 0x001122, 23)
                else
                    quickWrite(lib_box.x+1, lib_box.y+2, gates_lib[scroll_pos+1].name or "Empty", 0xDDEEFF, 0x001122, 23)
                end
            else
                quickWrite(lib_box.x+1, lib_box.y+2, "Empty", 0xDDEEFF, 0x001122, 23)
            end

            quickWrite(lib_box.x+2, lib_box.y+1, (scroll_pos+1).."/"..#gates_lib, 0xDDEEFF, base_background, 7)
        end

        if event_dat[1] == "key_down" and event_dat[4] == kb.keys.lshift then
            show_address = true
            thread.create(function()
                os.sleep()
                computer.pushSignal("scroll","kk",1,1,0,"kk")
            end)
        elseif event_dat[1] == "key_up" and event_dat[4] == kb.keys.lshift then
            show_address = false
            thread.create(function()
                os.sleep()
                computer.pushSignal("scroll","kk",1,1,0,"kk")
            end)
        end

        if event_dat[1] == "touch" then
            if checkClick(event_dat[3], event_dat[4],buttons.add) then
                local choice_box = drawFancyBox(1,12,27,14,"double_hori_dot","1. Manual 2. Last 3. Auto",0x44AAFF)
                local _, _, _, code = event.pull("key_up")
                hideBox(choice_box)
                if code == kb.keys["numpad1"] or code == kb.keys["1"] then
                    local choice_box2 = drawFancyBox(1,12,24,14,"double_hori_dot","1. Code 2. Symbol Name",0x44AAFF)
                    local _, _, _, in_type = event.pull("key_up")
                    hideBox(choice_box2)

                    local input_type
                    if in_type == kb.keys["numpad1"] or in_type == kb.keys["1"] then
                        input_type = "code"
                    elseif in_type == kb.keys["numpad2"] or in_type == kb.keys["2"] then
                        input_type = "name"
                    end


                    local choice_box3 = drawFancyBox(1,12,27,14,"double_hori_dot","1. 6 Symbols 2. 8 Symbols",0x44AAFF)
                    local _, _, _, length = event.pull("key_up")
                    hideBox(choice_box3)

                    local input_len
                    if length == kb.keys["numpad1"] or length == kb.keys["1"] then
                        input_len = 6
                    else
                        input_len = 8
                    end

                    local symbols_box = drawFancyBox(1,15,18,24,"double_hori_dot",nil,0x44AAFF)

                    local new_address = {}

                    local symbol_type = sg.getGateType():lower()

                    local cancel = false

                    debug_cb_msg(tostring(input_len))

                    for i1=1, tonumber(input_len) do
                        local input_box = drawFancyBox(1,12,25,14,"double_hori_dot",nil,0x44AAFF)
                        quickWrite(input_box.x+1, input_box.y, "Symbol "..input_type, 0x44AAFF)
                        term.setCursor(input_box.x+1,input_box.y+1)
                        gpu.fill(symbols_box.x+1,symbols_box.y+i1,1,1,">")
                        local input = inputBox(16,filter.alphanumeric,true,0xDDEEFF)

                        if input == "cancel" or (not symbol_to_id(symbol_type,input) and input_type == "name") then
                            hideBox(input_box)
                            hideBox(symbols_box)
                            cancel = true
                            break
                        end

                        debug_cb_msg(input)
                        debug_cb_msg(tostring(tonumber(input)))
                        
                        if input_type == "code" then
                            new_address[#new_address+1] = tonumber(input)
                            hideBox(input_box)
                            term.setCursor(symbols_box.x+1,symbols_box.y+i1)
                            gpu.setForeground(symbols_box.fg)
                            gpu.setBackground(symbols_box.bg)
                            term.write(symbols_list[symbol_type][new_address[#new_address]+1].name)
                        elseif input_type == "name" then
                            new_address[#new_address+1] = symbol_to_id(symbol_type, input)
                            hideBox(input_box)
                            term.setCursor(symbols_box.x+1,symbols_box.y+i1)
                            gpu.setForeground(symbols_box.fg)
                            gpu.setBackground(symbols_box.bg)
                            term.write(symbols_list[symbol_type][new_address[#new_address]].name)
                        end
                    end

                    hideBox(symbols_box)

                    if not cancel then
                        local name_box = drawFancyBox(1,12,25,14,"double_hori_dot",nil,0x44AAFF)
                        quickWrite(name_box.x+1, name_box.y, "New Name", 0x44AAFF)
                        term.setCursor(name_box.x+1, name_box.y+1)
                        local new_name = inputBox(23, filter.alphanumeric, true, 0xDDEEFF, base_background)

                        gates_lib[#gates_lib+1] = {
                            address = new_address,
                            name = new_name
                        }

                        save_gates_lib()

                        hideBox(name_box)
                        scroll_pos = #gates_lib-1
                    end
                elseif code == kb.keys["numpad2"] or code == kb.keys["2"] then
                    local last_address = getData("last_address")
                    if #last_address == 8 or #last_address == 6 then
                        local input_box = drawFancyBox(1,12,25,14,"double_hori_dot",nil,0x44AAFF)
                        quickWrite(input_box.x+1, input_box.y, "New Name", 0x44AAFF)
                        term.setCursor(input_box.x+1, input_box.y+1)
                        local new_name = inputBox(23, filter.alphanumeric, true, 0xDDEEFF, base_background)

                        gates_lib[#gates_lib+1] = {
                            address = last_address,
                            name = new_name
                        }

                        save_gates_lib()

                        hideBox(input_box)
                        scroll_pos = #gates_lib-1
                    end
                elseif code == kb.keys["numpad3"] or code == kb.keys["3"] then

                    local stack = inv.getStackInSlot(1,1)
                    if stack then
                        local dial_box = drawFancyBox(1,15,18,24,"double_all",nil,0x44AAFF)
                        computer.beep(400,0.2)
                        
                        local nbt_data = nbt.decode(zzlib.gunzip(stack.tag))

                        local symbols = nbt_data.values[1].values
                        local address = {}
                        local symbol_type = ""

                        local write_line = 1

                        for k,v in ipairs(symbols) do
                            if v.name == "symbolType" then
                                if v.value == 0 then
                                    symbol_type = "milkyway"
                                elseif v.value == 1 then
                                    symbol_type = "pegasus"
                                elseif v.value == 2 then
                                    symbol_type = "universe"
                                end
                                break
                            end 
                        end

                        local type_box = drawFancyBox(19,15,36,17,"double_hori_dot",symbol_type,0x44AAFF)

                        for k,v in ipairs(symbols) do
                            if v.name:match("%d") then
                                term.setCursor(dial_box.x+1,dial_box.y+write_line)
                                gpu.setForeground(dial_box.fg)
                                gpu.setBackground(dial_box.bg)
                                term.write(v.name.." : "..v.value.." "..v.name:gsub("%D",""))
                                address[#address+1] = {
                                    symbol=v.value,
                                    pos=v.name:gsub("%D",""),
                                    name=symbols_list[symbol_type][v.value+1].name
                                }
                                write_line = write_line+1
                                os.sleep(0.0625)
                            end
                        end

                        local function address_sort(a,b)
                            if tonumber(a.pos) < tonumber(b.pos) then return true end
                        end

                        table.sort(address,address_sort)

                        local number_only_address = {}

                        for k,v in ipairs(address) do
                            number_only_address[#number_only_address+1] = v.symbol
                            quickWrite(dial_box.x+1, dial_box.y+#number_only_address, symbols_list[symbol_type][v.symbol+1].name, dial_box.fg, dial_box.bg, 16)
                            os.sleep(0.0625/2)
                        end


                        if #number_only_address == 8 or #number_only_address == 6 then
                            local input_box = drawFancyBox(1,12,25,14,"double_hori_dot",nil,0x44AAFF)
                            quickWrite(input_box.x+1, input_box.y, "New Name", 0x44AAFF)
                            term.setCursor(input_box.x+1, input_box.y+1)
                            local new_name = inputBox(23, filter.alphanumeric, true, 0xDDEEFF, base_background)
                            

                            gates_lib[#gates_lib+1] = {
                                address = number_only_address,
                                name = new_name
                            }

                            save_gates_lib()

                            hideBox(input_box)

                            scroll_pos = #gates_lib-1
                        end
                        hideBox(type_box)
                        hideBox(dial_box)
                    end
                end
            elseif checkClick(event_dat[3], event_dat[4],buttons.dial) then
                local saved_address = gates_lib[scroll_pos+1].address
                local symbol_type = sg.getGateType():lower()
                local dial_box = drawFancyBox(1,12,18,21,"double_all",nil,0x44AAFF)
                local address_to_call = {}
                for k,v in ipairs(saved_address) do
                    address_to_call[#address_to_call+1] = {name=symbols_list[symbol_type][v+1].name, symbol=k}
                    quickWrite(dial_box.x+1, dial_box.y+k, address_to_call[#address_to_call].name, 0x44AAFF, base_background, 16)
                end

                debug_cb_msg("lib dial: "..table.concat(saved_address,"-"))
                setData("last_address",saved_address)
                speak("Dialing lib address.")

                for k,v in ipairs(address_to_call) do
                    local chevr_box = drawFancyBox(19,12,36,14,"double_hori_dot",v.name,0x44AAFF)

                    term.setCursor(dial_box.x+1,dial_box.y+k)
                    gpu.setForeground(0xFFAA44)
                    gpu.setBackground(dial_box.bg)
                    term.write(string.rep(" ",16))
                    term.setCursor(dial_box.x+1,dial_box.y+k)
                    term.write(v.name)

                    sg.engageSymbol(v.name)
                    debug_cb_msg("Engaging "..v.symbol.." / "..v.name)
                    os.sleep(0.5)
                    event.pull(15,"stargate_spin_chevron_engaged")

                    term.setCursor(dial_box.x+1,dial_box.y+k)
                    gpu.setForeground(0xDDEEFF)
                    gpu.setBackground(dial_box.bg)
                    term.write(string.rep(" ",16))
                    term.setCursor(dial_box.x+1,dial_box.y+k)
                    term.write(v.name)

                    hideBox(chevr_box)
                end
                local chevr_box = drawFancyBox(19,12,36,14,"double_hori_dot",symbols_list[symbol_type].origin,0x44AAFF)

                sg.engageSymbol(symbols_list[symbol_type].origin)
                event.pull(20,"stargate_spin_chevron_engaged")
                hideBox(chevr_box)

                os.sleep(1)
                
                sg.engageGate()

                chevr_box = drawFancyBox(19,12,36,14,"double_hori_dot","Connecting",0x44AAFF)
                event.pull(8,"stargate_wormhole_stabilized")

                hideBox(chevr_box)
                hideBox(dial_box)
            elseif checkClick(event_dat[3], event_dat[4],buttons.exit) then
                hideBox(lib_box)
                return
            elseif checkClick(event_dat[3], event_dat[4],buttons.edit) then
                local input_box = drawFancyBox(1,12,25,14,"double_hori_dot",nil,0x44AAFF)
                quickWrite(input_box.x+1, input_box.y, "New Name", 0x44AAFF)
                term.setCursor(input_box.x+1, input_box.y+1)
                local new_name = inputBox(23, filter.alphanumeric, true, 0xDDEEFF, base_background)
                

                gates_lib[scroll_pos+1].name = new_name

                save_gates_lib()

                hideBox(input_box)
            elseif checkClick(event_dat[3], event_dat[4],buttons.del) then
                table.remove(gates_lib,scroll_pos+1)
                save_gates_lib()
                scroll_pos = 0
            end

            thread.create(function()
                os.sleep(0)
                computer.pushSignal("scroll","kk",1,1,0,"kk")
            end)
        end
    end


end)
drawFancyBox(36,1,44,3,"double_all","Library",0xDDEEFF)
