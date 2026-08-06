/************************************************************************
 * @description Snap Drag & Resize (High Refresh Rate Optimized)
 * @author Melo (melo@meloprofessional.com)
 * @credits Vampire https://www.autohotkey.com/boards/viewtopic.php?p=597540&sid=bdff9cf8316340cfb0c5006f1dd8cb78#p597540
 * @date 2026/06/09
 * @version 1.1.0
 ***********************************************************************/

;@region Snap, KDE Drag & Resize (MButton Modifier Hold)
if !IsSet(Snippets){
    Snippets := {
        SnapWindow: true,
        KDE_Drag: true
    }
}

#HotIf (Snippets.SnapWindow || Snippets.KDE_Drag)

; 1. INTERCEPT AND BLOCK NATIVE MBUTTON CLICK DOWN
MButton::
{
    global KDE_id, KDE_X1, KDE_Y1, KDE_WinX1, KDE_WinY1, KDE_WinWidth, KDE_WinHeight, KDE_WinMax
    global ActiveMode, HasMoved, KDE_WaitingForFirstMove
    
    SetWinDelay -1 ; Changed to -1 for maximum performance
    CoordMode "Mouse"
    
    ActiveMode := 0 
    HasMoved := false
    KDE_WaitingForFirstMove := true
    
    ; Capture the window context directly under the mouse cursor right now
    MouseGetPos &KDE_X1, &KDE_Y1, &KDE_id
    KDE_WinMax := WinGetMinMax("ahk_id " KDE_id)
    WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinWidth, &KDE_WinHeight, "ahk_id " KDE_id

    ; Keep thread alive while MButton is physically compressed
    while GetKeyState("MButton", "P")
    {
        ; Only run movement loops if KDE Drag feature is explicitly enabled
        if (Snippets.KDE_Drag) {
            if (ActiveMode == 1 || ActiveMode == 3)
                ProcessDragLogic()
            else if (ActiveMode == 2 || ActiveMode == 4)
                ProcessResizeLogic()
        }
            
        Sleep -1 ; Changed to -1 to uncap the loop for high Hz monitors
    }
    
    ; Handle the release mechanics when MButton is let go
    HandleMButtonRelease()
}

; 2. BLOCK NATIVE LEFT CLICK AND INITIATE DRAG MODE / SNAP LEFT MODE
#HotIf (Snippets.SnapWindow || Snippets.KDE_Drag) && GetKeyState("MButton", "P")
*LButton::
{
    global ActiveMode
    if (ActiveMode == 0)
        ActiveMode := 3 ; Left clicked, threshold tracking initialized
}

; 3. BLOCK NATIVE RIGHT CLICK AND INITIATE RESIZE MODE / SNAP RIGHT MODE
*RButton::
{
    global ActiveMode
    if (ActiveMode == 0)
        ActiveMode := 4 ; Right clicked, tracking 10px threshold
}
#HotIf


; --- HELPER FUNCTIONS ---

; High-accuracy Win32 API Fullscreen Detection Routine
IsFullscreen(hwnd)
{
    if !hwnd
        return false

    WinGetPos &wx, &wy, &ww, &wh, "ahk_id " hwnd

    mon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")

    mi := Buffer(40, 0)
    NumPut("uint", 40, mi, 0)

    DllCall("GetMonitorInfo", "ptr", mon, "ptr", mi)

    left   := NumGet(mi,  4, "int")
    top    := NumGet(mi,  8, "int")
    right  := NumGet(mi, 12, "int")
    bottom := NumGet(mi, 16, "int")

    return (
        wx = left
        && wy = top
        && ww = right - left
        && wh = bottom - top
    )
}

; Forces a window out of fullscreen or maximized state completely
ExitFullscreenAndMaximize(wID, WindowWasFullscreen) {
    try {
        if (WindowWasFullscreen) {
            ; 1. Only send F11 if the window is truly in borderless/fullscreen mode
            ControlSend "{F11}", , "ahk_id " wID
            Sleep 150 ; Give the application a brief moment to process the state change
            
            ; 2. Check if the app dropped from fullscreen straight into a Maximized state (1)
            ; or if it completely ignored the F11 and needs a hard style clear.
            if (WinGetMinMax("ahk_id " wID) == 1 || IsFullscreen(wID)) {
                WinSetStyle "+0x00C00000", "ahk_id " wID ; WS_CAPTION
                WinSetStyle "+0x00040000", "ahk_id " wID ; WS_SIZEBOX
                WinRestore "ahk_id " wID
            }
        } else {
            ; If it was just normally maximized, a clean standard OS restore works instantly
            WinRestore "ahk_id " wID
        }
        
        ; Double check/force restoration state one more time to break layout locks
        if (WinGetMinMax("ahk_id " wID) == 1) {
            WinRestore "ahk_id " wID
        }
        
        ; Grab current monitor stats via Win32 structure to size down centered gracefully
        mon := DllCall("MonitorFromWindow", "ptr", wID, "uint", 2, "ptr")
        mi := Buffer(40, 0)
        NumPut("uint", 40, mi, 0)
        DllCall("GetMonitorInfo", "ptr", mon, "ptr", mi)
        
        ML := NumGet(mi,  4, "int")
        MT := NumGet(mi,  8, "int")
        MR := NumGet(mi, 12, "int")
        MB := NumGet(mi, 16, "int")
        
        ; Calculate a smaller window geometry (80% of monitor size, centered)
        NewW := Integer((MR - ML) * 0.8)
        NewH := Integer((MB - MT) * 0.8)
        NewX := ML + Integer(((MR - ML) - NewW) / 2)
        NewY := MT + Integer(((MB - MT) - NewH) / 2)
        
        ; Explicitly slam the window size down to break layout limits smoothly
        WinMove NewX, NewY, NewW, NewH, "ahk_id " wID
    }
}

ProcessDragLogic() {
    global KDE_id, KDE_X1, KDE_Y1, KDE_X2, KDE_Y2, KDE_WinX1, KDE_WinY1, KDE_WinWidth, KDE_WinHeight, KDE_WinMax
    global ActiveMode, HasMoved, KDE_WaitingForFirstMove
    
    local WindowWasFullscreen
    
    MouseGetPos &KDE_X2, &KDE_Y2
    KDE_X_Offset := (KDE_X2 - KDE_X1)
    KDE_Y_Offset := (KDE_Y2 - KDE_Y1)
    
    if (ActiveMode == 3 && (Abs(KDE_X_Offset) > 20 || Abs(KDE_Y_Offset) > 20)) {
        HasMoved := true
        ActiveMode := 1 ; Threshold broken, transition to drag
        
        WindowWasFullscreen := IsFullscreen(KDE_id)
        
        ; Break out of Fullscreen or Maximized before dragging begins
        if (WindowWasFullscreen || KDE_WinMax) {
            ExitFullscreenAndMaximize(KDE_id, WindowWasFullscreen)
            KDE_WinMax := 0 ; Clear flag since it's no longer maximized
            
            ; Re-anchor coordinates from the new window placement
            WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinWidth, &KDE_WinHeight, "ahk_id " KDE_id
            KDE_X1 := KDE_X2
            KDE_Y1 := KDE_Y2
            KDE_X_Offset := 0
            KDE_Y_Offset := 0
        }
    }
    
    if (ActiveMode == 1) {
        ; Fast Win32 Native API Move (bypasses WinMove overhead, 5th param = bRepaint)
        try DllCall("MoveWindow", "ptr", KDE_id, "int", KDE_WinX1 + KDE_X_Offset, "int", KDE_WinY1 + KDE_Y_Offset, "int", KDE_WinWidth, "int", KDE_WinHeight, "int", 1)
    }
}

ProcessResizeLogic() {
    global KDE_id, KDE_X1, KDE_Y1, KDE_X2, KDE_Y2, KDE_WinX1, KDE_WinY1, KDE_WinWidth, KDE_WinHeight
    global ActiveMode, HasMoved, KDE_WinLeft, KDE_WinUp
    
    local WindowWasFullscreen, isMaximized
    
    MouseGetPos &KDE_X2, &KDE_Y2
    KDE_X_Offset := (KDE_X2 - KDE_X1)
    KDE_Y_Offset := (KDE_Y2 - KDE_Y1)
    
    if (ActiveMode == 4 && (Abs(KDE_X_Offset) > 20 || Abs(KDE_Y_Offset) > 20)) {
        HasMoved := true
        ActiveMode := 2 ; Threshold broken, transition to resize
        
        WindowWasFullscreen := IsFullscreen(KDE_id)
        isMaximized := WinGetMinMax("ahk_id " KDE_id)
        
        ; Break out before resizing calculations begin
        if (WindowWasFullscreen || isMaximized) {
            ExitFullscreenAndMaximize(KDE_id, WindowWasFullscreen)
            
            ; Re-anchor coordinates from the new window placement
            WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinWidth, &KDE_WinHeight, "ahk_id " KDE_id
            KDE_X1 := KDE_X2
            KDE_Y1 := KDE_Y2
            KDE_X_Offset := 0
            KDE_Y_Offset := 0
        }
        
        KDE_WinLeft := (KDE_X1 < KDE_WinX1 + KDE_WinWidth / 2) ? 1 : -1
        KDE_WinUp := (KDE_Y1 < KDE_WinY1 + KDE_WinHeight / 2) ? 1 : -1
    }
    
    if (ActiveMode == 2) {
        WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinWidth, &KDE_WinHeight, "ahk_id " KDE_id
        KDE_X_Diff := KDE_X2 - KDE_X1
        KDE_Y_Diff := KDE_Y2 - KDE_Y1
        
        ; Calculate integers explicitly for strict DllCall compatibility
        NewX := KDE_WinX1 + Integer((KDE_WinLeft+1)/2*KDE_X_Diff)
        NewY := KDE_WinY1 + Integer((KDE_WinUp+1)/2*KDE_Y_Diff)
        NewW := KDE_WinWidth - Integer(KDE_WinLeft*KDE_X_Diff)
        NewH := KDE_WinHeight - Integer(KDE_WinUp*KDE_Y_Diff)

        ; Fast Win32 Native API Move
        try DllCall("MoveWindow", "ptr", KDE_id, "int", NewX, "int", NewY, "int", NewW, "int", NewH, "int", 1)

        KDE_X1 := (KDE_X_Diff + KDE_X1)
        KDE_Y1 := (KDE_Y_Diff + KDE_Y1)
    }
}

HandleMButtonRelease() {
    global ActiveMode, HasMoved, Snippets, KDE_id, KDE_X2, KDE_Y2
    
    ; Scenario A: You pressed MButton, tapped a direction button, but released WITHOUT dragging -> SNAP WINDOW
    if (Snippets.SnapWindow && !HasMoved && (ActiveMode == 3 || ActiveMode == 4)) {
        WinActivate "ahk_id " KDE_id 
        if (ActiveMode == 3)
            Send "#+{Left}"
        else if (ActiveMode == 4)
            Send "#+{Right}"
            
    ; Scenario B: You activated Drag Mode and dragged past the threshold -> CHECK FOR EDGE MAXIMIZE
    } else if (ActiveMode == 1 && HasMoved && Snippets.KDE_Drag) {
        MouseGetPos &KDE_X2, &KDE_Y2
        MonitorCount := MonitorGetCount()
        Loop MonitorCount {
            MonitorGet A_Index, &KDE_MonitorLeft, &KDE_MonitorTop, &KDE_MonitorRight, &KDE_MonitorBottom
            if ((KDE_Y2 == KDE_MonitorTop) && (KDE_X2 >= KDE_MonitorLeft) && (KDE_X2 < KDE_MonitorRight)) {
                WinMaximize "ahk_id " KDE_id
                break
            }
        }
        
    ; Scenario C: ActiveMode is STILL 0. This means you held MButton and let go without tapping left or right.
    ; Fire a completely normal, standard Middle Click down to your web browser / apps.
    } else if (ActiveMode == 0) {
        Click "Middle"
    }
}
;@endregion