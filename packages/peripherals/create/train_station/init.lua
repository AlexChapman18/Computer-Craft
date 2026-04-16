-- Based on: https://wiki.createmod.net/users/cc-tweaked-integration/train/train-station

-- "Inherit" from Peripheral Base
local PeripheralBase  = require("packages.peripherals_base")

local TrainStation = {
    NAME = "Train Station",
    BLOCK_TYPE = "Create_Station"
}

function TrainStation.new(peripheral_name)
    return PeripheralBase.new(TrainStation, peripheral_name)
end

return TrainStation
