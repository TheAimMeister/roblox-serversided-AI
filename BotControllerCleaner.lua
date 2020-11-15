-- THIS SCRIPT IS MADE BY FoxTheNimrod/TheAimMeister on github
-- I am still learning lua and the environment of Roblox.
-- How I managed to get this to work as it is, is stunning to me.
-- And yes, I am aware the script is a mess

-- NOTE: The script is still a W.I.P.


-- Static Variables
local RunService = game:GetService('RunService')
local seed = Random.new(tonumber(os.date('%H%M%S')) + 679868074576) -- Set seed for Random
local ParentalRoot = workspace:GetChildren() -- Retrieve all workspace children, required for createUID()



-- Baseplate coordinates(Each four corners), use this as a treshold for roaming
local baseplateXMax = -580
local baseplateXMin = -95
local baseplateZMax = 250
local baseplateZMin = -220

local detectionRange = 8 -- Detection range for the bot using CFrame comparisons



-- Dynamic variables
local botName = 'RoamingDummy'
local botStates = {} -- IsReady? Will also return false if a player is within range
local botTask = {} -- Current bot task
local botTimers = {} -- Bot timer limit
local botDelta = {} -- Bot delta to timer
local botInteract = {} -- Can the bot interact? Will be false if following player
local botInteractDelta = {} -- Interaction timeout
local botInteractRan = {} -- Prevent interaction from running twice
local isPlayerInRange = {} -- Booleans for each player, if they're in range of a bot
local availableBots = {} -- Bot instances(Model)
local OnlinePlayers = {} -- Online players, required for the bot function "Follow"



-- Player activity
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		table.insert(OnlinePlayers, character)
		table.insert(isPlayerInRange, {character.Name, false})
	end)
end)


game.Players.PlayerRemoving:Connect(function(player)
	player.CharacterRemoving:Connect(function(character)
		table.remove(OnlinePlayers, table.find(OnlinePlayers, character))
		for interval, _ in pairs(isPlayerInRange) do
			if table.find(isPlayerInRange[interval], character.Name) then
				table.remove(isPlayerInRange, interval)
			end
		end
	end)
end)


-- Functions
-- Because RunService is used, each bot has it's own instance of the functions below.
-- Knowing this, you won't have to worry for local variables interfering with eachother.
local function Roam(controller)
	botTask[controller.UID.Value] = 'Roam' -- Set bot state to roaming
	local locTimer = 0 -- Total wait time
	local timerValue = 0 -- New wait time, required to end the repeat loop
	
	repeat	
		-- If the new timervalue does not trespass the bot's timer limit, then wait.
		-- Also runs the mains script for roaming, so that if it doesn't wait, the bot won't be spastically moving
		if (timerValue + locTimer <= botTimers[controller.UID.Value]) and timerValue > 0 then
			wait(timerValue)
			
			-- Roaming script
			local newX, newZ = seed:NextInteger(baseplateXMin, baseplateXMax), seed:NextInteger(baseplateZMin, baseplateZMax) -- Set new coordinates
			controller.Humanoid:MoveTo(Vector3.new(newX, 0, newZ)) -- Move the AI
		end
		
		
		timerValue = seed:NextInteger(2, 6)	
	until not string.match(botTask[controller.UID.Value], 'Roam') or locTimer >= botTimers[controller.UID.Value] or not botStates[controller.UID.Value]
end



local function Follow(controller)
	if #OnlinePlayers <= 0 then -- If no player is present, return. In this case, the bot will be idle till the timer runs out.
		return
	end
	
	botTask[controller.UID.Value] = 'Follow' -- Set bot state to roaming
	botInteract[controller.UID.Value] = false -- Prevent the bot from being interacted with
	
	-- Select the lucky player ;)
	local selector = seed:NextInteger(1, #OnlinePlayers)
	local selected = OnlinePlayers[selector]:FindFirstChild("HumanoidRootPart")
	
	
	repeat
		--Move AI
		local plrPos = selected.Position
		controller.Humanoid:MoveTo(plrPos)
		RunService.Heartbeat:Wait()
		
	until not string.match(botTask[controller.UID.Value], 'Follow') or not botStates[controller.UID.Value]
	
	botInteract[controller.UID.Value] = true -- Allow the bot to interact again
end



-- THE FOLLOWING FUNCTION IS REQUIRED, AS IT CREATES AN UNIQUE ID AMONGST ALL HUMANOIDS WHICH IS REQUIRED TO ACCESS ITS CORRESPONDING TABLES
local function createUID() -- Create unique ID and necesarry data amongst humanoids with the model name "RoamingDummy"
	
	local identifier = 1
	
	for _, k in pairs(ParentalRoot) do
		if string.match(k.Name, botName) then
			
			-- Create the label UID as IntValue
			local part = Instance.new('IntValue', k)
			part.Name = 'UID'
			part.Value = identifier
			
			-- Populate the necessary tables
			table.insert(botStates, identifier, true)
			table.insert(botInteract, identifier, true)
			table.insert(botInteractRan, identifier, {false, 30})
			table.insert(botInteractDelta, identifier, false)
			table.insert(botTask, identifier, "idle")
			table.insert(botTimers, identifier, 0)
			table.insert(botDelta, identifier, 0)
			table.insert(availableBots, identifier, k)
			
			-- Increase identifier value
			identifier = identifier + 1
		end
	end
end



local function runTask(task, controller) -- Return the task among with delta
	return task(controller)
end



local function randomTask() -- Select task and delta
	local tasks = {Roam, Follow}
	return tasks[seed:NextInteger(1, #tasks)], seed:NextInteger(15,30)
end



-- Retrieve bot tasks
local function createNewTask()
	for _, index in pairs(availableBots) do -- Create timer for each bot
		local UID = index.UID.Value -- Retrieve bot UID
		
		if botStates[UID] and botTask[UID] == "idle" and botTimers[UID] == 0 then -- Must return true, true
			local task, duration = randomTask()
			botTimers[UID] = duration -- Set duration limit for the bot
			botDelta[UID] = tick() -- Start bot delta
			runTask(task, availableBots[UID]) -- Start the task
		end
	end
end



-- Wait for timer to end
local function endTask()
	for _, index in pairs(availableBots) do
		local UID = index.UID.Value -- Retrieve bot UID
		local timer = math.min(tick() - botDelta[UID], botTimers[UID]) -- Get delta to timer limit for each bot
		
		if timer >= botTimers[UID] then -- Reset each bot values if delta has reached it's limit
			botTimers[UID] = 0
			botTask[UID] = "idle"
		end
	end
end


-- Tasks
createUID()

RunService.Heartbeat:Connect(function()
	createNewTask()
	endTask()
end)
