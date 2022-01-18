local QBCore = exports['qb-core']:GetCoreObject()
local closestScrapyard = 0
local isBusy = false

CreateThread(function()
	for id, scrapyard in pairs(Config.Locations) do
		local blip = AddBlipForCoord(Config.Locations[id]["main"].x, Config.Locations[id]["main"].y, Config.Locations[id]["main"].z)
        SetBlipSprite(blip, 380)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 9)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Scrap Yard")
        EndTextCommandSetBlipName(blip)
	end
    Wait(1000)
    while true do
        SetClosestScrapyard()
        Wait(10000)
    end
end)

CreateThread(function()
	while true do
		Wait(1)
		if closestScrapyard ~= 0 then
			local pos = GetEntityCoords(PlayerPedId())
			if #(pos - vector3(Config.Locations[closestScrapyard]["deliver"].x, Config.Locations[closestScrapyard]["deliver"].y, Config.Locations[closestScrapyard]["deliver"].z)) < 10.0 then
				local vehicle = vGetClosestVehicle(pos)
				if vehicle ~= 0 and vehicle ~= nil then
					local vehpos = GetEntityCoords(vehicle)
					if #(pos - vector3(vehpos.x, vehpos.y, vehpos.z)) < 15.0  and not isBusy then
						if IsPedInAnyVehicle(PlayerPedId()) then
							exports['qb-drawtext']:DrawText('Park Vehicle','left')
						else
							exports['qb-drawtext']:DrawText('Scrap Vehicle','left')
							if IsControlJustReleased(0, 38) then
								exports['qb-drawtext']:KeyPressed()
								local plate = QBCore.Functions.GetPlate(vehicle)
								if plate == nil then 
									QBCore.Functions.Notify("Inavlid Plate", "error")
								else
									isBusy = true
									QBCore.Functions.TriggerCallback('stix-vinsystem:server:getVehicleVin', function(vin, vehicle)
										if vin == 'scratched' then
											print('Export Called - A', vin, plate)
											
											ScrapVehicle(vehicle)
										elseif vin ~= nil and vin ~= 'scratched' then
											print('Export Called - B', vin, plate)
								
											QBCore.Functions.Notify("This vehicle still has traceable parts, please remove vin.", "error")
										end
									end, plate)
								end
							end
						end
					else
						exports['qb-drawtext']:HideText()
					end
				end
			else
				exports['qb-drawtext']:HideText()
			end
		end
	end
end)

vGetClosestVehicle = function(coords)
    if coords == nil then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
    end

    Wait(100)

    local cv = QBCore.Functions.GetClosestVehicle(coords)

    if cv == nil then
        return false
    else
        return cv        
    end
end


function ScrapVehicle(vehicle)
	isBusy = true
	local scrapTime = math.random(28000, 37000)
	ScrapVehicleAnim(scrapTime)
	QBCore.Functions.Progressbar("scrap_vehicle", "Demolish Vehicle", scrapTime, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		StopAnimTask(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 1.0)
		TriggerServerEvent("qb-scrapyard:server:ScrapVehicle")
		SetEntityAsMissionEntity(vehicle, true, true)
		DeleteVehicle(vGetClosestVehicle())
		isBusy = false
	end, function() -- Cancel
		StopAnimTask(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 1.0)
		isBusy = false
		QBCore.Functions.Notify("Canceled", "error")
	end)
end

function SetClosestScrapyard()
	local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil
	for id, scrapyard in pairs(Config.Locations) do
		if current ~= nil then
			if #(pos - vector3(Config.Locations[id]["main"].x, Config.Locations[id]["main"].y, Config.Locations[id]["main"].z)) < dist then
				current = id
				dist = #(pos - vector3(Config.Locations[id]["main"].x, Config.Locations[id]["main"].y, Config.Locations[id]["main"].z))
			end
		else
			dist = #(pos - vector3(Config.Locations[id]["main"].x, Config.Locations[id]["main"].y, Config.Locations[id]["main"].z))
			current = id
		end
	end
	closestScrapyard = current
end

function ScrapVehicleAnim(time)
    time = (time / 1000)
    loadAnimDict("mp_car_bomb")
    TaskPlayAnim(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic" ,3.0, 3.0, -1, 16, 0, false, false, false)
    openingDoor = true
    CreateThread(function()
        while openingDoor do
            TaskPlayAnim(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Wait(2000)
			time = time - 2
            if time <= 0 then
                openingDoor = false
                StopAnimTask(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 1.0)
            end
        end
    end)
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end
