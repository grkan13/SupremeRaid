local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local HBD = LibStub("HereBeDragons-2.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local AceLocale = LibStub("AceLocale-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local addonName = ...
local _

local playerGUID = UnitGUID("player")
local _, playerClass = UnitClass("player")
local playerName = UnitName("player")
local playerRaidRole = nil
local skullListSelector, crossListSelector, squareListSelector, moonListSelector,
triangleListSelector, diamondListSelector, circleListSelector, starListSelector
local selectedTab = "tab2"

local raid = {}
raid.members = {}
raid.healers = {}
raid.tanks = {}
raid.filteredMemberList = {}
--[[
raid.skullPlayers = {}
raid.crossPlayers = {}
raid.squarePlayers = {}
raid.moonPlayers = {}
raid.trianglePlayers = {}
raid.diamondPlayers = {}
raid.circlePlayers = {}
raid.starPlayers = {}
]]

SupremeRaid = LibStub("AceAddon-3.0"):NewAddon("SupremeRaid", "AceConsole-3.0",
"AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
SupremeRaid.Version = GetAddOnMetadata(addonName, 'Version')
SupremeRaid.Author = GetAddOnMetadata(addonName, "Author")

local yourAssignedTank = nil
local yourAssignedTankIndex = nil
local selectedClassesToFilter = {}
local drinkingStatus = false

SupremeRaid.AnnouncementChannels = {
	"say", "yell", "party", "raid", "raid_warning", "supremeheals"
}

SupremeRaid.DrinkAnnouncementChannels = {
	"say", "yell", "party", "raid"
}

SupremeRaid.ClassList = {
	druid = "Druid", hunter = "Hunter", mage = "Mage", priest = "Priest",
	rogue = "Rogue", shaman = "Shaman", warlock = "Warlock", warrior = "Warrior"
}

local raidIconList = {
	star = "{rt1}", circle = "{rt2}", diamond = "{rt3}", triangle = "{rt4}",
  moon = "{rt5}", square = "{rt6}", cross = "{rt7}", skull = "{rt8}"
}


local raid1 = {}
raid1.healers = {}
raid1.tanks = {}
raid1.members = {}
function addmember(name,class)
  local member = {}
  member.name = name
  member.class = class
  member.tank1 = false
  member.tank2 = false
  member.tank3 = false
  member.tank4 = false
  member.tank5 = false
  member.tank1healer = false
  member.tank2healer = false
  member.tank3healer = false
  member.tank4healer = false
  member.tank5healer = false
  member.targetskull = false
  member.targetcross = false
  member.raidIcon = {}
  table.insert(raid.members, member)
end

addmember("Warrior1", "Warrior")
addmember("Warrior2", "Warrior")
addmember("Priest1", "Priest")
addmember("Priest2", "Priest")
addmember("Shaman1", "Shaman")
addmember("Shaman2", "Shaman")
addmember("Druid1", "Druid")
addmember("Druid2", "Druid")
addmember("Mage1", "Mage")
addmember("Mage2", "Mage")
addmember("Rogue1", "Rogue")
addmember("Rogue2", "Rogue")
addmember("Hunter1", "Hunter")
addmember("Hunter2", "Hunter")
addmember("Warlock1", "Warlock")
addmember("Warlock2", "Warlock")

local Default_Profile = {
	profile = {
		DebugEnabled = false,
		DrinkAnnouce = {
			Enabled = false,
			ChannelIndex = 1,
			ManaThreshold = 50,
			MessageTemplate = "$pn Drinking $mp% $tn",
      EndMessageTemplate = "$pn Back to Healing $mp% $tn"
		},
		HealAssigment = {
			ChannelIndex = 6,
		},
		TargetAssigment = {
			ChannelIndex = 4,
		},
	}
}

function SupremeRaid:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
	self.db = LibStub("AceDB-3.0"):New("SupremeRaidDB")
	local acedb = LibStub:GetLibrary("AceDB-3.0")
	self.db = acedb:New("SupremeRaidDB", Default_Profile)
	-- self.db.RegisterCallback(self, "OnNewProfile", "ResetProfile")
	--self.db.RegisterCallback(self, "OnProfileReset", "ResetProfile")
	--self.db.RegisterCallback(self, "OnProfileChanged", "HandleProfileChanges")
	--self.db.RegisterCallback(self, "OnProfileCopied", "HandleProfileChanges")
	SupremeRaid:EnableDebugPrint(false);
end

function SupremeRaid:OnEnable()
	if self.db.profile.optionA then
		self.db.profile.playerName = UnitName("player")
	end
end

function SupremeRaid:SlashCommandHandler(input)
  -- Process the slash command ('input' contains whatever follows the slash command)
	SupremeRaid:CreateFrame();
end
SupremeRaid:RegisterChatCommand("sup", "SlashCommandHandler")

local function GetChannelNameFromIndex(index)
	return SupremeRaid.AnnouncementChannels[index]
end

function SupremeRaid:OnUnitAuraEvent(eventName, unitTarget)
	local message
	if SupremeRaid:IsDrinkAnnounceEnabled() then
		for i=1,40 do
			local name = UnitBuff("player",i)
			if name == "Drink" then
				if drinkingStatus == false then
					local maxMana = UnitPowerMax("player")
					local currentMana = UnitPower("player")
					local percentMana = currentMana / maxMana * 100
					if percentMana < SupremeRaid:GetDrinkAnnounceManaThreshold() then
						message = SupremeRaid:GetDrinkAnnounceMessageTemplate()
						message = string.gsub(message, "$pn", playerName)
						message = string.gsub(message, "$mp", tostring(math.floor(percentMana)))
						if yourAssignedTank == nil then
							yourAssignedTank.name = ""
						end
						message = string.gsub(message, "$tn", yourAssignedTank.name)
						SupremeRaid:PrintDebug(message)
						SendMessageToChat(message, GetChannelNameFromIndex(SupremeRaid:GetDrinkAnnounceChannelIndex()))
						drinkingStatus  = true;
					end
				end
				break
			end
				-- Finished drinking but hasn't announced that yet
			if(i == 40 and drinkingStatus  == true) then
        local maxMana = UnitPowerMax("player")
        local currentMana = UnitPower("player")
        local percentMana = currentMana / maxMana * 100
        message = SupremeRaid:GetEndDrinkAnnounceMessageTemplate()
        message = string.gsub(message, "$pn", playerName)
        message = string.gsub(message, "$mp", tostring(math.floor(percentMana)))
        if yourAssignedTank == nil then
          yourAssignedTank.name = ""
        end
        message = string.gsub(message, "$tn", yourAssignedTank.name)
        SupremeRaid:PrintDebug(message)
				SendMessageToChat(message, GetChannelNameFromIndex(SupremeRaid:GetDrinkAnnounceChannelIndex()))
				SupremeRaid:PrintDebug(message)
				drinkingStatus  = false
			end
		end
	end
end

local function GetCombatRoleMembersFromRaid(combatRole)
	local combatRoleTable = {}
	if(combatRole == "healer") then
		for i=1,#raid.members do
			if(raid.members[i].class == "Priest" or raid.members[i].class == "Shaman" or raid.members[i].class == "Druid") then
				table.insert(combatRoleTable, raid.members[i])
			end
		end
	end
	if(combatRole == "tank") then
		for i=1,#raid.members do
			if(raid.members[i].class == "Warrior" or raid.members[i].class == "Druid") then
				table.insert(combatRoleTable, raid.members[i])
			end
		end
	end
	return combatRoleTable
end

local function GetRaidMembers()
local num = GetNumGroupMembers()
	for raidIndex = 1, num do
 		local member = {}
	  local name, rank, subgroup, level, class, fileName, zone, online,
    isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex);
		member.name = name
		member.class = class
		member.role = role
		member.tank1healer = false
		member.tank2healer = false
		member.tank3healer = false
		member.tank4healer = false
		member.tank5healer = false
		member.tank1 = false
		member.tank2 = false
		member.tank3 = false
		member.tank4 = false
		member.tank5 = false
		member.raidIcon = {}
		if name == playerName then
			playerRaidRole = role;
		end
		table.insert(raid.members, member)
	end
  raid.healers = GetCombatRoleMembersFromRaid("healer")
  raid.tanks = GetCombatRoleMembersFromRaid("tank")
end

local function GetClassMembersFromRaid(class)
	local memberTable = {}
	for i=1,#raid.members do
		if(raid.members[i].class == class) then
			table.insert(memberTable, raid.members[i])
		end
	end
	return memberTable
end

local function DropDownList(mainList)
  local simpleList = {}
  for i=1,#mainList do
    table.insert(simpleList, mainList[i].name)
  end
  return simpleList
end

function classFilterCallBack(self, event, key, checked)
    local class = SupremeRaid.ClassList[key]
	if checked then
		selectedClassesToFilter[key] = class
	else
		selectedClassesToFilter[key] = nil
	end
	for i=1,#raid.members do
		if raid.members[i].class == class then
			if checked then
				table.insert(raid.filteredMemberList, raid.members[i].name)
			else
				raid.members[i].raidIcon = {}
				for j=1, #raid.filteredMemberList do
					if raid.filteredMemberList[j] == raid.members[i].name then
						table.remove(raid.filteredMemberList, j)
						break
					end
				end
			end
		end
	end
	repopulateFilteredClassList()
end

function repopulateFilteredClassList()
	skullListSelector:SetList(raid.filteredMemberList)
	crossListSelector:SetList(raid.filteredMemberList)
	squareListSelector:SetList(raid.filteredMemberList)
	moonListSelector:SetList(raid.filteredMemberList)
	triangleListSelector:SetList(raid.filteredMemberList)
	diamondListSelector:SetList(raid.filteredMemberList)
	circleListSelector:SetList(raid.filteredMemberList)
	starListSelector:SetList(raid.filteredMemberList)


	for i=1, #raid.members do
		if raid.members[i].raidIcon.skull == raidIconList.skull then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					skullListSelector:SetItemValue(j, true)
					break
				end
			end
		end
		if raid.members[i].raidIcon.cross == raidIconList.cross then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					crossListSelector:SetItemValue(j, true)
					break
				end
			end
		end
		if raid.members[i].raidIcon.square == raidIconList.square then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					squareListSelector:SetItemValue(j, true)
					break
				end
			end
		end
		if raid.members[i].raidIcon.moon == raidIconList.moon then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					moonListSelector:SetItemValue(j, true)
					break
				end
			end
		end
		if raid.members[i].raidIcon.triangle == raidIconList.triangle then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					triangleListSelector:SetItemValue(j, true)
					break
				end
			end
		end
		if raid.members[i].raidIcon.diamond == raidIconList.diamond then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					diamondListSelector:SetItemValue(j, true)
					break
				end
			end
		end
		if raid.members[i].raidIcon.circle == raidIconList.circle then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					circleListSelector:SetItemValue(j, true)
					break
				end
			end
		end
		if raid.members[i].raidIcon.star == raidIconList.star then
			for j=1, #raid.filteredMemberList do
				if raid.filteredMemberList[j] == raid.members[i].name then
					starListSelector:SetItemValue(j, true)
					break
				end
			end
		end
	end
end



function skullSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon.skull = raidIconList.skull
      else
		raid.members[i].raidIcon.skull = nil
      end
      break
    end
  end
end

function crossSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon["cross"] = "{rt7}"
      else
		raid.members[i].raidIcon["cross"] = nil
      end
      break
    end
  end
end

function squareSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon["square"] = "{rt6}"
      else
		raid.members[i].raidIcon["square"] = nil
      end
      break
    end
  end
end

function moonSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon["moon"] = "{rt5}"
      else
		raid.members[i].raidIcon["moon"] = nil
      end
      break
    end
  end
end

function triangleSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon["triangle"] = "{rt4}"
      else
		raid.members[i].raidIcon["triangle"] = nil
      end
      break
    end
  end
end

function diamondSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon["diamond"] = "{rt3}"
      else
		raid.members[i].raidIcon["diamond"] = nil
      end
      break
    end
  end
end

function circleSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon["circle"] = "{rt2}"
      else
		raid.members[i].raidIcon["circle"] = nil
      end
      break
    end
  end
end

function starSelectorCallback(self, event, key, checked)
  for i=1, #raid.members do
    if raid.filteredMemberList[key] == raid.members[i].name then
      if checked then
		raid.members[i].raidIcon["star"] = "{rt1}"
      else
		raid.members[i].raidIcon["star"] = nil
      end
      break
    end
  end
end

function tank1HealerCallback(self, event, key, checked)
	for i=1, #raid.members do
		if raid.healers[key].name == raid.members[i].name then
			raid.members[i].tank1healer = checked
		end
	end
end

function tank2HealerCallback(self, event, key, checked)
	for i=1, #raid.members do
		if raid.healers[key].name == raid.members[i].name then
			raid.members[i].tank2healer = checked
		end
	end
end

function tank3HealerCallback(self, event, key, checked)
	for i=1, #raid.members do
		if raid.healers[key].name == raid.members[i].name then
			raid.members[i].tank3healer = checked
		end
	end
end

function tank4HealerCallback(self, event, key, checked)
	for i=1, #raid.members do
		if raid.healers[key].name == raid.members[i].name then
			raid.members[i].tank4healer = checked
		end
	end
end

function tank5HealerCallback(self, event, key, checked)
	for i=1, #raid.members do
		if raid.healers[key].name == raid.members[i].name then
			raid.members[i].tank5healer = checked
		end
	end
end

function tank1Callback(self, event, key, checked)
	for i=1, #raid.members do
		raid.members[i].tank1 = false
		if raid.tanks[key].name == raid.members[i].name then
			raid.members[i].tank1 = true
		end
	end
end

function tank2Callback(self, event, key, checked)
	for i=1, #raid.members do
		raid.members[i].tank2 = false
		if raid.tanks[key].name == raid.members[i].name then
			raid.members[i].tank2 = true
		end
	end
end

function tank3Callback(self, event, key, checked)
	for i=1, #raid.members do
		raid.members[i].tank3 = false
		if raid.tanks[key].name == raid.members[i].name then
			raid.members[i].tank3 = true
		end
	end
end

function tank4Callback(self, event, key, checked)
	for i=1, #raid.members do
		raid.members[i].tank4 = false
		if raid.tanks[key].name == raid.members[i].name then
			raid.members[i].tank4 = true
		end
	end
end

function tank5Callback(self, event, key)
	for i=1, #raid.members do
		raid.members[i].tank5 = false
		if raid.tanks[key].name == raid.members[i].name then
			raid.members[i].tank5 = true
		end
	end
end

function healAssigmentAnnounceChannelSelectionCallBack(self, event, key)
	SupremeRaid:SetHealAssigmentAnnounceChannelIndex(key)
	SupremeRaid:PrintDebug(SupremeRaid:GetHealAssigmentAnnounceChannelIndex())
end

function targetAssigmentAnnounceChannelSelectionCallBack(self, event, key)
	SupremeRaid:SetTargetAssingmentAnnounceChannelIndex(key)
	SupremeRaid:PrintDebug(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex())
end

function drinkAnnounceChannelSelectionCallBack(self, event, key)
	SupremeRaid:SetDrinkAnnounceChannelIndex(key)
	SupremeRaid:PrintDebug(SupremeRaid:GetDrinkAnnounceChannelIndex())
end

function drinkAnnounceEditBoxCallBack(self, event, text)

	local num = tonumber(text)
	if num == nil then
		SupremeRaid:Print("Only numbers")
	elseif num > 100 then
		SupremeRaid:Print("Maximum 100")
	elseif num < 0 then
		SupremeRaid:Print("Minimum 0")
	else
		SupremeRaid:SetDrinkAnnounceManaThreshold(num)
		SupremeRaid:PrintDebug(SupremeRaid:GetDrinkAnnounceManaThreshold())
	end
end

function DrinkingAnnounceCheckBoxCallBack(self, event, value)
	SupremeRaid:EnableDrinkAnnounce(value)
	SupremeRaid:PrintDebug(SupremeRaid:IsDrinkAnnounceEnabled())
end

function assignedTankCallback(self, event, key)
	yourAssignedTank = raid.tanks[key]
	yourAssignedTankIndex = key
	SupremeRaid:PrintDebug(yourAssignedTank)
end

function announceMessageEditBoxCallBack(self, event, text)
	SupremeRaid:SetDrinkAnnounceMessageTemplate(text)
	SupremeRaid:PrintDebug(SupremeRaid:GetDrinkAnnounceMessageTemplate())
end

function announceEndMessageEditBoxCallBack(self, event, text)
	SupremeRaid:SetEndDrinkAnnounceMessageTemplate(text)
	SupremeRaid:PrintDebug(SupremeRaid:GetEndDrinkAnnounceMessageTemplate())
end

function announceHealAssigment()
	local tank1Message, tank2Message, tank3Message, tank4Message, tank5Message = nil,nil,nil,nil,nil
  local tank1, tank2, tank3, tank4, tank5 = nil,nil,nil,nil,nil
  local tank1healers, tank2healers, tank3healers, tank4healers, tank5healers = {},{},{},{},{}
  for i=1, #raid.members do
      local member = raid.members[i]
      if member.tank1 then tank1 = member.name end
      if member.tank2 then tank2 = member.name end
      if member.tank3 then tank3 = member.name end
      if member.tank4 then tank4 = member.name end
      if member.tank5 then tank5 = member.name end
      if member.tank1healer then table.insert(tank1healers, member.name) end
      if member.tank2healer then table.insert(tank2healers, member.name) end
      if member.tank3healer then table.insert(tank3healers, member.name) end
      if member.tank4healer then table.insert(tank4healers, member.name) end
      if member.tank5healer then table.insert(tank5healers, member.name) end
  end
	if tank1 == nil then
		SupremeRaid:Print("Assign Tank 1")
	elseif tank1healers == nil or #tank1healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 1")
	else
		tank1Message = tank1 .. " -- " .. table.concat(tank1healers,", ")
  	SupremeRaid:PrintDebug(tank1Message)
    SendMessageToChat(tank1Message, GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if tank2 == nil then
		SupremeRaid:Print("Assign Tank 2")
	elseif tank2healers == nil or #tank2healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 2")
	else
		tank2Message = tank2 .. " -- " .. table.concat(tank2healers,", ")
  	SupremeRaid:PrintDebug(tank2Message)
    SendMessageToChat(tank2Message, GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if tank3 == nil then
		SupremeRaid:Print("Assign Tank 3")
	elseif tank3healers == nil or #tank3healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 3")
	else
		tank3Message = tank3 .. " -- " .. table.concat(tank3healers,", ")
  	SupremeRaid:PrintDebug(tank3Message)
    SendMessageToChat(tank3Message, GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if tank4 == nil then
		SupremeRaid:Print("Assign Tank 4")
	elseif tank4healers == nil or #tank4healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 4")
	else
		tank4Message = tank4 .. " -- " .. table.concat(tank4healers,", ")
  	SupremeRaid:PrintDebug(tank1Message)
    SendMessageToChat(tank4Message, GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if tank5 == nil then
		SupremeRaid:Print("Assign Tank 5")
	elseif tank5healers == nil or #tank5healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 5")
	else
		tank5Message = tank5 .. " -- " .. table.concat(tank5healers,", ")
  	SupremeRaid:PrintDebug(tank5Message)
    SendMessageToChat(tank5Message, GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
end

function announceTargetAssigment()
	local skullMessage, crossMessage, squareMessage, moonMessage,
	triangleMessage, diamondMessage, circleMessage, starMessage
	local skullList, crossList, squareList, moonList, triangleList,
	diamondList, circleList, starList = {} , {}, {}, {}, {}, {}, {}, {}
	for i=1, #raid.members do
		if raid.members[i].raidIcon.skull == raidIconList.skull then
			table.insert(skullList, raid.members[i].name)
		end
		if raid.members[i].raidIcon.cross == raidIconList.cross then
			table.insert(crossList, raid.members[i].name)
		end
		if raid.members[i].raidIcon.square == raidIconList.square then
			table.insert(squareList, raid.members[i].name)
		end
		if raid.members[i].raidIcon.moon == raidIconList.moon then
			table.insert(moonList, raid.members[i].name)
		end
		if raid.members[i].raidIcon.triangle == raidIconList.triangle then
			table.insert(triangleList, raid.members[i].name)
		end
		if raid.members[i].raidIcon.diamond == raidIconList.diamond then
			table.insert(diamondList, raid.members[i].name)
		end
		if raid.members[i].raidIcon.circle == raidIconList.circle then
			table.insert(circleList, raid.members[i].name)
		end
		if raid.members[i].raidIcon.star == raidIconList.star then
			table.insert(starList, raid.members[i].name)
		end
	end
	if skullList == nil or #skullList == 0 then
		SupremeRaid:Print("Assign Players to SKULL")
	else
		skullMessage = raidIconList.skull .. " = " .. table.concat(skullList,", ")
		SupremeRaid:PrintDebug(skullMessage)
		SendMessageToChat(skullMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if crossList == nil  or #crossList == 0 then
		SupremeRaid:Print("Assign Players to CROSS")
	else
		crossMessage = "{rt7}" .. " = " .. table.concat(crossList,", ")
		SupremeRaid:PrintDebug(crossMessage)
		SendMessageToChat(crossMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if squareList == nil or #squareList == 0 then
		SupremeRaid:Print("Assign Players to SQUARE")
	else
		squareMessage = "{rt6}" .. " = " .. table.concat(squareList,", ")
		SupremeRaid:PrintDebug(squareMessage)
		SendMessageToChat(squareMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if moonList == nil or #moonList == 0 then
		SupremeRaid:Print("Assign Players to MOON")
	else
		moonMessage = "{rt5}" .. " = " .. table.concat(moonList,", ")
		SupremeRaid:PrintDebug(moonMessage)
		SendMessageToChat(moonMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if triangleList == nil or #triangleList == 0 then
		SupremeRaid:Print("Assign Players to TRIANGLE")
	else
		triangleMessage = "{rt4}" .. " = " .. table.concat(triangleList,", ")
		SupremeRaid:PrintDebug(triangleMessage)
		SendMessageToChat(triangleMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if diamondList == nil or #diamondList == 0 then
		SupremeRaid:Print("Assign Players to DIAMOND")
	else
		diamondMessage = "{rt3}" .. " = " .. table.concat(diamondList,", ")
		SupremeRaid:PrintDebug(diamondMessage)
		SendMessageToChat(diamondMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if circleList == nil or #circleList == 0 then
		SupremeRaid:Print("Assign Players to CIRCLE")
	else
		circleMessage = "{rt2}" .. " = " .. table.concat(circleList,", ")
		SupremeRaid:PrintDebug(circleMessage)
		SendMessageToChat(circleMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if starList == nil or #starList == 0 then
		SupremeRaid:Print("Assign Players to STAR")
	else
		starMessage = "{rt1}" .. " = " .. table.concat(starList,", ")
		SupremeRaid:PrintDebug(starMessage)
		SendMessageToChat(starMessage, GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
end


-- function that draws the widgets for the second tab
local function DrawGroup1(container)

	local desc = AceGUI:Create("Label")
	desc:SetText("You will announce your drinking status to the selected channels")
	desc:SetFullWidth(true)
	container:AddChild(desc)

	local disableCheckBox = AceGUI:Create("CheckBox")
	disableCheckBox:SetLabel("Enabled")
	disableCheckBox:SetValue(SupremeRaid:IsDrinkAnnounceEnabled())
	disableCheckBox:SetCallback("OnValueChanged", DrinkingAnnounceCheckBoxCallBack)
	container:AddChild(disableCheckBox)

	local announceChannelSelector = AceGUI:Create("Dropdown")
	announceChannelSelector:SetLabel("Announce your drinking status to:")
	announceChannelSelector:SetFullWidth(true)
	announceChannelSelector:SetText("Select Channel")
	announceChannelSelector:SetList(SupremeRaid.DrinkAnnouncementChannels)
	announceChannelSelector:SetValue(SupremeRaid:GetDrinkAnnounceChannelIndex())
	announceChannelSelector:SetCallback("OnValueChanged", drinkAnnounceChannelSelectionCallBack)
	container:AddChild(announceChannelSelector)

	local manaThresholdEditBox = AceGUI:Create("EditBox")
	manaThresholdEditBox:SetFullWidth(true)
	manaThresholdEditBox:SetLabel("You will only announce if your mana is over %")
	manaThresholdEditBox:SetMaxLetters(3)
	manaThresholdEditBox:SetCallback("OnEnterPressed", drinkAnnounceEditBoxCallBack)
	manaThresholdEditBox:SetText(tostring(SupremeRaid:GetDrinkAnnounceManaThreshold()))
	container:AddChild(manaThresholdEditBox)

	local tankSelector = AceGUI:Create("Dropdown")
	tankSelector:SetLabel("You will mention your tank in the message")
	tankSelector:SetRelativeWidth(1)
	tankSelector:SetText("Select Your Assigned Tank")
	tankSelector:SetList(DropDownList(raid.tanks))
	tankSelector:SetValue(yourAssignedTankIndex)
	tankSelector:SetCallback("OnValueChanged", assignedTankCallback)
	container:AddChild(tankSelector)

	local announceMessageEditBox = AceGUI:Create("EditBox")
	announceMessageEditBox:SetFullWidth(true)
	announceMessageEditBox:SetLabel("Your drinking announce message template: ")
	announceMessageEditBox:SetMaxLetters(100)
	announceMessageEditBox:SetCallback("OnEnterPressed", announceMessageEditBoxCallBack)
	announceMessageEditBox:SetText(SupremeRaid:GetDrinkAnnounceMessageTemplate())
	container:AddChild(announceMessageEditBox)

  local announceEndMessageEditBox = AceGUI:Create("EditBox")
  announceEndMessageEditBox:SetFullWidth(true)
  announceEndMessageEditBox:SetLabel("End of drinking announce message template: ")
  announceEndMessageEditBox:SetMaxLetters(100)
  announceEndMessageEditBox:SetCallback("OnEnterPressed", announceEndMessageEditBoxCallBack)
  announceEndMessageEditBox:SetText(SupremeRaid:GetEndDrinkAnnounceMessageTemplate())
  container:AddChild(announceEndMessageEditBox)

	local messageDescriptionText = AceGUI:Create("Label")
	messageDescriptionText:SetText([[
$pn - Player name
$mp - Current mana percentage
$tn - Tank name
]])
	messageDescriptionText:SetFullWidth(true)
	container:AddChild(messageDescriptionText)
end

-- function that draws the widgets for the first tab
local function DrawGroup2(container)

  local simpleTankList = DropDownList(raid.tanks)
  local simpleHealerList = DropDownList(raid.healers)
	local tankSelector1 = AceGUI:Create("Dropdown")
	tankSelector1:SetLabel("Tank #1")
	tankSelector1:SetRelativeWidth(0.5)
	tankSelector1:SetText("Select A Tank")
	tankSelector1:SetList(simpleTankList)
	tankSelector1:SetCallback("OnValueChanged", tank1Callback)
	container:AddChild(tankSelector1)
	for i=1, #raid.tanks do
		if(raid.tanks[i].tank1) then
			tankSelector1:SetValue(i)
		break
		end
	end

  local healerSelector1 = AceGUI:Create("Dropdown")
	healerSelector1:SetLabel("Healer #1")
	healerSelector1:SetRelativeWidth(0.5)
	healerSelector1:SetText("Select Healer")
	healerSelector1:SetList(simpleHealerList)
	healerSelector1:SetMultiselect(true)
	healerSelector1:SetCallback("OnValueChanged", tank1HealerCallback)
	container:AddChild(healerSelector1)
	for i=1, #raid.healers do
		healerSelector1:SetItemValue(i,raid.healers[i].tank1healer)
	end

	local tankSelector2 = AceGUI:Create("Dropdown")
	tankSelector2:SetLabel("Tank #2")
	tankSelector2:SetRelativeWidth(0.5)
	tankSelector2:SetText("Select A Tank")
	tankSelector2:SetList(simpleTankList)
	tankSelector2:SetCallback("OnValueChanged", tank2Callback)
	container:AddChild(tankSelector2)
	for i=1, #raid.tanks do
		if(raid.tanks[i].tank2) then
			tankSelector2:SetValue(i)
		break
		end
	end

	local healerSelector2 = AceGUI:Create("Dropdown")
	healerSelector2:SetLabel("Healer #2")
	healerSelector2:SetRelativeWidth(0.5)
	healerSelector2:SetText("Select Healer")
	healerSelector2:SetMultiselect(true)
	healerSelector2:SetList(simpleHealerList)
	healerSelector2:SetCallback("OnValueChanged", tank2HealerCallback)
	container:AddChild(healerSelector2)
	for i=1, #raid.healers do
		healerSelector2:SetItemValue(i,raid.healers[i].tank2healer)
	end

	local tankSelector3 = AceGUI:Create("Dropdown")
	tankSelector3:SetLabel("Tank #3")
	tankSelector3:SetRelativeWidth(0.5)
	tankSelector3:SetText("Select A Tank")
	tankSelector3:SetList(simpleTankList)
	tankSelector3:SetCallback("OnValueChanged", tank3Callback)
	container:AddChild(tankSelector3)
	for i=1, #raid.tanks do
		if(raid.tanks[i].tank3) then
			tankSelector3:SetValue(i)
		break
		end
	end

	local healerSelector3 = AceGUI:Create("Dropdown")
	healerSelector3:SetLabel("Healer #3")
	healerSelector3:SetRelativeWidth(0.5)
	healerSelector3:SetText("Select Healer")
	healerSelector3:SetMultiselect(true)
	healerSelector3:SetList(simpleHealerList)
	healerSelector3:SetCallback("OnValueChanged", tank3HealerCallback)
	container:AddChild(healerSelector3)
	for i=1, #raid.healers do
		healerSelector3:SetItemValue(i,raid.healers[i].tank3healer)
	end

	local tankSelector4 = AceGUI:Create("Dropdown")
	tankSelector4:SetLabel("Tank #4")
	tankSelector4:SetRelativeWidth(0.5)
	tankSelector4:SetText("Select A Tank")
	tankSelector4:SetList(simpleTankList)
	tankSelector4:SetCallback("OnValueChanged", tank4Callback)
	container:AddChild(tankSelector4)
	for i=1, #raid.tanks do
		if(raid.tanks[i].tank4) then
			tankSelector4:SetValue(i)
		break
		end
	end

	local healerSelector4 = AceGUI:Create("Dropdown")
	healerSelector4:SetLabel("Healer #4")
	healerSelector4:SetRelativeWidth(0.5)
	healerSelector4:SetText("Select Healer")
	healerSelector4:SetMultiselect(true)
	healerSelector4:SetList(simpleHealerList)
	healerSelector4:SetCallback("OnValueChanged", tank4HealerCallback)
	container:AddChild(healerSelector4)
	for i=1, #raid.healers do
		healerSelector4:SetItemValue(i,raid.healers[i].tank4healer)
	end

	local tankSelector5 = AceGUI:Create("Dropdown")
	tankSelector5:SetLabel("Tank #5")
	tankSelector5:SetRelativeWidth(0.5)
	tankSelector5:SetText("Select A Tank")
	tankSelector5:SetList(simpleTankList)
	tankSelector5:SetCallback("OnValueChanged", tank5Callback)
	container:AddChild(tankSelector5)
	for i=1, #raid.tanks do
		if(raid.tanks[i].tank5) then
			tankSelector5:SetValue(i)
		break
		end
	end


	local healerSelector5 = AceGUI:Create("Dropdown")
	healerSelector5:SetLabel("Healer #5")
	healerSelector5:SetRelativeWidth(0.5)
	healerSelector5:SetText("Select Healer")
	healerSelector5:SetMultiselect(true)
	healerSelector5:SetList(simpleHealerList)
	healerSelector5:SetCallback("OnValueChanged", tank5HealerCallback)
	container:AddChild(healerSelector5)
	for i=1, #raid.healers do
		healerSelector5:SetItemValue(i,raid.healers[i].tank5healer)
	end

	local announceChannelSelector = AceGUI:Create("Dropdown")
	announceChannelSelector:SetLabel("Announce Heal Assignment to:")
	announceChannelSelector:SetRelativeWidth(0.5)
	announceChannelSelector:SetText("Select Channel")
	announceChannelSelector:SetList(SupremeRaid.AnnouncementChannels)
	announceChannelSelector:SetValue(SupremeRaid:GetHealAssigmentAnnounceChannelIndex())
	announceChannelSelector:SetCallback("OnValueChanged", healAssigmentAnnounceChannelSelectionCallBack)
	container:AddChild(announceChannelSelector)

	local button = AceGUI:Create("Button")
	button:SetRelativeWidth(0.5)
	button:SetText("Announce")
	button:SetCallback("OnClick", announceHealAssigment)
	container:AddChild(button)
end

-- function that draws the widgets for the second tab
local function DrawGroup3(container)

	local classFilterSelector = AceGUI:Create("Dropdown")
	classFilterSelector:SetLabel("Select Classes to Filter")
	classFilterSelector:SetRelativeWidth(0.99)
	classFilterSelector:SetText("Select Classes")
	classFilterSelector:SetList(SupremeRaid.ClassList)
	classFilterSelector:SetCallback("OnValueChanged", classFilterCallBack)
	classFilterSelector:SetMultiselect(true)
	container:AddChild(classFilterSelector)
	for key,value in pairs(selectedClassesToFilter) do
		classFilterSelector:SetItemValue(key, value)
	end

	local skullText = AceGUI:Create("Label")
	skullText:SetText("|cffffffffSKULL|r")
	skullText:SetRelativeWidth(0.2)
	container:AddChild(skullText)

	skullListSelector = AceGUI:Create("Dropdown")
	skullListSelector:SetLabel("Select Player to Assign")
	skullListSelector:SetRelativeWidth(0.79)
	skullListSelector:SetText("Select Classes")
	skullListSelector:SetMultiselect(true)
	skullListSelector:SetCallback("OnValueChanged", skullSelectorCallback)
	container:AddChild(skullListSelector)

	local crossText = AceGUI:Create("Label")
	crossText:SetText("|cffFF0000CROSS|r")
	crossText:SetRelativeWidth(0.2)
	container:AddChild(crossText)

	crossListSelector = AceGUI:Create("Dropdown")
	crossListSelector:SetLabel("Select Player to Assign")
	crossListSelector:SetRelativeWidth(0.79)
	crossListSelector:SetText("Select Classes")
	crossListSelector:SetMultiselect(true)
	crossListSelector:SetCallback("OnValueChanged", crossSelectorCallback)
	container:AddChild(crossListSelector)

	local squareText = AceGUI:Create("Label")
	squareText:SetText("|cff00BFFFSQUARE|r")
	squareText:SetRelativeWidth(0.2)
	container:AddChild(squareText)

	squareListSelector = AceGUI:Create("Dropdown")
	squareListSelector:SetLabel("Select Player to Assign")
	squareListSelector:SetRelativeWidth(0.79)
	squareListSelector:SetText("Select Classes")
	squareListSelector:SetMultiselect(true)
	squareListSelector:SetCallback("OnValueChanged", squareSelectorCallback)
	container:AddChild(squareListSelector)

	local moonText = AceGUI:Create("Label")
	moonText:SetText("|cffc7c7cfMOON|r")
	moonText:SetRelativeWidth(0.2)
	container:AddChild(moonText)

	moonListSelector = AceGUI:Create("Dropdown")
	moonListSelector:SetLabel("Select Player to Assign")
	moonListSelector:SetRelativeWidth(0.79)
	moonListSelector:SetText("Select Classes")
	moonListSelector:SetMultiselect(true)
	moonListSelector:SetCallback("OnValueChanged", moonSelectorCallback)
	container:AddChild(moonListSelector)

	local triangleText = AceGUI:Create("Label")
	triangleText:SetText("|cff7CFC00TRIANGLE|r")
	triangleText:SetRelativeWidth(0.2)
	container:AddChild(triangleText)

	triangleListSelector = AceGUI:Create("Dropdown")
	triangleListSelector:SetLabel("Select Player to Assign")
	triangleListSelector:SetRelativeWidth(0.79)
	triangleListSelector:SetText("Select Classes")
	triangleListSelector:SetMultiselect(true)
	triangleListSelector:SetCallback("OnValueChanged", triangleSelectorCallback)
	container:AddChild(triangleListSelector)

	local diamondText = AceGUI:Create("Label")
	diamondText:SetText("|cffff00ffDIAMOND|r")
	diamondText:SetRelativeWidth(0.2)
	container:AddChild(diamondText)

	diamondListSelector = AceGUI:Create("Dropdown")
	diamondListSelector:SetLabel("Select Player to Assign")
	diamondListSelector:SetRelativeWidth(0.79)
	diamondListSelector:SetText("Select Classes")
	diamondListSelector:SetMultiselect(true)
	diamondListSelector:SetCallback("OnValueChanged", diamondSelectorCallback)
	container:AddChild(diamondListSelector)

	local circleText = AceGUI:Create("Label")
	circleText:SetText("|cffff8000CIRCLE|r")
	circleText:SetRelativeWidth(0.2)
	container:AddChild(circleText)

	circleListSelector = AceGUI:Create("Dropdown")
	circleListSelector:SetLabel("Select Player to Assign")
	circleListSelector:SetRelativeWidth(0.79)
	circleListSelector:SetText("Select Classes")
	circleListSelector:SetMultiselect(true)
	circleListSelector:SetCallback("OnValueChanged", circleSelectorCallback)
	container:AddChild(circleListSelector)

	local starText = AceGUI:Create("Label")
	starText:SetText("|cffffff00STAR|r")
	starText:SetRelativeWidth(0.2)
	container:AddChild(starText)

	starListSelector = AceGUI:Create("Dropdown")
	starListSelector:SetLabel("Select Player to Assign")
	starListSelector:SetRelativeWidth(0.79)
	starListSelector:SetText("Select Classes")
	starListSelector:SetMultiselect(true)
	starListSelector:SetCallback("OnValueChanged", starSelectorCallback)
	container:AddChild(starListSelector)

	local announceChannelSelector = AceGUI:Create("Dropdown")
	announceChannelSelector:SetLabel("Announce Target Assignment to:")
	announceChannelSelector:SetRelativeWidth(0.5)
	announceChannelSelector:SetText("Select Channel")
	announceChannelSelector:SetList(SupremeRaid.AnnouncementChannels)
	announceChannelSelector:SetValue(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex())
	announceChannelSelector:SetCallback("OnValueChanged", targetAssigmentAnnounceChannelSelectionCallBack)
	container:AddChild(announceChannelSelector)

	local button = AceGUI:Create("Button")
	button:SetRelativeWidth(0.5)
	button:SetText("Announce")
	button:SetCallback("OnClick", announceTargetAssigment)
	container:AddChild(button)

	repopulateFilteredClassList()
end

-- Callback function for OnGroupSelected
local function SelectGroup(container, event, group)
	container:ReleaseChildren()
	if group == "tab1" then
		selectedTab = "tab1"
		DrawGroup1(container)
	elseif group == "tab2" then
		selectedTab = "tab2"
		DrawGroup2(container)
	elseif group == "tab3" then
		selectedTab = "tab3"
		DrawGroup3(container)
	end
end

function SupremeRaid:CreateFrame()
	GetRaidMembers()
	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Supreme Raid Helper")
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame:SetWidth(500)
	frame:SetHeight(600)
	frame:SetLayout("Fill")

	-- Create the TabGroup
	local tab =  AceGUI:Create("TabGroup")
	local tabs = {}
	tab:SetLayout("Flow")
	-- Register callback
	tab:SetCallback("OnGroupSelected", SelectGroup)
	-- if playerClass == "Priest" or playerClass == "Shaman" or playerClass == "Druid" then
		table.insert(tabs, {text="Drink Announcement", value="tab1"})
		tab:SetTabs(tabs)
		if selectedTab == nil then
			selectedTab = "tab1"
		end
	-- end
	if playerRole == nil or playerRole == "maintank" or playerRole == "mainassist" then
		table.insert(tabs, {text="Heal Assigment", value="tab2"})
		table.insert(tabs, {text="Target Assigment", value="tab3"})
		tab:SetTabs(tabs)
		if selectedTab == nil then
			selectedTab = "tab2"
		end
	end
	-- Set initial Tab (this will fire the OnGroupSelected callback)
		tab:SelectTab(selectedTab)
	-- add to the frame container
	frame:AddChild(tab)
end

function SendMessageToChat(message, channelName)
	if channelName == "say" or channelName == "yell" or channelName == "raid" or channelName == "party" or channelName == "raid_warning" then
		SendChatMessage(message, channelName)
	else
		local channelID = GetChannelName(channelName);
		if channelID > 0 then
			SendChatMessage(message, "CHANNEL", nil, channelID)
		end
	end
end

function SupremeRaid:PrintDebug(...)
	if SupremeRaid:IsDebugPrintEnabled() then
		SupremeRaid:Print(...)
	end
end

function SupremeRaid:IsDebugPrintEnabled()
	return SupremeRaid.db.profile.DebugEnabled
end

function SupremeRaid:EnableDebugPrint(value)
	SupremeRaid.db.profile.DebugEnabled = value
end

function SupremeRaid:EnableDrinkAnnounce(value)
	SupremeRaid.db.profile.DrinkAnnouce.Enabled = value
end

function SupremeRaid:IsDrinkAnnounceEnabled()
	return SupremeRaid.db.profile.DrinkAnnouce.Enabled
end

function SupremeRaid:SetDrinkAnnounceManaThreshold(value)
	SupremeRaid.db.profile.DrinkAnnouce.ManaThreshold = value
end

function SupremeRaid:GetDrinkAnnounceManaThreshold()
	return SupremeRaid.db.profile.DrinkAnnouce.ManaThreshold
end

function SupremeRaid:SetDrinkAnnounceMessageTemplate(value)
	SupremeRaid.db.profile.DrinkAnnouce.MessageTemplate = value
end

function SupremeRaid:GetDrinkAnnounceMessageTemplate()
	return SupremeRaid.db.profile.DrinkAnnouce.MessageTemplate
end

function SupremeRaid:SetEndDrinkAnnounceMessageTemplate(value)
	SupremeRaid.db.profile.DrinkAnnouce.EndMessageTemplate = value
end

function SupremeRaid:GetEndDrinkAnnounceMessageTemplate()
	return SupremeRaid.db.profile.DrinkAnnouce.EndMessageTemplate
end

function SupremeRaid:SetHealAssigmentAnnounceChannelIndex(value)
	SupremeRaid.db.profile.HealAssigment.ChannelIndex = value
end

function SupremeRaid:GetHealAssigmentAnnounceChannelIndex()
	return SupremeRaid.db.profile.HealAssigment.ChannelIndex
end

function SupremeRaid:SetDrinkAnnounceChannelIndex(value)
	SupremeRaid.db.profile.DrinkAnnouce.ChannelIndex = value
end

function SupremeRaid:GetDrinkAnnounceChannelIndex()
	return SupremeRaid.db.profile.DrinkAnnouce.ChannelIndex
end

function SupremeRaid:SetTargetAssingmentAnnounceChannelIndex(value)
	SupremeRaid.db.profile.TargetAssigment.ChannelIndex = value
end

function SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()
	return SupremeRaid.db.profile.TargetAssigment.ChannelIndex
end

function tablePrint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tablePrint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

SupremeRaid:RegisterEvent("UNIT_AURA", "OnUnitAuraEvent")
