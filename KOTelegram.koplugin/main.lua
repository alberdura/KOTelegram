local Widget = require("ui/widget/widget")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local http = require("socket.http")
local ltn12 = require("ltn12")

local KOTelegram = Widget:extend{
    name = "KOTelegram",
    ultimo_tiempo_envio = 0,
}

local queue_path = "plugins/KOTelegram.koplugin/queue.txt"

local function read_config()
    local filepath = "plugins/KOTelegram.koplugin/config.txt"
    local file = io.open(filepath, "r")
    if not file then return nil end
    local token = file:read("*line")
    local chat_id = file:read("*line")
    file:close()
    return { token = token, chat_id = chat_id }
end

local function json_escape(str)
    -- Quita caracteres novalidos en JSON para que no haya caracteres raros
    return str:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
end

function KOTelegram:send_request(text_to_send)
    local config = read_config()
    if not config then return false end
    
    -- Construye el payload para que sea un JSON bien
    local payload = string.format('{"chat_id":"%s","text":"%s","parse_mode":"HTML"}', config.chat_id, json_escape(text_to_send))
    local url = string.format("https://api.telegram.org/bot%s/sendMessage", config.token)
    
    local response = {}
    local _, code = http.request{
        url = url,
        method = "POST",
        headers = { ["Content-Type"] = "application/json", ["Content-Length"] = #payload },
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response)
    }
    return code == 200
end

function KOTelegram:process_queue()
    local file = io.open(queue_path, "r")
    if not file then return end
    local lines = {}
    for line in file:lines() do table.insert(lines, line) end
    file:close()
    
    local remaining = {}
    for _, text in ipairs(lines) do
        if not self:send_request(text) then
            table.insert(remaining, text)
        end
    end
    
    if #remaining > 0 then
        local out = io.open(queue_path, "w")
        for _, line in ipairs(remaining) do out:write(line .. "\n") end
        out:close()
    else
        os.remove(queue_path)
    end
end

function KOTelegram:sendToTelegram(text, title, author)
    local final_message = "📖 <b>" .. title .. "</b>\n👤 <i>" .. author .. "</i>\n\n" .. text
    
    if self:send_request(final_message) then
        self:process_queue()
        UIManager:show(InfoMessage:new{text = "Sended to Telegram", timeout = 2})
    else
        -- conection error or 400: save in queue
        local file = io.open(queue_path, "a")
        if file then
            file:write(final_message .. "\n")
            file:close()
        end
        UIManager:show(InfoMessage:new{text = "Saved for later", timeout = 3})
    end
end

function KOTelegram:init()
    local ReaderHighlight = require("apps/reader/modules/readerhighlight")
    if ReaderHighlight.telegram_hook_aplicado then return end
    ReaderHighlight.telegram_hook_aplicado = true
    
    local original_saveHighlight = ReaderHighlight.saveHighlight
    local plugin_instance = self
    
    ReaderHighlight.saveHighlight = function(this, ...)
        original_saveHighlight(this, ...)
        local selected_text = type(this.selected_text) == "table" and this.selected_text.text or this.selected_text
        
        if selected_text and selected_text ~= "" then
            local tiempo_actual = os.time()
            if (tiempo_actual - plugin_instance.ultimo_tiempo_envio) < 2 then return end
            plugin_instance.ultimo_tiempo_envio = tiempo_actual
            
            local props = (this.ui and this.ui.document and this.ui.document.getProps and this.ui.document:getProps()) or {}
            UIManager:scheduleIn(0.5, function()
                plugin_instance:sendToTelegram(selected_text, props.title or "Sin titulo", props.authors or "Desconocido")
            end)
        end
    end
end

return KOTelegram