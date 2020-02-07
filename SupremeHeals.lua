local frame = CreateFrame("FRAME", "SupremeHeals");
frame:RegisterEvent("UNIT_AURA");
--frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
local drinking = false

local function AuraEvent(self, event)

getRaidMembers()
	for i=1,40 do
		local name = UnitBuff("player",i)
		if (name == "Drink") then
			local maxMana = UnitPowerMax("player")
			local currentMana = UnitPower("player")
			local percentMana = currentMana / maxMana * 100
			local message = string.format("Drinking %d", percentMana)
			print(message)
			SendChatMessage("Drinking")
			drinking = true;
			break
		end
		if(i == 40 and name ~= "Drink") then
			if(drinking == true) then
				print("done drinking")
				drinking = false
			end
		end
	end
end

function getRaidMembers()
local warriors, priests, shamans, druids = {}, {}, {}, {}
	print("getting raid")
	for raidIndex = 1, 5 do
	    local name, rank, subgroup, level, class, fileName,
  zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex);
			if (class == "Warrior") then
				print(name)
				table.insert(warriors, name)
			elseif (class == "Priest") then
				print(name)
				table.insert(priests, name)
			elseif (class == "Shaman") then
				table.insert(shamans, name)
			elseif (class == "Druid") then
				table.insert(druids, name)
			end
	end
	 print(table.concat(warriors,", "))
end

frame:SetScript("OnEvent", AuraEvent)
