local Relay = {}
Relay.__index = Relay

function Relay.new(peripheralName)
	local wrapped = peripheral.wrap(peripheralName)
	if not wrapped then
		error("Relay not found: " .. peripheralName)
	end

	local self = setmetatable({}, Relay)
	self.device = wrapped
	return self
end

function Relay:pulse(side)
	self:set_output(side, false)
    sleep(0.2)
    self:set_output(side, true)
    sleep(0.5)
    self:set_output(side, false)
end

function Relay:get_input(side)
    return self.device.getInput(side)
end

function Relay:get_output(side)
    return self.device.getOutput(side)
end

function Relay:set_output(side, value)
	self.device.setOutput(side, value)
end

return Relay
