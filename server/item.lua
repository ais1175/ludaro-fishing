if GetResourceState("es_extended") == "started" then
	if exports["es_extended"] and exports["es_extended"].getSharedObject then
		ESX = exports["es_extended"]:getSharedObject()
	else
		TriggerEvent("esx:getSharedObject", function(obj)
			ESX = obj
		end)
	end
end

RegisterNetEvent("ludaro-fishing:catchFish")
AddEventHandler("ludaro-fishing:catchFish", function(item, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addInventoryItem(item, amount)
end)

RegisterNetEvent("ludaro-fishing:removeItem")
AddEventHandler("ludaro-fishing:removeItem", function(item)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem(item, 1)
end)

lib.callback.register("ludaro-fishing:getFishingRod", function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	return xPlayer.getInventoryItem(Config.FishingRodItem).count > 0
end)

lib.callback.register("ludaro-fishing:hasenoughspace", function(source, item, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	return xPlayer.canCarryItem(item, amount)
end)
