local PeripheralBase = {}

PeripheralBase.__index = function(self, key)
    local class = rawget(self, "__class")
    -- Call function of wrapper if it exists first
    if class and class[key] ~= nil then
        return class[key]
    end

    -- Call function on underlying device
    local device = rawget(self, "device")
    if device then
        local value = device[key]
        if type(value) == "function" then
            -- Ignore the first parameter (PeripheralBase), forward the rest of the parameters
            -- Turning PeripheralBase:getName() -> device:getName()
            return function(_, ...)
                return value(...)
            end
        end
        return value
    end
end

local function resolveDevice(class, name)
    local device
    if name then
        device = peripheral.wrap(name)
    else
        device = peripheral.find(class.BLOCK_TYPE)
    end

	if not device then
		error("Peripheral not found: " .. (name or class.NAME))
	end

	return device
end

PeripheralBase.new = function(class, name)
    local device = resolveDevice(class, name)
    
    return setmetatable({
        device = device,
        __class = class
    }, PeripheralBase)
end

return PeripheralBase




