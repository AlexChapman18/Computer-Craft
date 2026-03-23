local inventory = {}

-- Constants
TOTAL_INVENTORY_SLOTS = 16

-- Equipment
function inventory.findAndSelectItem(itemName)
	local itemIndex = findItemIndex(itemName)
	turtle.select(itemIndex)
end

function findItemIndex(itemName)
	for i = 1, TOTAL_INVENTORY_SLOTS do
		local itemDetails = turtle.getItemDetail(i)
		if itemDetails and (itemDetails.name == itemName) then
			-- Return slot index of item in inventory
			return i
		end
	end
	error("Item not found: " .. itemName)
end

return inventory
