local AceGUI = LibStub("AceGUI-3.0")
hardcore_modern_menu = nil
hardcore_modern_menu_state = {}
hardcore_modern_menu_state.guild_online = {}
hardcore_modern_menu_state.guild_versions = {}
hardcore_modern_menu_state.guild_versions_status = {}
hardcore_modern_menu_state.online_pulsing = {}
hardcore_modern_menu_state.levels_sort_state = "date"
hardcore_modern_menu_state.accountability_sort_state = "v"
hardcore_modern_menu_state.levels_page = 1
hardcore_modern_menu_state.total_levels = 1
hardcore_modern_menu_state.levels_max_page = 1
hardcore_modern_menu_state.changeset = {}
hardcore_modern_menu_state.entry_tbl = {}

local function RequestHCData(target_name)
	if
		other_hardcore_character_cache[target_name] == nil
		or time() - other_hardcore_character_cache[target_name].last_received > 30
	then
		Hardcore:RequestCharacterData(target_name)
	end
end

local date_to_num = {
	["Jan"] = 1,
	["Feb"] = 2,
	["Mar"] = 3,
	["Apr"] = 4,
	["May"] = 5,
	["Jun"] = 6,
	["Jul"] = 7,
	["Aug"] = 8,
	["Sep"] = 9,
	["Oct"] = 10,
	["Nov"] = 11,
	["Dec"] = 12,
}
local function convertToStamp(date_str)
	local pattern = "(%d+) (%d+):(%d+):(%d+) (%d+)"
	local pattern2 = " (%a+)"
	local runday, runhour, runminute, runseconds, runyear = date_str:match(pattern)
	local runmonth = date_str:match(pattern2)
	return time({
		year = runyear,
		month = date_to_num[runmonth],
		day = runday,
		hour = runhour,
		min = runminute,
		sec = runseconds,
	})
end

local sort_functions = {
	["Alph"] = function(t, a, b)
		return a < b
	end,
	["rAlph"] = function(t, a, b)
		return b < a
	end,
	["lvl"] = function(t, a, b)
		return t[a]["level"] > t[b]["level"]
	end,
	["rlvl"] = function(t, a, b)
		return t[b]["level"] > t[a]["level"]
	end,
	["v"] = function(t, a, b)
		return (hardcore_modern_menu_state.guild_versions[a] or "0")
			< (hardcore_modern_menu_state.guild_versions[b] or "0")
	end,
	["rv"] = function(t, a, b)
		return (hardcore_modern_menu_state.guild_versions[a] or "0")
			> (hardcore_modern_menu_state.guild_versions[b] or "0")
	end,
	["date"] = function(t, a, b)
		local t1 = convertToStamp(t[a]["localtime"])
		local t2 = convertToStamp(t[b]["localtime"])
		return t1 > t2
	end,
	["rdate"] = function(t, a, b)
		local t1 = convertToStamp(t[a]["localtime"])
		local t2 = convertToStamp(t[b]["localtime"])
		return t1 < t2
	end,
	["simpledate"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = ""
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = ""
		else
			t1 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end

		local t2 = ""
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = ""
		else
			t2 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end
		return t1 > t2
	end,
	["rsimpledate"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = ""
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = ""
		else
			t1 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end

		local t2 = ""
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = ""
		else
			t2 = other_hardcore_character_cache[player_name_short].first_recorded or ""
		end
		return t1 < t2
	end,
	["pt"] = function(t, a, b)
		return t[b]["playedtime"] > t[a]["playedtime"]
	end,
	["rpt"] = function(t, a, b)
		return t[b]["playedtime"] < t[a]["playedtime"]
	end,
	["achievements"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = 0
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = 0
		else
			t1 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end

		local t2 = 0
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = 0
		else
			t2 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end
		return t1 > t2
	end,
	["rachievements"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = 0
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = 0
		else
			t1 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end

		local t2 = 0
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = 0
		else
			t2 = #other_hardcore_character_cache[player_name_short].achievements or 0
		end
		return t1 < t2
	end,
	["mode"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end
		return t1 > t2
	end,
	["rmode"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].party_mode or "None"
		end
		return t1 < t2
	end,
	["hctag"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end
		return t1 > t2
	end,
	["rhctag"] = function(t, a, b)
		local player_name_short = string.split("-", a)
		local t1 = "None"
		if other_hardcore_character_cache[player_name_short] == nil then
			t1 = "None"
		else
			t1 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end

		local t2 = "None"
		player_name_short = string.split("-", b)
		if other_hardcore_character_cache[player_name_short] == nil then
			t2 = "None"
		else
			t2 = other_hardcore_character_cache[player_name_short].hardcore_player_name or "None"
		end
		return t1 < t2
	end,
}

-- sort function from stack overflow
local function spairs(t, order)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	if order then
		table.sort(keys, function(a, b)
			return order(t, a, b)
		end)
	else
		table.sort(keys)
	end

	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

local function DrawGeneralTab(container)
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_container:AddChild(scroll_frame)

	local first_menu_description_title = AceGUI:Create("Label")
	first_menu_description_title:SetWidth(500)
	first_menu_description_title:SetText("Welcome to Classic hardcore!")
	first_menu_description_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20)
	-- first_menu_description_title:SetPoint("TOP", 2,5)
	scroll_frame:AddChild(first_menu_description_title)

	local first_menu_description = AceGUI:Create("Label")
	first_menu_description:SetWidth(600)
	first_menu_description:SetText(
		"\n\n Check out the following tabs \n\n\n   |c00FFFF00Rules|r: Compiled list of hardcore challenge rules\n\n   |c00FFFF00Verify|r: Generate a verification string to confirm your max level character\n\n   |c00FFFF00Death Knight|r: Read about Death Knight rules and/or sacrifice/activate\n\n   |c00FFFF00Levels|r: See a list of your recorded character levels\n\n   |c00FFFF00Accountability|r: See whose playing in your Hardcore guild and what addon versions they are using\n\n   |c00FFFF00Achievements|r: Check out all available achievements to try\n\n   |c00FFFF00Leaderboard|r: (Not available yet)"
	)
	first_menu_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	-- first_menu_description:SetPoint("TOP", 2,5)
	scroll_frame:AddChild(first_menu_description)

	local changelog_title = AceGUI:Create("Label")
	changelog_title:SetWidth(500)
	changelog_title:SetText("\n\nChangelog")
	changelog_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20)
	scroll_frame:AddChild(changelog_title)

	local changelog_title = AceGUI:Create("Label")
	changelog_title:SetWidth(500)
	changelog_title:SetText("9.5")
	changelog_title:SetFont("Fonts\\FRIZQT__.TTF", 16)
	scroll_frame:AddChild(changelog_title)

	local changelog_description = AceGUI:Create("Label")
	changelog_description:SetWidth(600)
	changelog_description:SetText(
		"- Verification string in new menu ui fixed\n- Teleport moonglade fixed (again) for Druid of the Claw\n- Optimizations for level list.  Level list is now paginated and should no longer cause long freezes.\n- Optimizations for accountability tab.  Accountability tab now loads more quickly up on clicking `inspect all`.  Accountability tab no longer causes a stutter every 7 seconds.\n- HC main menu added to UI special frames; Escape key can be used to exit the menu.\n- Dungeon list updated to include BFD and WotLK dungeons\n- Currency tab is now handled correctly.  Previously, the HC tab would overlap with the currency tab, and the currency panel/ hc panel would still be drawn when switching between the two.\n- Self-made achievement updates.  Self-made no longer fails you for equipping tabards or gear with stat bonuses.  Starting gear list of items updated as well.\n- Self-made no longer allows equipping quest items."
	)
	changelog_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(changelog_description)

	local changelog_title = AceGUI:Create("Label")
	changelog_title:SetWidth(500)
	changelog_title:SetText("9.4")
	changelog_title:SetFont("Fonts\\FRIZQT__.TTF", 16)
	scroll_frame:AddChild(changelog_title)

	local changelog_description = AceGUI:Create("Label")
	changelog_description:SetWidth(600)
	changelog_description:SetText(
		"- Inspect Players in main menu's accountability tab\n- Moonglade correctly detected for duo/trio partners\n- Defaults to modern menu for hardcore show.  To use the old menu again, go to interface options and uncheck the checkbox."
	)
	changelog_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(changelog_description)

	local changelog_title = AceGUI:Create("Label")
	changelog_title:SetWidth(500)
	changelog_title:SetText("9.3")
	changelog_title:SetFont("Fonts\\FRIZQT__.TTF", 16)
	scroll_frame:AddChild(changelog_title)

	local changelog_description = AceGUI:Create("Label")
	changelog_description:SetWidth(600)
	changelog_description:SetText(
		"- Fixed issue where trade partner verification check was being recorded for duo/trio partner trades\n"
	)
	changelog_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(changelog_description)

	local changelog_title = AceGUI:Create("Label")
	changelog_title:SetWidth(500)
	changelog_title:SetText("9.2")
	changelog_title:SetFont("Fonts\\FRIZQT__.TTF", 16)
	scroll_frame:AddChild(changelog_title)

	local changelog_description = AceGUI:Create("Label")
	changelog_description:SetWidth(600)
	changelog_description:SetText(
		"- Shivved updated to allow fishing poles\n- Hammertime updated to allow fishing poles\n- Self-made fixed and updated to allow fishing poles and starting gear\n- Force initialize and bound hardcore_settings to fix some lingering with settings\n- Remove character frame taint; Players can now open character frame during combat but not the HC tab\n- Add ability for mods to appeal achievements in-game\n- Added beta modern menu which replaces /hardcore show\n- Minor verbage changes in rules in beta menu\n- Dungeon levels added to rules in beta menu\n- Achievements added to beta menu\n- Formatting fixes for level list and accountability in beta menu\n- Druid of the claw fixed issue where moonglade wasn't allowed\n- Scavenger fixed issue where other addons could buy from merchants\n - Bandaid fix for other addons removing inspect frame"
	)
	changelog_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(changelog_description)
end

local function DrawRulesTab(container)
	local function DrawRulesLabel(text, _scroll_frame)
		local general_rules_label = AceGUI:Create("HardcoreClassTitleLabel")
		general_rules_label:SetWidth(600)
		general_rules_label:SetHeight(60)
		general_rules_label:SetText(text)
		general_rules_label:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20)
		_scroll_frame:AddChild(general_rules_label)
	end
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_container:AddChild(scroll_frame)

	DrawRulesLabel("General", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"\nFor more info, rules, news, hall of legends, challenges, and more visit the classichc website. Help is available on discord (link on website) \n\nAll professions allowed\nNo restriction on talents\n\nYou can use gear that you pickup or craft\nNo Auction house, No mailbox, No trading\n\nNo grouping in open world\n\nNo battlegrounds allowed\n\nBuffs from others are allowed, don't ask for others for buffs\n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	local function DrawDungeonLevels(scroll_Frame)
		local function addEntry(_scroll_frame, _name, _era, _wotlk)
			local entry = AceGUI:Create("SimpleGroup")
			entry:SetLayout("Flow")
			entry:SetFullWidth(true)
			_scroll_frame:AddChild(entry)

			local name_label = AceGUI:Create("Label")
			name_label:SetWidth(100)
			name_label:SetText("")
			name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
			entry:AddChild(name_label)

			local name_label = AceGUI:Create("Label")
			name_label:SetWidth(175)
			name_label:SetText(_name)
			name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
			entry:AddChild(name_label)

			local level_label = AceGUI:Create("Label")
			level_label:SetWidth(155)
			level_label:SetText(_era)
			level_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
			entry:AddChild(level_label)

			local name_label = AceGUI:Create("Label")
			name_label:SetWidth(100)
			name_label:SetText(_wotlk)
			name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
			entry:AddChild(name_label)
		end
		local row_header = AceGUI:Create("SimpleGroup")
		row_header:SetLayout("Flow")
		row_header:SetFullWidth(true)
		scroll_frame:AddChild(row_header)

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(100)
		name_label:SetText("")
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		row_header:AddChild(name_label)

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(150)
		name_label:SetText("|c00FFFF00Dungeon Name|r")
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		row_header:AddChild(name_label)

		local level_label = AceGUI:Create("Label")
		level_label:SetWidth(150)
		level_label:SetText("|c00FFFF00Max Lvl (Era)|r")
		level_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		row_header:AddChild(level_label)

		local played_time_label = AceGUI:Create("Label")
		played_time_label:SetWidth(200)
		played_time_label:SetText("|c00FFFF00Max Lvl (WotlK)|r")
		played_time_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		row_header:AddChild(played_time_label)

		addEntry(scroll_frame, "Ragefire Chasm", 18, 20)
		addEntry(scroll_frame, "The Deadmines", 26, 24)
		addEntry(scroll_frame, "Wailing Caverns", 24, 24)
		addEntry(scroll_frame, "Shadowfang Keep", 30, 25)
		addEntry(scroll_frame, "Blackfathon Deeps", 32, 28)
		addEntry(scroll_frame, "Stockades", 32, 29)
		addEntry(scroll_frame, "Razorfen Kraul", 38, 31)
		addEntry(scroll_frame, "Gnomeregan", 38, 32)
		addEntry(scroll_frame, "Razorfen Downs", 46, 41)
		addEntry(scroll_frame, "Scarlet Monastery", 45, 44)
		addEntry(scroll_frame, "Uldaman", 51, 44)
		addEntry(scroll_frame, "Zul'Farrak", 54, 50)
		addEntry(scroll_frame, "Maraudon", 55, 52)
		addEntry(scroll_frame, "Sunken Temple", 60, 54)
		addEntry(scroll_frame, "Blackrock Depths", 60, 60)
		addEntry(scroll_frame, "Lower Blackrock Spire", 60, 62)
		addEntry(scroll_frame, "Scholomance", 60, 62)
		addEntry(scroll_frame, "Dire Maul", 60, 62)
		addEntry(scroll_frame, "Upper Blackrock Spire", 60, 62)
		addEntry(scroll_frame, "Stratholme", 60, 62)
		addEntry(scroll_frame, "Hellfire Ramparts", "---", 64)
		addEntry(scroll_frame, "Blood Furnace", "---", 65)
		addEntry(scroll_frame, "The Slave Pens", "---", 66)
		addEntry(scroll_frame, "The Underbog", "---", 66)
		addEntry(scroll_frame, "Mana Tombs", "---", 68)
		addEntry(scroll_frame, "Utgarde Keep", "---", 74)
		addEntry(scroll_frame, "Nexus", "---", 75)
		addEntry(scroll_frame, "Azjol-Nerub", "---", 76)
		addEntry(scroll_frame, "Ahn'kahet", "---", 77)
		addEntry(scroll_frame, "Drak'Tharon Keep", "---", 78)
		addEntry(scroll_frame, "Violet Hold", "---", 79)
		addEntry(scroll_frame, "Grundrak", "---", 80)
		addEntry(scroll_frame, "Halls of Stone", "---", 80)
		addEntry(scroll_frame, "Halls of Lightning", "---", 80)
		addEntry(scroll_frame, "The Culling of Stratholme", "---", 80)
		addEntry(scroll_frame, "The Oculus", "---", 80)
		addEntry(scroll_frame, "Utgarde Pinnacle", "---", 80)
		addEntry(scroll_frame, "Forge of Souls", "---", 80)
		addEntry(scroll_frame, "Pit of Saron", "---", 80)
		addEntry(scroll_frame, "Halls of Reflection", "---", 80)
		addEntry(scroll_frame, "Trial of the Champion", "---", 80)
		addEntry(scroll_frame, "\n\n\n\n", "", "")
	end
	DrawRulesLabel("Dungeon Groups", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"\nDungeon Groups are authorized but only ONE run of each Dungeon per character.  Everyone in party must be following hardcore rules.  Everyone must be in level range of the meeting stone.  Group at the meeting stone to start the dungeon.  You can invite people who are on the way.  If you level up inside of the dungeon and exceed the meeting stone requirement you can stay.  Warlocks are allowed to summon players to the meeting stone\n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)
	DrawDungeonLevels(scroll_frame)

	DrawRulesLabel("Class and Item Specific", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"\nWarlocks can’t resurrect via SS.  Shamans can’t resurrect via Ankh.  Paladins can’t Bubble Hearth. \n\nNo Light of Elune + Hearthstone\n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	DrawRulesLabel("Verification", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"\nYou can verify your run using this addon (Get verified tab). Recording or streaming is also recommended to provide evidence for special circumstances such as disconnection deaths.\n\nAt MAX level you earn your IMMORTALITY and become a full fledged character with insane bragging rights.\n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	DrawRulesLabel("Duos/Trios", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"\nYou must not leave the same zone as each other, unless you are a Druid going to Moonglade to complete essential class quests.\nYou must choose a combo that spawns in the same starting location.\nIf one of you dies, the other must fall on the sword and the run is over.\nYou can trade your duo partner found or crafted items, including gold.\nMultiboxing goes against the spirit of the Hardcore Challenge and is not allowed.\n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)
end

local function DrawVerifyTab(container, _hardcore_character)
	local ATTRIBUTE_SEPARATOR = "_"
	local function GenerateVerificationString()
		local version = GetAddOnMetadata("Hardcore", "Version")
		local _, class, _, race, _, name = GetPlayerInfoByGUID(UnitGUID("player"))
		local realm = GetRealmName()
		local level = UnitLevel("player")
	
		local tradePartners = Hardcore_join(_hardcore_character.trade_partners, ",")
		local converted_successfully = "FALSE"
		if _hardcore_character.converted_successfully then
			converted_successfully = "TRUE"
		end
		local game_version_checker = _hardcore_character.game_version or { _G["HardcoreBuildLabel"] }
	
		local baseVerificationData = {
			version,
			_hardcore_character.guid,
			realm,
			race,
			class,
			name,
			level,
			_hardcore_character.time_played,
			_hardcore_character.time_tracked,
			#_hardcore_character.deaths,
			tradePartners,
			_hardcore_character.sacrificed_at,
			converted_successfully,
			game_version_checker,
		}
		local baseVerificationString =
			Hardcore_join(Hardcore_map(baseVerificationData, Hardcore_stringOrNumberToUnicode), ATTRIBUTE_SEPARATOR)
		local bubbleHearthIncidentsVerificationString = Hardcore_tableToUnicode(_hardcore_character.bubble_hearth_incidents)
		local playedtimeGapsVerificationString = Hardcore_tableToUnicode(_hardcore_character.played_time_gap_warnings)
		return Hardcore_join({
			baseVerificationString,
			bubbleHearthIncidentsVerificationString,
			playedtimeGapsVerificationString,
		}, ATTRIBUTE_SEPARATOR)
	end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_container:AddChild(scroll_frame)

	local first_menu_description_title = AceGUI:Create("Label")
	first_menu_description_title:SetWidth(500)
	first_menu_description_title:SetText("Verify Your Character")
	first_menu_description_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20)
	scroll_frame:AddChild(first_menu_description_title)

	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText("\n\nTo get verified, copy the string below and visit the classichc website.")
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	local first_menu_description = AceGUI:Create("MultiLineEditBox")
	first_menu_description.button:Hide()
	first_menu_description:SetMaxLetters(0)
	first_menu_description:SetHeight(850)
	first_menu_description.button:SetPoint("BOTTOMLEFT", 0, -150)
	first_menu_description:SetWidth(750)
	first_menu_description:SetLabel("")
	first_menu_description:SetText(GenerateVerificationString())
	scroll_frame:AddChild(first_menu_description)

	local copy_tip_label = AceGUI:Create("Label")
	copy_tip_label:SetText("\n\n\n\n\n\n\n\n\n\n\n\n\nSelect All (Ctrl-A), Copy (Ctrl-C), and Paste (Ctrl-V)")
	copy_tip_label:SetWidth(700)
	copy_tip_label:SetFontObject(GameFontHighlightSmall)
	scroll_frame:AddChild(copy_tip_label)
end

local function DrawDKTab(container, dk_button_function)
	local function DrawRulesLabel(text, _scroll_frame)
		local general_rules_label = AceGUI:Create("HardcoreClassTitleLabel")
		general_rules_label:SetWidth(600)
		general_rules_label:SetHeight(60)
		general_rules_label:SetText(text)
		general_rules_label:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20)
		_scroll_frame:AddChild(general_rules_label)
	end
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_frame:SetHeight(320)
	scroll_container:AddChild(scroll_frame)

	DrawRulesLabel("", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"Death Knights are authorized for the Hardcore Challenge, adding in these following rules.  You must level a character of the SAME FACTION following the standard HC Ruleset, at which point it must be sacrificed to create a Death Knight.  The sacrificial level is a range between 55 and 58. You cannot sacrifice before or after these levels.  As a side note, sacrificing a toon does not mean you must delete it, but it will no longer be valid HC toon.\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	DrawRulesLabel("", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"\nIf you should die or fail your run while playing as a Death Knight, you must start over from level 1, with a fresh toon to perform the sacrifice again. You may create your DK in advance if you wish to RSVP a name, but do not log onto them. Remember that you need to have a lvl 55 already on the server to create a DK.  Duo and Trio groups who wish to have a DK in the party must follow some additional steps in creating a DK. These steps are listed further below.  General achievements will carry over when you activate your DK\n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	DrawRulesLabel("Solo DK", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"Listed below is a step by step process for creating a DK while solo.. \n    Step 1: Level a character of the “SAME FACTION” to the required level range, following the HC rules.\n    Step 2: Click on the “SACRIFICE” button below. This starts a 5 minute timer. You cannot activate the “SACRIFICE” button while in combat, stealthed, or during Feign Death.\n    Step 3: During these 5 minutes, you must die on your current character. After dying, log out.\n    Step 4: DO NOT DELETE THE TOON YOU SACRIFICED UNTIL AFTER THE DK IS ACTIVATED!!\n    Step 5: Create or log onto your Death Knight.\n    Step 6: Click on “ACTIVATE” below. Then do a /reload. You are now good to go.\nSurvive well out there!\n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	DrawRulesLabel("Duo/Trio DK", scroll_frame)
	local general_rules_description = AceGUI:Create("Label")
	general_rules_description:SetWidth(600)
	general_rules_description:SetText(
		"There are some additional things you must do when you wish to create a DK for Duo or Trio groups.\n    Step 1: Start your Duo/Trio group of the “SAME FACTION” and reach the level range for sacrifice, following the HC rules.\n    Step 2: For the player who is sacrificing, click on the “SACRIFICE” button below. This starts a 5 minute timer. You cannot activate the “SACRIFICE” button while in combat, stealthed, or during Feign Death.\n    Step 3: During these 5 minutes, you must die on your current character. After dying, drop group and logout. Your partners who are not sacrificing MUST STAY ONLINE!\n    Step 4: DO NOT DELETE THE TOON YOU SACRIFICED UNTIL AFTER THE DK IS ACTIVATED!!\n    Step 5: Create or log onto your Death Knight.\n    Step 6: Click on “ACTIVATE” below.\n    Step 7: Rejoin the party with your partners using /inv “Name” \n    Step 8: All party member must /reload\n    Step 9: If more than one player is creating a DK, then you must follow the steps ONE PERSON AT A TIME! Multiple players creating a DK in the party at the same time WILL invalidate your run. \n\n\n\n"
	)
	general_rules_description:SetFont("Fonts\\FRIZQT__.TTF", 12)
	scroll_frame:AddChild(general_rules_description)

	local button_container = AceGUI:Create("SimpleGroup")
	button_container:SetFullWidth(true)
	button_container:SetFullHeight(true)
	button_container:SetLayout("Flow")
	scroll_container:AddChild(button_container)

	local sacrifice_button = AceGUI:Create("Button")
	sacrifice_button:SetText("Sacrifice")
	sacrifice_button:SetWidth(100)
	button_container:AddChild(sacrifice_button)

	local activate_button = AceGUI:Create("Button")
	activate_button:SetText("Activate")
	activate_button:SetWidth(100)
	button_container:AddChild(activate_button)

	sacrifice_button:SetCallback("OnClick", function()
		dk_button_function(nil, "sacrifice")
	end)
	activate_button:SetCallback("OnClick", function()
		dk_button_function(nil, "activate")
	end)
end

local function DrawLevelsTab(container, _hardcore_settings)
	local function DrawNameColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("List")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			name_str = name_str .. _level_list[_player_list[i]].player .. "\n"
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(name_label)
	end

	local function DrawLevelColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			name_str = name_str .. _level_list[_player_list[i]].level .. "\n"
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(name_label)
	end

	local function DrawPlayedColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			if _level_list[_player_list[i]].playedtime ~= nil then
				name_str = name_str .. SecondsToTime(_level_list[_player_list[i]].playedtime) .. "\n"
			else
				name_str = name_str .. "\n"
			end
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(name_label)
	end

	local function DrawDateColumn(_scroll_frame, _level_list, _player_list, width, start, max_lines)
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetWidth(width)
		_scroll_frame:AddChild(entry)

		local name_str = ""
		for i = start, start + max_lines do
			if _player_list[i] == nil then
				break
			end
			name_str = name_str .. _level_list[_player_list[i]].localtime .. "\n"
		end

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(width)
		name_label:SetText(name_str)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(name_label)
	end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_frame:SetHeight(369)
	scroll_container:AddChild(scroll_frame)

	local row_header = AceGUI:Create("SimpleGroup")
	row_header:SetLayout("Flow")
	row_header:SetFullWidth(true)
	scroll_frame:AddChild(row_header)

	local name_label = AceGUI:Create("InteractiveLabel")
	name_label:SetWidth(150)
	name_label:SetText("|c00FFFF00Name|r")
	name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(name_label)

	name_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "Alph" then
			hardcore_modern_menu_state.levels_sort_state = "Alph"
		else
			hardcore_modern_menu_state.levels_sort_state = "rAlph"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local level_label = AceGUI:Create("InteractiveLabel")
	level_label:SetWidth(50)
	level_label:SetText("|c00FFFF00Lvl|r")
	level_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(level_label)

	level_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "lvl" then
			hardcore_modern_menu_state.levels_sort_state = "lvl"
		else
			hardcore_modern_menu_state.levels_sort_state = "rlvl"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local played_time_label = AceGUI:Create("InteractiveLabel")
	played_time_label:SetWidth(200)
	played_time_label:SetText("|c00FFFF00Played Time|r")
	played_time_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(played_time_label)

	played_time_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "pt" then
			hardcore_modern_menu_state.levels_sort_state = "pt"
		else
			hardcore_modern_menu_state.levels_sort_state = "rpt"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local date_label = AceGUI:Create("InteractiveLabel")
	date_label:SetWidth(200)
	date_label:SetText("|c00FFFF00Date|r")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(date_label)

	date_label:SetCallback("OnClick", function(widget)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.levels_sort_state ~= "date" then
			hardcore_modern_menu_state.levels_sort_state = "date"
		else
			hardcore_modern_menu_state.levels_sort_state = "rdate"
		end
		DrawLevelsTab(container, _hardcore_settings)
	end)

	local sorted_player_idx = {}
	local max_lines = 500
	hardcore_modern_menu.total_levels = #_hardcore_settings.level_list
	hardcore_modern_menu.max_pages = hardcore_modern_menu.total_levels / max_lines
	for i, v in spairs(_hardcore_settings.level_list, sort_functions[hardcore_modern_menu_state.levels_sort_state]) do
		table.insert(sorted_player_idx, i)
	end

	local start = (hardcore_modern_menu_state.levels_page - 1) * max_lines + 1
	DrawNameColumn(scroll_frame, Hardcore_Settings.level_list, sorted_player_idx, 150, start, max_lines)
	DrawLevelColumn(scroll_frame, Hardcore_Settings.level_list, sorted_player_idx, 50, start, max_lines)
	DrawPlayedColumn(scroll_frame, Hardcore_Settings.level_list, sorted_player_idx, 200, start, max_lines)
	DrawDateColumn(scroll_frame, Hardcore_Settings.level_list, sorted_player_idx, 200, start, max_lines)

	local entry = AceGUI:Create("SimpleGroup")
	entry:SetLayout("Flow")
	entry:SetWidth(10)
	scroll_frame:AddChild(entry)

	local button_container = AceGUI:Create("SimpleGroup")
	button_container:SetWidth(700)
	button_container:SetHeight(100)
	button_container:SetLayout("Flow")
	scroll_container:AddChild(button_container)

	local left_page_button = AceGUI:Create("Button")
	left_page_button:SetText("<")
	left_page_button:SetWidth(50)
	button_container:AddChild(left_page_button)
	left_page_button:SetCallback("OnClick", function()
		if hardcore_modern_menu_state.levels_page > 1 then
			container:ReleaseChildren()
			hardcore_modern_menu_state.levels_page = hardcore_modern_menu_state.levels_page - 1
			DrawLevelsTab(container, _hardcore_settings)
		end
	end)

	local date_label = AceGUI:Create("Label")
	date_label:SetWidth(100)
	date_label:SetText("|c00FFFF00Page " .. hardcore_modern_menu_state.levels_page .. "|r")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	button_container:AddChild(date_label)

	local date_label = AceGUI:Create("HardcoreClassTitleLabel")
	date_label:SetWidth(350)
	date_label:SetText("|c00FFFF00You've Leveled up " .. #_hardcore_settings.level_list .. " Times!|r")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	button_container:AddChild(date_label)

	local date_label = AceGUI:Create("HardcoreClassTitleLabel")
	date_label:SetWidth(100)
	date_label:SetText("")
	date_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	button_container:AddChild(date_label)

	local right_page_button = AceGUI:Create("Button")
	right_page_button:SetText(">")
	right_page_button:SetWidth(50)
	button_container:AddChild(right_page_button)
	right_page_button:SetCallback("OnClick", function()
		if hardcore_modern_menu_state.levels_page <= hardcore_modern_menu_state.levels_max_page + 1 then
			container:ReleaseChildren()
			hardcore_modern_menu_state.levels_page = hardcore_modern_menu_state.levels_page + 1
			DrawLevelsTab(container, _hardcore_settings)
		end
	end)
end

local function DrawAccountabilityTab(container)
	local function updateLabelData(_label_tbls, player_name_short)
		if other_hardcore_character_cache[player_name_short] ~= nil then
			_label_tbls["party_mode_label"]:SetText(other_hardcore_character_cache[player_name_short].party_mode)
			_label_tbls["first_recorded_label"]:SetText(
				date("%m/%d/%y", other_hardcore_character_cache[player_name_short].first_recorded or 0)
			)

			if
				other_hardcore_character_cache[player_name_short].achievements == nil
				or #other_hardcore_character_cache[player_name_short].achievements > 0
			then
				local inline_text = ""
				for i, achievement_name in ipairs(other_hardcore_character_cache[player_name_short].achievements) do
					inline_text = inline_text
						.. "|T"
						.. _G.achievements[achievement_name].icon_path
						.. ":16:16:0:0:64:64:4:60:4:60|t"
				end
				_label_tbls["achievement_label"]:SetText(inline_text)
				_label_tbls["achievement_label"]:SetCallback("OnEnter", function(widget)
					GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
					GameTooltip:AddLine("Active achievements")
					for i, achievement_name in ipairs(other_hardcore_character_cache[player_name_short].achievements) do
						GameTooltip:AddLine(_G.achievements[achievement_name].title)
					end
					GameTooltip:Show()
				end)
				_label_tbls["achievement_label"]:SetCallback("OnLeave", function(widget)
					GameTooltip:Hide()
				end)
			else
				_label_tbls["achievement_label"]:SetText("")
			end
			_label_tbls["hc_tag_label"]:SetText(
				other_hardcore_character_cache[player_name_short].hardcore_player_name or ""
			)
		end

		local player_name_long = player_name_short .. "-" .. GetRealmName()
		if hardcore_modern_menu_state.guild_online[player_name_long] ~= nil then
			local version_text
			if
				(
					hardcore_modern_menu_state.online_pulsing[player_name_long]
					and hardcore_modern_menu_state.guild_online[player_name_long]
				) or player_name_short == UnitName("player")
			then
				if player_name_short == UnitName("player") then
					version_text = GetAddOnMetadata("Hardcore", "Version")
				else
					version_text = hardcore_modern_menu_state.guild_versions[player_name_long]
				end

				if hardcore_modern_menu_state.guild_versions_status[player_name_long] == "updated" then
					version_text = "|c0000ff00" .. version_text .. "|r"
				else
					version_text = "|c00ffff00" .. version_text .. "|r"
				end
			else
				version_text = "|c00ff0000Not detected|r"
			end
			_label_tbls["version_label"]:SetText(version_text)

			_label_tbls["level_label"]:SetText(hardcore_modern_menu_state.guild_online[player_name_long].level)
		end
	end
	local function addEntry(_scroll_frame, player_name_short, _self_name)
		local _player_name = player_name_short .. "-" .. GetRealmName()
		local entry = AceGUI:Create("SimpleGroup")
		entry:SetLayout("Flow")
		entry:SetFullWidth(true)
		_scroll_frame:AddChild(entry)

		local name_label = AceGUI:Create("Label")
		name_label:SetWidth(110)
		name_label:SetText(player_name_short)
		name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(name_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short] = {}

		local level_label = AceGUI:Create("Label")
		level_label:SetWidth(50)
		level_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(level_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["level_label"] = level_label

		local version_label = AceGUI:Create("Label")
		version_label:SetWidth(80)
		version_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(version_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["version_label"] = version_label

		local party_mode_label = AceGUI:Create("Label")
		party_mode_label:SetWidth(75)
		party_mode_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(party_mode_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["party_mode_label"] = party_mode_label

		local first_recorded_label = AceGUI:Create("Label")
		first_recorded_label:SetWidth(85)
		first_recorded_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(first_recorded_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["first_recorded_label"] = first_recorded_label

		local achievement_label = AceGUI:Create("InteractiveLabel")
		achievement_label:SetWidth(120)
		achievement_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(achievement_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["achievement_label"] = achievement_label

		local hc_tag_label = AceGUI:Create("Label")
		hc_tag_label:SetWidth(75)
		hc_tag_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
		entry:AddChild(hc_tag_label)
		hardcore_modern_menu_state.entry_tbl[player_name_short]["hc_tag_label"] = hc_tag_label

		updateLabelData(hardcore_modern_menu_state.entry_tbl[player_name_short], player_name_short, _player_name)
	end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("List")
	scroll_container:AddChild(scroll_frame)

	local row_header = AceGUI:Create("SimpleGroup")
	row_header:SetLayout("Flow")
	row_header:SetFullWidth(true)
	scroll_frame:AddChild(row_header)

	local name_label = AceGUI:Create("InteractiveLabel")
	name_label:SetWidth(110)
	name_label:SetText("|c00FFFF00Name|r")
	name_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(name_label)

	name_label:SetCallback("OnClick", function(widget)
		hardcore_modern_menu_state.entry_tbl = {}
		hardcore_modern_menu_state.ticker_handler:Cancel()
		hardcore_modern_menu_state.ticker_handler = nil
		container:ReleaseChildren()
		if hardcore_modern_menu_state.accountability_sort_state ~= "Alph" then
			hardcore_modern_menu_state.accountability_sort_state = "Alph"
		else
			hardcore_modern_menu_state.accountability_sort_state = "rAlph"
		end
		DrawAccountabilityTab(container)
	end)

	local level_label = AceGUI:Create("InteractiveLabel")
	level_label:SetWidth(50)
	level_label:SetText("|c00FFFF00Lvl|r")
	level_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(level_label)

	level_label:SetCallback("OnClick", function(widget)
		hardcore_modern_menu_state.entry_tbl = {}
		hardcore_modern_menu_state.ticker_handler:Cancel()
		hardcore_modern_menu_state.ticker_handler = nil
		container:ReleaseChildren()
		if hardcore_modern_menu_state.accountability_sort_state ~= "lvl" then
			hardcore_modern_menu_state.accountability_sort_state = "lvl"
		else
			hardcore_modern_menu_state.accountability_sort_state = "rlvl"
		end
		DrawAccountabilityTab(container)
	end)

	local version_label = AceGUI:Create("InteractiveLabel")
	version_label:SetWidth(80)
	version_label:SetText("|c00FFFF00Version|r")
	version_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(version_label)

	version_label:SetCallback("OnClick", function(widget)
		hardcore_modern_menu_state.entry_tbl = {}
		hardcore_modern_menu_state.ticker_handler:Cancel()
		hardcore_modern_menu_state.ticker_handler = nil
		container:ReleaseChildren()
		if hardcore_modern_menu_state.accountability_sort_state ~= "v" then
			hardcore_modern_menu_state.accountability_sort_state = "v"
		else
			hardcore_modern_menu_state.accountability_sort_state = "rv"
		end
		DrawAccountabilityTab(container)
	end)

	local mode_label = AceGUI:Create("InteractiveLabel")
	mode_label:SetWidth(75)
	mode_label:SetText("|c00FFFF00Mode|r")
	mode_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(mode_label)

	mode_label:SetCallback("OnClick", function(widget)
		hardcore_modern_menu_state.entry_tbl = {}
		hardcore_modern_menu_state.ticker_handler:Cancel()
		hardcore_modern_menu_state.ticker_handler = nil
		container:ReleaseChildren()
		if hardcore_modern_menu_state.accountability_sort_state ~= "mode" then
			hardcore_modern_menu_state.accountability_sort_state = "mode"
		else
			hardcore_modern_menu_state.accountability_sort_state = "rmode"
		end
		DrawAccountabilityTab(container)
	end)

	local date_started_label = AceGUI:Create("InteractiveLabel")
	date_started_label:SetWidth(85)
	date_started_label:SetText("|c00FFFF00Started|r")
	date_started_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(date_started_label)

	date_started_label:SetCallback("OnClick", function(widget)
		hardcore_modern_menu_state.entry_tbl = {}
		hardcore_modern_menu_state.ticker_handler:Cancel()
		hardcore_modern_menu_state.ticker_handler = nil
		container:ReleaseChildren()
		if hardcore_modern_menu_state.accountability_sort_state ~= "simpledate" then
			hardcore_modern_menu_state.accountability_sort_state = "simpledate"
		else
			hardcore_modern_menu_state.accountability_sort_state = "rsimpledate"
		end
		DrawAccountabilityTab(container)
	end)

	local achievements_label = AceGUI:Create("InteractiveLabel")
	achievements_label:SetWidth(120)
	achievements_label:SetText("|c00FFFF00Achievements|r")
	achievements_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(achievements_label)

	achievements_label:SetCallback("OnClick", function(widget)
		hardcore_modern_menu_state.entry_tbl = {}
		hardcore_modern_menu_state.ticker_handler:Cancel()
		hardcore_modern_menu_state.ticker_handler = nil
		container:ReleaseChildren()
		if hardcore_modern_menu_state.accountability_sort_state ~= "achievements" then
			hardcore_modern_menu_state.accountability_sort_state = "achievements"
		else
			hardcore_modern_menu_state.accountability_sort_state = "rachievements"
		end
		DrawAccountabilityTab(container)
	end)

	local hc_tag_label = AceGUI:Create("InteractiveLabel")
	hc_tag_label:SetWidth(100)
	hc_tag_label:SetText("|c00FFFF00HC Tag|r")
	hc_tag_label:SetFont("Fonts\\FRIZQT__.TTF", 12)
	row_header:AddChild(hc_tag_label)

	hc_tag_label:SetCallback("OnClick", function(widget)
		hardcore_modern_menu_state.entry_tbl = {}
		hardcore_modern_menu_state.ticker_handler:Cancel()
		hardcore_modern_menu_state.ticker_handler = nil
		container:ReleaseChildren()
		if hardcore_modern_menu_state.accountability_sort_state ~= "hctag" then
			hardcore_modern_menu_state.accountability_sort_state = "hctag"
		else
			hardcore_modern_menu_state.accountability_sort_state = "rhctag"
		end
		DrawAccountabilityTab(container)
	end)

	self_name = UnitName("player")
	for _player_name, _ in
		spairs(
			hardcore_modern_menu_state.guild_online,
			sort_functions[hardcore_modern_menu_state.accountability_sort_state]
		)
	do
		local player_name_short = string.split("-", _player_name)
		addEntry(scroll_frame, player_name_short, self_name)
	end

	hardcore_modern_menu_state.ticker_handler = C_Timer.NewTicker(0.1, function()
		for k, _ in pairs(hardcore_modern_menu_state.changeset) do
			if hardcore_modern_menu_state.entry_tbl[k] == nil then
				-- addEntry(scroll_frame, k, self_name)
				-- No-op, this can look buggy
			else
				updateLabelData(hardcore_modern_menu_state.entry_tbl[k], k)
			end
		end
		hardcore_modern_menu_state.changeset = {}
	end)

	local button_container = AceGUI:Create("SimpleGroup")
	button_container:SetWidth(100)
	button_container:SetHeight(100)
	button_container:SetLayout("Flow")
	scroll_container:AddChild(button_container)

	local inspect_all_button = AceGUI:Create("Button")
	inspect_all_button:SetText("Inspect All")
	inspect_all_button:SetWidth(100)
	button_container:AddChild(inspect_all_button)
	inspect_all_button:SetCallback("OnClick", function()
		for _player_name, _ in
			spairs(
				hardcore_modern_menu_state.guild_online,
				sort_functions[hardcore_modern_menu_state.accountability_sort_state]
			)
		do
			local player_name_short = string.split("-", _player_name)
			if other_hardcore_character_cache[player_name_short] == nil then
				RequestHCData(player_name_short)
			end
		end
	end)
end

local function DrawAchievementsTab(container)
	local function addEntry(_scroll_frame, _player_name, _self_name) end

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("List")
	tabcontainer:AddChild(scroll_container)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)

	local achievements_container_second_row = AceGUI:Create("SimpleGroup")
	achievements_container_second_row:SetRelativeWidth(1.0)
	achievements_container_second_row:SetHeight(50)
	achievements_container_second_row:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container_second_row)
	local function DrawClassContainer(class_container, class, size)
		local c = 0
		for k, v in pairs(_G.achievements) do
			if v.class == class then
				c = c + 1
				local achievement_icon = AceGUI:Create("Icon")
				achievement_icon:SetWidth(size)
				achievement_icon:SetHeight(size)
				achievement_icon:SetImage(v.icon_path)
				achievement_icon:SetImageSize(size, size)
				achievement_icon.image:SetVertexColor(1, 1, 1)
				achievement_icon:SetCallback("OnEnter", function(widget)
					GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
					GameTooltip:AddLine(v.title)
					GameTooltip:AddLine(v.description, 1, 1, 1, true)
					GameTooltip:Show()
				end)
				achievement_icon:SetCallback("OnLeave", function(widget)
					GameTooltip:Hide()
				end)
				class_container:AddChild(achievement_icon)
			end
		end

		local achievement_icon = AceGUI:Create("Icon")
		achievement_icon:SetWidth(1)
		achievement_icon:SetHeight(10)
		class_container:AddChild(achievement_icon)
	end

	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("General Achievements")
	achievements_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16)
	achievements_container:AddChild(achievements_title)
	DrawClassContainer(achievements_container, "All", 50)

	local function DrawClassContainer2(container, class, size)
		local class_contianer = AceGUI:Create("SimpleGroup")
		class_contianer:SetWidth(120)
		class_contianer:SetHeight(50)
		class_contianer:SetLayout("Flow")
		container:AddChild(class_contianer)

		local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
		achievements_title:SetRelativeWidth(1.0)
		achievements_title:SetHeight(40)
		achievements_title:SetText(class)
		achievements_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16)
		class_contianer:AddChild(achievements_title)
		DrawClassContainer(class_contianer, class, size)
	end

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(200)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)
	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("\n\n\n\n")
	achievements_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16)
	scroll_container:AddChild(achievements_title)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)
	DrawClassContainer2(achievements_container, "Warrior", 36)
	DrawClassContainer2(achievements_container, "Hunter", 36)
	DrawClassContainer2(achievements_container, "Warlock", 36)
	DrawClassContainer2(achievements_container, "Mage", 36)
	DrawClassContainer2(achievements_container, "Druid", 36)
	DrawClassContainer2(achievements_container, "Paladin", 36)
	DrawClassContainer2(achievements_container, "Priest", 36)
	DrawClassContainer2(achievements_container, "Shaman", 36)
	DrawClassContainer2(achievements_container, "Rogue", 36)
end

local function DrawLeaderboardTab(container)
	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetFullWidth(true)
	scroll_container:SetFullHeight(true)
	scroll_container:SetLayout("Fill")
	tabcontainer:AddChild(scroll_container)

	local scroll_frame = AceGUI:Create("ScrollFrame")
	scroll_frame:SetLayout("Flow")
	scroll_container:AddChild(scroll_frame)

	local first_menu_description_title = AceGUI:Create("Label")
	first_menu_description_title:SetWidth(500)
	first_menu_description_title:SetText("Leaderboard coming soon!")
	first_menu_description_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20)
	scroll_frame:AddChild(first_menu_description_title)
end

function ShowMainMenu(_hardcore_character, _hardcore_settings, dk_button_function)
	hardcore_modern_menu = AceGUI:Create("HardcoreFrameModernMenu")
	hardcore_modern_menu:SetCallback("OnClose", function(widget)
		if hardcore_modern_menu_state.ticker_handler ~= nil then
			hardcore_modern_menu_state.ticker_handler:Cancel()
			hardcore_modern_menu_state.ticker_handler = nil
		end
		hardcore_modern_menu_state.entry_tbl = {}
		AceGUI:Release(widget)
	end)
	hardcore_modern_menu:SetCallback("OnHide", function(widget)
		if hardcore_modern_menu_state.ticker_handler ~= nil then
			hardcore_modern_menu_state.ticker_handler:Cancel()
			hardcore_modern_menu_state.ticker_handler = nil
		end
		hardcore_modern_menu_state.entry_tbl = {}
		AceGUI:Release(widget)
	end)
       _G["HardcoreModernMenu"] = hardcore_modern_menu.frame -- Close on <ESC>
        tinsert(UISpecialFrames, "HardcoreModernMenu")

	hardcore_modern_menu:SetTitle("Classic Hardcore")
	hardcore_modern_menu:SetStatusText("")
	hardcore_modern_menu:SetLayout("Flow")

	tabcontainer = AceGUI:Create("TabGroup") -- "InlineGroup" is also good
	tabcontainer:SetTabs({
		{ value = "WelcomeTab", text = "General" },
		{ value = "RulesTab", text = "Rules" },
		{ value = "VerifyTab", text = "Verify" },
		{ value = "DKTab", text = "Death Knight" },
		{ value = "LevelsTab", text = "Levels" },
		{ value = "AccountabilityTab", text = "Accountability" },
		{ value = "AchievementsTab", text = "Achievements" },
		{ value = "LeaderboardTab", text = "Leaderboard" },
	}) -- ,
	tabcontainer:SetFullWidth(true)
	tabcontainer:SetFullHeight(true) -- probably?
	tabcontainer:SetLayout("Fill") -- important!

	-- Callback function for OnGroupSelected
	local function SelectGroup(container, event, group)
		container:ReleaseChildren()
		if hardcore_modern_menu_state.ticker_handler ~= nil then
			hardcore_modern_menu_state.ticker_handler:Cancel()
			hardcore_modern_menu_state.ticker_handler = nil
			hardcore_modern_menu_state.entry_tbl = {}
		end
		if group == "WelcomeTab" then
			DrawGeneralTab(container)
		elseif group == "RulesTab" then
			DrawRulesTab(container)
		elseif group == "VerifyTab" then
			DrawVerifyTab(container, _hardcore_character)
		elseif group == "DKTab" then
			DrawDKTab(container, dk_button_function)
		elseif group == "LevelsTab" then
			DrawLevelsTab(container, _hardcore_settings)
		elseif group == "AccountabilityTab" then
			DrawAccountabilityTab(container)
		elseif group == "PartyTab" then
			local scroll_container = AceGUI:Create("SimpleGroup")
			scroll_container:SetFullWidth(true)
			scroll_container:SetFullHeight(true)
			scroll_container:SetLayout("Fill")
			tabcontainer:AddChild(scroll_container)

			local scroll_frame = AceGUI:Create("ScrollFrame")
			scroll_frame:SetLayout("Flow")
			scroll_container:AddChild(scroll_frame)
		elseif group == "AchievementsTab" then
			DrawAchievementsTab(container)
		elseif group == "LeaderboardTab" then
			DrawLeaderboardTab(container)
		end
	end

	tabcontainer:SetCallback("OnGroupSelected", SelectGroup)
	tabcontainer:SelectTab("WelcomeTab")

	hardcore_modern_menu:AddChild(tabcontainer)
end

local guild_roster_handler = CreateFrame("Frame")
guild_roster_handler:RegisterEvent("GUILD_ROSTER_UPDATE")

-- Register Definitions
guild_roster_handler:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "GUILD_ROSTER_UPDATE" then
		-- Create a new dictionary of just online people every time roster is updated
		hardcore_modern_menu_state.guild_online = {}
		local numTotal, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		for i = 1, numOnline, 1 do
			local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID =
				GetGuildRosterInfo(i)

			-- name is nil after a gquit, so nil check here
			if name then
				hardcore_modern_menu_state.guild_online[name] = {
					name = name,
					level = level,
					classDisplayName = classDisplayName,
				}
			end
		end
	end
end)
