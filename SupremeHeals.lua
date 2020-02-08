local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local HBD = LibStub("HereBeDragons-2.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local AceLocale = LibStub("AceLocale-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local addonName = ...
local _

local playerGUID = UnitGUID("player")
local playerClass, englishClass = UnitClass("player")

SupremeHeals = LibStub("AceAddon-3.0"):NewAddon("SupremeHeals", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
SupremeHeals.Version = GetAddOnMetadata(addonName, 'Version')
SupremeHeals.Author = GetAddOnMetadata(addonName, "Author") 

local raid = {}
raid.warriors = {"Kage", "Drakoh"}
raid.priests = {"Pio", "Chimble", "Macewindu"}
raid.shamans = {"Taz", "Salami", "Goshute"}
raid.druids = {"Cow", "Maruki"}
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

SupremeHeals.AnnouncementChannels = {
	"say", "yell", "party", "raid", "raid_warning", "supremeheals"
}SupremeHeals.ManaAnnouncementChannels = {
	"say", "yell", "party", "raid"
}

SupremeHeals.DebugPrintEnabled = true
SupremeHeals.ManaAnnounceThreshold = 50
SupremeHeals.selectedHealAnnounceChannel = "raid"
SupremeHeals.selectedManaAnnounceChannel = "supremeheals"
SupremeHeals.DrinkingStatus = false
SupremeHeals.DrinkingAnnounceStatus = true
SupremeHeals.YourAssignedTank = nil
SupremeHeals.ManaAnnounceMessage = "$pn - Drinking $mp - Tank $tn"

function SupremeHeals:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
	self.db = LibStub("AceDB-3.0"):New("SupremeHealsDB")
	local acedb = LibStub:GetLibrary("AceDB-3.0")
end

function SupremeHeals:SlashCommandHandler(input)
  -- Process the slash command ('input' contains whatever follows the slash command)
	SupremeHeals:CreateFrame();
end

SupremeHeals:RegisterChatCommand("sup", "SlashCommandHandler")

function SupremeHeals:OnUnitAuraEvent(eventName, unitTarget)
	local message
	if SupremeHeals.DrinkingAnnounceStatus then
		for i=1,40 do
			local name = UnitBuff("player",i)
			if (name == "Drink") then
				local maxMana = UnitPowerMax("player")
				local currentMana = UnitPower("player")
				local percentMana = currentMana / maxMana * 100
				message = string.format("Drinking %d", percentMana)
				SupremeHeals:PrintDebug(message)
				SendChatMessage(message)
				SupremeHeals.DrinkingStatus  = true;
				break
			end
			if(i == 40 and name ~= "Drink") then
				if(SupremeHeals.DrinkingStatus  == true) then
					message = "Finished Drinking"
					SupremeHeals:PrintDebug(message)
					SupremeHeals.DrinkingStatus  = false
					SendChatMessage(message)
				end
			end
		end
	end
end

function SupremeHeals:GetRaidMembers()

	 for raidIndex = 1, 40 do
	    local name, rank, subgroup, level, class, fileName,
  zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex);
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

function tank1HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank1healers)	
	SupremeHeals:PrintDebug(table.concat(raid.tank1healers,", "))
end

function tank2HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank2healers)	
	SupremeHeals:PrintDebug(table.concat(raid.tank2healers,", "))
end

function tank3HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank3healers)	
	SupremeHeals:PrintDebug(table.concat(raid.tank3healers,", "))
end

function tank4HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank4healers)	
	SupremeHeals:PrintDebug(table.concat(raid.tank4healers,", "))
end

function tank5HealerCallback(self, event, key, checked)
	tankHealerCallbackHandler(key,checked, raid.tank5healers)	
	SupremeHeals:PrintDebug(table.concat(raid.tank5healers,", "))
end

function tank1Callback(self, event, key, checked)	
	raid.tank1 = raid.tanks[key]
	SupremeHeals:PrintDebug(raid.tank1)
end

function tank2Callback(self, event, key, checked)	
	raid.tank2 = raid.tanks[key]
	SupremeHeals:PrintDebug(raid.tank2)
end

function tank3Callback(self, event, key, checked)	
	raid.tank3 = raid.tanks[key]
	SupremeHeals:PrintDebug(raid.tank3)
end

function tank4Callback(self, event, key, checked)	
	raid.tank4 = raid.tanks[key]
	SupremeHeals:PrintDebug(raid.tank4)
end

function tank5Callback(self, event, key)	
	raid.tank5 = raid.tanks[key]
	SupremeHeals:PrintDebug(raid.tank5)
end

function healAssigmentAnnounceChannelSelectionCallBack(self, event, key)
	SupremeHeals.selectedHealAnnounceChannel = SupremeHeals.AnnouncementChannels[key]
	SupremeHeals:PrintDebug(SupremeHeals.selectedHealAnnounceChannel)
end

function manaAnnounceChannelSelectionCallBack(self, event, key)
	SupremeHeals.selectedManaAnnounceChannel = SupremeHeals.ManaAnnouncementChannels[key]
	SupremeHeals:PrintDebug(SupremeHeals.selectedManaAnnounceChannel)
end

function manaAnnounceEditBoxCallBack(self, event, text)
	
	local num = tonumber(text)
	if num == nil then
		SupremeHeals:Print("Only numbers")
	elseif num > 100 then
		SupremeHeals:Print("Maximum 100")
	elseif num < 0 then	
		SupremeHeals:Print("Minimum 0")
	else 
		SupremeHeals.ManaAnnounceThreshold = num
		SupremeHeals:PrintDebug(SupremeHeals.ManaAnnounceThreshold)
	end
end

function DrinkingAnnounceCheckBoxCallBack(self, event, value)	
	SupremeHeals.DrinkingAnnounceStatus = value
	SupremeHeals:PrintDebug(SupremeHeals.DrinkingAnnounceStatus)
end

function assignedTankCallback(self, event, key)	
	SupremeHeals.YourAssignedTank = raid.tanks[key]
	SupremeHeals:PrintDebug(SupremeHeals.YourAssignedTank)
end

function announceHealAssigment() 
	local tank1Message, tank2Message, tank3Message, tank4Message, tank5Message
	if raid.tank1 == nil then
		SupremeHeals:Print("Assign Tank 1")
	elseif raid.tank1healers == nil or #raid.tank1healers == 0 then
		SupremeHeals:Print("Assign Healers for Tank 1")
	else	
		tank1Message = table.concat(raid.tank1healers,", ") .. " --> " .. raid.tank1
	end
	SupremeHeals:PrintDebug(tank1Message)
	
	if raid.tank2 == nil then
		SupremeHeals:Print("Assign Tank 2")
	elseif raid.tank2healers == nil or #raid.tank2healers == 0 then
		SupremeHeals:Print("Assign Healers for Tank 2")
	else	
		tank2Message = table.concat(raid.tank2healers,", ") .. " --> " .. raid.tank2
	end
	SupremeHeals:PrintDebug(tank2Message)
	
	if raid.tank3 == nil then
		SupremeHeals:Print("Assign Tank 3")
	elseif raid.tank3healers == nil or #raid.tank3healers == 0 then
		SupremeHeals:Print("Assign Healers for Tank 3")
	else	
		tank3Message = table.concat(raid.tank3healers,", ") .. " --> " .. raid.tank3
	end
	SupremeHeals:PrintDebug(tank3Message)
	
	if raid.tank4 == nil then
		SupremeHeals:Print("Assign Tank 4")
	elseif raid.tank4healers == nil or #raid.tank4healers == 0 then
		SupremeHeals:Print("Assign Healers for Tank 4")
	else	
		tank4Message = table.concat(raid.tank4healers,", ") .. " -> " .. raid.tank4
	end
	SupremeHeals:PrintDebug(tank4Message)
	
	if raid.tank5 == nil then
		SupremeHeals:Print("Assign Tank 5")
	elseif raid.tank5healers == nil or #raid.tank5healers == 0 then
		SupremeHeals:Print("Assign Healers for Tank 5")
	else	
		tank5Message = table.concat(raid.tank5healers,", ") .. " -> " .. raid.tank5
	end
	SupremeHeals:PrintDebug(tank5Message)	
end

-- function that draws the widgets for the second tab
local function DrawGroup1(container)

	local desc = AceGUI:Create("Label")
	desc:SetText("You will announce your drinking status to the selected channels")
	desc:SetFullWidth(true)
	container:AddChild(desc)
	
	local disableCheckBox = AceGUI:Create("CheckBox")
	disableCheckBox:SetLabel("Enabled")
	disableCheckBox:SetValue(SupremeHeals.DrinkingAnnounceStatus)
	disableCheckBox:SetCallback("OnValueChanged", DrinkingAnnounceCheckBoxCallBack)
	container:AddChild(disableCheckBox)
	  
	local announceChannelSelector = AceGUI:Create("Dropdown")
	announceChannelSelector:SetLabel("Announce your drinking status to:")
	announceChannelSelector:SetFullWidth(true)
	announceChannelSelector:SetText("Select Channel")
	announceChannelSelector:SetList(SupremeHeals.ManaAnnouncementChannels)
	announceChannelSelector:SetValue(1)
	announceChannelSelector:SetCallback("OnValueChanged", manaAnnounceChannelSelectionCallBack)
	container:AddChild(announceChannelSelector)
	
	local manaThresholdEditBox = AceGUI:Create("EditBox")
	manaThresholdEditBox:SetFullWidth(true)
	manaThresholdEditBox:SetLabel("You will only announce if your mana is above below %")
	manaThresholdEditBox:SetMaxLetters(3)
	manaThresholdEditBox:SetCallback("OnEnterPressed", manaAnnounceEditBoxCallBack)
	manaThresholdEditBox:SetText(tostring(SupremeHeals.ManaAnnounceThreshold))
	container:AddChild(manaThresholdEditBox)
	
	local tankSelector = AceGUI:Create("Dropdown")
	tankSelector:SetLabel("You will mention your tank in the message")
	tankSelector:SetRelativeWidth(1)
	tankSelector:SetText("Select Your Assigned Tank")	
	tankSelector:SetList(raid.tanks)
	tankSelector:SetCallback("OnValueChanged", assignedTankCallback)
	container:AddChild(tankSelector)
	
	local announceMessageEditBox = AceGUI:Create("EditBox")
	manaThresholdEditBox:SetFullWidth(true)
	manaThresholdEditBox:SetLabel("Your announce message template: ")
	manaThresholdEditBox:SetMaxLetters(50)
	manaThresholdEditBox:SetCallback("OnEnterPressed", announceMessageEditBoxCallBack)
	manaThresholdEditBox:SetText(tostring(SupremeHeals.ManaAnnounceThreshold))
	container:AddChild(manaThresholdEditBox)
end

-- function that draws the widgets for the first tab
local function DrawGroup2(container)
	local healerSelector1 = AceGUI:Create("Dropdown")
	healerSelector1:SetLabel("Healer #1")
	healerSelector1:SetRelativeWidth(0.5)
	healerSelector1:SetText("Select Healer")
	healerSelector1:SetList(raid.healers)
	healerSelector1:SetMultiselect(true)
	healerSelector1:SetCallback("OnValueChanged", tank1HealerCallback)
	container:AddChild(healerSelector1)

	local tankSelector1 = AceGUI:Create("Dropdown")
	tankSelector1:SetLabel("Tank #1")
	tankSelector1:SetRelativeWidth(0.5)
	tankSelector1:SetText("Select A Tank")
	tankSelector1:SetList(raid.tanks)
	tankSelector1:SetCallback("OnValueChanged", tank1Callback)
	container:AddChild(tankSelector1)

	local healerSelector2 = AceGUI:Create("Dropdown")
	healerSelector2:SetLabel("Healer #2")
	healerSelector2:SetRelativeWidth(0.5)
	healerSelector2:SetText("Select Healer")
	healerSelector2:SetMultiselect(true)
	healerSelector2:SetList(raid.healers)
	healerSelector2:SetCallback("OnValueChanged", tank2HealerCallback)
	container:AddChild(healerSelector2)

	local tankSelector2 = AceGUI:Create("Dropdown")
	tankSelector2:SetLabel("Tank #2")
	tankSelector2:SetRelativeWidth(0.5)
	tankSelector2:SetText("Select A Tank")
	tankSelector2:SetList(raid.tanks)
	tankSelector2:SetCallback("OnValueChanged", tank2Callback)
	container:AddChild(tankSelector2)

	local healerSelector3 = AceGUI:Create("Dropdown")
	healerSelector3:SetLabel("Healer #3")
	healerSelector3:SetRelativeWidth(0.5)
	healerSelector3:SetText("Select Healer")
	healerSelector3:SetMultiselect(true)
	healerSelector3:SetList(raid.healers)
	healerSelector3:SetCallback("OnValueChanged", tank3HealerCallback)
	container:AddChild(healerSelector3)

	local tankSelector3 = AceGUI:Create("Dropdown")
	tankSelector3:SetLabel("Tank #3")
	tankSelector3:SetRelativeWidth(0.5)
	tankSelector3:SetText("Select A Tank")
	tankSelector3:SetList(raid.tanks)
	tankSelector3:SetCallback("OnValueChanged", tank3Callback)
	container:AddChild(tankSelector3)

	local healerSelector4 = AceGUI:Create("Dropdown")
	healerSelector4:SetLabel("Healer #4")
	healerSelector4:SetRelativeWidth(0.5)
	healerSelector4:SetText("Select Healer")
	healerSelector4:SetMultiselect(true)
	healerSelector4:SetList(raid.healers)
	healerSelector4:SetCallback("OnValueChanged", tank4HealerCallback)
	container:AddChild(healerSelector4)

	local tankSelector4 = AceGUI:Create("Dropdown")
	tankSelector4:SetLabel("Tank #4")
	tankSelector4:SetRelativeWidth(0.5)
	tankSelector4:SetText("Select A Tank")
	tankSelector4:SetList(raid.tanks)
	tankSelector4:SetCallback("OnValueChanged", tank4Callback)
	container:AddChild(tankSelector4)

	local healerSelector5 = AceGUI:Create("Dropdown")
	healerSelector5:SetLabel("Healer #5")
	healerSelector5:SetRelativeWidth(0.5)
	healerSelector5:SetText("Select Healer")
	healerSelector5:SetMultiselect(true)
	healerSelector5:SetList(raid.healers)
	healerSelector5:SetCallback("OnValueChanged", tank5HealerCallback)
	container:AddChild(healerSelector5)

	local tankSelector5 = AceGUI:Create("Dropdown")
	tankSelector5:SetLabel("Tank #5")
	tankSelector5:SetRelativeWidth(0.5)
	tankSelector5:SetText("Select A Tank")
	tankSelector5:SetList(raid.tanks)
	tankSelector5:SetCallback("OnValueChanged", tank5Callback)
	container:AddChild(tankSelector5)
	
	local announceChannelSelector = AceGUI:Create("Dropdown")
	announceChannelSelector:SetLabel("Announce Heal Assignment to:")
	announceChannelSelector:SetRelativeWidth(0.5)
	announceChannelSelector:SetText("Select Channel")
	announceChannelSelector:SetList(SupremeHeals.AnnouncementChannels)
	announceChannelSelector:SetValue(4)
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
  local desc = AceGUI:Create("Label")
  desc:SetText("This is Tab 2")
  desc:SetFullWidth(true)
  container:AddChild(desc)
  
  local button = AceGUI:Create("Button")
  button:SetText("Tab 2 Button")
  button:SetWidth(200)
  container:AddChild(button)
end

-- Callback function for OnGroupSelected
local function SelectGroup(container, event, group)
   container:ReleaseChildren()
   if group == "tab1" then
      DrawGroup1(container)
   elseif group == "tab2" then
      DrawGroup2(container)
   elseif group == "tab3" then
      DrawGroup3(container)
   end
end

function SupremeHeals:CreateFrame()
	SupremeHeals:GetRaidMembers()
	raid.tanks = mergeTables(raid.warriors, raid.druids)
	raid.healers = mergeTables(raid.priests, raid.druids, raid.shamans)

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Supreme Raid Helper")
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame:SetWidth(500)
	frame:SetHeight(500)
	frame:SetLayout("Fill")
	
	-- Create the TabGroup
	local tab =  AceGUI:Create("TabGroup")
	local tabs = {}
	tab:SetLayout("Flow")
	-- Register callback
	tab:SetCallback("OnGroupSelected", SelectGroup)
	if playerClass == "Priest" or playerClass == "Shaman" or playerClass == "Druid" then
		tabs = {{text="Settings", value="tab1"}, {text="Heal Assigment", value="tab2"}, {text="Target Assigment", value="tab3"}}
		tab:SetTabs(tabs)
		tab:SelectTab("tab1")
	else 
		tabs = {{text="Heal Assigment", value="tab2"}, {text="Target Assigment", value="tab3"}}
		tab:SetTabs(tabs)
		tab:SelectTab("tab2")
	end
	-- Set initial Tab (this will fire the OnGroupSelected callback)
	
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

function SupremeHeals:PrintDebug(...)
	if SupremeHeals.DebugPrintEnabled ~= true then
		return
	end
	SupremeHeals:Print(...)
end

SupremeHeals:RegisterEvent("UNIT_AURA", "OnUnitAuraEvent")
SupremeHeals:CreateFrame();