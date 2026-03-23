Sticker = require("sticker")
Station = require("train_station")
Relay = require("relay")
Common = require("common")

local my_sticker = Sticker.new("block_reader_3", "redstone_relay_199", Common.Side.FRONT)
local my_station = Station.new("Create_Station_16", "redstone_relay_206", "redstone_relay_207", Common.Side.BACK, Common.Side.TOP, Common.Side.RIGHT, Common.Side.FRONT)


local load = false
while true do
    print("Waiting")
    while not my_station:train_present() do
        print("Waiting for train to arrive")
        sleep(1)
    end
    sleep(5)

    print("disassemble")
    my_station:disassemble()
    sleep(1)

    print("calibrate")
    my_sticker:calibrate()
    if load then
        my_sticker:extend()
    else
        my_sticker:retract()
    end
    load = not load

    sleep(1)
    print("assemble")
    my_station:assemble()
    sleep(1)

    print("set_output")
    my_station:trigger_station_redstone()
    
    while my_station:train_present() do
        print("Waiting for train to leave")
        sleep(1)
    end
end
