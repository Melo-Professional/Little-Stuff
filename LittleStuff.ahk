;@region Setup
;@region Description
/************************************************************************
 * @description A bundle of little snippets, because Power Toys sucks.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/12
 * @releasedate 2026/06/06
 * @version 1.7.0.0
 ***********************************************************************/

AppName := "Little Stuff"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.7.0.0"
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
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_Theme>
;#Include *i <_FrostedTheme>
;#Include *i <_TitleBar>
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
#Include *i .\.private\zzz_Melo_LittleStuff.ahk
#Include *i <Help>

;@endregion

;@region Startup
; SPLASHSCREEN
if IsSet(SplashScreen){
    SplashScreen("Icon")
}

; TRAY ICON + MENU
StartMenu()
Menu_Custom()
if IsSet(Menu_Custom2) && priv{
    Menu_Custom2()
}
if IsSet(StartAutoUpdater) {
	%"StartAutoUpdater"%()
}
;@endregion
;@endregion

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
AlwaysOnTopStart()

AlwaysOnTopStart() {
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


#HotIf (Snippets.AlwaysOnTop)
#!WheelUp:: AOT_Transparency(-25)
#!WheelDown:: AOT_Transparency(25)
#HotIf
; --- Core Worker Function ---
AOT_Transparency(step := 0) {
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
            
            OSDAOT.ClearCells()
            Try AOTImage := OSDAOT.SetCellImage(1,1, pin,,20)
            OSDAOT.Show()
            SoundPlayWin("Speech On")
        }
    } 
    else { ; --- SCROLL DOWN ---
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
                    OSDAOT.Show()
                }
                SoundPlayWin("Speech Sleep")
            }
        } else {
            ; Case E: Normal window being dimmed without AOT
            newTrans := Max(30, currentTrans - 25)
            try WinSetTransparent(newTrans, targetWindow)
        }
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



/* 
SoundPlayWin(audiofile := "Windows Notify", timer := 3000) {

    if !InStr(audiofile, "\")
        audiofile := A_WinDir "\Media\" audiofile ".wav"

    try SoundPlay(audiofile)
    SetTimer(ReleaseFile,-timer)
    ReleaseFile(){
    try SoundPlay("NON-EXISTENT.wav")  ; releases previously played file from "in use"
  }
}
 */

SoundPlayWin(audiofile := "Windows Notify", timer := 3000) {
    ; If relative/short name passed, resolve to standard Windows Media path
    if !InStr(audiofile, "\")
        audiofile := A_WinDir "\Media\" audiofile ".wav"

    ; SND_FILENAME (0x20000) | SND_ASYNC (0x1) | SND_NODEFAULT (0x2) = 0x20003
    ; Plays sound in background and avoids error beeps if file is missing
    try DllCall("Winmm.dll\PlaySoundW", "Str", audiofile, "Ptr", 0, "UInt", 0x20003)

    ; Schedule file release if timer is provided
    if (timer > 0)
        SetTimer(ReleaseFile, -timer)

    ReleaseFile() {
        ; Passing 0 as the path cleanly stops playback and releases file handles
        try DllCall("Winmm.dll\PlaySoundW", "Ptr", 0, "Ptr", 0, "UInt", 0x0)
    }
}

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
        
        ; Store monitor 1 bounds as fallback in case mouse isn't matched
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
        ; 1. FASTEST & HIGHEST ELIMINATION: Drop minimized windows first (pure integer check)
        if (WinGetMinMax("ahk_id " hwnd) == -1)
            continue

        ; 2. VERY FAST BITWISE CHECK: Filter tool windows / popups before fetching strings
        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x00000080 && !(exStyle & 0x00040000)) ; WS_EX_TOOLWINDOW without WS_EX_APPWINDOW
            continue

        ; 3. STRING CHECKS: Only extract strings if window passed basic style/minmax filters
        title := WinGetTitle("ahk_id " hwnd)
        if (title == "")
            continue

        winClass := WinGetClass("ahk_id " hwnd)
        if (winClass == "Progman" || winClass == "WorkerW" 
            || winClass == "Shell_TrayWnd" || winClass == "Shell_SecondaryTrayWnd" 
            || winClass == "Windows.UI.Core.CoreWindow")
            continue

        ; 4. HEAVY DLL CALL 1: Filter owned/child popups
        if DllCall("GetWindow", "ptr", hwnd, "uint", 4) && !(exStyle & 0x00040000) ; GW_OWNER = 4
            continue

        ; 5. HEAVY DLL CALL 2: Filter DWM Cloaked windows (Virtual Desktops / UWP)
        try {
            isCloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "uint*", &isCloaked, "uint", 4)
            if (isCloaked)
                continue
        }

        ; 6. GEOMETRY CHECK: Query window position last, only for surviving candidates
        WinGetPos &X, &Y, &W, &H, "ahk_id " hwnd
        winCenterX := X + (W / 2)
        winCenterY := Y + (H / 2)

        if (winCenterX >= mLeft && winCenterX <= mRight && winCenterY >= mTop && winCenterY <= mBottom) {
            visibleWindowsOnMonitor.Push(hwnd)
        }
    }

    ; 3. Decision Logic
    if (visibleWindowsOnMonitor.Length > 0) {
        HiddenWindows[targetMonitor] := visibleWindowsOnMonitor
        
        for hwnd in visibleWindowsOnMonitor {
            try WinMinimize("ahk_id " hwnd)
        }
    } 
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