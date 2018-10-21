if not IsAddOnLoaded("Titan") or IsAddOnLoaded("TitanOutfitter") then return end

Outfitter._TitanPlugin = {}

Outfitter._TitanPlugin.TitanID = "Outfitter"
Outfitter._TitanPlugin.TooltipHints = "Hint: Left-click to open Outfitter or Right-click to choose a new outfit"

function Outfitter._TitanPlugin:_New()
	local vParentFrame = CreateFrame("Frame", nil, UIParent)
	
	return CreateFrame("Button", "TitanPanelOutfitterButton", vParentFrame, "TitanPanelComboTemplate")
end

function Outfitter._TitanPlugin:_Construct()
	self:SetFrameStrata("FULLSCREEN")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnClick", self.OnClick)

	self.registry =
	{
		id = self.TitanID,
		version = Outfitter.cVersion,
		menuText = Outfitter.cTitle,
		category = "Interface",
		buttonTextFunction = "TitanPanelOutfitterButton_GetButtonText", 
		tooltipTitle = Outfitter.cTitle, 
		tooltipTextFunction = "TitanPanelOutfitterButton_GetTooltipText", 
		icon = "Interface\\Addons\\Outfitter\\Textures\\Icon",
		iconWidth = 16,
		savedVariables =
		{
			ShowIcon = 1,
			ShowLabelText = 1,
		},
	}
	
    Outfitter:RegisterOutfitEvent("WEAR_OUTFIT", function (...) self:OutfitEvent(...) end)
    Outfitter:RegisterOutfitEvent("UNWEAR_OUTFIT", function (...) self:OutfitEvent(...) end)
    Outfitter:RegisterOutfitEvent("OUTFITTER_INIT", function (...) self:OutfitEvent(...) end)
    
	TitanPanelButton_OnLoad(self)
end

function Outfitter._TitanPlugin:OutfitEvent(pEvent, pOutfitName, pOutfit)
	TitanPanelButton_UpdateButton(self.TitanID)
	
	-- Update the menu if it's currently shown
	
	if UIDROPDOWNMENU_OPEN_MENU == "TitanPanelOutfitterButtonRightClickMenu" then
		UIDropDownMenu_Initialize(TitanPanelOutfitterButtonRightClickMenu, TitanPanelRightClickMenu_PrepareOutfitterMenu, "MENU")
	end
end

function Outfitter._TitanPlugin:OnEvent()
end

function Outfitter._TitanPlugin:OnClick(pButton)
	if pButton == "LeftButton" then
		Outfitter:ToggleUI(true)
	end
	
	TitanPanelButton_OnClick(self, pButton)
end

function TitanPanelRightClickMenu_PrepareOutfitterMenu()
	local	vFrame = getglobal(UIDROPDOWNMENU_INIT_MENU)
	
	vFrame.ChangedValueFunc = Outfitter.MinimapButton_ItemSelected
	Outfitter.MinimapDropDown_InitializeOutfitList()

	Outfitter:AddCategoryMenuItem(TITAN_PANEL)
	TitanPanelRightClickMenu_AddToggleIcon(Outfitter.TitanPlugin.TitanID)
	TitanPanelRightClickMenu_AddToggleLabelText(Outfitter.TitanPlugin.TitanID)
	-- TitanPanelRightClickMenu_AddToggleColoredText(Outfitter.TitanPlugin.TitanID)
	TitanPanelRightClickMenu_AddSpacer();	
	TitanPanelRightClickMenu_AddCommand(TITAN_PANEL_MENU_HIDE, Outfitter.TitanPlugin.TitanID, TITAN_PANEL_MENU_FUNC_HIDE)
end

function TitanPanelOutfitterButton_GetButtonText()
	local	vCurrentOutfitName = Outfitter:GetCurrentOutfitInfo()
	
	if (TitanGetVar(Outfitter.TitanPlugin.TitanID, "ShowLabelText")) then	
		return Outfitter.cTitle..": ", HIGHLIGHT_FONT_COLOR_CODE..vCurrentOutfitName..FONT_COLOR_CODE_CLOSE
	else
		return nil, HIGHLIGHT_FONT_COLOR_CODE..vCurrentOutfitName..FONT_COLOR_CODE_CLOSE
	end
end

function TitanPanelOutfitterButton_GetTooltipText()
	return TitanUtils_GetGreenText(Outfitter.TitanPlugin.TooltipHints)
end

Outfitter.TitanPlugin = Outfitter:New(Outfitter._TitanPlugin)
