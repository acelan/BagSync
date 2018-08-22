--[[
	BagSync.lua
		A item tracking addon that works with practically any bag addon available.
		This addon has been heavily rewritten several times since it's creation back in 2007.
		
		This addon was inspired by Tuller and his Bagnon addon.  (Thanks Tuller!)

	Author: Xruptor

--]]

local BSYC = select(2, ...) --grab the addon namespace
BSYC = LibStub("AceAddon-3.0"):NewAddon(BSYC, "BagSync", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)
local Cache = LibStub('LibItemCache-2.0')

local debugf = tekDebug and tekDebug:GetFrame("BagSync")

function BSYC:Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

----------------------
--   DB Functions   --
----------------------

function BSYC:StartupDB()
	
	--get player information from Cache
	local player = Cache:GetOwnerInfo()

	--initiate global db variable
	BagSyncDB = BagSyncDB or {}
	BagSyncDB["options§"] = BagSyncDB["options§"] or {}
	BagSyncDB["blacklist§"] = BagSyncDB["blacklist§"] or {}
	
	--main DB call
	self.db = self.db or {}
	
	--realm DB
	BagSyncDB[player.realm] = BagSyncDB[player.realm] or {}
	self.db.realm = BagSyncDB[player.realm]
	
	--player DB
	self.db.realm[player.name] = self.db.realm[player.name] or {}
	self.db.player = self.db.realm[player.name]
	self.db.player.currency = self.db.player.currency or {}
	self.db.player.profession = self.db.player.profession or {}
	
	--blacklist DB
	self.db.blacklist = BagSyncDB["blacklist§"]
	
	--options DB
	self.db.options = BagSyncDB["options§"]
	if self.db.options.showTotal == nil then self.db.options.showTotal = true end
	if self.db.options.showGuildNames == nil then self.db.options.showGuildNames = false end
	if self.db.options.enableGuild == nil then self.db.options.enableGuild = true end
	if self.db.options.enableMailbox == nil then self.db.options.enableMailbox = true end
	if self.db.options.enableUnitClass == nil then self.db.options.enableUnitClass = false end
	if self.db.options.enableMinimap == nil then self.db.options.enableMinimap = true end
	if self.db.options.enableFaction == nil then self.db.options.enableFaction = true end
	if self.db.options.enableAuction == nil then self.db.options.enableAuction = true end
	if self.db.options.tooltipOnlySearch == nil then self.db.options.tooltipOnlySearch = false end
	if self.db.options.enableTooltips == nil then self.db.options.enableTooltips = true end
	if self.db.options.enableTooltipSeperator == nil then self.db.options.enableTooltipSeperator = true end
	if self.db.options.enableCrossRealmsItems == nil then self.db.options.enableCrossRealmsItems = true end
	if self.db.options.enableBNetAccountItems == nil then self.db.options.enableBNetAccountItems = false end
	if self.db.options.enableTooltipItemID == nil then self.db.options.enableTooltipItemID = false end
	if self.db.options.enableTooltipGreenCheck == nil then self.db.options.enableTooltipGreenCheck = true end
	if self.db.options.enableRealmIDTags == nil then self.db.options.enableRealmIDTags = true end
	if self.db.options.enableRealmAstrickName == nil then self.db.options.enableRealmAstrickName = false end
	if self.db.options.enableRealmShortName == nil then self.db.options.enableRealmShortName = false end
	if self.db.options.enableLoginVersionInfo == nil then self.db.options.enableLoginVersionInfo = true end
	if self.db.options.enableFactionIcons == nil then self.db.options.enableFactionIcons = true end
	if self.db.options.enableShowUniqueItemsTotals == nil then self.db.options.enableShowUniqueItemsTotals = true end

	--setup the default colors
	if self.db.options.colors == nil then self.db.options.colors = {} end
	if self.db.options.colors.first == nil then self.db.options.colors.first = { r = 128/255, g = 1, b = 0 }  end
	if self.db.options.colors.second == nil then self.db.options.colors.second = { r = 1, g = 1, b = 1 }  end
	if self.db.options.colors.total == nil then self.db.options.colors.total = { r = 244/255, g = 164/255, b = 96/255 }  end
	if self.db.options.colors.guild == nil then self.db.options.colors.guild = { r = 101/255, g = 184/255, b = 192/255 }  end
	if self.db.options.colors.cross == nil then self.db.options.colors.cross = { r = 1, g = 125/255, b = 10/255 }  end
	if self.db.options.colors.bnet == nil then self.db.options.colors.bnet = { r = 53/255, g = 136/255, b = 1 }  end
	if self.db.options.colors.itemid == nil then self.db.options.colors.itemid = { r = 82/255, g = 211/255, b = 134/255 }  end

	--do DB cleanup check by version number
	if not self.db.options.dbversion or self.db.options.dbversion ~= ver then	
		--self:FixDB()
		self.db.options.dbversion = ver
	end

	--player info
	self.db.player.money = player.money
	self.db.player.class = player.class
	self.db.player.race = player.race
	self.db.player.guild = player.guild
	self.db.player.gender = player.gender
	self.db.player.faction = player.faction

end

function BSYC:FixDB(onlyChkGuild)
	self:Print("|cFFFF9900"..L.FixDBComplete.."|r")
end

function BSYC:CleanAuctionsDB()
	--this function will remove expired auctions for all characters in every realm
	local timestampChk = { 30*60, 2*60*60, 12*60*60, 48*60*60 }
				
	for realm, rd in pairs(BagSyncDB) do
		--realm
		for k, v in pairs(rd) do
			--users k=name, v=values
			if BagSyncDB[realm][k].AH_LastScan and BagSyncDB[realm][k].AH_Count then --only proceed if we have an auction house time to work with
				--check to see if we even have something to work with
				if BagSyncDB[realm][k]["auction"] then
					--we do so lets do a loop
					local bVal = BagSyncDB[realm][k].AH_Count
					--do a loop through all of them and check to see if any expired
					for x = 1, bVal do
						if BagSyncDB[realm][k]["auction"][0][x] then
							--check for expired and remove if necessary
							--it's okay if the auction count is showing more then actually stored, it's just used as a means
							--to scan through all our items.  Even if we have only 3 and the count is 6 it will just skip the last 3.
							local dblink, dbcount, dbtimeleft = strsplit(",", BagSyncDB[realm][k]["auction"][0][x])
							
							--only proceed if we have everything to work with, otherwise this auction data is corrupt
							if dblink and dbcount and dbtimeleft then
								if tonumber(dbtimeleft) < 1 or tonumber(dbtimeleft) > 4 then dbtimeleft = 4 end --just in case
								--now do the time checks
								local diff = time() - BagSyncDB[realm][k].AH_LastScan 
								if diff > timestampChk[tonumber(dbtimeleft)] then
									--technically this isn't very realiable.  but I suppose it's better the  nothing
									BagSyncDB[realm][k]["auction"][0][x] = nil
								end
							else
								--it's corrupt delete it
								BagSyncDB[realm][k]["auction"][0][x] = nil
							end
						end
					end
				end
			end
		end
	end
	
end

function BSYC:FilterDB(dbSelect)

	local xIndex = {}
	local dbObj = self.db.global
	
	if dbSelect and dbSelect == 1 then
		--use BagSyncPROFESSION_DB
		dbObj = self.db.profession
	elseif dbSelect and dbSelect == 2 then
		--use BagSyncCURRENCY_DB
		dbObj = self.db.currency
	end

	--add more realm names if necessary based on BNet or Cross Realms
	if self.db.options.enableBNetAccountItems then
		for k, v in pairs(dbObj) do
			for q, r in pairs(v) do
				--we do this incase there are multiple characters with same name
				xIndex[q.."^"..k] = r
			end
		end
	elseif self.db.options.enableCrossRealmsItems then
		for k, v in pairs(dbObj) do
			if k == self.currentRealm or self.crossRealmNames[k] then
				for q, r in pairs(v) do
					----we do this incase there are multiple characters with same name
					xIndex[q.."^"..k] = r
				end
			end
		end
	else
		--do only the current realm if they don't have anything else configured
		for k, v in pairs(dbObj) do
			if k == self.currentRealm then
				for q, r in pairs(v) do
					----can't have multiple characters on same realm, but we need formatting anyways
					xIndex[q.."^"..k] = r
				end
			end
		end
	end
	
	return xIndex
end

function BSYC:GetRealmTags(srcName, srcRealm, isGuild)
	
	local tagName = srcName
	local fullRealmName = srcRealm --default to shortened realm first
	
	if self.db.realmkey[srcRealm] then fullRealmName = self.db.realmkey[srcRealm] end --second, if we have a realmkey with a true realm name then use it
	
	if not isGuild then
		local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
		--local NotReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-NotReady:0|t]]
		--Interface\\TargetingFrame\\UI-PVP-FFA

		--put a green check next to the currently logged in character name, make sure to put it as current realm only.  You can have toons with same name on multiple realms
		if srcName == self.currentPlayer and srcRealm == self.currentRealm and self.db.options.enableTooltipGreenCheck then
			tagName = tagName.." "..ReadyCheck
		end
	else
		--sometimes a person has characters on multiple connected servers joined to the same guild.
		--the guild information is saved twice because although the guild is on the connected server, the characters themselves are on different servers.
		--too compensate for this, lets check the connected server and return only the guild name.  So it doesn't get processed twice.
		for k, v in pairs(self.crossRealmNames) do
			--check to see if the guild exists already on a connected realm and not the current realm
			if k ~= srcRealm and self.db.guild[k] and self.db.guild[k][srcName] then
				--return non-modified guild name, we only want the guild listed once for the cross-realm
				return srcName
			end
		end
	end
	
	--make sure we work with player data not guild data
	if self.db.options.enableFactionIcons and self.db.global[srcRealm] and self.db.global[srcRealm][srcName] then
		local FactionIcon = [[|TInterface\Icons\Achievement_worldevent_brewmaster:18|t]]
		
		if self.db.global[srcRealm][srcName].faction == "Alliance" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_human:18|t]]
		elseif self.db.global[srcRealm][srcName].faction == "Horde" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_orc:18|t]]
		end
		
		tagName = FactionIcon.." "..tagName
	end
	
	--add Cross-Realm and BNet identifiers to Characters not on same realm
	local crossString = ""
	local bnetString = ""
	
	if self.db.options.enableRealmIDTags then
		crossString = "XR-"
		bnetString = "BNet-"
	end
	
	if self.db.options.enableRealmAstrickName then
		fullRealmName = "*"
	elseif self.db.options.enableRealmShortName then
		fullRealmName = string.sub(fullRealmName, 1, 5) --only use 5 characters of the server name
	end
	
	if self.db.options.enableBNetAccountItems then
		if srcRealm and srcRealm ~= self.currentRealm then
			if not self.crossRealmNames[srcRealm] then
				tagName = tagName.." "..rgbhex(self.db.options.colors.bnet).."["..bnetString..fullRealmName.."]|r"
			else
				tagName = tagName.." "..rgbhex(self.db.options.colors.cross).."["..crossString..fullRealmName.."]|r"
			end
		end
	elseif self.db.options.enableCrossRealmsItems then
		if srcRealm and srcRealm ~= self.currentRealm then
			tagName = tagName.." "..rgbhex(self.db.options.colors.cross).."["..crossString..fullRealmName.."]|r"
		end
	end
		
	return tagName
end

----------------------
--  Bag Functions   --
----------------------

function BSYC:SaveBag(bagname, bagid)
	if not bagname or not bagid then return end
	self.db.player[bagname] = self.db.player[bagname] or {}
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}

	if GetContainerNumSlots(bagid) > 0 then
		local slotItems = {}
		for slot = 1, GetContainerNumSlots(bagid) do
			local _, count, _,_,_,_, link = GetContainerItemInfo(bagid, slot)
			slotItems[slot] = self:ParseItemLink(link, count)
		end
		self.db.player[bagname][bagid] = slotItems
	else
		self.db.player[bagname][bagid] = nil
	end
end

function BSYC:SaveEquipment()
	self.db.player["equip"] = self.db.player["equip"] or {}
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	local slotItems = {}
	local NUM_EQUIPMENT_SLOTS = 19
	
	--start at 1, 0 used to be the old range slot (not needed anymore)
	for slot = 1, NUM_EQUIPMENT_SLOTS do
		local link = GetInventoryItemLink("player", slot)
		local count =  GetInventoryItemCount("player", slot)
		slotItems[slot] = self:ParseItemLink(link, count)
	end
	self.db.player["equip"][0] = slotItems
end

function BSYC:ScanEntireBank()
	--force scan of bank bag -1, since blizzard never sends updates for it
	self:SaveBag("bank", BANK_CONTAINER)
	for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		self:SaveBag("bank", i)
	end
	if IsReagentBankUnlocked() then 
		self:SaveBag("reagentbank", REAGENTBANK_CONTAINER)
	end
end

function BSYC:ScanVoidBank()
	if not self.atVoidBank then return end
	
	self.db.player["vault"] = self.db.player["vault"] or {}

	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}

	local numTabs = 2
	local index = 0
	local slotItems = {}
	
	for tab = 1, numTabs do
		for i = 1, 80 do
			local itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(tab, i)
			if (itemID) then
				index = index + 1
				slotItems[index] = itemID and tostring(itemID) or nil
			end
		end
	end
	
	self.db.player["vault"][0] = slotItems
end

function BSYC:ScanGuildBank()
	if not IsInGuild() then return end
	
	local MAX_GUILDBANK_SLOTS_PER_TAB = 98
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	local numTabs = GetNumGuildBankTabs()
	local index = 0
	local slotItems = {}
	
	for tab = 1, numTabs do
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		--if we don't check for isViewable we get a weirdo permissions error for the player when they attempt it
		if isViewable then
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
				local link = GetGuildBankItemLink(tab, slot)
				if link then
					index = index + 1
					local _, count = GetGuildBankItemInfo(tab, slot)
					slotItems[index] = self:ParseItemLink(link, count)
				end
			end
		end
	end
	
	self.db.realm[self.db.player.guild] = slotItems
end

function BSYC:ScanMailbox()
	--this is to prevent buffer overflow from the CheckInbox() function calling ScanMailbox too much :)
	if self.isCheckingMail then return end
	self.isCheckingMail = true

	 --used to initiate mail check from server, for some reason GetInboxNumItems() returns zero sometimes
	 --even though the user has mail in the mailbox.  This can be attributed to lag.
	CheckInbox()

	self.db.player["mailbox"] = self.db.player["mailbox"] or {}
	
	local slotItems = {}
	local mailCount = 0
	local numInbox = GetInboxNumItems()

	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			for i=1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i)
				local link = GetInboxItemLink(mailIndex, i)
				if name and link then
					mailCount = mailCount + 1
					slotItems[mailCount] = self:ParseItemLink(link, count)
				end
			end
		end
	end
	
	self.db.player["mailbox"][0] = slotItems
	self.isCheckingMail = false
end

function BSYC:ScanAuctionHouse()
	self.db.player["auction"] = self.db.player["auction"] or {}
	
	local slotItems = {}
	local ahCount = 0
	local numActiveAuctions = GetNumAuctionItems("owner")
	
	--reset our tooltip data since we scanned new items (we want current data not old)
	self.PreviousItemLink = nil
	self.PreviousItemTotals = {}
	
	--scan the auction house
	if (numActiveAuctions > 0) then
		for ahIndex = 1, numActiveAuctions do
			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner, saleStatus  = GetAuctionItemInfo("owner", ahIndex)
			if name then
				local link = GetAuctionItemLink("owner", ahIndex)
				local timeLeft = GetAuctionItemTimeLeft("owner", ahIndex)
				if link and timeLeft then
					ahCount = ahCount + 1
					count = (count or 1)
					slotItems[ahCount] = self:ParseItemLink(link, count)..";"..timeLeft
				end
			end
		end
	end
	
	self.db.player["auction"][0] = slotItems
	self.db.player.AH_Count = ahCount
end

------------------------
--   Money Tooltip    --
------------------------

function BSYC:ShowMoneyTooltip(objTooltip)
	local tooltip = _G["BagSyncMoneyTooltip"] or nil
	
	if (not tooltip) then
			tooltip = CreateFrame("GameTooltip", "BagSyncMoneyTooltip", UIParent, "GameTooltipTemplate")
			
			local closeButton = CreateFrame("Button", nil, tooltip, "UIPanelCloseButton")
			closeButton:SetPoint("TOPRIGHT", tooltip, 1, 0)
			
			tooltip:SetToplevel(true)
			tooltip:EnableMouse(true)
			tooltip:SetMovable(true)
			tooltip:SetClampedToScreen(true)
			
			tooltip:SetScript("OnMouseDown",function(self)
					self.isMoving = true
					self:StartMoving();
			end)
			tooltip:SetScript("OnMouseUp",function(self)
				if( self.isMoving ) then
					self.isMoving = nil
					self:StopMovingOrSizing()
				end
			end)
	end

	local usrData = {}
	
	tooltip:ClearLines()
	tooltip:ClearAllPoints()
	
	if objTooltip then
		tooltip:SetOwner(objTooltip, "ANCHOR_NONE")
		tooltip:SetPoint("CENTER",objTooltip,"CENTER",0,0)
	else
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetPoint("CENTER",UIParent,"CENTER",0,0)
	end

	tooltip:AddLine("BagSync")
	tooltip:AddLine(" ")
	
	--loop through our characters
	local xDB = self:FilterDB()

	for k, v in pairs(xDB) do
		local yName, yRealm  = strsplit("^", k)
		local playerName = BSYC:GetRealmTags(yName, yRealm)
		
		if v.gold then
			playerName = self:GetClassColor(playerName or "Unknown", v.class)
			table.insert(usrData, { name=playerName, gold=v.gold } )
		end
	end
	table.sort(usrData, function(a,b) return (a.name < b.name) end)
	
	local gldTotal = 0
	
	for i=1, table.getn(usrData) do
		tooltip:AddDoubleLine(usrData[i].name, GetCoinTextureString(usrData[i].gold), 1, 1, 1, 1, 1, 1)
		gldTotal = gldTotal + usrData[i].gold
	end
	if self.db.options.showTotal and gldTotal > 0 then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(tooltipColor(self.db.options.colors.total, L.TooltipTotal), GetCoinTextureString(gldTotal), 1, 1, 1, 1, 1, 1)
	end
	
	tooltip:AddLine(" ")
	tooltip:Show()
end

function BSYC:HideMoneyTooltip()
	local tooltip = _G["BagSyncMoneyTooltip"] or nil
	if tooltip then
		tooltip:Hide()
	end
end

------------------------
--      Currency      --
------------------------

function BSYC:ScanCurrency()
	--LETS AVOID CURRENCY SPAM AS MUCH AS POSSIBLE
	if self.doCurrencyUpdate and self.doCurrencyUpdate > 0 then return end
	if self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then
		--avoid (Honor point spam), avoid (arena point spam), if it's world PVP...well then it sucks to be you
		self.doCurrencyUpdate = 1
		BSYC:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	local lastHeader
	local limit = GetCurrencyListSize()

	for i=1, limit do
	
		local name, isHeader, isExpanded, _, _, count, icon = GetCurrencyListInfo(i)
		--extraCurrencyType = 1 for arena points, 2 for honor points; 0 otherwise (an item-based currency).

		if name then
			if(isHeader and not isExpanded) then
				ExpandCurrencyList(i,1)
				lastHeader = name
				limit = GetCurrencyListSize()
			elseif isHeader then
				lastHeader = name
			end
			if (not isHeader) then
				self.db.player.currency[icon] = {title = name, header = lastHeader, count = count}
			end
		end
	end
	--we don't want to overwrite currency, because some characters may have currency that the others dont have	
end

------------------------
--      Tooltip       --
------------------------

function BSYC:ResetTooltip()
	self.PreviousItemTotals = {}
	self.PreviousItemLink = nil
end

function BSYC:CreateItemTotals(countTable)
	local info = ""
	local total = 0
	local grouped = 0
	
	--order in which we want stuff displayed
	local list = {
		[1] = { "bag", 			L.TooltipBag },
		[2] = { "bank", 		L.TooltipBank },
		[3] = { "reagentbank", 	L.TooltipReagent },
		[4] = { "equip", 		L.TooltipEquip },
		[5] = { "guild", 		L.TooltipGuild },
		[6] = { "mailbox", 		L.TooltipMail },
		[7] = { "vault", 		L.TooltipVoid },
		[8] = { "auction", 		L.TooltipAuction },
	}
		
	for i = 1, #list do
		local count = countTable[list[i][1]]
		if count > 0 then
			grouped = grouped + 1
			info = info..L.TooltipDelimiter..tooltipColor(self.db.options.colors.first, list[i][2]).." "..tooltipColor(self.db.options.colors.second, count)
			total = total + count
		end
	end

	--remove the first delimiter since it's added to the front automatically
	info = strsub(info, string.len(L.TooltipDelimiter) + 1)
	if string.len(info) < 1 then return nil end --return nil for empty strings
	
	--if it's groupped up and has more then one item then use a different color and show total
	if grouped > 1 then
		info = tooltipColor(self.db.options.colors.second, total).." ("..info..")"
	end
	
	return info
end

function BSYC:GetClassColor(sName, sClass)
	if not self.db.options.enableUnitClass then
		return tooltipColor(self.db.options.colors.first, sName)
	else
		if sName ~= "Unknown" and sClass and RAID_CLASS_COLORS[sClass] then
			return rgbhex(RAID_CLASS_COLORS[sClass])..sName.."|r"
		end
	end
	return tooltipColor(self.db.options.colors.first, sName)
end

function BSYC:AddCurrencyTooltip(frame, currencyName, addHeader)
	if not self.db.options.enableTooltips then return end
	
	local tmp = {}
	local count = 0
	
	local xDB = BSYC:FilterDB(2) --dbSelect 2
		
	for k, v in pairs(xDB) do
		local yName, yRealm  = strsplit("^", k)
		local playerName = BSYC:GetRealmTags(yName, yRealm)

		playerName = self:GetClassColor(playerName or "Unknown", self.db.global[yRealm][yName].class)

		for q, r in pairs(v) do
			if q == currencyName then
				--we only really want to list the currency once for display
				table.insert(tmp, { name=playerName, count=r.count} )
				count = count + 1
			end
		end
	end
	
	if count > 0 then
		table.sort(tmp, function(a,b) return (a.name < b.name) end)
		if self.db.options.enableTooltipSeperator and not addHeader then
			frame:AddLine(" ")
		end
		if addHeader then
			local color = { r = 64/255, g = 224/255, b = 208/255 } --same color as header in Currency window
			frame:AddLine(rgbhex(color)..currencyName.."|r")
		end
		for i=1, #tmp do
			frame:AddDoubleLine(tooltipColor(self.db.options.colors.first, tmp[i].name), tooltipColor(self.db.options.colors.second, tmp[i].count))
		end
	end
	
	frame:Show()
end

function BSYC:AddItemToTooltip(frame, link) --workaround
	if not self.db.options.enableTooltips then return end
	
	--if we can't convert the item link then lets just ignore it altogether	
	local itemLink = self:ParseItemLink(link)
	if not itemLink then
		frame:Show()
		return
	end
	
	--use our stripped itemlink, not the full link
	local shortItemID = self:GetShortItemID(itemLink)

	--short the shortID and ignore all BonusID's and stats
	if self.db.options.enableShowUniqueItemsTotals then itemLink = shortItemID end
	
	--only show tooltips in search frame if the option is enabled
	if self.db.options.tooltipOnlySearch and frame:GetOwner() and frame:GetOwner():GetName() and string.sub(frame:GetOwner():GetName(), 1, 16) ~= "BagSyncSearchRow" then
		frame:Show()
		return
	end
	
	local permIgnore ={
		[6948] = "Hearthstone",
		[110560] = "Garrison Hearthstone",
		[140192] = "Dalaran Hearthstone",
		[128353] = "Admiral's Compass",
	}
	
	--ignore the hearthstone and blacklisted items
	if shortItemID and tonumber(shortItemID) then
		if permIgnore[tonumber(shortItemID)] or self.db.blacklist[self.currentRealm][tonumber(shortItemID)] then
			frame:Show()
			return
		end
	end
	
	--lag check (check for previously displayed data) if so then display it
	if self.PreviousItemLink and itemLink and itemLink == self.PreviousItemLink then
		if table.getn(self.PreviousItemTotals) > 0 then
			for i = 1, #self.PreviousItemTotals do
				local ename, ecount  = strsplit("@", self.PreviousItemTotals[i])
				if ename and ecount then
					local color = self.db.options.colors.total
					frame:AddDoubleLine(ename, ecount, color.r, color.g, color.b, color.r, color.g, color.b)
				else
					local color = self.db.options.colors.second
					frame:AddLine(self.PreviousItemTotals[i], color.r, color.g, color.b)				
				end
			end
		end
		frame:Show()
		return
	end

	--reset our last displayed
	self.PreviousItemTotals = {}
	self.PreviousItemLink = itemLink
	
	--this is so we don't scan the same guild multiple times
	local previousGuilds = {}
	local previousGuildsXRList = {}
	local grandTotal = 0
	local first = true
	
	local xDB = self:FilterDB()
	
	--loop through our characters
	--k = player, v = stored data for player
	for k, v in pairs(xDB) do

		local allowList = {
			["bag"] = 0,
			["bank"] = 0,
			["reagentbank"] = 0,
			["equip"] = 0,
			["mailbox"] = 0,
			["vault"] = 0,
			["auction"] = 0,
			["guild"] = 0,
		}
	
		local infoString
		local pFaction = v.faction or self.playerFaction --just in case ;) if we dont know the faction yet display it anyways
		
		--check if we should show both factions or not
		if self.db.options.enableFaction or pFaction == self.playerFaction then
		
			--now count the stuff for the user
			--q = bag name, r = stored data for bag name
			for q, r in pairs(v) do
				--only loop through table items we want
				if allowList[q] and type(r) == "table" then
					--bagID = bag name bagID, bagInfo = data of specific bag with bagID
					for bagID, bagInfo in pairs(r) do
						--slotID = slotid for specific bagid, itemValue = data of specific slotid
						if type(bagInfo) == "table" then
							for slotID, itemValue in pairs(bagInfo) do
								local dblink, dbcount = strsplit(",", itemValue)
								if dblink and self.db.options.enableShowUniqueItemsTotals then dblink = self:GetShortItemID(dblink) end
								if dblink and dblink == itemLink then
									allowList[q] = allowList[q] + (dbcount or 1)
									grandTotal = grandTotal + (dbcount or 1)
								end
							end
						end
					end
				end
			end
		
			if self.db.options.enableGuild then
				local guildN = v.guild or nil
			
				--check the guild bank if the character is in a guild
				if guildN and self.db.guild[v.realm][guildN] then
					--check to see if this guild has already been done through this run (so we don't do it multiple times)
					--check for XR/B.Net support, you can have multiple guilds with same names on different servers
					local gName = self:GetRealmTags(guildN, v.realm, true)
					
					--check to make sure we didn't already add a guild from a connected-realm
					local trueRealmList = self.db.realmkey[0][v.realm] --get the connected realms
					if trueRealmList then
						table.sort(trueRealmList, function(a,b) return (a < b) end) --sort them alphabetically
						trueRealmList = table.concat(trueRealmList, "|") --concat them together
					else
						trueRealmList = v.realm
					end
					trueRealmList = guildN.."-"..trueRealmList --add the guild name in front of concat realm list

					if not previousGuilds[gName] and not previousGuildsXRList[trueRealmList] then
						--we only really need to see this information once per guild
						local tmpCount = 0
						for q, r in pairs(self.db.guild[v.realm][guildN]) do
							local dblink, dbcount = strsplit(",", r)
							if dblink and self.db.options.enableShowUniqueItemsTotals then dblink = self:GetShortItemID(dblink) end
							if dblink and dblink == itemLink then
								--if we have show guild names then don't show any guild info for the character, otherwise it gets repeated twice
								if not self.db.options.showGuildNames then
									allowList["guild"] = allowList["guild"] + (dbcount or 1)
								end
								tmpCount = tmpCount + (dbcount or 1)
								grandTotal = grandTotal + (dbcount or 1)
							end
						end
						previousGuilds[gName] = tmpCount
						previousGuildsXRList[trueRealmList] = true
					end
				end
			end
			
			--get class for the unit if there is one
			infoString = self:CreateItemTotals(allowList)

			if infoString then
				local yName, yRealm  = strsplit("^", k)
				local playerName = self:GetRealmTags(yName, yRealm)
				table.insert(self.PreviousItemTotals, self:GetClassColor(playerName or "Unknown", v.class).."@"..(infoString or "unknown"))
			end
			
		end
		
	end
	
	--sort it
	table.sort(self.PreviousItemTotals, function(a,b) return (a < b) end)
	
	--show guildnames last
	if self.db.options.enableGuild and self.db.options.showGuildNames then
		for k, v in self:pairsByKeys(previousGuilds) do
			--only print stuff higher then zero
			if v > 0 then
				table.insert(self.PreviousItemTotals, tooltipColor(self.db.options.colors.guild, k).."@"..tooltipColor(self.db.options.colors.second, v))
			end
		end
	end
	
	--show grand total if we have something
	--don't show total if there is only one item
	if self.db.options.showTotal and grandTotal > 0 and getn(self.PreviousItemTotals) > 1 then
		table.insert(self.PreviousItemTotals, tooltipColor(self.db.options.colors.total, L.TooltipTotal).."@"..tooltipColor(self.db.options.colors.second, grandTotal))
	end
	
	--add ItemID if it's enabled
	if table.getn(self.PreviousItemTotals) > 0 and self.db.options.enableTooltipItemID and shortItemID and tonumber(shortItemID) then
		table.insert(self.PreviousItemTotals, 1 , tooltipColor(self.db.options.colors.itemid, L.TooltipItemID).." "..tooltipColor(self.db.options.colors.second, shortItemID))
	end
	
	--now check for seperater and only add if we have something in the table already
	if table.getn(self.PreviousItemTotals) > 0 and self.db.options.enableTooltipSeperator then
		table.insert(self.PreviousItemTotals, 1 , " ")
	end
	
	--add it all together now
	if table.getn(self.PreviousItemTotals) > 0 then
		for i = 1, #self.PreviousItemTotals do
			local ename, ecount  = strsplit("@", self.PreviousItemTotals[i])
			if ename and ecount then
				local color = self.db.options.colors.total
				frame:AddDoubleLine(ename, ecount, color.r, color.g, color.b, color.r, color.g, color.b)
			else
				local color = self.db.options.colors.second
				frame:AddLine(self.PreviousItemTotals[i], color.r, color.g, color.b)				
			end
		end
	end

	frame:Show()
end

function BSYC:HookTooltip(tooltip)

	tooltip.isModified = false
	
	tooltip:HookScript("OnHide", function(self)
		self.isModified = false
		self.lastHyperLink = nil
	end)	
	tooltip:HookScript("OnTooltipCleared", function(self)
		self.isModified = false
	end)

	tooltip:HookScript("OnTooltipSetItem", function(self)
		if self.isModified then return end
		local name, link = self:GetItem()

		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
			return
		end
		--sometimes we have a tooltip but no link because GetItem() returns nil, this is the case for recipes
		--so lets try something else to see if we can get the link.  Doesn't always work!  Thanks for breaking GetItem() Blizzard... you ROCK! :P
		if not self.isModified and self.lastHyperLink then
			local xName, xLink = GetItemInfo(self.lastHyperLink)
			if xLink then  --only show info if the tooltip text matches the link
				self.isModified = true
				BSYC:AddItemToTooltip(self, xLink)
			end		
		end
	end)

	---------------------------------
	--Special thanks to GetItem() being broken we need to capture the ItemLink before the tooltip shows sometimes
	hooksecurefunc(tooltip, "SetBagItem", function(self, tab, slot)
		local link = GetContainerItemLink(tab, slot)
		if link then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetInventoryItem", function(self, tab, slot)
		local link = GetInventoryItemLink(tab, slot)
		if link then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetGuildBankItem", function(self, tab, slot)
		local link = GetGuildBankItemLink(tab, slot)
		if link then
			self.lastHyperLink = link
		end
	end)
	hooksecurefunc(tooltip, "SetHyperlink", function(self, link)
		if self.isModified then return end
		if link then
			--I'm pretty sure there is a better way to do this but since Recipes fire OnTooltipSetItem with empty/nil GetItem().  There is really no way to my knowledge to grab the current itemID
			--without storing the ItemLink from the bag parsing or at least grabbing the current SetHyperLink.
			if tooltip:IsVisible() then self.isModified = true end --only do the modifier if the tooltip is showing, because this interferes with ItemRefTooltip if someone clicks it twice in chat
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	---------------------------------

	--lets hook other frames so we can show tooltips there as well, sometimes GetItem() doesn't work right and returns nil
	hooksecurefunc(tooltip, "SetVoidItem", function(self, tab, slot)
		if self.isModified then return end
		local link = GetVoidItemInfo(tab, slot)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetVoidDepositItem", function(self, slot)
		if self.isModified then return end
		local link = GetVoidTransferDepositInfo(slot)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetVoidWithdrawalItem", function(self, slot)
		if self.isModified then return end
		local link = GetVoidTransferWithdrawalInfo(slot)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetRecipeReagentItem", function(self, recipeID, reagentIndex)
		if self.isModified then return end
		local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetRecipeResultItem", function(self, recipeID)
		if self.isModified then return end
		local link = C_TradeSkillUI.GetRecipeItemLink(recipeID)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)	
	hooksecurefunc(tooltip, "SetQuestLogItem", function(self, itemType, index)
		if self.isModified then return end
		local link = GetQuestLogItemLink(itemType, index)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)
	hooksecurefunc(tooltip, "SetQuestItem", function(self, itemType, index)
		if self.isModified then return end
		local link = GetQuestItemLink(itemType, index)
		if link then
			self.isModified = true
			BSYC:AddItemToTooltip(self, link)
		end
	end)	
	--------------------------------------------------
	hooksecurefunc(tooltip, "SetCurrencyToken", function(self, index)
		if self.isModified then return end
		self.isModified = true
		local currencyName = GetCurrencyListInfo(index)
		BSYC:AddCurrencyTooltip(self, currencyName)
	end)
	hooksecurefunc(tooltip, "SetCurrencyByID", function(self, id)
		if self.isModified then return end
		self.isModified = true
		local currencyName = GetCurrencyInfo(id)
		BSYC:AddCurrencyTooltip(self, currencyName)
	end)
	hooksecurefunc(tooltip, "SetBackpackToken", function(self, index)
		if self.isModified then return end
		self.isModified = true
		local currencyName = GetBackpackCurrencyInfo(index)
		BSYC:AddCurrencyTooltip(self, currencyName)
	end)

end

------------------------------
--    SLASH COMMAND         --
------------------------------

function BSYC:ChatCommand(input)

	local parts = { (" "):split(input) }
	local cmd, args = strlower(parts[1] or ""), table.concat(parts, " ", 2)

	if string.len(cmd) > 0 then

		if cmd == L.SlashSearch then
			self:GetModule("Search"):StartSearch()
			return true
		elseif cmd == L.SlashGold then
			self:ShowMoneyTooltip()
			return true
		elseif cmd == L.SlashCurrency then
			self:GetModule("Currency").frame:Show()
			return true
		elseif cmd == L.SlashProfiles then
			self:GetModule("Profiles").frame:Show()
			return true
		elseif cmd == L.SlashProfessions then
			self:GetModule("Professions").frame:Show()
			return true
		elseif cmd == L.SlashBlacklist then
			self:GetModule("Blacklist").frame:Show()
			return true
		elseif cmd == L.SlashFixDB then
			self:FixDB()
			return true
		elseif cmd == L.SlashConfig then
			InterfaceOptionsFrame:Show() --has to be here to load the about frame onLoad
			InterfaceOptionsFrame_OpenToCategory(self.aboutPanel) --force the panel to show
			return true
		else
			--do an item search, use the full command to search
			self:GetModule("Search"):StartSearch(input)
			return true
		end

	end

	self:Print(L.HelpSearchItemName)
	self:Print(L.HelpSearchWindow)
	self:Print(L.HelpGoldTooltip)
	self:Print(L.HelpCurrencyWindow)
	self:Print(L.HelpProfilesWindow)
	self:Print(L.HelpProfessionsWindow)
	self:Print(L.HelpBlacklistWindow)
	self:Print(L.HelpFixDB)
	self:Print(L.HelpConfigWindow )

end

------------------------------
--    KEYBINDING            --
------------------------------

function BagSync_ShowWindow(windowName)
	if windowName == "Search" then
		BSYC:GetModule("Search"):StartSearch()
	elseif windowName == "Gold" then
		BSYC:ShowMoneyTooltip()
	else
		BSYC:GetModule(windowName).frame:Show()
	end
end

------------------------------
--    LOGIN HANDLER         --
------------------------------

function BSYC:OnEnable()
	--NOTE: Using OnEnable() instead of OnInitialize() because not all the SavedVarables fully loaded
	--also one of the major issues is that UnitFullName() will return nil for the short named realm

	--load the keybinding locale information
	BINDING_HEADER_BAGSYNC = "BagSync"
	BINDING_NAME_BAGSYNCBLACKLIST = L.KeybindBlacklist
	BINDING_NAME_BAGSYNCCURRENCY = L.KeybindCurrency
	BINDING_NAME_BAGSYNCGOLD = L.KeybindGold
	BINDING_NAME_BAGSYNCPROFESSIONS = L.KeybindProfessions
	BINDING_NAME_BAGSYNCPROFILES = L.KeybindProfiles
	BINDING_NAME_BAGSYNCSEARCH = L.KeybindSearch

	local ver = GetAddOnMetadata("BagSync","Version") or 0
	
	--load our player info after login
	self.currentPlayer = UnitName("player")
	self.currentRealm = select(2, UnitFullName("player")) --get shortend realm name with no spaces and dashes
	self.playerClass = select(2, UnitClass("player"))
	self.playerFaction = UnitFactionGroup("player")

	--strip realm of whitespace and special characters, alternative to UnitFullName, since UnitFullName does not work on OnInitialize()
	--BSYC:Debug(gsub(GetRealmName(),"[%s%-]",""))
	
	local realmList = {} --we are going to use this to store a list of connected realms, including the current realm
	local autoCompleteRealms = GetAutoCompleteRealms() or { self.currentRealm }
	
	table.insert(realmList, self.currentRealm)
	
	self.crossRealmNames = {}
	for k, v in pairs(autoCompleteRealms) do
		if v ~= self.currentRealm then
			self.crossRealmNames[v] = true
			table.insert(realmList, v)
		end
	end
	
	--initiate the db
	self:StartupDB()
	
	--save all inventory data, including backpack(0)
	for i = BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS do
		self:SaveBag("bag", i)
	end

	--force an equipment scan
	self:SaveEquipment()
	
	--force token scan
	hooksecurefunc("BackpackTokenFrame_Update", function(self) BSYC:ScanCurrency() end)
	self:ScanCurrency()
	
	--clean up old auctions
	--self:CleanAuctionsDB()
	
	--check for minimap toggle
	if self.db.options.enableMinimap and BagSync_MinimapButton and not BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Show()
	elseif not self.db.options.enableMinimap and BagSync_MinimapButton and BagSync_MinimapButton:IsVisible() then
		BagSync_MinimapButton:Hide()
	end
				
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
	
	--currency
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

	--void storage
	self:RegisterEvent("VOID_STORAGE_OPEN")
	self:RegisterEvent("VOID_STORAGE_CLOSE")
	self:RegisterEvent("VOID_STORAGE_UPDATE")
	self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE")
	self:RegisterEvent("VOID_TRANSFER_DONE")
	
	--this will be used for getting the tradeskill link
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")

	--hook the tooltips
	self:HookTooltip(GameTooltip)
	self:HookTooltip(ItemRefTooltip)
	
	--register the slash command
	self:RegisterChatCommand("bgs", "ChatCommand")
	self:RegisterChatCommand("bagsync", "ChatCommand")
	
	if self.db.options.enableLoginVersionInfo then
		self:Print("[v|cFF20ff20"..ver.."|r] /bgs, /bagsync")
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function BSYC:CURRENCY_DISPLAY_UPDATE()
--if C_PetBattles.IsInBattle() then return end
	if self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self.doCurrencyUpdate = 0
	self:ScanCurrency()
end

function BSYC:PLAYER_REGEN_ENABLED()
	if self:IsInBG() or self:IsInArena() or InCombatLockdown() or UnitAffectingCombat("player") then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	--were out of an arena or battleground scan the points
	self.doCurrencyUpdate = 0
	self:ScanCurrency()
end

function BSYC:GUILD_ROSTER_UPDATE()
	self.db.player.guild = Cache:GetOwnerInfo().guild
end

function BSYC:PLAYER_MONEY()
	self.db.player.money = Cache:GetOwnerInfo().money
end

------------------------------
--      BAG UPDATES  	    --
------------------------------

function BSYC:BAG_UPDATE(event, bagid)
	-- -1 happens to be the primary bank slot ;)
	if (bagid > BANK_CONTAINER) then
	
		--this will update the bank/bag slots
		local bagname

		--get the correct bag name based on it's id, trying NOT to use numbers as Blizzard may change bagspace in the future
		--so instead I'm using constants :)
		if ((bagid >= NUM_BAG_SLOTS + 1) and (bagid <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS)) then
			bagname = "bank"
		elseif (bagid >= BACKPACK_CONTAINER) and (bagid <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
			bagname = "bag"
		else
			return
		end
		
		if bagname == "bank" and not self.atBank then return; end
		--now save the item information in the bag from bagupdate, this could be bag or bank
		self:SaveBag(bagname, bagid)
		
	end
end

function BSYC:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" then
		self:SaveEquipment()
	end
end

------------------------------
--      BANK	            --
------------------------------

function BSYC:BANKFRAME_OPENED()
	self.atBank = true
	self:ScanEntireBank()
end

function BSYC:BANKFRAME_CLOSED()
	self.atBank = false
end

function BSYC:PLAYERBANKSLOTS_CHANGED(event, slotid)
	--Remove self.atBank when/if Blizzard allows Bank access without being at the bank
	if self.atBank then
		self:SaveBag("bank", BANK_CONTAINER)
	end
end

------------------------------
--		REAGENT BANK		--
------------------------------

function BSYC:PLAYERREAGENTBANKSLOTS_CHANGED()
	self:SaveBag("reagentbank", REAGENTBANK_CONTAINER)
end

------------------------------
--      VOID BANK	        --
------------------------------

function BSYC:VOID_STORAGE_OPEN()
	self.atVoidBank = true
	self:ScanVoidBank()
end

function BSYC:VOID_STORAGE_CLOSE()
	self.atVoidBank = false
end

function BSYC:VOID_STORAGE_UPDATE()
	self:ScanVoidBank()
end

function BSYC:VOID_STORAGE_CONTENTS_UPDATE()
	self:ScanVoidBank()
end

function BSYC:VOID_TRANSFER_DONE()
	self:ScanVoidBank()
end

------------------------------
--      GUILD BANK	        --
------------------------------

function BSYC:GUILDBANKFRAME_OPENED()
	self.atGuildBank = true
	if not self.db.options.enableGuild then return end
	if not self.GuildTabQueryQueue then self.GuildTabQueryQueue = {} end
	
	local numTabs = GetNumGuildBankTabs()
	for tab = 1, numTabs do
		-- add this tab to the queue to refresh; if we do them all at once the server bugs and sends massive amounts of events
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab)
		if isViewable then
			self.GuildTabQueryQueue[tab] = true
		end
	end
end

function BSYC:GUILDBANKFRAME_CLOSED()
	self.atGuildBank = false
end

function BSYC:GUILDBANKBAGSLOTS_CHANGED()
	if not self.db.options.enableGuild then return end

	if self.atGuildBank then
		-- check if we need to process the queue
		local tab = next(self.GuildTabQueryQueue)
		if tab then
			QueryGuildBankTab(tab)
			self.GuildTabQueryQueue[tab] = nil
		else
			-- the bank is ready for reading
			self:ScanGuildBank()
		end
	end
end

------------------------------
--      MAILBOX  	        --
------------------------------

function BSYC:MAIL_SHOW()
	if self.isCheckingMail then return end
	if not self.db.options.enableMailbox then return end
	self:ScanMailbox()
end

function BSYC:MAIL_INBOX_UPDATE()
	if self.isCheckingMail then return end
	if not self.db.options.enableMailbox then return end
	self:ScanMailbox()
end

------------------------------
--     AUCTION HOUSE        --
------------------------------

function BSYC:AUCTION_HOUSE_SHOW()
	if not self.db.options.enableAuction then return end
	self:ScanAuctionHouse()
end

function BSYC:AUCTION_OWNED_LIST_UPDATE()
	if not self.db.options.enableAuction then return end
	self.db.player.AH_LastScan = time()
	self:ScanAuctionHouse()
end

------------------------------
--     PROFESSION           --
------------------------------

function BSYC:doRegularTradeSkill(numIndex, dbPlayer, dbIdx)
	local name, texture, rank, maxRank, numSpells, spelloffset, skillLine, rankModifier, specializationIndex, specializationOffset, skillLineName = GetProfessionInfo(numIndex)
	if name and rank then
		dbPlayer[dbIdx] = dbPlayer[dbIdx] or {}
		dbPlayer[dbIdx].name = name
		dbPlayer[dbIdx].texture = texture
		dbPlayer[dbIdx].rank = rank
		dbPlayer[dbIdx].maxRank = maxRank
		dbPlayer[dbIdx].skillLineName = skillLineName
	end
end

function BSYC:TRADE_SKILL_SHOW()
	--IsTradeSkillLinked() returns true only if trade window was opened from chat link (meaning another player)
	if (not _G.C_TradeSkillUI.IsTradeSkillLinked()) then
		
		local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
		
		local dbPlayer = self.db.player.profession
		
		--prof1
		if prof1 then
			self:doRegularTradeSkill(prof1, dbPlayer, 1)
		elseif not prof1 and dbPlayer[1] then
			--they removed a profession
			dbPlayer[1] = nil
		end

		--prof2
		if prof2 then
			self:doRegularTradeSkill(prof2, dbPlayer, 2)
		elseif not prof2 and dbPlayer[2] then
			--they removed a profession
			dbPlayer[2] = nil
		end
		
		--archaeology
		if archaeology then
			self:doRegularTradeSkill(archaeology, dbPlayer, 3)
		elseif not archaeology and dbPlayer[3] then
			--they removed a profession
			dbPlayer[3] = nil
		end
		
		--fishing
		if fishing then
			self:doRegularTradeSkill(fishing, dbPlayer, 4)
		elseif not fishing and dbPlayer[4] then
			--they removed a profession
			dbPlayer[4] = nil
		end
		
		--cooking
		if cooking then
			self:doRegularTradeSkill(cooking, dbPlayer, 5)
		elseif not cooking and dbPlayer[5] then
			--they removed a profession
			dbPlayer[5] = nil
		end
		
		--firstAid
		if firstAid then
			self:doRegularTradeSkill(firstAid, dbPlayer, 6)
		elseif not firstAid and dbPlayer[6] then
			--they removed a profession
			dbPlayer[6] = nil
		end
	end
	
	--grab the player recipes but only scan once, TRADE_SKILL_LIST_UPDATE is triggered multiple times for some reason
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
end

--this function pretty much only grabs the recipelist for the CURRENT opened profession, not all the profession info which TRADE_SKILL_SHOW does.
--this is because you can't open up herbalism, mining, etc...
function BSYC:TRADE_SKILL_LIST_UPDATE()

	if (not _G.C_TradeSkillUI.IsTradeSkillLinked()) then
	
		local getIndex = 0
		local getProfIndex = 0
		local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
		--Blizzard_APIDocumentation/TradeSkillUIDocumentation.lua
		local tradeSkillID, skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier, parentSkillLineID, parentSkillLineName = _G.C_TradeSkillUI.GetTradeSkillLine()
		
		if not parentSkillLineName then return end --don't do anything if no tradeskill name
		
		--prof1
		if prof1 and GetProfessionInfo(prof1) == parentSkillLineName then
			getIndex = 1
			getProfIndex = prof1
		elseif prof2 and GetProfessionInfo(prof2) == parentSkillLineName then
			getIndex = 2
			getProfIndex = prof2
		elseif archaeology and GetProfessionInfo(archaeology) == parentSkillLineName then
			getIndex = 3
			getProfIndex = archaeology
		elseif fishing and GetProfessionInfo(fishing) == parentSkillLineName then
			getIndex = 4
			getProfIndex = fishing
		elseif cooking and GetProfessionInfo(cooking) == parentSkillLineName then
			getIndex = 5
			getProfIndex = cooking
		elseif firstAid and GetProfessionInfo(firstAid) == parentSkillLineName then
			getIndex = 6
			getProfIndex = firstAid
		end
		
		--don't do anything if we have nothing to work with
		if getIndex < 1 then return end
		
		local name, texture, rank, maxRank, numSpells, spelloffset, skillLine, rankModifier, specializationIndex, specializationOffset, skillLineName = GetProfessionInfo(getProfIndex)
		
		local recipeString = ""
		local recipeIDs = _G.C_TradeSkillUI.GetAllRecipeIDs()
		local recipeInfo = {}

		for idx = 1, #recipeIDs do
			recipeInfo = _G.C_TradeSkillUI.GetRecipeInfo(recipeIDs[idx])
			
			if recipeInfo and recipeInfo.learned then
				recipeString = recipeString.."|"..recipeInfo.recipeID
			end
		end

		--only record if we have something to work with
		if name and rank and string.len(recipeString) > 0 then
			recipeString = strsub(recipeString, string.len("|") + 1) --remove the delimiter in front of recipeID list
			self.db.player.profession[getIndex] = self.db.player.profession[getIndex] or {}
			self.db.player.profession[getIndex].recipes = recipeString
		end
		
	end
	
	--unregister for next time the tradeskill window is opened
	self:UnregisterEvent("TRADE_SKILL_LIST_UPDATE")
end

--if they have the tradeskill window opened and then click on another professions it keeps the window opened and thus TRADE_SKILL_LIST_UPDATE never gets fired
function BSYC:TRADE_SKILL_DATA_SOURCE_CHANGED()
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
end