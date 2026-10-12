;@credits https://github.com/The-CoDingman/The-Loupe/blob/main/The%20Loupe.ahk

/*
#x::{
    if (Loupe.Gui)
        Loupe.Stop()
    else
        Loupe.Magnify(300, 2, 1, "80ff80")
}
F1::Loupe.Magnify()
F2::Loupe.Stop()
F3::Loupe.Magnify(750, 3, 8, "660066")
F5::Loupe.Reset()
*/

/**
 * Special thanks to RockssJoke for the doing all the hardwork
 * https://www.autohotkey.com/boards/viewtopic.php?f=83&t=134936
 * Special thanks to Wilkster for their contributions
 * 
 * I took what they made, optimized it some and turned it into a class
**/
class Loupe {
    static MagnificationFactor := 2, LensSize := 75
    static BorderWidth := 3, BorderColor := "367588"
    static Gui := 0, hMemDC := 0, hObm := 0, hBitmap := 0, hDC := 0, hBorderPen := 0
    static PrevLoc := Buffer(8, 0), UpdateTimer := ObjBindMethod(Loupe, "Update")

    static Magnify(LensSize := Loupe.LensSize, MagnificationFactor := Loupe.MagnificationFactor, BorderWidth := Loupe.BorderWidth, BorderColor := Loupe.BorderColor) {
        LensSize := IsSet(LensSize) && (LensSize >= 75) ? LensSize : Loupe.LensSize
        MagnificationFactor := IsSet(MagnificationFactor) && (MagnificationFactor >= 1) ? MagnificationFactor : Loupe.MagnificationFactor
        BorderWidth := IsSet(BorderWidth) && (BorderWidth >= 1) ? BorderWidth : Loupe.BorderWidth
        BorderColor := IsSet(BorderColor) && IsXDigit(BorderColor) ? BorderColor : Loupe.BorderColor

        SizeChanged := (LensSize != Loupe.LensSize)
        BorderChanged := (BorderWidth != Loupe.BorderWidth) || (BorderColor != Loupe.BorderColor)

        Loupe.LensSize := LensSize
        Loupe.MagnificationFactor := MagnificationFactor
        Loupe.BorderWidth := BorderWidth
        Loupe.BorderColor := BorderColor

        ; Create GUI if it doesn't exist yet
        if (!Loupe.Gui) {
            Loupe.Gui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
            if (!DllCall("User32\SetWindowDisplayAffinity", "Ptr", Loupe.Gui.Hwnd, "Int", 0x00000011, "Int")) {
                MsgBox("There was an error setting the window affinity", "Error", "262144")
                Loupe.Gui.Destroy(), Loupe.Gui := 0
                return
            }
            Loupe.Gui.Opt("+E0x20 +E0x80000")
            Loupe.Gui.Show("NA x0 y0 w0 h0")
            SetTimer(Loupe.UpdateTimer, 16)
        }

        ; Rebuild GDI buffers on dimension or border changes without destroying GUI
        if (SizeChanged || BorderChanged || !Loupe.hBitmap) {
            Loupe.FreeGDI()
            
            Loupe.hDC := DllCall("GetDC", "Ptr", 0)
            Loupe.hMemDC := DllCall("CreateCompatibleDC", "Ptr", Loupe.hDC)
            Loupe.hBitmap := DllCall("CreateCompatibleBitmap", "Ptr", Loupe.hDC, "Int", Loupe.LensSize, "Int", Loupe.LensSize)
            Loupe.hObm := DllCall("SelectObject", "Ptr", Loupe.hMemDC, "Ptr", Loupe.hBitmap)
            Loupe.hBorderPen := DllCall("Gdi32\CreatePen", "Int", 0, "Int", Loupe.BorderWidth, "UInt", Loupe.ConvertColor(Loupe.BorderColor), "Ptr")
            DllCall("Gdi32\SelectObject", "Ptr", Loupe.hMemDC, "Ptr", Loupe.hBorderPen)
            DllCall("Gdi32\SelectObject", "Ptr", Loupe.hMemDC, "Ptr", DllCall("Gdi32\GetStockObject", "Int", 5)) ; Null Brush
            
            DllCall("SetWindowRgn", "Ptr", Loupe.Gui.Hwnd, "Ptr", Loupe.CreateCircularRegion(Loupe.LensSize), "Int", 1)
        }
    }

    static FreeGDI() {
        if (Loupe.hMemDC) {
            if (Loupe.hObm)
                DllCall("SelectObject", "Ptr", Loupe.hMemDC, "Ptr", Loupe.hObm)
            if (Loupe.hBorderPen)
                DllCall("Gdi32\DeleteObject", "Ptr", Loupe.hBorderPen)
            DllCall("Gdi32\DeleteObject", "Ptr", Loupe.hBitmap)
            DllCall("Gdi32\DeleteDC", "Ptr", Loupe.hMemDC)
        }
        if (Loupe.hDC)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", Loupe.hDC)

        Loupe.hDC := Loupe.hMemDC := Loupe.hObm := Loupe.hBitmap := Loupe.hBorderPen := 0
    }

    static Reset() {
        Loupe.Stop()
        Loupe.MagnificationFactor := 2, Loupe.LensSize := 75
        Loupe.BorderWidth := 3, Loupe.BorderColor := "367588"
    }

    static Stop() {
        if (!Loupe.Gui)
            return

        SetTimer(Loupe.UpdateTimer, 0)
        Loupe.FreeGDI()
        Loupe.Gui.Destroy()
        Loupe.Gui := 0
    }

    static Update() {
        if (!Loupe.Gui || !Loupe.hMemDC)
            return

        try {
            CoordMode("Mouse", "Screen"), MouseGetPos(&mX, &mY)
            SourceSize := Loupe.LensSize / Loupe.MagnificationFactor
            SourceX := Round(mX - (SourceSize / 2)), SourceY := Round(mY - (SourceSize / 2))
            WindowX := Round(mX - (Loupe.LensSize / 2)), WindowY := Round(mY - (Loupe.LensSize / 2))
            NumPut("Int", WindowX, "Int", WindowY, Loupe.PrevLoc)

            DllCall("StretchBlt", "Ptr", Loupe.hMemDC, "Int", 0, "Int", 0, "Int", Loupe.LensSize, "Int", Loupe.LensSize, "Ptr", Loupe.hDC, "Int", SourceX, "Int", SourceY, "Int", SourceSize, "Int", SourceSize, "UInt", 0x00CC0020)
            DllCall("Gdi32\Ellipse", "Ptr", Loupe.hMemDC, "Int", Loupe.BorderWidth / 2, "Int", Loupe.BorderWidth / 2, "Int", Loupe.LensSize - Loupe.BorderWidth / 2, "Int", Loupe.LensSize - Loupe.BorderWidth / 2)
            DllCall("User32\UpdateLayeredWindow", "Ptr", Loupe.Gui.Hwnd, "Ptr", 0, "Ptr", Loupe.PrevLoc, "Int64*", Loupe.LensSize | (Loupe.LensSize << 32), "Ptr", Loupe.hMemDC, "Int64*", 0, "UInt", 0, "UInt*", 0xFF << 16, "UInt", 2)
        }
    }

    static CreateCircularRegion(Size) => DllCall("CreateEllipticRgn", "Int", 0, "Int", 0, "Int", Size, "Int", Size, "Ptr")
    static ConvertColor(BGR) => (RGB := BGR ~= "^0x" ? BGR : "0x" BGR, (((RGB & 0xFF) << 16) | (RGB & 0xFF00) | (RGB >> 16 & 0xFF)))
}