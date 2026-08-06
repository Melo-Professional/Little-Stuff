#Requires AutoHotkey v2.0

; Global configuration storage
global NavControls := []
global GlobalFontSizeBig := 0
global GlobalFontSizeMedium := 0
global GlobalSettingsFontName := ""
global GlobalThemeColors := Map()
global ActiveTabIndex := 1
global ActiveHelpGuiHwnd := 0
global AllHelpGuiGroups := []

ShowHelpGUI() {
    global NavControls, GlobalFontSizeBig, GlobalFontSizeMedium, GlobalSettingsFontName, GlobalThemeColors, ActiveTabIndex, ActiveHelpGuiHwnd, AllHelpGuiGroups
    
    MyGui := Gui("+LastFound", App.Name " - Hotkey Guide")
    ActiveHelpGuiHwnd := MyGui.Hwnd
    
    fontSizeSmall    := Settings.GuiFontSizeSmall + 1
    fontSizeMedium   := Settings.GuiFontSizeMedium + 1
    fontSizeBig      := Settings.GuiFontSizeBig + 0
    fontSizeExtraBig := Settings.GuiFontSizeExtraBig + 0
    
    GlobalFontSizeBig := fontSizeBig
    GlobalFontSizeMedium := fontSizeMedium
    GlobalSettingsFontName := Settings.GuiFontName
    ActiveTabIndex := 1
    
    guiWidth := 960
    guiWidth := 780
    contentWidth := guiWidth - 100 
    
    colors := Settings.Theme.%CurrentActualTheme%
    GlobalThemeColors := colors
    MyGui.SetFont("s" fontSizeMedium, Settings.GuiFontName)

    ; ==========================================
    ; --- CUSTOM THEME-FRIENDLY NAVIGATION ---
    ; ==========================================
    Nav1 := MyGui.Add("Text", "x50 y20 w180 h35 +Center +BackgroundTrans", "Window Mgmt")
    Nav2 := MyGui.Add("Text", "x240 y20 w240 h35 +Center +BackgroundTrans", "Loupe & Navigation")
    Nav3 := MyGui.Add("Text", "x490 y20 w180 h35 +Center +BackgroundTrans", "Tabs & System")

    Nav1.Opt("+0x80")
    Nav2.Opt("+0x80")
    Nav3.Opt("+0x80")

    Nav1.BypassTheme := true
    Nav2.BypassTheme := true
    Nav3.BypassTheme := true

    NavControls := [Nav1, Nav2, Nav3]
    
    Nav1.OnEvent("Click", (*) => SwitchTab(1))
    Nav2.OnEvent("Click", (*) => SwitchTab(2))
    Nav3.OnEvent("Click", (*) => SwitchTab(3))

    Group1 := [], Group2 := [], Group3 := []

    ; ==========================================
    ; --- TAB 1 CONTENT: WINDOW MANAGEMENT ---
    ; ==========================================
    Group1.Push(AddSectionHeader(MyGui, "Always On Top and Transparency", contentWidth, fontSizeExtraBig, colors, "x50 y80"))
    for ctrl in AddHotkeyRow(MyGui, "Alt + WheelUp", "AOT on + transparency.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y130")
        Group1.Push(ctrl)
    for ctrl in AddHotkeyRow(MyGui, "Win+ Alt + WheelDown", "AOT off + transparency.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y165")
        Group1.Push(ctrl)
    
    Group1.Push(AddSectionHeader(MyGui, "Snap, Drag and Resize", contentWidth, fontSizeExtraBig, colors, "x50 y230"))
    for ctrl in AddHotkeyRow(MyGui, "Hold MButton + LButton + Move", "Drag a window.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y280")
        Group1.Push(ctrl)
    for ctrl in AddHotkeyRow(MyGui, "Hold MButton + RButton + Move", "Resize a window.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y315")
        Group1.Push(ctrl)
    
    for ctrl in AddHotkeyRow(MyGui, "Hold MButton + LButton + Release", "Send window to the LEFT monitor.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y350")
        Group1.Push(ctrl)
    for ctrl in AddHotkeyRow(MyGui, "Hold MButton + RButton + Release", "Send window to the RIGHT monitor.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y385")
        Group1.Push(ctrl)

    ; ==========================================
    ; --- TAB 2 CONTENT: LOUPE & NAVIGATION ---
    ; ==========================================
    Group2.Push(AddSectionHeader(MyGui, "The Loupe (Screen Magnifier)", contentWidth, fontSizeExtraBig, colors, "x50 y80"))
    for ctrl in AddHotkeyRow(MyGui, "Win + WheelUp", "Activate magnifying glass lens / Zoom In", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y130")
        Group2.Push(ctrl)
    for ctrl in AddHotkeyRow(MyGui, "Win + WheelDown", "Zoom Out / Deactivate magnifying glass lens.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y165")
        Group2.Push(ctrl)
    
    Group2.Push(AddSectionHeader(MyGui, "Current Monitor Desktop", contentWidth, fontSizeExtraBig, colors, "x50 y230"))
    for ctrl in AddHotkeyRow(MyGui, "Win + D", "Minimize / Restore on the CURRENT monitor only.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y280")
        Group2.Push(ctrl)

    ; ==========================================
    ; --- TAB 3 CONTENT: TABS & SYSTEM ---
    ; ==========================================
    Group3.Push(AddSectionHeader(MyGui, "Cycle Tabs Wheel (CTW)", contentWidth, fontSizeExtraBig, colors, "x50 y80"))
    for ctrl in AddHotkeyRow(MyGui, "Hover Titlebar + Wheel", "Scroll through tabs in Chrome, Firefox, File Explorer, etc.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y130")
        Group3.Push(ctrl)
    
    Group3.Push(AddSectionHeader(MyGui, "System Utilities and Fixes", contentWidth, fontSizeExtraBig, colors, "x50 y195"))
    for ctrl in AddHotkeyRow(MyGui, "Caps + Shift + (Typing)", "Triggers warning alert if CapsLock is accidentally active.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y245")
        Group3.Push(ctrl)
    for ctrl in AddHotkeyRow(MyGui, "Ctrl + Alt + C", "Triggers the 'Compare' action palette sequence in VSCodium.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y280")
        Group3.Push(ctrl)

    for ctrl in AddHotkeyRow(MyGui, "Desktop double click", "Toggles desktop icons visibility.", contentWidth, fontSizeBig, fontSizeMedium, colors, "x55 y315")
        Group3.Push(ctrl)

    AllHelpGuiGroups := [Group1, Group2, Group3]

    ; Bottom Buttons
    MyGui.SetFont("s" fontSizeMedium " w400", Settings.GuiFontName)
    btnX := guiWidth - 160
    
;    CloseBtn := MyGui.Add("Button", "x" btnX " y645 w150 h44 Default", "&Close")
    CloseBtn := MyGui.Add("Button", "x" btnX " y445 w120 h34 Default", "&Close")
    CloseBtn.Opt("+0x80")
    CloseBtn.OnEvent("Click", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)
    
    ; Initialize visible fields
    SwitchTab(1)
    
    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)
    MyGui.Show("w" guiWidth " h520")

    ; Bind global event messages
    OnMessage(0x0200, OnMouseMove)
    OnMessage(0x001A, OnSettingChange) ; WM_SETTINGCHANGE: Triggers right when Windows changes themes

    SwitchTab(tabIndex) {
        ActiveTabIndex := tabIndex
        ForceTextThemeUpdate()
    }

    CleanDestroy(*) {
        OnMessage(0x0200, OnMouseMove, 0)
        OnMessage(0x02A3, OnMouseLeave, 0)
        OnMessage(0x001A, OnSettingChange, 0)
        ActiveHelpGuiHwnd := 0
        RemoveGuiFromArray(MyGui)
        MyGui.Destroy()
    }
}

; ==================================================
; --- FORCE INDEPENDENT TEXT COLOR REPAINT ENGINE ---
; ==================================================
ForceTextThemeUpdate() {
    global NavControls, ActiveTabIndex, AllHelpGuiGroups, GlobalFontSizeBig, GlobalFontSizeMedium
    
    ; Pause briefly (50ms) to allow your framework to complete its work before we force the overwrite
    Sleep(50)
    
    currentColors := Settings.Theme.%CurrentActualTheme%
    
    for gIdx, groupArray in AllHelpGuiGroups {
        isVisibleTab := (gIdx == ActiveTabIndex)
        for ctrl in groupArray {
            ctrl.Visible := isVisibleTab
            if (isVisibleTab) {
                if (ctrl.HasProp("IsHeader") && ctrl.IsHeader) {
                    ctrl.SetFont("c" currentColors.TextStrong)
                } else if (ctrl.HasProp("IsHotkey") && ctrl.IsHotkey) {
                    ctrl.SetFont("c" currentColors.TextDefault)
                } else {
                    ctrl.SetFont("c" currentColors.TextDefault)
                }
                ctrl.Redraw()
            }
        }
    }
        
    NavControls[1].SetFont(ActiveTabIndex == 1 ? "s" GlobalFontSizeBig " w700 c" currentColors.TextStrong : "s" GlobalFontSizeMedium " w400 c" currentColors.TextDefault, GlobalSettingsFontName)
    NavControls[2].SetFont(ActiveTabIndex == 2 ? "s" GlobalFontSizeBig " w700 c" currentColors.TextStrong : "s" GlobalFontSizeMedium " w400 c" currentColors.TextDefault, GlobalSettingsFontName)
    NavControls[3].SetFont(ActiveTabIndex == 3 ? "s" GlobalFontSizeBig " w700 c" currentColors.TextStrong : "s" GlobalFontSizeMedium " w400 c" currentColors.TextDefault, GlobalSettingsFontName)
    
    NavControls[1].Redraw(), NavControls[2].Redraw(), NavControls[3].Redraw()
}

; Intercept the native Windows OS message loop when system settings alter
OnSettingChange(wParam, lParam, msg, hwnd) {
    global ActiveHelpGuiHwnd
    ; Only fire if our specific guide window handle is up on screen
    if (ActiveHelpGuiHwnd && WinExist(ActiveHelpGuiHwnd)) {
        ForceTextThemeUpdate()
    }
}

; ==================================================
; --- SYSTEM HOVER CORE INTERCEPT MOTOR ROUTINES ---
; ==================================================
OnMouseMove(wParam, lParam, msg, hwnd) {
    global NavControls, ActiveTabIndex
    static isHovering := false

    isTargetNav := false
    targetIdx := 0
    
    for idx, ctrl in NavControls {
        if (hwnd == ctrl.Hwnd) {
            isTargetNav := true
            targetIdx := idx
            break
        }
    }

    if (isTargetNav) {
        if (!isHovering) {
            isHovering := true
            liveColors := Settings.Theme.%CurrentActualTheme%
            
            if (targetIdx != ActiveTabIndex) {
                NavControls[targetIdx].SetFont("c" liveColors.TextStrong)
                NavControls[targetIdx].Redraw()
            }

            TME := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
            NumPut("UInt", TME.Size, TME, 0)
            NumPut("UInt", 2,        TME, 4)
            NumPut("Ptr",  hwnd,     TME, 8)
            DllCall("User32\TrackMouseEvent", "Ptr", TME)
            
            OnMessage(0x02A3, OnMouseLeave)
        }
        DllCall("User32\SetCursor", "Ptr", DllCall("User32\LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
    } else {
        isHovering := false
    }
}

OnMouseLeave(wParam, lParam, msg, hwnd) {
    global NavControls, ActiveTabIndex
    
    OnMessage(0x02A3, OnMouseLeave, 0)
    liveColors := Settings.Theme.%CurrentActualTheme%
    
    for idx, ctrl in NavControls {
        if (hwnd == ctrl.Hwnd && idx != ActiveTabIndex) {
            ctrl.SetFont("c" liveColors.TextDefault)
            ctrl.Redraw()
            break
        }
    }
}

; ==========================================
; --- STRUCTURAL HELPERS ---
; ==========================================
AddSectionHeader(GuiObj, HeaderText, width, fontSize, colors, position) {
    GuiObj.SetFont("s" fontSize " w700 c" colors.TextStrong, GlobalSettingsFontName)
    txtCtrl := GuiObj.Add("Text", "w" width " " position " +Left +BackgroundTrans", HeaderText)
    txtCtrl.Opt("+0x80")
    txtCtrl.BypassTheme := true 
    txtCtrl.IsHeader := true
    return txtCtrl
}

AddHotkeyRow(GuiObj, HotkeyText, DescriptionText, width, keyFontSize, descFontSize, colors, position) {
    keyColWidth := 280 
    descColWidth := width - keyColWidth - 20
    
    RegExMatch(position, "i)x(\d+)\s+y(\d+)", &match)
    posX := Integer(match[1])
    posY := Integer(match[2])
    
    descX := posX + keyColWidth + 20

    GuiObj.SetFont("s" keyFontSize " w700 c" colors.TextDefault, GlobalSettingsFontName) 
    keyCtrl := GuiObj.Add("Text", "x" posX " y" posY " w" keyColWidth " r1 +BackgroundTrans", HotkeyText) 
    keyCtrl.Opt("+0x80")
    keyCtrl.BypassTheme := true
    keyCtrl.IsHotkey := true
    
    GuiObj.SetFont("s" descFontSize " w400 c" colors.TextDefault, GlobalSettingsFontName) 
    descCtrl := GuiObj.Add("Text", "x" descX " y" posY " w" descColWidth " r1 +BackgroundTrans", DescriptionText)
    descCtrl.Opt("+0x80")
    descCtrl.BypassTheme := true
    descCtrl.IsDescription := true
    
    return [keyCtrl, descCtrl]
}