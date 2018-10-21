-- FuBar support.  Original version written by A. Nolan et al
-- Modified by John Stephen for integration into Outfitter and for Ace3 compatibility

if not Rock or not IsAddOnLoaded("FuBar") then
	return
end

Outfitter._Fu = {}

function Outfitter._Fu:_New()
	return Rock:NewAddon("OutfitterFu", "LibFuBarPlugin-3.0", "LibRockEvent-1.0", "LibRockConfig-1.0", "LibRockDB-1.0")
end

function Outfitter._Fu:_Construct()
	-- create the plugin object and configure
	
	self.version = Outfitter.cVersion
	self.date = ""
	self:SetFuBarOption("hasIcon", true)
	self:SetFuBarOption("iconPath", "Interface\\AddOns\\Outfitter\\Textures\\Icon")
	self:SetFuBarOption('clickableTooltip', true)
	self:SetFuBarOption('tooltipType', "Tablet-2.0")
	
	-- library access
	
	self.Tablet = AceLibrary("Tablet-2.0")
	
	-- static properties
	
	self.BANKED_FONT_COLOR = {r = 0.25, g = 0.2, b = 1.0}
	self.BANKED_FONT_COLOR_CODE = '|cff4033ff'
	self.textLengthLowerBound = 4
	self.textLengthUpperBound = 40
	
	self:SetDatabase("OutfitterFuDB")
	self:SetDatabaseDefaults("profile",
	{
		hiddenCategories = {},
		hideMissing = false,
		removePrefixes = false,
		maxTextLength = self.textLengthUpperBound,
	})
end


-- event hook registered with Outfitter

function Outfitter._Fu:OutfitEvent(pEvent, pOutfitName, pOutfit)
   self:UpdateFuBarPlugin()
end

-- define options context menu

function Outfitter._Fu:OnInitialize()
	local options =
	{
		name = "Outfitter",
		desc = self.notes,
		type = 'group',
		args =
		{
			hideMissing =
			{
				order = 10,
				name = Outfitter.cFuHideMissing,
				desc = Outfitter.cFuHideMissingDesc,
				type = 'toggle',
				get = "HideMissing",
				set = "SetHideMissing",
			},
			removePrefixes =
			{
				order = 20,
				name = Outfitter.cFuRemovePrefixes,
				desc = Outfitter.cFuRemovePrefixesDesc,
				type = 'toggle',
				get = "RemovePrefixes",
				set = "SetRemovePrefixes",
			},
			maxTextLength =
			{
				order = 30,
				name = Outfitter.cFuMaxTextLength,
				desc = Outfitter.cFuMaxTextLengthDesc,
				type = 'range',
				min = Outfitter._Fu.textLengthLowerBound,
				max = Outfitter._Fu.textLengthUpperBound,
				step = 1,
				get = "MaxTextLength",
				set = "SetMaxTextLength",
			},
			hideOutfitterMinimapIcon =
			{
				order = 40,
				name = Outfitter.cFuHideMinimapButton,
				desc = Outfitter.cFuHideMinimapButtonDesc,
				type = 'toggle',
				get = function() return not OutfitterMinimapButton:IsVisible() end,
				set = function(v) Outfitter:SetShowMinimapButton(not v) end,
			},
		}
	}
	self:SetConfigTable(options)
end

function Outfitter._Fu:HideMissing()
   return self.db.profile.hideMissing
end

function Outfitter._Fu:SetHideMissing(enabled)
   if enabled then
      self.db.profile.hideMissing = true
   else
      self.db.profile.hideMissing = false
   end
   self:OnUpdateFuBarTooltip()
end

function Outfitter._Fu:RemovePrefixes()
   return self.db.profile.removePrefixes
end

function Outfitter._Fu:SetRemovePrefixes(enabled)
   if enabled then
      self.db.profile.removePrefixes = true
   else
      self.db.profile.removePrefixes = false
   end
   self:UpdateText()
end

function Outfitter._Fu:MaxTextLength()
   return self.db.profile.maxTextLength
end

function Outfitter._Fu:SetMaxTextLength(length)
   if length > self.textLengthUpperBound then
      self.db.profile.maxTextLength = self.textLengthUpperBound
      return
   end
   if length < self.textLengthLowerBound then
      self.db.profile.maxTextLength = self.textLengthLowerBound
      return
   end
   self.db.profile.maxTextLength = length
   self:UpdateText()
end

-- registers event callbacks with Outfitter and WoW

function Outfitter._Fu:OnEnable()
   Outfitter:RegisterOutfitEvent('OUTFITTER_INIT', function (...) self:OutfitEvent(...) end)
   Outfitter:RegisterOutfitEvent('WEAR_OUTFIT', function (...) self:OutfitEvent(...) end)
   Outfitter:RegisterOutfitEvent('UNWEAR_OUTFIT', function (...) self:OutfitEvent(...) end)
   
   self:AddEventListener('PLAYER_ENTERING_WORLD', 'UpdateFuBarPlugin')
   self:AddEventListener('ZONE_CHANGED_NEW_AREA', 'UpdateFuBarPlugin')
   self:AddEventListener('BANKFRAME_OPENED', 'UpdateFuBarPlugin')
   self:AddEventListener('BANKFRAME_CLOSED', 'UpdateFuBarPlugin')
end

function Outfitter._Fu:SetBoundedText(colorCode, text)
   local t = text
   if self:RemovePrefixes() then
      local replacements = 0
      t, replacements = t:gsub("^%a+:%s+", "")
   end
   local length = t:len()
   local maxLength = self:MaxTextLength()
   if length > maxLength then
      t = t:sub(1, maxLength - 3) .. '...'
   end
   self:SetFuBarText(colorCode .. t .. '|r')
end

-- updates text in FuBar

function Outfitter._Fu:OnUpdateFuBarText()
   if not Outfitter:IsInitialized() then
      self:SetBoundedText(NORMAL_FONT_COLOR_CODE, Outfitter.cFuInitializing)
      return
   end
   
   local name, vOutfit = Outfitter:GetCurrentOutfitInfo()
   local vEquippableItems = Outfitter.ItemList_GetEquippableItems()
   local vMissingItems, vBankedItems = Outfitter.ItemList_GetMissingItems(vEquippableItems, vOutfit)

   local vItemColor = NORMAL_FONT_COLOR_CODE
   if vMissingItems then
      vItemColor = RED_FONT_COLOR_CODE
   elseif vBankedItems then
      vItemColor = self.BANKED_FONT_COLOR_CODE
   end
   
   self:SetBoundedText(vItemColor, name)
end

-- updates FuBar tooltip

function Outfitter._Fu:OnUpdateFuBarTooltip()
   if not Outfitter:IsInitialized() then
      self.Tablet:AddCategory():AddLine('text', Outfitter.cFuInitializing)
      return
   end
   
   -- self.Tablet:SetHint(Outfitter.cFuHint)
	
	local vEquippableItems = Outfitter.ItemList_GetEquippableItems()
	local vCategoryOrder = Outfitter:GetCategoryOrder()
	local category

	for vCategoryIndex, vCategoryID in ipairs(vCategoryOrder) do
		local vCategoryName = Outfitter["c"..vCategoryID.."Outfits"]
		local vOutfits = Outfitter:GetOutfitsByCategoryID(vCategoryID)
      
		if Outfitter:HasVisibleOutfits(vOutfits) then
			category = self.Tablet:AddCategory(
					'id', vCategoryID,
					'text', vCategoryName,
					'textR', 1,
					'textG', 1,
					'textB', 1,
					'hideBlankLine', true,
					'showWithoutChildren', true,
					'hasCheck', true,
					'checked', true,
					'checkIcon', self.db.profile.hiddenCategories[vCategoryID] and 'Interface\\Buttons\\UI-PlusButton-Up' or 'Interface\\Buttons\\UI-MinusButton-Up',
					'func', 'ToggleCategory',
					'arg1', self,
					'arg2', vCategoryID,
					'child_func', 'OutfitClick',
					'child_arg1', self)
     
			if (not self.db.profile.hiddenCategories[vCategoryID]) then
				for vIndex, vOutfit in ipairs(vOutfits) do
					if Outfitter:OutfitIsVisible(vOutfit) then
						local vMissingItems, vBankedItems = Outfitter.ItemList_GetMissingItems(vEquippableItems, vOutfit)
						
						if not vMissingItems or not self:HideMissing() then
							local vWearingOutfit = Outfitter:WearingOutfit(vOutfit)
							local vItemColor = NORMAL_FONT_COLOR
							
							if vMissingItems then
								vItemColor = RED_FONT_COLOR
								elseif vBankedItems then
								vItemColor = self.BANKED_FONT_COLOR
							end
							
							category:AddLine(
									'text', ' ' .. vOutfit.Name,
									'textR', vItemColor.r,
									'textG', vItemColor.g,
									'textB', vItemColor.b,
									'arg2', {CategoryID = vCategoryID, Index = vIndex},
									'hasCheck', true,
									'checked', vWearingOutfit,
									'indentation', 12)
						end
					end
				end
			end
		end
	end
end

-- callback for tooltip menu category click

function Outfitter._Fu:ToggleCategory(id, button)
   if self.db.profile.hiddenCategories[id] then
      self.db.profile.hiddenCategories[id] = false
   else
      self.db.profile.hiddenCategories[id] = true
   end
   
   self:OnUpdateFuBarTooltip()
end

-- callback for tooltip menu outfit click

function Outfitter._Fu:OutfitClick(outfitRef, button)
   Outfitter.MinimapButton_ItemSelected(nil, outfitRef)
   self:UpdateFuBarPlugin()
end

-- toggles the Outfitter frame

function Outfitter._Fu:OnClick()
	Outfitter:ToggleUI(true)
end

Outfitter.Fu = Outfitter:New(Outfitter._Fu)
