local Miner = {}
Miner.__index = Miner

function Miner.new(peripheralName)
	local wrapped = peripheral.wrap(peripheralName)
	if not wrapped then
		error("No peripheral found on " .. peripheralName)
	end

	local self = setmetatable({}, Miner)
	self.device = wrapped
	return self
end

function Miner:start()
	return self.device.start()
end

function Miner:stop()
	return self.device.stop()
end

function Miner:isRunning()
	return self.device.isRunning()
end

function Miner:getToMine()
	return self.device.getToMine()
end

function Miner:isFinished()
	return self:getToMine() == 0
end

return Miner
