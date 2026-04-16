Common = require("packages.common")

-- https://websockets.readthedocs.io/en/stable/intro/tutorial2.html

local SERVER = "wss://adchapman.co.uk/ws/cc_tunnel"
local TOKEN = "supersecret123"
local bearer_token = ("Bearer " .. TOKEN)

local ws, error = http.websocket(
    SERVER,
    {["Authorization"] = bearer_token
})
if ws then
    print("Hello!")
    ws.send("Hello!") -- Send a message
    local received = ws.receive()
    print(received) -- And receive the reply
    ws.close()
else
    print("Error: ", error)
end
