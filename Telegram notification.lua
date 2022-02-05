--============================================================================
script_name("Notf by Mercy")
script_authors("Mercy", 'Vespan')
script_version("0.3")
--==================================[Библиотеки]==============================

require 'lib.moonloader'

local imgui 				= require 'imgui'
local encoding 				= require 'encoding'
local ev 					= require 'lib.samp.events'
local inicfg 				= require 'inicfg'
local effil 				= require("effil") 
local ffi 					= require('ffi')
local updateid 
 
encoding.default = 'CP1251'
u8 = encoding.UTF8

--============================================================================
if not doesDirectoryExist('moonloader/config/SendTG') then -- +
	createDirectory('moonloader/config/SendTG')
end

local mainIni = inicfg.load({
    Telegram =
    {
        chat_id = '',
        token = '',
    }
}, 'SendTG.ini')

if not doesFileExist("moonloader/config/SendTG/SendTG.ini") then inicfg.save(mainIni, "SendTG/SendTG.ini") end -- +
inik = inicfg.load(nil, 'SendTG/SendTG')

local window = imgui.ImBool(false)

buffer_token = imgui.ImBuffer(''..inik.Telegram.token, 128)
buffer_chatid = imgui.ImBuffer(''..inik.Telegram.chat_id, 128)

chat_id = inik.Telegram.chat_id
token = inik.Telegram.token

--============================================================================


ffi.cdef [[
    typedef int BOOL;
    typedef unsigned long HANDLE;
    typedef HANDLE HWND;
    typedef int bInvert;
 
    HWND GetActiveWindow(void);

    BOOL FlashWindow(HWND hWnd, BOOL bInvert);
    BOOL ShowWindow(HWND hWnd, BOOL bInvert);
]]

function main()
    while not isSampAvailable() do wait(200) end

	sampAddChatMessage('[{87CEFA}Notification{FFFFFF} by Mercy] {00FF00}Загружен! {FFFFFF}| Автор: {FFD700}vk.com/supergame297', -1)
	print('[{87CEFA}Notification{FFFFFF} by Mercy] {00FF00}Загружен! {FFFFFF}| Автор: {FFD700}vk.com/supergame297')

    sampRegisterChatCommand('notf', function()
        window.v = not window.v
    end)	

	imgui.Process = false
	window.v = false

	inicfg.load(nil, 'SendTG')

    lua_thread.create(get_telegram_updates)
	
    while true do
        wait(0)

        imgui.Process = window.v

	end
end	

function imgui.OnDrawFrame()
    if window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(420.0, 230.0), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(550.0, 200.0), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'Notf by Mercy', window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		
            imgui.InputText('TOKEN', buffer_token, imgui.InputTextFlags.Password)
            imgui.InputText('USER ID', buffer_chatid)

            if imgui.Button(u8'Тестовая отправка.', imgui.ImVec2(121, 50)) then
                sendTelegramNotification('Тест. Всё работает!')
            end

			imgui.SameLine(140)

            if imgui.Button(u8'Сохранить', imgui.ImVec2(108, 50)) then
                inicfg.save({
                    Telegram =
                    {
                        chat_id = buffer_chatid.v,
                        token = buffer_token.v,
                    }
                }, 'SendTG/SendTG')
                chat_id = buffer_chatid.v
                token = buffer_token.v
			end	          		

		imgui.End()
	end
end

function threadHandle(runner, url, args, resolve, reject)
    local t = runner(url, args)
    local r = t:get(0)
    while not r do
        r = t:get(0)
        wait(0)
    end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then resolve(result) else reject(result) end
    elseif err then
        reject(err)
    elseif status == 'canceled' then
        reject(status)
    end
    t:cancel(0)
end

function requestRunner()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then reject = function() end end
    lua_thread.create(function()
        threadHandle(runner, url, args, resolve, reject)
    end)
end

function encodeUrl(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg)
    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg)
    async_http_request('https://api.telegram.org/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text='..msg,'', function(result) end)
end

function get_telegram_updates()
    while not updateid do wait(1) end
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do
        url = 'https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chat_id..'&offset=-1'
        threadHandle(runner, url, args, processing_telegram_messages, reject)
        wait(0)
    end
end

function getLastUpdate()
    async_http_request('https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chat_id..'&offset=-1','',function(result)
        if result then
            local proc_table = decodeJson(result)
            if proc_table.ok then
                if #proc_table.result > 0 then
                    local res_table = proc_table.result[1]
                    if res_table then
                        updateid = res_table.update_id
                    end
                else
                    updateid = 1
                end
            end
        end
    end)
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
    style.WindowRounding = 5.0
    style.FramePadding = ImVec2(5, 5)
    style.FrameRounding = 4.0
    style.ItemSpacing = ImVec2(12, 8)
    style.ItemInnerSpacing = ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 9.0
    style.GrabMinSize = 5.0
    style.GrabRounding = 3.0


            colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 0.78)
            colors[clr.TextDisabled]         = ImVec4(1.00, 1.00, 1.00, 1.00)
            colors[clr.WindowBg]             = ImVec4(0.11, 0.15, 0.17, 1.00)
            colors[clr.ChildWindowBg]        = ImVec4(0.15, 0.18, 0.22, 1.00)
            colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
            colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
            colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
            colors[clr.FrameBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.FrameBgHovered]       = ImVec4(0.12, 0.20, 0.28, 1.00)
            colors[clr.FrameBgActive]        = ImVec4(0.09, 0.12, 0.14, 1.00)
            colors[clr.TitleBg]              = ImVec4(0.53, 0.20, 0.16, 0.65)
            colors[clr.TitleBgActive]        = ImVec4(0.56, 0.14, 0.14, 1.00)
            colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
            colors[clr.MenuBarBg]            = ImVec4(0.15, 0.18, 0.22, 1.00)
            colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.39)
            colors[clr.ScrollbarGrab]        = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
            colors[clr.ScrollbarGrabActive]  = ImVec4(0.09, 0.21, 0.31, 1.00)
            colors[clr.ComboBg]              = ImVec4(0.20, 0.25, 0.29, 1.00)
            colors[clr.CheckMark]            = ImVec4(1.00, 0.28, 0.28, 1.00)
            colors[clr.SliderGrab]           = ImVec4(0.64, 0.14, 0.14, 1.00)
            colors[clr.SliderGrabActive]     = ImVec4(1.00, 0.37, 0.37, 1.00)
            colors[clr.Button]               = ImVec4(0.59, 0.13, 0.13, 1.00)
            colors[clr.ButtonHovered]        = ImVec4(0.69, 0.15, 0.15, 1.00)
            colors[clr.ButtonActive]         = ImVec4(0.67, 0.13, 0.07, 1.00)
            colors[clr.Header]               = ImVec4(0.20, 0.25, 0.29, 0.55)
            colors[clr.HeaderHovered]        = ImVec4(0.98, 0.38, 0.26, 0.80)
            colors[clr.HeaderActive]         = ImVec4(0.98, 0.26, 0.26, 1.00)
            colors[clr.Separator]            = ImVec4(0.50, 0.50, 0.50, 1.00)
            colors[clr.SeparatorHovered]     = ImVec4(0.60, 0.60, 0.70, 1.00)
            colors[clr.SeparatorActive]      = ImVec4(0.70, 0.70, 0.90, 1.00)
            colors[clr.ResizeGrip]           = ImVec4(0.26, 0.59, 0.98, 0.25)
            colors[clr.ResizeGripHovered]    = ImVec4(0.26, 0.59, 0.98, 0.67)
            colors[clr.ResizeGripActive]     = ImVec4(0.06, 0.05, 0.07, 1.00)
            colors[clr.CloseButton]          = ImVec4(0.40, 0.39, 0.38, 0.16)
            colors[clr.CloseButtonHovered]   = ImVec4(0.40, 0.39, 0.38, 0.39)
            colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
            colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
            colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
            colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
            colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
            colors[clr.TextSelectedBg]       = ImVec4(0.25, 1.00, 0.00, 0.43)
            colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
apply_custom_style()