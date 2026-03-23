-- Imports
Logger = require "log"
Logger:enable()
Sticker = require("sticker")
Common = require("common")

local Side = {
    FRONT = "front",
    LEFT = "left",
    RIGHT = "right",
    TOP = "top",
    BOTTOM = "bottom",
    BACK = "back"
}

local CRANE_RELAY_ID = "redstone_relay_197"
local HOME_RELAY_ID =  "redstone_relay_26"
local CONTACT_SIDE = Side.BOTTOM
local LAMP_SIDE = Side.BACK

local CLOCKWISE_INPUT = false

local GantryState = {
    MOVING = false,
    THROUGHPUT = true,
}
local ClutchState = {
    INACTIVE = false,
    ACTIVE = true,
}
local GearshiftState = {
    CLOCKWISE = not CLOCKWISE_INPUT,
    COUNTER_CLOCKWISE = CLOCKWISE_INPUT
}
local GantryDirection = {
    POSITIVE = true,
    NEGATIVE = false
}
local PullyDirection = {
    UP = false,
    DOWN = true
}


-- Crane Relay
local CraneRelaySides = {
    A_GEARSHIFT = Side.TOP,
    B_CLUTCH = Side.LEFT,
    C_GANTRY = Side.BACK,
    D_GANTRY = Side.RIGHT,
    E_STICKER = Side.BOTTOM
}

-- IDK
local my_sticker = Sticker.new("block_reader_2", "redstone_relay_197", Common.Side.BOTTOM)

local function filter_table_by_value(input, text)
    local result = {}

    for _, name in ipairs(input) do
        local is_redstone_relay = string.find(name, text, 1, true)
        if (is_redstone_relay and (name ~= CRANE_RELAY_ID)) then
            table.insert(result, name)
        end
    end

    return result
end

local function get_redstone_relay_side(name, side)
    return peripheral.call(name, "getInput", side)
end


local function get_all_redstone_relays(peripherals)
    return filter_table_by_value(peripherals, "redstone_relay")
end

local function set_redstone_relay_side(name, side, state)
    peripheral.call(name, "setOutput", side, state)
end

local function set_all_redstone_relays_side(redstone_relays, side, state)
    for _, name in ipairs(redstone_relays) do
        set_redstone_relay_side(name, side, state)
    end
end

local function set_all_redstone_relays_sides(redstone_relays, state)
    for _, side in pairs(Side) do
        set_all_redstone_relays_side(redstone_relays, side, state)
    end
end

local function set_crane(side, state)
    set_redstone_relay_side(CRANE_RELAY_ID, side, state)
end

local function stop()
    set_crane(CraneRelaySides.B_CLUTCH, ClutchState.ACTIVE)
end

local function start()
    sleep(0.5)
    set_crane(CraneRelaySides.B_CLUTCH, ClutchState.INACTIVE)
end

local function move_x(direction)
    Logger.trace("Gantry moving in X: " .. (direction and "Positive" or "Negative"))

    stop()
    set_crane(CraneRelaySides.A_GEARSHIFT, (direction == GearshiftState.CLOCKWISE))
    set_crane(CraneRelaySides.C_GANTRY, GantryState.MOVING)
    start()
end

local function move_y(direction)
    Logger.trace("Gantry moving in Y: " .. (direction and "Positive" or "Negative"))
    direction = not direction -- Inverted for second gantry

    stop()
    set_crane(CraneRelaySides.A_GEARSHIFT, (direction == GearshiftState.CLOCKWISE))
    set_crane(CraneRelaySides.C_GANTRY, GantryState.THROUGHPUT)
    set_crane(CraneRelaySides.D_GANTRY, GantryState.MOVING)
    start()
end

local function move_pully(direction)
    stop()
    set_crane(CraneRelaySides.A_GEARSHIFT, (direction == GearshiftState.CLOCKWISE))
    set_crane(CraneRelaySides.C_GANTRY, GantryState.THROUGHPUT)
    set_crane(CraneRelaySides.D_GANTRY, GantryState.THROUGHPUT)
    start()
end

local function is_home()
    Logger.trace(HOME_RELAY_ID)
    Logger.trace(CONTACT_SIDE)
    return get_redstone_relay_side(HOME_RELAY_ID, CONTACT_SIDE)
end

local function pully_up()
    move_pully(PullyDirection.UP)
end

local function pully_down()
    move_pully(PullyDirection.DOWN)
end

local function home_gantry()
    while not is_home() do
        move_x(GantryDirection.NEGATIVE)
        sleep(5)
        move_y(GantryDirection.NEGATIVE)
        sleep(5)
    end
    stop()
    Logger.trace("Homed Gantry")
end

local function home_pully()
    while not my_sticker:is_present() do
        pully_up()
    end
    stop()
    Logger.trace("Homed Pully")
end

local function fake_home_pully()
    pully_up()
    sleep(5)
    stop()
    Logger.trace("Fake homed Pully")
end

local function home_sticker()
    my_sticker:calibrate()
    stop()
    Logger.trace("Homed Sticker")
end

local function home()
    Logger.trace("Homing...")
    fake_home_pully()
    home_gantry()
    home_pully()
    home_sticker()
    Logger.trace("Homed")
end




local function get_active_contact(roof_relays)
    for _, relay in ipairs(roof_relays) do
        if (get_redstone_relay_side(relay, CONTACT_SIDE)) then
            set_redstone_relay_side(relay, LAMP_SIDE, true)
            return relay
        end
        set_redstone_relay_side(relay, LAMP_SIDE, false)
    end
end

local function save_grid_to_file(grid)
    Logger.trace("Saving config")
    FILENAME = "grid.lua"
    local file = io.open("CraneConfig.lua", "w")
    -- Return if cannot create file
    if file == nil then error("Cannot create CraneConfig.lua") end

    file:write("local grid = {\n")
    for coord, value in pairs(grid) do
        -- log.trace("Saving coordinate: "..coord.." / "..value)
        file:write("    [\"" .. coord .. "\"] = \"" .. value .. "\",\n")
        file:write("    [\"" .. value .. "\"] = \"" .. coord .. "\",\n")
    end
    file:write("}\n")
    file:write("return grid\n")
    file:close()
    Logger.trace("Config saved")
end



local function calibrate_contacts(roof_relays)
    home()

    local current_x_direction = GantryDirection.POSITIVE

    local grid = {}
    local time_last_contact = os.time()
    local max_time_since_last_contact = .09
    local last_x = 0
    local last_relay = ""
    local failed_to_find_x = false
    local failed_to_find_y = false
    local found_relay

    for y = 0, 999 do
        failed_to_find_y = false
        
        local reverse_x = (y % 2 ~= 0)
        move_x(GantryDirection.POSITIVE ~= reverse_x)

        local x_max = (not reverse_x) and 999 or 0
        local x_min = (not reverse_x) and 0 or last_x
        local incrementor = (not reverse_x) and 1 or -1

        for x = x_min, x_max, incrementor do
            failed_to_find_x = false
            
            Logger.trace("Finding X: ", x, "Y: ", y)
            while true do
                local contact = get_active_contact(roof_relays)

                if contact and contact ~= last_relay then
                    found_relay = contact
                    break
                end

                sleep(0.1)

                if (os.time() - time_last_contact) > max_time_since_last_contact then
                    Logger.trace("Could not find X: ", x, "Y: ", y)
                    failed_to_find_x = true
                    break
                end
            end

            if failed_to_find_x then
                break
            end
            found_relay = get_active_contact(roof_relays)
            Logger.trace("Found relay: ", found_relay)


            grid[x.."_"..y] = found_relay
            last_relay = found_relay
            last_x = x
            time_last_contact = os.time()
            save_grid_to_file(grid)
        end

        time_last_contact = os.time()
        move_y(GantryDirection.POSITIVE)

        while true do
            local contact = get_active_contact(roof_relays)

            if contact and contact ~= last_relay then
                break
            end

            sleep(0.1)

            if (os.time() - time_last_contact) > max_time_since_last_contact then
                Logger.trace("Could not find Y after X: ", last_x, "Y: ", y)
                failed_to_find_y = true
                break
            end
        end

        if failed_to_find_y then
            break
        end
    end
    save_grid_to_file(grid)
    stop()
end

local all_peripherals = peripheral.getNames()
local redstone_relays = get_all_redstone_relays(all_peripherals)
set_all_redstone_relays_sides(redstone_relays, true)


function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

if not file_exists("CraneConfig.lua") then
    calibrate_contacts(redstone_relays)
end

local CraneConfig = require "CraneConfig"

local function get_coords_from_relay(relay)
    local x, y = CraneConfig[relay]:match("^(%d+)_(%d+)$")
    print("Coords from relay: "..x..", "..y)
    return tonumber(x), tonumber(y)
end

local function get_relay_from_coords(x, y)
    local relay = CraneConfig[x.."_"..y]
    print("Relay from coords: "..relay)
    return relay
end


local function go_to(target_x, target_y)
    local active_contact = get_active_contact(redstone_relays)
    print("Current relay: "..active_contact)
    local current_x, current_y = get_coords_from_relay(active_contact)
    print("Current coords: "..current_x..", "..current_y)

    local target_relay = get_relay_from_coords(target_x, target_y)

    local pivot_x = current_x
    local pivot_y = target_y
    local pivot_relay = get_relay_from_coords(pivot_x, pivot_y)
    print("Pivot coords: "..pivot_x..", "..pivot_y)
    print("Pivot relay: "..pivot_relay)

    if target_y < current_y then
        move_y(GantryDirection.NEGATIVE)
    else
        move_y(GantryDirection.POSITIVE)
    end

    while not get_redstone_relay_side(pivot_relay, CONTACT_SIDE) do
        sleep(0.2)
    end
    stop()

    if target_x < current_x then
        move_x(GantryDirection.NEGATIVE)
    else
        move_x(GantryDirection.POSITIVE)
    end

    while not get_redstone_relay_side(target_relay, CONTACT_SIDE) do
        sleep(0.2)
    end

    stop()
end

home()

go_to(1, 2)

pully_down()
sleep(4)
pully_up()
sleep (4)
stop()
my_sticker:extend()
sleep(5)

home()