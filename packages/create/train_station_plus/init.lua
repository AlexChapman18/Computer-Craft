local Relay = require("packages.peripherals.advanced_peripherals.relay")

local Station = {}
Station.__index = Station

function Station.new(stationName, breakerPlacerName, deployerName, breakerSide, placerSide, deployerSide, stationSide)
    local wrappedStation = peripheral.wrap(stationName)
	if not wrappedStation then
		error("Station not found: " .. stationName)
	end
    local breakerPlacerRelay = Relay.new(breakerPlacerName)
    local deployerRelay = Relay.new(deployerName)

	local self = setmetatable({}, Station)
	self.wrappedStation = wrappedStation
	self.breakerPlacerRelay = breakerPlacerRelay
	self.deployerRelay = deployerRelay

    self.stationName = stationName
    self.breakerSide = breakerSide
    self.placerSide = placerSide
    self.deployerSide = deployerSide
    self.stationSide = stationSide
	return self
end

function Station:toggle_deployer()
    self.deployerRelay:pulse(self.deployerSide)
end

function Station:is_assembled()
    return not self.wrappedStation:isInAssemblyMode()
end

function Station:ensure_connected()
    if not peripheral.wrap(self.stationName) then
        self.breakerPlacerRelay:pulse(self.placerSide)
        sleep(0.5)
        if not peripheral.wrap(self.stationName) then
            error("Failed to connect station")
        end
    end
end


function Station:ensure_disconnected()
    if peripheral.wrap(self.stationName) then
        self.breakerPlacerRelay:pulse(self.breakerSide)
        sleep(0.5)
        if peripheral.wrap(self.stationName) then
            error("Failed to disconnect station")
        end
    end
end

function Station:assemble()
    if not self.wrappedStation.isInAssemblyMode() then
        return
    end
    self:ensure_disconnected()
    self:toggle_deployer()
    sleep(3)
    self:ensure_connected()
    if self.wrappedStation.isInAssemblyMode() then
        error("Failed to assemble train")
    end
end

function Station:disassemble()
    if self.wrappedStation.isInAssemblyMode() then
        return
    end
    self:ensure_disconnected()
    self:toggle_deployer()
    sleep(3)
    self:ensure_connected()
    if not self.wrappedStation.isInAssemblyMode() then
        error("Failed to dissasemble train")
    end
end

function Station:train_present()
	return self.wrappedStation:isTrainPresent()
end

function Station:trigger_station_redstone()
    self.deployerRelay:pulse(self.stationSide)
end

return Station