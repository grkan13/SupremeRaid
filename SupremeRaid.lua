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
local skullListSelector, crossListSelector, squareListSelector, moonListSelector, triangleListSelector, diamondListSelector, circleListSelector, starListSelector
local healers1Table = nil
local selectedTab = "tab2"

local raid = {}
raid.members = {}
raid.warriors = {"Kagedorf", "Drakoh"}
raid.priests = {"Pio", "Chimble", "Macewindu"}
raid.shamans = {"Xpace", "HungrySalami"}
raid.druids = {"Cowhileonard", "Dwigthcoward"}
raid.mages = {"Rekks", "Murdera"}
raid.rogues = {"Aagrim", "Cidolbones"}
raid.hunters = {"Satchmaux", "Servicer"}
raid.warlocks = {"Majutsu", "Lowkey"}
raid.healers = {}
raid.tanks = {}
raid.tank1 = nil
raid.tank1healers = {}
raid.tank2 = nil
raid.tank2healers = {}
raid.tank3 = nil
raid.tank3healers = {}
raid.tank4 = nil
raid.tank4healers = {}
raid.tank5 = nil
raid.tank5healers = {}
raid.filteredClassList = {}
raid.skullPlayers = {}
raid.crossPlayers = {}
raid.squarePlayers = {}
raid.moonPlayers = {}
raid.trianglePlayers = {}
raid.diamondPlayers = {}
raid.circlePlayers = {}
raid.starPlayers = {}

local raid1 = {}
raid1.healers = {}
raid1.tanks = {}
raid1.members = {}
function addmember(name,class)
  local member = {}
  member.name = name
  member.class = class
  table.insert(raid1.members, member)
end

addmember("Kagedorf", "warrior")
addmember("Drakoh", "warrior")
addmember("Pio", "priest")
addmember("Chimble", "priest")
addmember("Xpace", "shaman")
addmember("Hungrysalami", "shaman")
addmember("Cow", "druid")
addmember("Maruki", "druid")
addmember("Murdera", "mage")
table.insert(raid1.members, member)


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

SupremeRaid = LibStub("AceAddon-3.0"):NewAddon("SupremeRaid", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
SupremeRaid.Version = GetAddOnMetadata(addonName, 'Version')
SupremeRaid.Author = GetAddOnMetadata(addonName, "Author")

SupremeRaid.AnnouncementChannels = {
	"say", "yell", "party", "raid", "raid_warning", "supremeheals"
}

SupremeRaid.DrinkAnnouncementChannels = {
	"say", "yell", "party", "raid"
}

SupremeRaid.ClassList = {
	"priest", "shaman", "druid", "warrior", "hunter", "mage", "warlock", "rogue"
}

SupremeRaid.RaidIconList = {
	"Sk"
}

SupremeRaid.YourAssignedTank = nil
SupremeRaid.YourAssignedTankIndex = nil
SupremeRaid.SelectedClassesToFilter = {}
local drinkingStatus = false

local Default_Profile = {
	profile = {
		DebugEnabled = false,
		DrinkAnnouce = {
			Enabled = false,
			ChannelIndex = 1,
			ManaThreshold = 50,
			MessageTemplate = "$pn - Drinking $mp% - $tn",
		},
		HealAssigment = {
			ChannelIndex = 6,
		},
		TargetAssigment = {
			ChannelIndex = 4,
		},
	}
}

SupremeRaid:RegisterChatCommand("super", "MySlashProcessorFunc")

function SupremeRaid:MySlashProcessorFunc(input)
	table.insert(raid.warriors, input)
	table.insert(raid.priests, input .. "a")
  -- Process the slash command ('input' contains whatever follows the slash command)
end

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

	SupremeRaid:CreateFrame()

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
						if SupremeRaid.YourAssignedTank == nil then
							SupremeRaid.YourAssignedTank = ""
						end
						message = string.gsub(message, "$tn", SupremeRaid.YourAssignedTank)
						SupremeRaid:PrintDebug(message)
						SupremeRaid:SendMessageToChat(message, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetDrinkAnnounceChannelIndex()))
						drinkingStatus  = true;
					end
				end
				break
			end
				-- Finished drinking but hasn't announced that yet
			if(i == 40 and drinkingStatus  == true) then
				message = "Finished Drinking"
				SupremeRaid:SendMessageToChat(message, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetDrinkAnnounceChannelIndex()))
				SupremeRaid:PrintDebug(message)
				drinkingStatus  = false
			end
		end
	end
end

function SupremeRaid:GetChannelNameFromIndex(index)
	return SupremeRaid.AnnouncementChannels[index]
end

function SupremeRaid:GetRaidMembers()
	local num = GetNumGroupMembers()
	 for raidIndex = 1, num do
 			local member = {}
	    local name, rank, subgroup, level, class, fileName,
  zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex);
			member.name = name
			member.class = class
			member.role = role
			member.rank = rank
		if name == playerName then
			playerRaidRole = role;
		end
		table.insert(raid.members, member)
		if (class == "Warrior") then
			table.insert(raid.warriors, name)
		elseif (class == "Priest") then
			table.insert(raid.priests, name)
		elseif (class == "Shaman") then
			table.insert(raid.shamans, name)
		elseif (class == "Druid") then
			table.insert(raid.druids, name)
		elseif (class == "Rogue") then
			table.insert(raid.rogues, name)
		elseif (class == "Warlock") then
			table.insert(raid.warlocks, name)
		elseif (class == "Mage") then
			table.insert(raid.mages, name)
		elseif (class == "Hunter") then
			table.insert(raid.hunters, name)
		end
	end
end

function SupremeRaid:GetClassMembersFromRaid(class)
	local memberTable = {}
	for i=1,#raid1.members do
		if(raid1.members[i].class == class) then
			table.insert(memberTable, raid1.members[i])
		end
	end
	return memberTable
end

function SupremeRaid:GetCombatRoleMembersFromRaid(combatRole)
	local combatRoleTable = {}
	if(combatRole == "healer") then
		for i=1,#raid1.members do
			if(raid1.members[i].class == "priest" or raid1.members[i].class == "shaman" or raid1.members[i].class == "druid") then
				table.insert(combatRoleTable, raid1.members[i])
			end
		end
	end
	if(combatRole == "tank") then
		for i=1,#raid1.members do
			if(raid1.members[i].class == "warrior" or raid1.members[i].class == "druid") then
				table.insert(combatRoleTable, raid1.members[i])
			end
		end
	end
	return combatRoleTable
end

function DropDownList(mainList)
  local simpleList = {}
  for i=1,#mainList do
    table.insert(simpleList, mainList[i].name)
  end
  return simpleList
end

function resetRaidInformation()
	raid.warriors = {}
	raid.priests = {}
	raid.shamans = {}
	raid.druids = {}
	raid.mages = {}
	raid.rogues = {}
	raid.hunters = {}
	raid.warlocks = {}
	raid.healers = {}
	raid.tanks = {}
	raid.tank1 = nil
	raid.tank1healers = {}
	raid.tank2 = nil
	raid.tank2healers = {}
	raid.tank3 = nil
	raid.tank3healers = {}
	raid.tank4 = nil
	raid.tank4healers = {}
	raid.tank5 = nil
	raid.tank5healers = {}
	raid.filteredClassList = {}
	raid.skullPlayers = {}
	raid.crossPlayers = {}
	raid.squarePlayers = {}
	raid.moonPlayers = {}
	raid.trianglePlayers = {}
	raid.diamondPlayers = {}
	raid.circlePlayers = {}
	raid.starPlayers = {}
end

function tankHealerCallbackHandler(key, checked, healergroup)
	if(checked) then
		table.insert(healergroup, raid.healers[key])
	else
		for i=1,#healergroup do
			if raid.healers[key] == healergroup[i] then
				table.remove(healergroup, i)
				break
			end
		end
	end
end

function targetPlayerSelectorCallBackHandler(key, checked, selectedGroup)
	if(checked) then
		table.insert(selectedGroup, raid.filteredClassList[key])
	else
		for i=1,#selectedGroup do
			if raid.filteredClassList[key] == selectedGroup[i] then
				table.remove(selectedGroup, i)
				break
			end
		end
	end
end



function skullSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.skullPlayers)
	SupremeRaid:PrintDebug(table.concat(raid.skullPlayers,", "))
end

function crossSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.crossPlayers)
	SupremeRaid:PrintDebug(table.concat(raid.crossPlayers,", "))
end

function squareSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.squarePlayers)
	SupremeRaid:PrintDebug(table.concat(raid.squarePlayers,", "))
end

function moonSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.moonPlayers)
	SupremeRaid:PrintDebug(table.concat(raid.moonPlayers,", "))
end

function triangleSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.trianglePlayers)
	SupremeRaid:PrintDebug(table.concat(raid.trianglePlayers,", "))
end

function diamondSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.diamondPlayers)
	SupremeRaid:PrintDebug(table.concat(raid.diamondPlayers,", "))
end

function circleSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.circlePlayers)
	SupremeRaid:PrintDebug(table.concat(raid.circlePlayers,", "))
end

function starSelectorCallback(self, event, key, checked)
	targetPlayerSelectorCallBackHandler(key,checked, raid.starPlayers)
	SupremeRaid:PrintDebug(table.concat(raid.starPlayers,", "))
end

function tank1HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank1healers)
	SupremeRaid:PrintDebug(table.concat(raid.tank1healers,", "))


end

function tank2HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank2healers)
	SupremeRaid:PrintDebug(table.concat(raid.tank2healers,", "))
end

function tank3HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank3healers)
	SupremeRaid:PrintDebug(table.concat(raid.tank3healers,", "))
end

function tank4HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank4healers)
	SupremeRaid:PrintDebug(table.concat(raid.tank4healers,", "))
end

function tank5HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank5healers)
	SupremeRaid:PrintDebug(table.concat(raid.tank5healers,", "))
end

function tank1Callback(self, event, key, checked)
	raid.tank1 = raid.tanks[key]
	SupremeRaid:PrintDebug(raid.tank1)
end

function tank2Callback(self, event, key, checked)
	raid.tank2 = raid.tanks[key]
	SupremeRaid:PrintDebug(raid.tank2)
end

function tank3Callback(self, event, key, checked)
	raid.tank3 = raid.tanks[key]
	SupremeRaid:PrintDebug(raid.tank3)
end

function tank4Callback(self, event, key, checked)
	raid.tank4 = raid.tanks[key]
	SupremeRaid:PrintDebug(raid.tank4)
end

function tank5Callback(self, event, key)
	raid.tank5 = raid.tanks[key]
	SupremeRaid:PrintDebug(raid.tank5)
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
	SupremeRaid.YourAssignedTank = raid.tanks[key]
	SupremeRaid.YourAssignedTankIndex = key
	SupremeRaid:PrintDebug(SupremeRaid.YourAssignedTank)
end

function announceMessageEditBoxCallBack(self, event, text)
	SupremeRaid:SetDrinkAnnounceMessageTemplate(text)
	SupremeRaid:PrintDebug(SupremeRaid:GetDrinkAnnounceMessageTemplate())
end

function announceHealAssigment()
	local tank1Message, tank2Message, tank3Message, tank4Message, tank5Message
	if raid.tank1 == nil then
		SupremeRaid:Print("Assign Tank 1")
	elseif raid.tank1healers == nil or #raid.tank1healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 1")
	else
		tank1Message = raid.tank1 .. " -- " .. table.concat(raid.tank1healers,", ")
	end
	if tank1Message ~= nil then
		SupremeRaid:PrintDebug(tank1Message)
		SupremeRaid:SendMessageToChat(tank1Message, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if raid.tank2 == nil then
		SupremeRaid:Print("Assign Tank 2")
	elseif raid.tank2healers == nil or #raid.tank2healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 2")
	else
		tank2Message = raid.tank2 .. " -- " .. table.concat(raid.tank2healers,", ")
	end
	if tank2Message ~= nil then
		SupremeRaid:PrintDebug(tank2Message)
		SupremeRaid:SendMessageToChat(tank2Message, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if raid.tank3 == nil then
		SupremeRaid:Print("Assign Tank 3")
	elseif raid.tank3healers == nil or #raid.tank3healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 3")
	else
		tank3Message = raid.tank3 .. " -- " .. table.concat(raid.tank3healers,", ")
	end
	if tank3Message ~= nil then
		SupremeRaid:PrintDebug(tank3Message)
		SupremeRaid:SendMessageToChat(tank3Message, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if raid.tank4 == nil then
		SupremeRaid:Print("Assign Tank 4")
	elseif raid.tank4healers == nil or #raid.tank4healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 4")
	else
		tank4Message = raid.tank4 .. " -- " .. table.concat(raid.tank4healers,", ")
	end
	if tank4Message ~= nil then
		SupremeRaid:PrintDebug(tank4Message)
		SupremeRaid:SendMessageToChat(tank4Message, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
	if raid.tank5 == nil then
		SupremeRaid:Print("Assign Tank 5")
	elseif raid.tank5healers == nil or #raid.tank5healers == 0 then
		SupremeRaid:Print("Assign Healers for Tank 5")
	else
		tank5Message = raid.tank5 .. " -- " .. table.concat(raid.tank5healers,", ")
	end
	if tank5Message ~= nil then
		SupremeRaid:PrintDebug(tank5Message)
		SupremeRaid:SendMessageToChat(tank5Message, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetHealAssigmentAnnounceChannelIndex()))
	end
end

function announceTargetAssigment()
	local skullMessage, crossMessage, squareMessage, moonMessage, triangleMessage, diamondMessage, circleMessage, starMessage
	if raid.skullPlayers == nil or #raid.skullPlayers == 0 then
		SupremeRaid:Print("Assign Players to SKULL")
	else
		skullMessage = "{rt8}" .. " -- " .. table.concat(raid.skullPlayers,", ")
	end
	if skullMessage ~= nil then
		SupremeRaid:PrintDebug(skullMessage)
		SupremeRaid:SendMessageToChat(skullMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if raid.crossPlayers == nil  or #raid.crossPlayers == 0 then
		SupremeRaid:Print("Assign Players to CROSS")
	else
		crossMessage = "{rt7}" .. " -- " .. table.concat(raid.crossPlayers,", ")
	end
	if crossMessage ~= nil then
		SupremeRaid:PrintDebug(crossMessage)
		SupremeRaid:SendMessageToChat(crossMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if raid.squarePlayers == nil or #raid.squarePlayers == 0 then
		SupremeRaid:Print("Assign Players to SQUARE")
	else
		squareMessage = "{rt6}" .. " -- " .. table.concat(raid.squarePlayers,", ")
	end
	if squareMessage ~= nil then
		SupremeRaid:PrintDebug(squareMessage)
		SupremeRaid:SendMessageToChat(squareMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if raid.moonPlayers == nil or #raid.moonPlayers == 0 then
		SupremeRaid:Print("Assign Players to MOON")
	else
		moonMessage = "{rt5}" .. " -- " .. table.concat(raid.moonPlayers,", ")
	end
	if moonMessage ~= nil then
		SupremeRaid:PrintDebug(moonMessage)
		SupremeRaid:SendMessageToChat(moonMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if raid.trianglePlayers == nil or #raid.trianglePlayers == 0 then
		SupremeRaid:Print("Assign Players to TRIANGLE")
	else
		triangleMessage = "{rt4}" .. " -- " .. table.concat(raid.trianglePlayers,", ")
	end
	if triangleMessage ~= nil then
		SupremeRaid:PrintDebug(triangleMessage)
		SupremeRaid:SendMessageToChat(triangleMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if raid.diamondPlayers == nil or #raid.diamondPlayers == 0 then
		SupremeRaid:Print("Assign Players to DIAMOND")
	else
		diamondMessage = "{rt3}" .. " -- " .. table.concat(raid.diamondPlayers,", ")
	end
	if diamondMessage ~= nil then
		SupremeRaid:PrintDebug(diamondMessage)
		SupremeRaid:SendMessageToChat(diamondMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if raid.circlePlayers == nil or #raid.circlePlayers == 0 then
		SupremeRaid:Print("Assign Players to CIRCLE")
	else
		circleMessage = "{rt2}" .. " -- " .. table.concat(raid.circlePlayers,", ")
	end
	if circleMessage ~= nil  then
		SupremeRaid:PrintDebug(circleMessage)
		SupremeRaid:SendMessageToChat(circleMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
	if raid.starPlayers == nil or #raid.starPlayers == 0 then
		SupremeRaid:Print("Assign Players to STAR")
	else
		starMessage = "{rt1}" .. " -- " .. table.concat(raid.starPlayers,", ")
	end
	if starMessage ~= nil then
		SupremeRaid:PrintDebug(starMessage)
		SupremeRaid:SendMessageToChat(starMessage, SupremeRaid:GetChannelNameFromIndex(SupremeRaid:GetTargetAssigmentAnnounceChannelIndex()))
	end
end

function getNecessaryClass (classKey)
	if classKey == "priest" then
		return raid.priests
	elseif classKey == "shaman" then
		return raid.shamans
	elseif classKey == "druid" then
		return raid.druids
	elseif classKey == "warrior" then
		return raid.warriors
	elseif classKey == "rogue" then
		return raid.rogues
	elseif classKey == "hunter" then
		return raid.hunters
	elseif classKey == "mage" then
		return raid.mages
	elseif classKey == "warlock" then
		return raid.warlocks
	end
end

function classFilterCallBack(self, event, key, checked)
	if checked then
		table.insert(SupremeRaid.SelectedClassesToFilter, SupremeRaid.ClassList[key])
		raid.filteredClassList = mergeTables(raid.filteredClassList, getNecessaryClass(SupremeRaid.ClassList[key]))
	elseif  SupremeRaid.SelectedClassesToFilter ~= nil then
		for i=1,#SupremeRaid.SelectedClassesToFilter do
			if SupremeRaid.ClassList[key] == SupremeRaid.SelectedClassesToFilter[i] then
				table.remove(SupremeRaid.SelectedClassesToFilter, i)
				break
			end
		end
		raid.filteredClassList = {}
		for i=1,#SupremeRaid.SelectedClassesToFilter do
			raid.filteredClassList = mergeTables(raid.filteredClassList, getNecessaryClass(SupremeRaid.SelectedClassesToFilter[i]))
		end
	end
	SupremeRaid:PrintDebug(table.concat(SupremeRaid.SelectedClassesToFilter,", "))
	SupremeRaid:PrintDebug(table.concat(raid.filteredClassList,", "))
	skullListSelector:SetList(raid.filteredClassList)
	crossListSelector:SetList(raid.filteredClassList)
	squareListSelector:SetList(raid.filteredClassList)
	moonListSelector:SetList(raid.filteredClassList)
	triangleListSelector:SetList(raid.filteredClassList)
	diamondListSelector:SetList(raid.filteredClassList)
	circleListSelector:SetList(raid.filteredClassList)
	starListSelector:SetList(raid.filteredClassList)
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
	tankSelector:SetList(raid.tanks)
	tankSelector:SetValue(SupremeRaid.YourAssignedTankIndex)
	tankSelector:SetCallback("OnValueChanged", assignedTankCallback)
	container:AddChild(tankSelector)

	local announceMessageEditBox = AceGUI:Create("EditBox")
	announceMessageEditBox:SetFullWidth(true)
	announceMessageEditBox:SetLabel("Your announce message template: ")
	announceMessageEditBox:SetMaxLetters(50)
	announceMessageEditBox:SetCallback("OnEnterPressed", announceMessageEditBoxCallBack)
	announceMessageEditBox:SetText(SupremeRaid:GetDrinkAnnounceMessageTemplate())
	container:AddChild(announceMessageEditBox)

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
	raid1.healers = SupremeRaid:GetCombatRoleMembersFromRaid("healer")
	raid1.tanks = SupremeRaid:GetCombatRoleMembersFromRaid("tank")

	local tankSelector1 = AceGUI:Create("Dropdown")
	tankSelector1:SetLabel("Tank #1")
	tankSelector1:SetRelativeWidth(0.5)
	tankSelector1:SetText("Select A Tank")
	tankSelector1:SetList(DropDownList(raid1.tanks))
	tankSelector1:SetCallback("OnValueChanged", tank1Callback)
	container:AddChild(tankSelector1)

  local healerSelector1 = AceGUI:Create("Dropdown")
	healerSelector1:SetLabel("Healer #1")
	healerSelector1:SetRelativeWidth(0.5)
	healerSelector1:SetText("Select Healer")
	healerSelector1:SetList(DropDownList(raid1.healers))
	healerSelector1:SetMultiselect(true)
	healerSelector1:SetCallback("OnValueChanged", tank1HealerCallback)
	container:AddChild(healerSelector1)

	local tankSelector2 = AceGUI:Create("Dropdown")
	tankSelector2:SetLabel("Tank #2")
	tankSelector2:SetRelativeWidth(0.5)
	tankSelector2:SetText("Select A Tank")
	tankSelector2:SetList(DropDownList(raid1.tanks))
	tankSelector2:SetCallback("OnValueChanged", tank2Callback)
	container:AddChild(tankSelector2)

	local healerSelector2 = AceGUI:Create("Dropdown")
	healerSelector2:SetLabel("Healer #2")
	healerSelector2:SetRelativeWidth(0.5)
	healerSelector2:SetText("Select Healer")
	healerSelector2:SetMultiselect(true)
	healerSelector2:SetList(DropDownList(raid1.healers))
	healerSelector2:SetCallback("OnValueChanged", tank2HealerCallback)
	container:AddChild(healerSelector2)
	healerSelector2:SetItemValue(2,true)
	healerSelector2:SetItemValue(3,true)

	local tankSelector3 = AceGUI:Create("Dropdown")
	tankSelector3:SetLabel("Tank #3")
	tankSelector3:SetRelativeWidth(0.5)
	tankSelector3:SetText("Select A Tank")
	tankSelector3:SetList(DropDownList(raid1.tanks))
	tankSelector3:SetCallback("OnValueChanged", tank3Callback)
	container:AddChild(tankSelector3)

	local healerSelector3 = AceGUI:Create("Dropdown")
	healerSelector3:SetLabel("Healer #3")
	healerSelector3:SetRelativeWidth(0.5)
	healerSelector3:SetText("Select Healer")
	healerSelector3:SetMultiselect(true)
	healerSelector3:SetList(DropDownList(raid1.healers))
	healerSelector3:SetCallback("OnValueChanged", tank3HealerCallback)
	container:AddChild(healerSelector3)

	local tankSelector4 = AceGUI:Create("Dropdown")
	tankSelector4:SetLabel("Tank #4")
	tankSelector4:SetRelativeWidth(0.5)
	tankSelector4:SetText("Select A Tank")
	tankSelector4:SetList(DropDownList(raid1.tanks))
	tankSelector4:SetCallback("OnValueChanged", tank4Callback)
	container:AddChild(tankSelector4)

	local healerSelector4 = AceGUI:Create("Dropdown")
	healerSelector4:SetLabel("Healer #4")
	healerSelector4:SetRelativeWidth(0.5)
	healerSelector4:SetText("Select Healer")
	healerSelector4:SetMultiselect(true)
	healerSelector4:SetList(DropDownList(raid1.healers))
	healerSelector4:SetCallback("OnValueChanged", tank4HealerCallback)
	container:AddChild(healerSelector4)

	local tankSelector5 = AceGUI:Create("Dropdown")
	tankSelector5:SetLabel("Tank #5")
	tankSelector5:SetRelativeWidth(0.5)
	tankSelector5:SetText("Select A Tank")
	tankSelector5:SetList(DropDownList(raid1.tanks))
	tankSelector5:SetCallback("OnValueChanged", tank5Callback)
	container:AddChild(tankSelector5)
  

	local healerSelector5 = AceGUI:Create("Dropdown")
	healerSelector5:SetLabel("Healer #5")
	healerSelector5:SetRelativeWidth(0.5)
	healerSelector5:SetText("Select Healer")
	healerSelector5:SetMultiselect(true)
	healerSelector5:SetList(DropDownList(raid1.healers))
	healerSelector5:SetCallback("OnValueChanged", tank5HealerCallback)
	container:AddChild(healerSelector5)

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

	local skullText = AceGUI:Create("Label")
	skullText:SetText("|cffffffffSKULL|r")
	skullText:SetRelativeWidth(0.2)
	container:AddChild(skullText)

	skullListSelector = AceGUI:Create("Dropdown")
	skullListSelector:SetLabel("Select Classes to Filter")
	skullListSelector:SetRelativeWidth(0.79)
	skullListSelector:SetText("Select Classes")
	skullListSelector:SetList(raid.filteredClassList)
	skullListSelector:SetMultiselect(true)
	skullListSelector:SetCallback("OnValueChanged", skullSelectorCallback)
	container:AddChild(skullListSelector)

	local crossText = AceGUI:Create("Label")
	crossText:SetText("|cffFF0000CROSS|r")
	crossText:SetRelativeWidth(0.2)
	container:AddChild(crossText)

	crossListSelector = AceGUI:Create("Dropdown")
	crossListSelector:SetLabel("Select Classes to Filter")
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
	squareListSelector:SetLabel("Select Classes to Filter")
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
	moonListSelector:SetLabel("Select Classes to Filter")
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
	triangleListSelector:SetLabel("Select Classes to Filter")
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
	diamondListSelector:SetLabel("Select Classes to Filter")
	diamondListSelector:SetRelativeWidth(0.79)
	diamondListSelector:SetText("Select Classes")
	diamondListSelector:SetMultiselect(true)
	crossListSelector:SetCallback("OnValueChanged", crossSelectorCallback)
	container:AddChild(diamondListSelector)

	local circleText = AceGUI:Create("Label")
	circleText:SetText("|cffff8000CIRCLE|r")
	circleText:SetRelativeWidth(0.2)
	container:AddChild(circleText)

	circleListSelector = AceGUI:Create("Dropdown")
	circleListSelector:SetLabel("Select Classes to Filter")
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
	starListSelector:SetLabel("Select Classes to Filter")
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
	-- resetRaidInformation()
	SupremeRaid:GetRaidMembers()
	raid.tanks = mergeTables(raid.warriors, raid.druids)
	raid.healers = mergeTables(raid.priests, raid.druids, raid.shamans)

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

function mergeTables(table1, table2, table3)

	local table = {unpack(table1)}
	if table2 ~= nill then
		for i = 1, #table2 do
			table[#table1+i] = table2[i]
		end
	end
	local nextTable = {unpack(table)}
	if table3 ~= nil then
		for i = 1, #table3 do
			nextTable[#table+i] = table3[i]
		end
	end
	return nextTable
end

function SupremeRaid:SendMessageToChat(message, channelName)
	if channelName == "say" or channelName == "yell" or channelName == "raid" or channelName "party" or channelName == "raid_warning" then
		SendChatMessage(message, channelName)
	else
		local channelID = GetChannelName(channelName);
		if channelID > 0 then
			SendChatMessage(message, "CHANNEL", nil, channelID)
		end
	end
end

function SupremeRaid:PrintDebug(...)
	if SupremeRaid.IsDebugPrintEnabled() then
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

SupremeRaid:RegisterEvent("UNIT_AURA", "OnUnitAuraEvent")
