local move = {}

-- Constants
SLEEP_DELAY = 0.5

-- Movement
function move.forward(distance)
	moveDistance(distance, turtle.forward)
end

function move.back(distance)
	moveDistance(distance, turtle.back)
end

function move.up(distance)
	moveDistance(distance, turtle.up)
end

function move.down(distance)
	moveDistance(distance, turtle.down)
end

function moveDistance(distance, directionCallback)
	local failures = 0
	
	distance = distance or 1
	for i = 1, distance do
		failures = 0
		local successful, reason =  directionCallback()
		
		while not successful do
			if failures > 4 then
				error(reason)
			end
			failures = failures + 1
			sleep(SLEEP_DELAY)
		end
	end
end

-- Rotations
function move.right(rotations)
	turn(rotations, turtle.turnRight)
end

function move.left(rotations)
	turn(rotations, turtle.turnLeft)
end

function move.turnAround()
	move.right(2)
end

function turn(rotations, directionCallback)
	rotations = rotations or 1
	for i = 1, rotations do
		while not directionCallback() do
			sleep(SLEEP_DELAY)
		end
	end
end

return move
