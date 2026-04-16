-- Based on: https://wiki.createmod.net/users/cc-tweaked-integration/train/train-station

-- "Inherit" from Peripheral Base
local PeripheralBase  = require("packages.peripherals_base")

local SpeakerBlock = {
    NAME = "Speaker Block",
    BLOCK_TYPE = "supplementaries:speaker_block"
}

SpeakerBlock.Narrator ={
    CHAT = "CHAT",
    NARRATOR = "NARRATOR"
}

function SpeakerBlock.new(peripheral_name)
    return PeripheralBase.new(SpeakerBlock, peripheral_name)
end

return SpeakerBlock
