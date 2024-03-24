if GetResourceState("es_extended") == "started" then
	if exports["es_extended"] and exports["es_extended"].getSharedObject then
		ESX = exports["es_extended"]:getSharedObject()
	else
		TriggerEvent("esx:getSharedObject", function(obj)
			ESX = obj
		end)
	end
end

local function SetFishingStatus(status)
	fishing = status
end

function getFishingStatus()
	return fishing
end

zones = {}
for k, v in pairs(Config.Locations) do
	onEnter = function()
		inside = true
	end

	onExit = function()
		inside = false
	end
	box = lib.zones.box({
		coords = vec3(v.coords.x, v.coords.y, v.coords.z),
		size = vec3(v.range, v.range, v.range),
		rotation = 45,
		debug = Config.Debug,
		inside = inside,
		onEnter = onEnter,
		onExit = onExit,
	})

	if v.blip.enable then
		-- add blip here with own code
		local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
		SetBlipSprite(blip, v.blip.sprite)
		SetBlipColour(blip, v.blip.color)
		SetBlipScale(blip, 0.8)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(v.blip.label)
		EndTextCommandSetBlipName(blip)
	end
end
function PerformRaycast(playerPed)
	-- Get player's position and heading
	local playerPos = GetEntityCoords(playerPed)
	local playerHeading = GetEntityHeading(playerPed)

	-- Calculate heading vector
	local headingVector = vector3(math.sin(math.rad(playerHeading)), math.cos(math.rad(playerHeading)), 0.0)

	-- Define raycast parameters
	local raycastStart = playerPos
	local raycastEnd = playerPos + headingVector * 100.0 -- Adjust 100.0 to desired max distance
	local flags = 16 | 1 -- Intersect everything (bit 4) and ignore some entities (bit 1)
	local ignoreEntity = playerPed -- Ignore player entity

	-- Perform the raycast
	local _, hit, hitCoords, _, _ = GetShapeTestResult(
		StartShapeTestRay(
			raycastStart.x,
			raycastStart.y,
			raycastStart.z,
			raycastEnd.x,
			raycastEnd.y,
			raycastEnd.z,
			flags,
			ignoreEntity,
			7
		)
	)

	-- Check if the ray hit something
	if hit then
		return hitCoords
	else
		return nil
	end
end

function IsFacingWater()
	local ped = PlayerPedId()
	local headPos = PerformRaycast(ped)
	local offsetPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 50.0, -25.0)
	local hit, hitPos = TestProbeAgainstWater(headPos.x, headPos.y, headPos.z, offsetPos.x, offsetPos.y, offsetPos.z)
	return hit
end

AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() == resourceName then
		StopFishing()
	end
end)
function StopFishing()
	if DoesEntityExist(rod) then
		DeleteEntity(rod)
	end
	DeleteNearbyFishingRods(2.0)
	SetFishingStatus(false) -- Set fishing status to false
	ClearPedTasks(PlayerPedId())
end

AddEventHandler("esx:onPlayerDeath", function(data)
	StopFishing()
end)

Citizen.CreateThread(function()
	while true do
		Wait(0)
		if fishing then
			if IsControlJustReleased(0, 73) then
				StopFishing()
			end
		end
	end
end)

function DeleteNearbyFishingRods(range)
	local playerPed = PlayerPedId()
	local playerPos = GetEntityCoords(playerPed)

	local objects = GetGamePool("CObject")
	for _, object in ipairs(objects) do
		local objectPos = GetEntityCoords(object)
		local distance = GetDistanceBetweenCoords(playerPos, objectPos, true)

		if distance <= range then
			local model = GetEntityModel(object)
			if model == GetHashKey("prop_fishing_rod_01") then
				DeleteEntity(object)
			end
		end
	end
end

function startFishingAnimation()
	fishing = true
	local ped = PlayerPedId()
	local fishing = "amb@world_human_stand_fishing@idle_a"
	RequestAnimDict(fishing)
	while not HasAnimDictLoaded(fishing) do
		Wait(100)
	end
	TaskPlayAnim(ped, fishing, "idle_a", 8.0, 8.0, -1, 1, 0, false, false, false)
	-- spawning the rod
	rod = CreateObject(GetHashKey("prop_fishing_rod_01"), 0, 0, 0, true, true, true)
	AttachEntityToEntity(
		rod,
		ped,
		GetPedBoneIndex(ped, 60309),
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		true,
		true,
		false,
		true,
		1,
		true
	)
	return rod
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if fishing then
			Wait(Config.TimeInterval)
			CatchFish()
		end
	end
end)

function getItem()
	local item = nil
	local total = 0
	for k, v in pairs(Config.Items) do
		total = total + v.rarity
	end
	local random = math.random(0, total)
	for k, v in pairs(Config.Items) do
		if random <= v.rarity then
			item = k
			break
		else
			random = random - v.rarity
		end
	end
	return item, Config.Items[item].amount
end

function CatchFish()
	-- make it so that the fishing rod can break if Config.FishingrodBreak = true
	if Config.CanFishingrodBreak then
		if math.random(0, 100) <= Config.FishingRodPercantage then
			Config.Functions.ShowNotification(Locale("fishingpolebroken"))
			TriggerServerEvent("ludaro-fishing:removeItem", Config.FishingRodItem)
			StopFishing()
			return
		end
	end

	local item, amount = getItem()
	if item then
		hasenoughspace = lib.callback.await("ludaro-fishing:hasenoughspace", false, item, amount)
		if not hasenoughspace then
			Config.Functions.ShowNotification(Locale("not_enough_space"))
			StopFishing()
			return
		end
		local amount = Config.Items[item].amount
		TriggerServerEvent("ludaro-fishing:catchFish", item, amount)
		Config.Functions.ShowNotification(string.format(Locale("caught"), amount, item))
	end
end
local fishing = false

function isInside()
	if Config.OnlyLocations then
		return inside
	else
		return false
	end
end

Citizen.CreateThread(function()
	while true do
		Wait(0)
		fishing = getFishingStatus()
		if isInside() and IsFacingWater() then
			Config.Functions.TextUI(Locale("pressetofish"))
			if IsControlJustReleased(0, 38) then
				hasfishingrod = lib.callback.await("ludaro-fishing:getFishingRod", false)
				if hasfishingrod then
					startFishingAnimation()
					fishing = true
					SetFishingStatus(true)
				else
					Config.Functions.ShowNotification(Locale("no_fishing_rod"))
				end
			end
		end
	end
end)

function Locale(msg)
	return Config.Locale[Config.Locale.Language][msg] or msg
end
