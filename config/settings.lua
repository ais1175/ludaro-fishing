Config.OnlyLocations = true -- If true, only locations in the Locations table will be used. If false, you can fish anywhere
Config.Debug = true -- If true, debug messages will be printed to the console
Config.Locations = {
	[1] = {
		coords = vector4(-1709.4929, -2498.2036, 3.2295, 301.8156),
		range = 30,
		blip = {
			enable = true,
			sprite = 68,
			color = 2,
			label = "Fishing Spot",
		},
	},
}
Config.FishingRodItem = "petrol"
Config.CanFishingrodBreak = true -- If true, the fishing rod can break
Config.FishingRodPercantage = 20 -- The percentage of the fishing rod breaking

Config.TimeInterval = 10000 -- Time in milliseconds to get a fish or something in the Config.Items table

Config.Items = {

	["fish"] = {
		rarity = 80, -- in percent
		amount = 2, -- how much
	},

	["wood"] = {
		rarity = 10, -- in percent
		amount = 1, -- how much
	},

	["alive_chicken"] = {
		rarity = 5, -- in percent
		amount = 1, -- how much
	},
}
