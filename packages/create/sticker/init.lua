local Reader = require("packages.block_reader")
local Relay = require("packages.relay")
local Logger = require "log"
-- Logger:disable()

STICKER_BLOCK_NAME = "create:sticker"
EXTENDED_FIELDNAME = "extended"

local Sticker = {}
Sticker.__index = Sticker

Sticker.State ={
    EXTENDED = true,
    RETRACTED = false
}

function Sticker.new(readerName, relayName, relay_side)
	local wrappedReader = Reader.new(readerName)
    local wrappedRelay = Relay.new(relayName)

	local self = setmetatable({}, Sticker)
	self.reader = wrappedReader
	self.relay = wrappedRelay
    self.relay_side = relay_side
    self.state = Sticker.State.RETRACTED -- Init to retracted
	return self
end

function Sticker:required_present()
    if not self:is_present() then
        error("Sticker not present")
    end
end

function Sticker:is_present()
    return self.reader:is_block(STICKER_BLOCK_NAME)
end

function Sticker:set_state(new_state)
    Logger.trace("Current state: ", self.current_state)
    self.current_state = new_state
end

function Sticker:read_state()
    self:required_present()
	self:set_state(self.reader:getBlockStateValue(EXTENDED_FIELDNAME))
end

function Sticker:toggle_sticker()
    Logger.trace("Toggling sticker")
    self.relay:set_output(self.relay_side, false)
    sleep(0.2)
    self.relay:set_output(self.relay_side, true)
    sleep(0.2)
    self.relay:set_output(self.relay_side, false)

    self:set_state(not self.current_state)
    return true
end

function Sticker:set_extended(should_extended)
    Logger.trace("Is extended: ", self.current_state)
    if (should_extended ~= self.current_state) then
        self:toggle_sticker()
    end
end

function Sticker:extend()
    Logger.trace("Extending")
    local result = self:set_extended(true)
    Logger.trace("Extended")
    return result
end

function Sticker:retract()
    Logger.trace("Retracting")
    local result =  self:set_extended(false)
    Logger.trace("retracted")
    return result
end

function Sticker:calibrate()
    self:read_state()
    self:retract()
end

return Sticker
