#Requires AutoHotkey v2.0

; INITIALIZE THE CROSSHAIR
;MyCrosshair := MouseCrosshair()

; SETUP TRAY MENU
;A_TrayMenu.Delete()
;A_TrayMenu.Add("Toggle Crosshair", (*) => MyCrosshair.Toggle())
;A_TrayMenu.Add()
;A_TrayMenu.AddStandard()

; Optional hotkey toggle
;F8::MyCrosshair.Toggle()

; delete instance
;MyCrosshair := ""

class MouseCrosshair {
    __New() {
        ; --- Your Preferred Configuration ---
        cfgColor       := "0xC4FFFB00" ; ARGB Format
        cfgColor       := "0xdcff00bf" ; ARGB Format
        cfgColor       := "0xdcff7b00" ; ARGB Format
        cfgThickness   := 3
        cfgSize        := 14
        cfgEnds        := 4            ; 4 = full cross (+), 2 = partial line (| or -)
        cfgOrientation := "vertical"   ; if partial, "horizontal" or "vertical"
        cfgCenterGap   := 10
        ; ------------------------------------

        ; Explicit instance mapping
        this.Color       := cfgColor
        this.Thickness   := cfgThickness
        this.Size        := cfgSize
        this.Ends        := cfgEnds
        this.Orientation := cfgOrientation
        this.CenterGap   := cfgCenterGap

        this.IsActive := false
        this.LastX := 0
        this.LastY := 0
        
        this.ScreenW := A_ScreenWidth
        this.ScreenH := A_ScreenHeight

        ; 1. Initialize GDI+
        this.hGdiplus := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
        si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        NumPut("UInt", 1, si)
        
        ; FIXED: Use temporary local variable for reference parameter
        tmpToken := 0
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &tmpToken, "Ptr", si, "Ptr", 0)
        this.pToken := tmpToken

        ; 2. Create Fullscreen Layered Window
        this.Gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
        
        ; 3. Setup Buffers
        this.hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
        this.hdcMem := DllCall("CreateCompatibleDC", "Ptr", this.hdcScreen, "Ptr")
        this.hbm := DllCall("CreateCompatibleBitmap", "Ptr", this.hdcScreen, "Int", this.ScreenW, "Int", this.ScreenH, "Ptr")
        this.hObj := DllCall("SelectObject", "Ptr", this.hdcMem, "Ptr", this.hbm, "Ptr")
        
        ; FIXED: Use temporary local variable for reference parameter
        tmpGraphics := 0
        DllCall("gdiplus\GdipCreateFromHDC", "Ptr", this.hdcMem, "Ptr*", &tmpGraphics)
        this.pGraphics := tmpGraphics

        ; FIXED: Use temporary local variable for reference parameter
        tmpPen := 0
        DllCall("gdiplus\GdipCreatePen1", "UInt", this.Color, "Float", this.Thickness, "Int", 2, "Ptr*", &tmpPen)
        this.pPen := tmpPen
        
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", this.pGraphics, "Int", 1)

        ; Pre-allocate buffer structures for UpdateLayeredWindow
        this.ptZero := Buffer(8, 0)
        this.sizeCanvas := Buffer(8, 0)
        NumPut("Int", this.ScreenW, this.sizeCanvas, 0)
        NumPut("Int", this.ScreenH, this.sizeCanvas, 4)
        this.blendObj := Buffer(4, 0)
        NumPut("UChar", 255, this.blendObj, 2)
        NumPut("UChar", 1, this.blendObj, 3)

        ; Bind method loop thread context
        this.TimerRoutine := ObjBindMethod(this, "Update")
    }

    Toggle() {
        this.IsActive := !this.IsActive
        if this.IsActive {
            this.Gui.Show("x0 y0 w" this.ScreenW " h" this.ScreenH " NoActivate")
            SetTimer(this.TimerRoutine, 1, -1)
        } else {
            SetTimer(this.TimerRoutine, 0)
            DllCall("gdiplus\GdipGraphicsClear", "Ptr", this.pGraphics, "UInt", 0)
            DllCall("UpdateLayeredWindow", "Ptr", this.Gui.Hwnd, "Ptr", this.hdcScreen, "Ptr", 0, "Ptr", this.sizeCanvas, "Ptr", this.hdcMem, "Ptr", this.ptZero, "UInt", 0, "Ptr", this.blendObj, "UInt", 2)
            this.Gui.Hide()
        }
    }

    Update() {
        CoordMode "Mouse", "Screen"
        MouseGetPos(&mx, &my)
        
        if (mx != this.LastX || my != this.LastY) {
            DllCall("gdiplus\GdipGraphicsClear", "Ptr", this.pGraphics, "UInt", 0)
            
            ; --- Draw Horizontal ---
            if (this.Ends = 4 || (this.Ends = 2 && this.Orientation = "horizontal")) {
                DllCall("gdiplus\GdipDrawLine", "Ptr", this.pGraphics, "Ptr", this.pPen, "Float", mx - this.CenterGap - this.Size, "Float", my, "Float", mx - this.CenterGap, "Float", my)
                DllCall("gdiplus\GdipDrawLine", "Ptr", this.pGraphics, "Ptr", this.pPen, "Float", mx + this.CenterGap, "Float", my, "Float", mx + this.CenterGap + this.Size, "Float", my)
            }
            
            ; --- Draw Vertical ---
            if (this.Ends = 4 || (this.Ends = 2 && this.Orientation = "vertical")) {
                DllCall("gdiplus\GdipDrawLine", "Ptr", this.pGraphics, "Ptr", this.pPen, "Float", mx, "Float", my - this.CenterGap - this.Size, "Float", mx, "Float", my - this.CenterGap)
                DllCall("gdiplus\GdipDrawLine", "Ptr", this.pGraphics, "Ptr", this.pPen, "Float", mx, "Float", my + this.CenterGap, "Float", mx, "Float", my + this.CenterGap + this.Size)
            }
            
            DllCall("UpdateLayeredWindow", "Ptr", this.Gui.Hwnd, "Ptr", this.hdcScreen, "Ptr", 0, "Ptr", this.sizeCanvas, "Ptr", this.hdcMem, "Ptr", this.ptZero, "UInt", 0, "Ptr", this.blendObj, "UInt", 2)
            
            this.LastX := mx
            this.LastY := my
        }
    }

    __Delete() {
        SetTimer(this.TimerRoutine, 0)
        DllCall("gdiplus\GdipDeletePen", "Ptr", this.pPen)
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", this.pGraphics)
        DllCall("SelectObject", "Ptr", this.hdcMem, "Ptr", this.hObj)
        DllCall("DeleteObject", "Ptr", this.hbm)
        DllCall("DeleteDC", "Ptr", this.hdcMem)
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", this.hdcScreen)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", this.pToken)
    }
}