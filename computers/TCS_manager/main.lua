TurtleHelpers = require("packages.turtle_helpers")

-- https://websockets.readthedocs.io/en/stable/intro/tutorial2.html

local SERVER = "wss://adchapman.co.uk/ws/cc_tunnel"
local TOKEN = "supersecret123"
local BEARER_TOKEN = ("Bearer " .. TOKEN)

local ws, error = http.websocket(
    SERVER,
    {["Authorization"] = BEARER_TOKEN
})

local function sendPacket(ws, data)
    ws.send(textutils.serializeJSON(data))
end

local movement_map = {
    forward = TurtleHelpers.Movement.forward,
    backward = TurtleHelpers.Movement.back,
    left = TurtleHelpers.Movement.left,
    right = TurtleHelpers.Movement.right,
    up = TurtleHelpers.Movement.up,
    down = TurtleHelpers.Movement.down
}

local action_map = {
    dig = TurtleHelpers.Interaction.mineBlockForward,
}

local init_packet = {
    type = "init",
    id = os.getComputerID()
}

if ws then
    print("Sending Init")
    sendPacket(ws, init_packet)
    sleep(2)

    while true do
        local reply = ws.receive()

        if reply then
            local data = textutils.unserializeJSON(reply)
            textutils.pagedTabulate(data)
            if data["type"] == "move" then
                print("Moving: " .. data["direction"])
                movement_map[data["direction"]]()
            elseif data["type"] == "action" then
                print("Actioning: " .. data["action"])
                action_map[data["action"]]()
            end
        else
            print("Connection closed")
        end
    end
    ws.close()
else
    print("Error: ", error)
end
