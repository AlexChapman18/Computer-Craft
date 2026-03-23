local equip = {
	Equipment = {
		PICKAXE = "minecraft:diamond_pickaxe",
		CHATBOX = "advancedperipherals:chat_box",
		MODEM = "computercraft:wireless_modem_advanced",
	},
	Side = {
		LEFT = "left",
		RIGHT = "right",
	},
}

-- imports
local inventory = require("turtle_helpers.inventory")

-- Enum
GetEquipmentFunc = {
	[equip.Side.LEFT] = turtle.getEquippedLeft,
	[equip.Side.RIGHT] = turtle.getEquippedRight,
}

-- Equip Left/Right
function equip.right(equipment)
	equipItem(equipment, equip.Side.RIGHT)
end

function equip.left(equip)
	equipItem(equip, equip.Side.LEFT)
end

-- Get the name of the equip on side
function getEquipmentNameOnSide(side)
	local equippedItem = GetEquipmentFunc[side]()
	if equippedItem then
		return equippedItem.name
	else
		return ""
	end
end

-- Given an item and a side, equip it
function equipItem(itemName, side)
	local itemNotEquipped = (getEquipmentNameOnSide(side) ~= itemName)
	if itemNotEquipped then
		inventory.findAndSelectItem(itemName)
		turtle.equipRight()
	end
end

return equip
