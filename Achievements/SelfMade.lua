local _G = _G
local self_made_achievement = CreateFrame("Frame")
_G.achievements.SelfMade = self_made_achievement
Player = UnitName("Player")

-- General info
self_made_achievement.name = "SelfMade"
self_made_achievement.title = "Self-Made"
self_made_achievement.class = "All"
self_made_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_self_made.blp"
self_made_achievement.description =
"Complete the Hardcore challenge without at any point equipping an item that you have not crafted yourself. Items your character has conjured (e.g. Firestones) are considered crafted. No items bought, dropped, or rewarded by quests are allowed to be equipped (items provided for a quest can be equipped). The items your character starts with are allowed to be equipped. Bags are equipped items."

-- Registers
function self_made_achievement:Register(fail_function_executor)
	self_made_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self_made_achievement.fail_function_executor = fail_function_executor
end

function self_made_achievement:Unregister()
	self_made_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

-- This function sets initial logic to false, then loops through the tooltip of the item that was equipped. 
-- If it finds the UnitName("Player") in the text it sets that variable to "true" breaks out of the loop and finishes the failure of the achievement.
local function isSelfCreated(...)
	local player_found = false
	for i = 1, GameTooltip:NumLines() do
		local mytext = _G["GameTooltipTextLeft" .. i]
		local text = mytext:GetText()
		if string.match(text, Player) then
			player_found = true
			break
		else
			player_found = false
		end
	end
	return player_found
end

-- Register Definitions
self_made_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		GameTooltip:SetInventoryItem("player", arg[1])
		if isSelfCreated() == false then
			local item_id = GetInventoryItemID("player", arg[1])
			local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
			Hardcore:Print("Equipped " .. item_name .. " which was not created by" .. Player)
			self_made_achievement.fail_function_executor.Fail(self_made_achievement.name)
		end
	end
end)
