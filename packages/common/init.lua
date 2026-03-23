Common = {}

function Common.print_table(tbl)
    for k,v in pairs(tbl) do
        print(k, " = ", v)
    end
end

Common.Side = {
    FRONT = "front",
    LEFT = "left",
    RIGHT = "right",
    TOP = "top",
    BOTTOM = "bottom",
    BACK = "back"
}

return Common
