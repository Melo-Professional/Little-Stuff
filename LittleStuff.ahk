;@region Setup
;@region Description
/************************************************************************
 * @description A bundle of little snippets, because Power Toys sucks.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/25
 * @releasedate 2026/06/06
 * @version 1.8.2.105
 ***********************************************************************/

AppName := "Little Stuff"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.8.2.105"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "A bundle of little snippets, because Power Toys sucks."
;@endregion

;_bkpMode := "AppVersionAndMinutes"

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
A_MenuMaskKey := "vkFF"
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
; --- Optimization Settings ---
;ProcessSetPriority("High")
ListLines(False)
KeyHistory(0)
A_MaxHotkeysPerInterval := 5000
A_HotkeyInterval := 1000
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Backup>
#Include *i <_SaveSettings>
#Include *i <_Config&Vars>
#Include *i <_HelperFuncs>
#Include *i <_Theme>
;#Include *i <_FrostedTheme>
;#Include *i <_TitleBar>
#Include *i <_GuiTracker>
;#Include *i <_ModernSlider>
;#Include *i <_Color_Picker_Dialog>
;#Include *i <_ReloadWithArgs>
;#Include *i <_HotkeysRecorder>
;#Include *i <_ODColors>
#Include *i <_OSDCustom>
#Include *i <_AutoUpdater>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>

#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <InternetConnectivityMonitor>
#Include <Loupe>
#Include <SnapDragResize>
#Include <MouseCrosshair>
#Include <DesktopIcons>
#Include <_SelectFileOrFolder>
#Include <IntegrityCheck>
#Include *i .\.private\zzz_Melo_LittleStuff.ahk
#Include *i <Help>

;@endregion

;@region Startup
if !A_Args.Length {
	if IsSet(SplashScreen) {
	    SplashScreen()
	} else if isSet(SplashScreenOSD) {
		SplashScreenOSD()
	}
}

IsSet(StartMenu) ? StartMenu() : 0
IsSet(Menu_Custom) ? Menu_Custom() : 0
IsSet(StartAutoUpdater) ? StartAutoUpdater() : 0
;@endregion
;@endregion

if IsSet(Menu_Custom2) && priv{
    Menu_Custom2()
}
;throw Error('Message', A_ThisFunc, )
;a := "test"
;OutputDebug(a) ; debug tab
;Menu_Custom()
;^p::Reload()


;@region InternetMonitor
InternetConnectivityMonitorStart()

InternetConnectivityMonitorStart(){
    if !(Snippets.InternetMonitor){
        InternetConnectivityMonitor.onEvent(onInternetConnectivityChanged, 0)
        return
    }

    InternetConnectivityMonitor.onEvent(onInternetConnectivityChanged)

    OSDIM := OSDCustom()
    OSDIM.Position := "x0.5 y0.9"
    text := OSDIM.SetCellText(1,1," ", "Center",{FontWeight: 1000})

    InternetMonitorCheckNow()

    InternetMonitorCheckNow(){
        connectivity := InternetConnectivityMonitor.isConnected()
        onInternetConnectivityChanged(connectivity)
    }  

    onInternetConnectivityChanged(connectivity){
        if !(Snippets.InternetMonitor)
            return

        static previewsconnectivity := ""

        CurrentTime := FormatTime(, "HH:mm:ss")
        if connectivity {
                OSDIM.UpdateTextObject(text, "ONLINE")
                OSDIM.Show(,, 3000)
            if previewsconnectivity != ""
                ;DllCall("user32\MessageBeep", "uint", 0x10)
                SoundPlayWin("Windows Notify")
        } else {
                OSDIM.UpdateTextObject(text, CurrentTime " - OFFLINE", 0)
                OSDIM.Show(,,0)
;            DllCall("user32\MessageBeep", "uint", 0x30)
            SoundPlayWin("Windows Balloon")

        }
        previewsconnectivity := connectivity
    }
}
;@endregion


;@region AlwaysOnTop
#HotIf (Snippets.AlwaysOnTop)
#!WheelUp:: AOT_Core(-25)
#!WheelDown:: AOT_Core(25)
#HotIf

AOTStartOSD()

AOTStartOSD() {
    Global AOTImage
    if !(Snippets.AlwaysOnTop){
        return
    }
    unpin := A_ScriptDir "\assets\images\unpin.png"
    pin := A_ScriptDir "\assets\images\pin.png"
    Global OSDAOT
    OSDAOT := OSDCustom()
    OSDAOT.Position := "x0.92 y0.0"
    OSDAOT.TimeOut := 5000
    OSDAOT.MinWidth := 5
    OSDAOT.MarginX := 5
    OSDAOT.MarginY := 10
    try AOTImage := OSDAOT.SetCellImage(1,1, unpin,,20)
}

; --- Core Worker Function ---
AOT_Core(step := 0) {
    Global AOTImage
    MouseGetPos ,, &targetWindow
    
    pin := A_ScriptDir "\assets\images\pin.png"
    unpin := A_ScriptDir "\assets\images\unpin.png"

    currentTrans := 255
    try {
        ret := WinGetTransparent(targetWindow)
        if (ret != "")
            currentTrans := ret
    }

    isAOT := IsAlwaysOnTop(targetWindow)

    ; 2. Determine Action based on Direction and Current State
    ; Note: Negative step = WheelUp, Positive step = WheelDown
    
    if (step < 0) { ; --- SCROLL UP ---
        if (isAOT) {
            ; Case A: Already AOT, make it more transparent (dimmer)
            newTrans := Max(30, currentTrans - 25)
            try WinSetTransparent(newTrans, targetWindow)
        } else if (currentTrans < 255) {
            ; Case B: Normal window currently dimmed. Scroll up brings it back to solid.
            newTrans := currentTrans + 25
            if (newTrans >= 255) {
                ; Hits 255! Just make it completely solid. Do not turn on AOT yet.
                try WinSetTransparent("", targetWindow)
            } else {
                try WinSetTransparent(newTrans, targetWindow)
            }
        } else {
            ; Case C: Completely normal solid window. First scroll up ONLY locks AOT.
            WinSetAlwaysOnTop(1, targetWindow)
            DrawBorder(targetWindow, 0x00FFFF, 1)
            
			;Location := _Location(targetWindow)
            OSDAOT.ClearCells()
            Try AOTImage := OSDAOT.SetCellImage(1,1, pin,,20)
            ;OSDAOT.Show()
            OSDAOT.Show( , _Location(targetWindow))
            SoundPlayWin("Speech On")
        }
    } else { ; --- SCROLL DOWN ---
        if (isAOT) {
            if (currentTrans < 255) {
                ; Case D: AOT window being brightened back to solid
                newTrans := currentTrans + 25
                if (newTrans >= 255) {
                    ; Hits 255 solid. Strip transparency but KEEP AOT for this tick.
                    try WinSetTransparent("", targetWindow)
                } else {
                    try WinSetTransparent(newTrans, targetWindow)
                }
            } else {
                ; Case D-Extension: It is already 255 and AOT. One more scroll down removes AOT.
                WinSetAlwaysOnTop(0, targetWindow)
                DrawBorder(targetWindow, 0x00FFFF, 0)
                
                if OSDAOT.IsVisible {
                    Try OSDAOT.UpdateImageObject(AOTImage, unpin, 5000)
                } else {
                    OSDAOT.ClearCells()
                    Try AOTImage := OSDAOT.SetCellImage(1,1, unpin,,20)
                    ;OSDAOT.Show()
                    OSDAOT.Show( , _Location(targetWindow))
                }
                SoundPlayWin("Speech Sleep")
            }
        } else {
            ; Case E: Normal window being dimmed without AOT
            newTrans := Max(30, currentTrans - 25)
            try WinSetTransparent(newTrans, targetWindow)
        }
    }

	IsAlwaysOnTop(hwnd) {
		try {
			exStyle := WinGetExStyle(hwnd)
			return exStyle & 0x8 ; Returns true if WS_EX_TOPMOST (0x8) flag is active
		}
		return false
	}

	DrawBorder(hwnd, c, e) {
		DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", 34, "int*",
		e ? (c & 0xFF) << 16 | c & 0xFF00 | c >> 16 & 0xFF : 0xFFFFFFFF, "int", 4)
	}

	_Location(hwnd) {
		WinGetPos &winX, &winY, &winW, &winH, hwnd
		paddingX := DPIScale(-30)
		paddingY := DPIScale(20)
		targetX_px := winX + winW + paddingX
		targetY_px := winY + paddingY
		return Format("x" targetX_px " y" targetY_px)
	}
}
;@endregion


;@region TheLoupe
;@credits https://github.com/The-CoDingman/The-Loupe/blob/main/The%20Loupe.ahk

#HotIf Snippets.TheLoupe
#WheelUp::LoupeHandler(1)
#WheelDown::LoupeHandler(-1)
#HotIf 

LoupeHandler(direction) {
    static loupefactor := 1.5
    static loupesize := 600
    loupefactorsteps := 1.5
    loupesizesteps := 1.1

    if (direction = -1) && (loupefactor <=2)
        return

    if (loupefactor == 1.5)
        SoundPlayWin(A_ScriptDir "\assets\audios\on_260702.wav")

    if (direction = 1) {
        loupefactor *= loupefactorsteps
        loupesize   *= loupesizesteps
    } else if (direction = -1) {
        loupefactor /= loupefactorsteps
        loupesize   /= loupesizesteps
    }

    loupesize := Round(loupesize)

    if (loupefactor <= 1.5) {
        SoundPlayWin(A_ScriptDir "\assets\audios\off_260702.wav")
        loupefactor := 1.5
        loupesize := 600
        Loupe.Stop()
        return
    }

    Loupe.Magnify(loupesize, loupefactor, 1, "00ffff")
;    Tooltip("Factor: " . loupefactor . "`nSize: " . loupesize)
}
;@endregion

#Hotif !A_IsCompiled
^p::ReloadClean()
#HotIf


;@region Win D
/*  WINDOWS + D = CURRENT MONITOR ONLY */
$#d:: {
    static HiddenWindows := Map()
    drama := 30
    
    CoordMode "Mouse", "Screen"
    DetectHiddenWindows False

    ; 1. Identify target monitor
    MouseGetPos &mouseX, &mouseY
    monitorCount := MonitorGetCount()
    targetMonitor := 1

    mLeft := 0, mTop := 0, mRight := 0, mBottom := 0

    Loop monitorCount {
        MonitorGet(A_Index, &curLeft, &curTop, &curRight, &curBottom)
        
        if (A_Index == 1) {
            mLeft := curLeft, mTop := curTop, mRight := curRight, mBottom := curBottom
        }

        if (mouseX >= curLeft && mouseX <= curRight && mouseY >= curTop && mouseY <= curBottom) {
            targetMonitor := A_Index
            mLeft := curLeft, mTop := curTop, mRight := curRight, mBottom := curBottom
            break
        }
    }

    if !HiddenWindows.Has(targetMonitor)
        HiddenWindows[targetMonitor] := []

    ; 2. Scan for visible windows on target monitor
    visibleWindowsOnMonitor := []
    
    for hwnd in WinGetList() {
        ; 1. FASTEST & HIGHEST ELIMINATION: Drop minimized windows
        try {
            if (WinGetMinMax("ahk_id " hwnd) == -1)
                continue
        } catch {
            continue
        }

        ; 2. VERY FAST BITWISE CHECK: Filter tool windows / popups
        try exStyle := WinGetExStyle("ahk_id " hwnd)
        catch
            continue

        if (exStyle & 0x00000080 && !(exStyle & 0x00040000)) ; WS_EX_TOOLWINDOW without WS_EX_APPWINDOW
            continue

        ; 3. STRING CHECKS
        try title := WinGetTitle("ahk_id " hwnd)
        catch
            continue

        if (title == "")
            continue

        try winClass := WinGetClass("ahk_id " hwnd)
        catch
            continue

        if (winClass == "Progman" || winClass == "WorkerW" 
            || winClass == "Shell_TrayWnd" || winClass == "Shell_SecondaryTrayWnd" 
            || winClass == "Windows.UI.Core.CoreWindow"
            || winClass == "ParsecOverlay")
            continue

        ; 4. HEAVY DLL CALL 1: Filter owned/child popups
        if DllCall("GetWindow", "ptr", hwnd, "uint", 4) && !(exStyle & 0x00040000) ; GW_OWNER = 4
            continue

        ; 5. HEAVY DLL CALL 2: Filter DWM Cloaked windows (Virtual Desktops / UWP)
        try {
            isCloaked := 0
            if (DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "uint*", &isCloaked, "uint", 4) == 0) {
                if (isCloaked)
                    continue
            }
        } catch {
        }

        ; 6. GEOMETRY CHECK
        try {
            WinGetPos &X, &Y, &W, &H, "ahk_id " hwnd
            winCenterX := X + (W / 2)
            winCenterY := Y + (H / 2)

            if (winCenterX >= mLeft && winCenterX <= mRight && winCenterY >= mTop && winCenterY <= mBottom) {
                visibleWindowsOnMonitor.Push(hwnd)
            }
        }
    }

    ; 3. Decision Logic
    ; IF VISIBLE WINDOWS EXIST: Always minimize them first
    if (visibleWindowsOnMonitor.Length > 0) {
        HiddenWindows[targetMonitor] := visibleWindowsOnMonitor
        
        for hwnd in visibleWindowsOnMonitor {
            try WinMinimize("ahk_id " hwnd)
        }

        try {
            if WinExist("ahk_class WorkerW") {
                WinActivate("ahk_class WorkerW")
                ControlFocus("SysListView321", "ahk_class WorkerW")
            } else if WinExist("ahk_class Progman") {
                WinActivate("ahk_class Progman")
                ControlFocus("SysListView321", "ahk_class Progman")
            }
        }
    } 
    ; IF NO VISIBLE WINDOWS: Check if we have stored windows to restore
    else if (HiddenWindows[targetMonitor].Length > 0) {
        Loop HiddenWindows[targetMonitor].Length {
            hwnd := HiddenWindows[targetMonitor][HiddenWindows[targetMonitor].Length - A_Index + 1]
            if WinExist("ahk_id " hwnd) {
                try WinRestore("ahk_id " hwnd)

                if A_Index > (HiddenWindows[targetMonitor].Length - 2)
                    drama += 220
                Sleep(drama)
            }
        }
        HiddenWindows[targetMonitor] := []
    }
}
;@endregion



;@region wRONG cAPS
/*
*   WARN wRONG cAPS
*/
global activeIH := ""
#HotIf GetKeyState("CapsLock", "T")
~Shift:: {
    global activeIH
    if (activeIH is InputHook && activeIH.InProgress) {
        activeIH.Stop()
    }
    activeIH := InputHook("L1 V")
    activeIH.Start()
    activeIH.Wait()

    if (activeIH.EndReason = "Max" && activeIH.Input != "" && IsAlpha(activeIH.Input)) {
        SoundPlayWin("Windows Default")
        if CaretGetPos(&caretX, &caretY) {
            ToolTip("wRONG cAPS", caretX, caretY - 25)
        } else {
            ToolTip("wRONG cAPS")
        }
        SetTimer(() => ToolTip(), -3500)
    }
}
~Shift Up:: {
    global activeIH
    if (activeIH is InputHook && activeIH.InProgress) {
        activeIH.Stop()
    }
}
#HotIf
;@endregion

;@region Cicle Tabs Wheel 
; CTW - Cicle Tabs Wheel
; ==============================================================================
; --- MOUSETABS RULES ---
; ==============================================================================
global TabAreaHeight    := 50    ; Height in pixels from the top of the window
global EnabledTabApps   := Map(
    "Chrome_WidgetWin_1", true,  ; Chrome, Edge, Brave, Opera, VS Code
    "MozillaWindowClass", true,  ; Firefox
    "Notepad++", true,           ; Notepad++
    "CabinetWClass", true        ; Windows 11 File Explorer
)

CheckCTW(){
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseXPos, &mouseYPos, &winId)
    Debug ? (ToolTip(" > 1000"), SetTimer(() => ToolTip(), -1000)) : ""
    
    try {
        winClass := WinGetClass("ahk_id " winId)
        WinGetPos(&winXPos, &winYPos, , , "ahk_id " winId)
        Debug ? (ToolTip(" Get pos"), SetTimer(() => ToolTip(), -1000)) : ""
        
        ; Verify application type and the horizontal boundary area
        if (EnabledTabApps.Has(winClass) && mouseYPos >= winYPos && mouseYPos <= (winYPos + TabAreaHeight)) {
            Debug ? (ToolTip(" APP SPOT"), SetTimer(() => ToolTip(), -1000)) : ""
            if !WinActive("ahk_id " winId) {
                WinActivate("ahk_id " winId)
            }
            return true
        }
    } catch {
        ; Fail-safe: continue to fallback if window elements are inaccessible
    }
    return false
}

#HotIf (Snippets.CicleTabsWheel) && CheckCTW()
WheelUp::{
    RunCTW(1)
}
WheelDown::{
    RunCTW(-1)
}
#HotIf

RunCTW(Direction) {
    Send(Direction > 0 ? "{Blind}^{PgUp}" : "{Blind}^{PgDn}")    
}
;@endregion

;@region VSCode Compare
/* VS Codium - compare - ctrl + alt + c */
#HotIf WinActive("ahk_exe VSCodium.exe")

^!c:: {
    Send("^+p")
    Sleep(350)
    Send("compare")
    Sleep(150)
    Send("{Enter}")
}

#HotIf
;@endregion
