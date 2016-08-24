
local L = LibStub("AceLocale-3.0"):NewLocale("BagSync", "enUS", true)
if not L then return end

L.TooltipBag = "Bags: %d"
L.TooltipBank = "Bank: %d"
L.TooltipEquip = "Equip: %d"
L.TooltipGuild = "Guild: %d"
L.TooltipMail = "Mail: %d"
L.TooltipVoid = "Void: %d"
L.TooltipReagent = "Reagent: %d"
L.TooltipAuction = "AH: %d"
L.TooltipTotal = "Total:"
L.TooltipDelimiter = ", "
L.Search = "Search"
L.Tokens = "Tokens"
L.Profiles = "Profiles"
L.Professions = "Professions"
L.Blacklist = "Blacklist"
L.Gold = "Gold"
L.Close = "Close"
L.FixDB = "FixDB"
L.Config = "Config"
L.DeleteWarning = "Select a profile to delete.\nNOTE: This is irreversible!"
L.Delete = "Delete"
L.Confirm = "Confirm"
L.ToggleSearch = "Toggle Search"
L.ToggleTokens = "Toggle Tokens"
L.ToggleProfiles = "Toggle Profiles"
L.ToggleProfessions = "Toggle Professions"
L.ToggleBlacklist = "Toggle Blacklist"
L.FixDBComplete = "A FixDB has been performed on BagSync!  The database is now optimized!"
L.ON = "ON"
L.OFF = "OFF"
L.LeftClickSearch = "Left Click = Search Window"
L.RightClickBagSyncMenu = "Right Click = BagSync Menu"
L.LeftClickViewTradeSkill = "Left Click = Link to view tradeskill."
L.RightClickInsertTradeskill = "Right Click = Insert tradeskill link."
L.ClickViewProfession = "Click to view profession: "
L.ClickHere = "Click Here"
L.ErrorUserNotFound = "BagSync: Error user not found!"
L.EnterItemID = "Please enter an itemid. (Use Wowhead.com)"
L.AddItemID = "Add ItemID"
L.RemoveItemID = "Remove ItemID"
-- ----THESE ARE FOR SLASH COMMANDS
L.SlashItemName = "[itemname]"
L.SlashSearch = "search"
L.SlashGold = "gold"
L.SlashConfig = "config"
L.SlashTokens = "tokens"
L.SlashFixDB = "fixdb"
L.SlashProfiles = "profiles"
L.SlashProfessions = "professions"
L.SlashBlacklist = "blacklist"
------------------------
L.HelpSearchItemName = "/bgs [itemname] - Does a quick search for an item"
L.HelpSearchWindow = "/bgs search - Opens the search window"
L.HelpGoldTooltip = "/bgs gold - Displays a tooltip with the amount of gold on each character."
L.HelpTokensWindow = "/bgs tokens - Opens the tokens/currency window."
L.HelpProfilesWindow = "/bgs profiles - Opens the profiles window."
L.HelpFixDB = "/bgs fixdb - Runs the database fix (FixDB) on BagSync."
L.HelpConfigWindow = "/bgs config - Opens the BagSync Config Window"
L.HelpProfessionsWindow = "/bgs professions - Opens the professions window."
L.HelpBlacklistWindow = "/bgs blacklist - Opens the blacklist window."
L.EnableBagSyncTooltip = "Enable BagSync Tooltips"
L.DisplayTotal = "Display [Total] amount."
L.DisplayGuildName = "Display [Guild Name] for guild bank items."
L.DisplayGuildBank = "Display guild bank items."
L.DisplayMailbox = "Display mailbox items."
L.DisplayAuctionHouse = "Display auction house items."
L.DisplayMinimap = "Display BagSync minimap button."
L.DisplayFaction = "Display items for both factions (Alliance/Horde)."
L.DisplayClassColor = "Display class colors for characters."
L.DisplayTooltipOnlySearch = "Display BagSync tooltip ONLY in the search window."
L.DisplayLineSeperator = "Display empty line seperator."
L.DisplayCrossRealm = "Display Cross-Realms characters."
L.DisplayBNET = "Display Battle.Net Account characters |cFFDF2B2B(Not Recommended)|r."
L.ColorPrimary = "Primary BagSync tooltip color."
L.ColorSecondary = "Secondary BagSync tooltip color."
L.ColorTotal = "BagSync [Total] tooltip color."
L.ColorGuild = "BagSync [Guild] tooltip color."
L.ColorCrossRealm = "BagSync [Cross-Realms] tooltip color."
L.ColorBNET = "BagSync [Battle.Net] tooltip color."
L.ConfigHeader = "Settings for various BagSync features."
L.ConfigDisplay = "Display"
L.ConfigTooltipHeader = "Settings for the displayed BagSync tooltip information."
L.ConfigColor = "Color"
L.ConfigColorHeader = "Color settings for BagSync tooltip information."
L.ConfigMain = "Main"
L.ConfigMainHeader = "Main settings for BagSync."
L.WarningItemSearch = "WARNING: A total of [%d] items were not searched!\nBagSync is still waiting for the server/cache to respond.\nPress the Search button again to retry."
L.WarningUpdatedDB = "You have been updated to latest database version!  You will need to rescan all your characters again!|r"
