local interact = {
	Side = {
		UP = "up",
		FRONT = "front",
		DOWN = "down",
	},
}

-- Imports
local equip = require("packages.turtle_helpers.equipment")
local inv = require("packages.turtle_helpers.inventory")

-- Enum
SideDigFunc = {
	[interact.Side.UP] = turtle.digUp,
	[interact.Side.FRONT] = turtle.dig,
	[interact.Side.DOWN] = turtle.digDown,
}
SidePlaceFunc = {
	[interact.Side.UP] = turtle.placeUp,
	[interact.Side.FRONT] = turtle.place,
	[interact.Side.DOWN] = turtle.placeDown,
}
SideInspectFunc = {
	[interact.Side.UP] = turtle.inspectUp,
	[interact.Side.FRONT] = turtle.inspect,
	[interact.Side.DOWN] = turtle.inspectDown,
}

-- Block Breaking
function interact.mineBlockAbove()
	equip.right(equip.Equipment.PICKAXE)
	return turtle.digUp()
end

-- Block Breaking
function interact.mineBlockForward()
	equip.right(equip.Equipment.PICKAXE)
	return turtle.dig()
end

-- Block quering
function interact.isBlockAboveNamed(desiredBlockName)
	return isBlockOnSideNamed(interact.Side.UP, desiredBlockName)
end

function isBlockOnSideNamed(side, desiredBlockName)
	local isBlockPresent, blockDetails = SideInspectFunc[side]()
	local blockName = blockDetails.name
	local isDesiredBlock = (blockName == desiredBlockName)
	return isBlockPresent and isDesiredBlock
end

-- Block placing
function interact.placeBlockAbove(itemName)
	inv.findAndSelectItem(itemName)
	success = turtle.placeUp()
	if not success then
		error("Failed to place block above: " .. itemName)
	end
end

return interact
