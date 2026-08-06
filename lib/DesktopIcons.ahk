; 2. Double-Click Hotkey Trigger
#HotIf (IsSet(Snippets) && Snippets.HasOwnProp("DesktopIcons") && Snippets.DesktopIcons && DesktopIconsManager.IsDesktopUnderMouse())
~LButton:: {
    if (A_PriorHotkey == "~LButton" && A_TimeSincePriorHotkey < DllCall("user32\GetDoubleClickTime", "UInt")) {
        hSysListView := DesktopIconsManager.GetSysListView()
        if (hSysListView && DllCall("user32\IsWindowVisible", "Ptr", hSysListView)) {
            CoordMode "Mouse", "Screen"
            MouseGetPos(&x, &y)
            if (DesktopIconsManager.IsMouseOverIcon(hSysListView, x, y))
                return
        }
        DesktopIconsManager.ToggleEffect()
    }
}
#HotIf

; ==============================================================================
; 3. DESKTOP ICONS MANAGER CLASS
; ==============================================================================

class DesktopIconsManager {
    static animTimer := 0
    static fadeDuration := 500
    static overlayGui := 0

    static GetShellDefView() {
        hProgman := WinExist("ahk_class WorkerW", "FolderView") ? WinExist() : WinExist("ahk_class Progman", "FolderView")
        return hProgman ? DllCall("user32\GetWindow", "Ptr", hProgman, "UInt", 5, "Ptr") : 0
    }

    static GetSysListView() {
        hShell := this.GetShellDefView()
        return hShell ? DllCall("user32\GetWindow", "Ptr", hShell, "UInt", 5, "Ptr") : 0
    }

    static IsDesktopUnderMouse() {
        MouseGetPos(, , &hWnd)
        if (!hWnd)
            return false
        winClass := WinGetClass(hWnd)
        return (winClass == "Progman" || winClass == "WorkerW" || winClass == "SHELLDLL_DefView" || winClass == "SysListView32")
    }

    static ToggleEffect() {
        hShell := this.GetShellDefView()
        hSysListView := this.GetSysListView()
        if (!hShell || !hSysListView)
            return

        if (this.animTimer) {
            SetTimer(this.animTimer, 0)
            this.animTimer := 0
        }

        isFadingIn := !DllCall("user32\IsWindowVisible", "Ptr", hSysListView)

        WinGetPos(&vX, &vY, &vW, &vH, hSysListView)
        if (vW <= 0 || vH <= 0) {
            vX := SysGet(76), vY := SysGet(77), vW := SysGet(78), vH := SysGet(79)
        }

        ; Capture screen snapshot
        hDC_Screen := DllCall("user32\GetDC", "Ptr", 0, "Ptr")
        hDC_Mem := DllCall("gdi32\CreateCompatibleDC", "Ptr", hDC_Screen, "Ptr")
        hBitmap := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", hDC_Screen, "Int", vW, "Int", vH, "Ptr")
        hOldBmp := DllCall("gdi32\SelectObject", "Ptr", hDC_Mem, "Ptr", hBitmap, "Ptr")
        DllCall("gdi32\BitBlt", "Ptr", hDC_Mem, "Int", 0, "Int", 0, "Int", vW, "Int", vH, "Ptr", hDC_Screen, "Int", vX, "Int", vY, "UInt", 0x00CC0020)
        DllCall("user32\ReleaseDC", "Ptr", 0, "Ptr", hDC_Screen)

        ; Setup overlay GUI
        if (!this.overlayGui)
            this.overlayGui := Gui("-Caption +ToolWindow -SysMenu +E0x80000 +E0x20")

        this.UpdateAlpha(this.overlayGui.Hwnd, hDC_Mem, vX, vY, vW, vH, 255)
        this.overlayGui.Show("NA x" vX " y" vY " w" vW " h" vH)
        DllCall("user32\SetWindowPos", "Ptr", this.overlayGui.Hwnd, "Ptr", 1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)

        ; Toggle Shell icons
        SendMessage(0x111, 0x7402, 0, , "ahk_id " hShell)

        if (isFadingIn)
            Sleep(600) ; fade in wait

        startTime := A_TickCount

        AnimateStep() {
            elapsed := A_TickCount - startTime
            rawProgress := Min(1.0, elapsed / this.fadeDuration)
            progress := rawProgress * rawProgress * (3 - 2 * rawProgress) ; Smoothstep easing
            alpha := Integer(255 * (1.0 - progress))

            this.UpdateAlpha(this.overlayGui.Hwnd, hDC_Mem, vX, vY, vW, vH, alpha)

            if (rawProgress >= 1.0) {
                SetTimer(this.animTimer, 0)
                this.animTimer := 0
                
                ; Cleanup GDI objects
                DllCall("gdi32\SelectObject", "Ptr", hDC_Mem, "Ptr", hOldBmp)
                DllCall("gdi32\DeleteDC", "Ptr", hDC_Mem)
                DllCall("gdi32\DeleteObject", "Ptr", hBitmap)
                if (this.overlayGui) {
                    this.overlayGui.Destroy()
                    this.overlayGui := 0
                }
            }
        }

        this.animTimer := AnimateStep
        SetTimer(this.animTimer, 15)
    }

    static UpdateAlpha(hwnd, hDCSource, x, y, width, height, alpha) {
        ptDst := Buffer(8), NumPut("Int", x, ptDst, 0), NumPut("Int", y, ptDst, 4)
        sizeDst := Buffer(8), NumPut("Int", width, sizeDst, 0), NumPut("Int", height, sizeDst, 4)
        ptSrc := Buffer(8, 0)
        blend := Buffer(4), NumPut("UChar", 0, blend, 0), NumPut("UChar", 0, blend, 1), NumPut("UChar", alpha, blend, 2), NumPut("UChar", 0, blend, 3)

        DllCall("user32\UpdateLayeredWindow", "Ptr", hwnd, "Ptr", 0, "Ptr", ptDst, "Ptr", sizeDst, "Ptr", hDCSource, "Ptr", ptSrc, "UInt", 0, "Ptr", blend, "UInt", 2)
    }

    static IsMouseOverIcon(hSysListView, x, y) {
        pt := Buffer(8), NumPut("Int", x, pt, 0), NumPut("Int", y, pt, 4)
        DllCall("user32\ScreenToClient", "Ptr", hSysListView, "Ptr", pt)

        pid := WinGetPID("ahk_id " hSysListView)
        hProc := DllCall("kernel32\OpenProcess", "UInt", 0x38, "Int", 0, "UInt", pid, "Ptr")
        if (!hProc)
            return false

        pMem := DllCall("kernel32\VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "UPtr", 24, "UInt", 0x1000, "UInt", 0x4, "Ptr")
        if (pMem) {
            buf := Buffer(24, 0)
            NumPut("Int", NumGet(pt, 0, "Int"), buf, 0)
            NumPut("Int", NumGet(pt, 4, "Int"), buf, 4)
            DllCall("kernel32\WriteProcessMemory", "Ptr", hProc, "Ptr", pMem, "Ptr", buf, "UPtr", 8, "UPtr*", 0)

            itemIndex := SendMessage(0x1012, 0, pMem, , "ahk_id " hSysListView) ; LVM_HITTEST

            DllCall("kernel32\ReadProcessMemory", "Ptr", hProc, "Ptr", pMem + 8, "Ptr", buf, "UPtr", 4, "UPtr*", 0)
            flags := NumGet(buf, 0, "UInt")

            DllCall("kernel32\VirtualFreeEx", "Ptr", hProc, "Ptr", pMem, "UPtr", 0, "UInt", 0x8000)
            DllCall("kernel32\CloseHandle", "Ptr", hProc)

            return (itemIndex != -1 && (flags & 0xE))
        }
        DllCall("kernel32\CloseHandle", "Ptr", hProc)
        return false
    }
}