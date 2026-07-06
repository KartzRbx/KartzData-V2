local Data = {
	Currencies = {
		Coins = 0,
		Gems = 0,
	},
	Stats = {
		Level = 1,
		XP = 0,
	},
	Inventory = {} :: { string },
	Units = {
		List = {
			{ Name = "Warrior", Damage = 500 },
			{ Name = "Mage", Damage = 700 },
		},
	},
	Private = {
		AdminFlags = {},
	},
}

export type Schema = typeof(Data)

return Data
