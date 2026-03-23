local Reader = {}
Reader.__index = Reader

function Reader.new(peripheralName)
	local wrapped = peripheral.wrap(peripheralName)
	if not wrapped then
		error("Block Reader not found: " .. peripheralName)
	end

	local self = setmetatable({}, Reader)
	self.device = wrapped
	return self
end

function Reader:is_block(name)
    return self.device.getBlockName() == name
end

function Reader:getBlockStateValue(field)
	return self.device.getBlockStates()[field]
end

return Reader
