--============================================================================
script_name("ClickCoord")
script_authors("NotReal", "FYP", "Mercy")
script_version_number(5)
script_moonloader(19)
script_dependencies("SAMPFUNCS")
script_description("Click click, teleport!")
--==================================[Библиотеки]==============================
require "lib.moonloader"
require"lib.sampfuncs"
require('moonloader')

local hook 				= require 'lib.samp.events'
local vector 			= require 'vector3d'
local imgui 			= require("imgui")
local encoding 			= require 'encoding'
local Matrix3X3 		= require "matrix3x3"
local Vector3D 			= require "vector3d"

--============================================================================

local tp, sync = false, false
local tpCount, timer = 3, 3

distancetp = imgui.ImFloat(21.5) -- 21.5
waittp = imgui.ImFloat(350) -- 350

keyToggle = VK_MBUTTON
keyApply = VK_LBUTTON

--============================================================================

encoding.default = 'CP1251'
u8 = encoding.UTF8

local window = imgui.ImBool(false)
local statustp = imgui.ImBool(true)

--============================================================================

function main()
    repeat wait(0) until isSampAvailable()
    wait(1000)
		
		sampRegisterChatCommand("tpmenu", function()
			window.v = not window.v
		end)
		sampRegisterChatCommand('tp', teleport)
		
		imgui.Process = false
	    window.v = false
		
		initializeRender()
	  
		while true do

		if isKeyDown(0x2D) and not sampIsChatInputActive() and not sampIsDialogActive()  then
			window.v = not window.v
			wait(200)
		end

		if statustp.v then
		
			if os.clock() - timer > 2600 and sync then
				timer, tpCount = 0, 0
				sync = true
				sampForceOnfootSync()
				sync = false
				sampForceOnfootSync()
			end
		
			if tp then
				if getDistanceBetweenCoords3d(blipX, blipY, blipZ, charPosX, charPosY, charPosZ) > 19 then
					sync = true
					vectorX = blipX - charPosX
					vectorY = blipY - charPosY
					vectorZ = blipZ - charPosZ
					local vec = vector(vectorX, vectorY, vectorZ)
					vec:normalize()
					charPosX = charPosX + vec.x * distancetp.v
					charPosY = charPosY + vec.y * distancetp.v
					charPosZ = charPosZ + vec.z * distancetp.v
					
					sendOnfootSync(charPosX, charPosY, charPosZ)
					sendOnfootSync(charPosX, charPosY, charPosZ)
					local dist = getDistanceBetweenCoords3d(blipX, blipY, blipZ, charPosX, charPosY, charPosZ)
					if dist > 5 then
						printStringNow(string.format("[TP by MERCY] %0.2fM", dist), 1000)
					end
					wait(waittp.v)
					else
						sendOnfootSync(charPosX, charPosY, charPosZ)
						setCharCoordinates(playerPed, blipX, blipY, blipZ)
						sampForceAimSync()
						sampForceOnfootSync()
						tp = false
						sync = false
						act = false
				end
			end
		
			if isKeyDown(keyToggle) then
					cursorEnabled = not cursorEnabled
					showCursor(cursorEnabled)
					while isKeyDown(keyToggle) do wait(80) end
			end

			if cursorEnabled then
			  local mode = sampGetCursorMode()
			  if mode == 0 then
				showCursor(true)
			  end
			  local sx, sy = getCursorPos()
			  local sw, sh = getScreenResolution()
			  -- is cursor in game window bounds?
			  if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
				local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 300.0)
				local camX, camY, camZ = getActiveCameraCoordinates()
				-- search for the collision point
				local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
				if result and colpoint.entity ~= 0 then
				  local normal = colpoint.normal
				  local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
				  local zOffset = 300
				  if normal[3] >= 0.5 then zOffset = 1 end
				  -- search for the ground position vertically down
				  local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3,
					true, true, false, true, false, false, false)
				  if result then
					pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)

					local curX, curY, curZ  = getCharCoordinates(playerPed)
					local dist              = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
					local hoffs             = renderGetFontDrawHeight(font)

					sy = sy - 2
					sx = sx - 2
					renderFontDrawText(font, string.format("%0.2fM", dist), sx, sy - hoffs, 0xFECCEDBF)

					local tpIntoCar = nil
					if colpoint.entityType == 2 then
					  local car = getVehiclePointerHandle(colpoint.entity)
					  if doesVehicleExist(car) and (not isCharInAnyCar(playerPed) or storeCarCharIsInNoSave(playerPed) ~= car) then
						displayVehicleName(sx, sy - hoffs * 2, getNameOfVehicleModel(getCarModel(car)))
						local color = 0xAAFFFFFF
						if isKeyDown(VK_RBUTTON) then
						  tpIntoCar = car
						  color = 0xFFFFFFFF
						end
						renderFontDrawText(font2, "Hold right mouse button to teleport into the car", sx, sy - hoffs * 3, color)
					  end
					end

					createPointMarker(pos.x, pos.y, pos.z)
					
					if isKeyDown(keyApply) then
					  if tpIntoCar then
						if not jumpIntoCar(tpIntoCar) then
						  -- teleport to the car if there is no free seats
						  teleportPlayer(pos.x, pos.y, pos.z)
						end
					  else
						teleportPlayer(pos.x, pos.y, pos.z)
					  end
					  removePointMarker()

					  while isKeyDown(keyApply) do wait(0) end
					  showCursor(false)
					end
				  end
				end
			  end
			end
		
		end
		
		wait(0)
		removePointMarker()

		imgui.Process = window.v
		
		end
	end

function teleport(args)
		lua_thread.create(function()	
			if args == 'm' then
				blip, blipX, blipY, blipZ = getTargetBlipCoordinatesFixed()					
				teleportPlayer(blipX, blipY, blipZ)		
			elseif args == 'c' then
				blap, blapX, blapY, blapZ = SearchMarker()				
				teleportPlayer(blapX, blapY, blapZ)		
			else
				sampAddChatMessage(tag .. "Не верный параметр.", -1)
				return			
			end	
		end)
	end

function getTargetBlipCoordinatesFixed()
	local bool, x, y, z = getTargetBlipCoordinates(); 
    if not bool then 
        return false 
    end
    requestCollision(x, y); loadScene(x, y, z)
    local bool, x, y, z = getTargetBlipCoordinates()
    return bool, x, y, z
end

function SearchMarker()
	local isFind = false
    if not isFind then
        local ret_posX = 0.0
        local ret_posY = 0.0
        local ret_posZ = 0.0
        for id = 0, 31 do
            local MarkerStruct = 0
            MarkerStruct = 0xC7F168 + id * 56
            local MarkerPosX = representIntAsFloat(readMemory(MarkerStruct + 0, 4, false))
            local MarkerPosY = representIntAsFloat(readMemory(MarkerStruct + 4, 4, false))
            local MarkerPosZ = representIntAsFloat(readMemory(MarkerStruct + 8, 4, false))
            if MarkerPosX ~= 0.0 or MarkerPosY ~= 0.0 or MarkerPosZ ~= 0.0 then
                ret_posX = MarkerPosX
                ret_posY = MarkerPosY
                ret_posZ = MarkerPosZ
                isFind = true
            end
        end
        return isFind, ret_posX, ret_posY, ret_posZ
    end
end

function imgui.OnDrawFrame() 
    if window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(450.0, 280.0), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(415.0, 200.0), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'Телепорт by Mercy', window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		
		if imgui.Checkbox(u8'Включить/Выключить телепорт.', statustp) then
		
		end		

		imgui.SliderFloat(u8"Дистанция прыжка.", distancetp, 1.0, 50)

		imgui.SliderFloat(u8"Задержка прыжка.", waittp, 0, 1000)

		imgui.End()		
	end
end	

function initializeRender()
  font = renderCreateFont("Tahoma", 9, FCR_BOLD + FCR_BORDER)
  font2 = renderCreateFont("Arial", 7, FCR_ITALICS + FCR_BORDER)
end

function rotateCarAroundUpAxis(car, vec)
  local mat = Matrix3X3(getVehicleRotationMatrix(car))
  local rotAxis = Vector3D(mat.up:get())
  vec:normalize()
  rotAxis:normalize()
  local theta = math.acos(rotAxis:dotProduct(vec))
  if theta ~= 0 then
    rotAxis:crossProduct(vec)
    rotAxis:normalize()
    rotAxis:zeroNearZero()
    mat = mat:rotate(rotAxis, -theta)
  end
  setVehicleRotationMatrix(car, mat:get())
end

function readFloatArray(ptr, idx)
  return representIntAsFloat(readMemory(ptr + idx * 4, 4, false))
end

function writeFloatArray(ptr, idx, value)
  writeMemory(ptr + idx * 4, 4, representFloatAsInt(value), false)
end

function getVehicleRotationMatrix(car)
  local entityPtr = getCarPointer(car)
  if entityPtr ~= 0 then
    local mat = readMemory(entityPtr + 0x14, 4, false)
    if mat ~= 0 then
      local rx, ry, rz, fx, fy, fz, ux, uy, uz
      rx = readFloatArray(mat, 0)
      ry = readFloatArray(mat, 1)
      rz = readFloatArray(mat, 2)

      fx = readFloatArray(mat, 4)
      fy = readFloatArray(mat, 5)
      fz = readFloatArray(mat, 6)

      ux = readFloatArray(mat, 8)
      uy = readFloatArray(mat, 9)
      uz = readFloatArray(mat, 10)
      return rx, ry, rz, fx, fy, fz, ux, uy, uz
    end
  end
end

function setVehicleRotationMatrix(car, rx, ry, rz, fx, fy, fz, ux, uy, uz)
  local entityPtr = getCarPointer(car)
  if entityPtr ~= 0 then
    local mat = readMemory(entityPtr + 0x14, 4, false)
    if mat ~= 0 then
      writeFloatArray(mat, 0, rx)
      writeFloatArray(mat, 1, ry)
      writeFloatArray(mat, 2, rz)

      writeFloatArray(mat, 4, fx)
      writeFloatArray(mat, 5, fy)
      writeFloatArray(mat, 6, fz)

      writeFloatArray(mat, 8, ux)
      writeFloatArray(mat, 9, uy)
      writeFloatArray(mat, 10, uz)
    end
  end
end

function displayVehicleName(x, y, gxt)
  x, y = convertWindowScreenCoordsToGameScreenCoords(x, y)
  useRenderCommands(true)
  setTextWrapx(600.0)
  setTextProportional(true)
  setTextJustify(false)
  setTextScale(0.33, 0.75)
  setTextDropshadow(0, 0, 0, 0, 0)
  setTextColour(255, 255, 255, 230)
  setTextEdge(1, 0, 0, 0, 100)
  setTextFont(1)
  displayText(x, y, gxt)
end

function createPointMarker(x, y, z)
  pointMarker = createUser3dMarker(x, y, z + 0.3, 144)
end

function removePointMarker()
  if pointMarker then
    removeUser3dMarker(pointMarker)
    pointMarker = nil
  end
end

function getCarFreeSeat(car)
  if doesCharExist(getDriverOfCar(car)) then
    local maxPassengers = getMaximumNumberOfPassengers(car)
    for i = 0, maxPassengers do
      if isCarPassengerSeatFree(car, i) then
        return i + 1
      end
    end
    return nil -- no free seats
  else
    return 0 -- driver seat
  end
end

function jumpIntoCar(car)
  local res , carid = sampGetVehicleIdByCarHandle(car)
  if res then 
	local x, y, z = getCarCoordinates(car) 
	lua_thread.create(function() 
		setCharCoordinates(PLAYER_PED, x, y, z) 
		wait(300) 
		sampSendEnterVehicle(carid, 1) 
		wait(800) 
		warpCharIntoCarAsPassenger(PLAYER_PED, car, 0) 
	end) 
  end 
  return true
end

function teleportPlayer(x, y, z)
  local px,py,pz = getCharCoordinates(PLAYER_PED)
  local dist = getDistanceBetweenCoords3d(px,py,pz,x,y,z)
  if isCharInAnyCar(playerPed) then
    sampAddChatMessage('teleport incar',-1)
	blipXa, blipYa, blipZa = x,y,z
	charPosXa, charPosYa, charPosZa = px,py,pz
    tpa = true
	sync = true
  end
  if dist > 19 then
    blipX, blipY, blipZ = x,y,z
	sync = true
	charPosX, charPosY, charPosZ = px,py,pz
	tp = true
  else
    setCharCoordinatesDontResetAnim(playerPed, x, y, z)
  end
end

function setCharCoordinatesDontResetAnim(char, x, y, z)
  if doesCharExist(char) then
    local ptr = getCharPointer(char)
    setEntityCoordinates(ptr, x, y, z)
  end
end

function setEntityCoordinates(entityPtr, x, y, z)
  if entityPtr ~= 0 then
    local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
    if matrixPtr ~= 0 then
      local posPtr = matrixPtr + 0x30
      writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
      writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
      writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
    end
  end
end

function showCursor(toggle)
  if toggle then
    sampSetCursorMode(CMODE_LOCKCAM)
  else
    sampToggleCursor(false)
  end
  cursorEnabled = toggle
end

function sendOnfootSync(x, y, z)
    local data = samp_create_sync_data('player')
	data.position = {x, y, z}
	data.moveSpeed = {-0.7, 0.7, 0.1}
	data.send()
end

function sendOnfootSync1(x, y, z)
    local data = samp_create_sync_data('vehicle')
	data.position = {x, y, z}
	data.moveSpeed = {0.0, 0.3, 0.03}
	data.send()
end

function hook.onSetPlayerPos(p)
  if sync then
	timer = os.clock()
	return false
  end
end

function hook.onSendPlayerSync(data)
  if tp then return false end
end

function hook.onSetPlayerPosition(p)
	if sync then
		return false
	end
end

function hook.onSetVehiclePosition(p)
	if sync then
		timer = os.clock()
		return false
	end
end

function hook.onSetVehiclePos(p)
	if sync then
		timer = os.clock()
		return false
	end
end

function hook.onSendVehicleSync(data)
	if tp then return false end
end

function samp_create_sync_data(sync_type, copy_from_player)
	local ffi = require 'ffi'
	local sampfuncs = require 'sampfuncs'
	-- from SAMP.Lua
	local raknet = require 'samp.raknet'
	--require 'samp.synchronization'

	copy_from_player = copy_from_player or true
	local sync_traits = {
		player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
		vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
		passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
		aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
		trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
		unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
		bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
		spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
	}
	local sync_info = sync_traits[sync_type]
	local data_type = 'struct ' .. sync_info[1]
	local data = ffi.new(data_type, {})
	local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
	-- copy player's sync data to the allocated memory
	if copy_from_player then
		local copy_func = sync_info[3]
		if copy_func then
			local _, player_id
			if copy_from_player == true then
				_, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
			else
				player_id = tonumber(copy_from_player)
			end
			copy_func(player_id, raw_data_ptr)
		end
	end
	-- function to send packet
	local func_send = function()
		local bs = raknetNewBitStream()
		raknetBitStreamWriteInt8(bs, sync_info[2])
		raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
		raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
		raknetDeleteBitStream(bs)
	end
	-- metatable to access sync data and 'send' function
	local mt = {
		__index = function(t, index)
			return data[index]
		end,
		__newindex = function(t, index, value)
			data[index] = value
		end
	}
	return setmetatable({send = func_send}, mt)
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