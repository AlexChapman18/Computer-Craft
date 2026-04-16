# Tables (similar to objects)

- In Lua everything is built on tables
- key-value maps

```lua
local my_table = {
    name = "train",
    speed = 10
}

print(my_table.name) -- "train"
```

## Method syntact (: vs .)

```lua
function obj:hello()
    print("hi")
end
-- /\ Syntactic sugar for \/
function obj.hello(self)
    print("hi")
end
-- THEREFOR
obj:hello()
-- /\ Syntactic sugar for \/
obj.hello(obj)
```

## Metatables

- Lua does not have classes, it has meta-tables
- It allows you to control behaviours, such as
    - missing fields
    - operators
    - comparisons

```lua
local t = {}
setmetatable(t, { __index = function(...) end })
```

- Example `__index` is run when a key in a table is not found
- i.e. if `a.foo` does not exist, call `__index`

```lua
local my_table = {}

setmetatable(my_table, {
    __index = function(self, key)
        print("This key does not exist:", key)
    end
})

print(my_table.foo) -- triggers __index
```

## Delegation

- You can use `__index` to forward calls if they are not in the table

```lua
-- Base Table
local peripheral = {
    getName = function(self)
        return "Alex"
    end
}

-- Base table wrapper
peripheralWrapper = {
    peripheral = peripheral
}

-- Forwards unknown wrapper calls to base table
setmetatable(peripheralWrapper, {
    __index = function(self, key)
        return self.peripheral[key]
    end
})

peripheralWrapper:getName() -- peripheralWrapper.getName(peripheralWrapper)
```

This has an issue
`peripheral.getName` receives `peripheralWrapper`, not `peripheral` as the self object

```lua
setmetatable(peripheralWrapper, {
    __index = function(self, key)
        local peripheralFunc = self.peripheral[key]

        if type(peripheralFunc) == "function" then
            -- Ignore the first parameter (peripheralWrapper), forward the rest of the parameters
            -- Turning peripheralWrapper:getName() -> peripheral:getName()
            return function(_, ...)
                return peripheralFunc(self.peripheral, ...)
            end
        end
    end
})
```

## Avoiding infinite recursion

- Ignore metatables

```lua
rawget(self, "device")
```

## Construction pattern

```lua
TrainStation.new = function(...)
    return Base.new(TrainStation, ...)
end
```

## Varargs

- Pass through args without caring

```lua
function a(...)
    b(...)
end
```
