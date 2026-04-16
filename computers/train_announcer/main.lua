Station = require("packages.peripherals.create.train_station")
Speaker = require("packages.peripherals.supplementaries.speaker_block")

local station = Station.new()
local speaker = Speaker.new()

speaker:setName(".")
speaker:setNarrator(Speaker.Narrator.NARRATOR)

while true do
    print("Waiting")
    while not station:isTrainPresent() do
        print("Waiting for train to arrive")
        sleep(1)
    end

    local train_name = station:getTrainName()
    local announcement_message = "train, " .. train_name .. ", has arrived"
    speaker:setMessage(announcement_message)
    speaker:activate()
    print("Speaker: " .. announcement_message)

    while station:isTrainPresent() do
        print("Waiting for train to leave")
        sleep(1)
    end
end