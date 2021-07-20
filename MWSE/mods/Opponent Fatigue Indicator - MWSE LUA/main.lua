local gameHUDID = nil
local gameHUD = nil
local barMenuID = nil
local barMenu = nil

local redrawFatigueTimer
local lastTarget = nil

local function opponentFatigueReset()
	redrawFatigueTimer = nil
	lastTarget = nil
end

local function createFatigueBar(_current, _max)
	-- Create the bar itself
    barMenuID = tes3ui.registerID("OpponentFatigueIndicator.bar")
	
	-- ROOT vanilla HUD element
	-- Could also do:
	--	local gameHUDID = tes3ui.registerID("MenuMulti")
	--  local gameHUD = tes3ui.findMenu(gameHUDID)
	local menuMulti = tes3ui.findMenu(-526)
	local enemyHealthBar = menuMulti:findChild(-573)
	
	-- Make sure the enemy fatigue bar appears below the health bar
	enemyHealthBar.parent.flowDirection = "top_to_bottom"
	barMenu = enemyHealthBar.parent:createFillBar{id = barMenuID, current = _current, max = _max}
	
	-- Vanilla bar sizes
	barMenu.width = 65
	barMenu.height = 12
	
	-- Not sure this does anything useful
	barMenu.alpha = menuMulti.alpha
	
	-- Set the bar's color to orange
	barMenu.widget.fillColor = {1.0, 0.47, 0.0}
	
	barMenu.widget.showText = false
end

local function updateFatigueBar()
    -- Can't update or destroy the fatigue bar if it's been destroyed
	if((barMenu == nil) or (redrawFatigueTimer == nil) or (lastTarget == nil)) then
		return
	end

	-- Need to cancel the bar if the enemy is dead
	if(lastTarget.mobile.health.current <= 0.0)
	then
	    --mwse.log("Destroying fatigue bar")
		barMenu:destroy()
		barMenu = nil
		redrawFatigueTimer:cancel()
		redrawFatigueTimer = nil
	else 
	    --mwse.log("Updating fatigue bar values")
		barMenu.widget.max = lastTarget.mobile.fatigue.base
		barMenu.widget.current = lastTarget.mobile.fatigue.current
	end
end

local function opponentFatigueBarCallback(e)
    -- Someone other than the player is attacking
    if (e.reference ~= tes3.player) then
        return
    end
	
	--mwse.log("Player attacking")

    -- The player has hit an ememy
    if (e.targetReference ~= nil) 
	then
		lastTarget = e.targetReference
	
		-- The fatigue bar does not already exist
		if(barMenu == nil) 
		then
		    --mwse.log("Creating fatigue bar")
			createFatigueBar(e.targetReference.mobile.fatigue.current, e.targetReference.mobile.fatigue.base)
		end
		
		-- We always need to reset the timer if a hit has occured
		redrawFatigueTimer = timer.start({ duration = 0.1, callback = updateFatigueBar, type = timer.simulate, iterations = -1 })
    end
end

-- On any attack, call my method to put up a health bar for the enemy hit, lasting 5 seconds since the last hit
event.register("attack", opponentFatigueBarCallback)

event.register("load", opponentFatigueReset)