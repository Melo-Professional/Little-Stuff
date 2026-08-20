/************************************************************************
 * @description Robust, Modular Menu (No-Crash Dependency Checking)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.3.1
 ***********************************************************************/

#Requires AutoHotkey v2.0

Menu_Custom() {

    TrayMenu := A_TrayMenu
    MoreMenu := TrayMenu.HasProp("MoreMenu") ? TrayMenu.MoreMenu : ""

    Snippets_Menu := Menu()
    A_TrayMenu.Snippets_Menu := Snippets_Menu
    TrayMenu.Insert("More", "Snippets", Snippets_Menu)

    try MoreMenu.Delete("Pause")

    Snippets_Menu.Insert(,"Integrity Check", (*) => IntegrityCheck())

    Item := "Mouse Crosshair"
    Snippets_Menu.Insert(, Item, MouseCrossHairHandler)
    if (Snippets.MouseCrossHair){
        Snippets_Menu.Check(Item)
        global MyCrosshair
        MyCrosshair := MouseCrosshair()
        MyCrosshair.Toggle()
    }

    MouseCrossHairHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.MouseCrossHair := !Snippets.MouseCrossHair
        Snippets.MouseCrossHair? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
        try {
            MyCrosshair.Toggle()
        } catch {
            MyCrosshair := MouseCrosshair()
            MyCrosshair.Toggle()
        }
    
        if !(Snippets.MouseCrossHair){
            MyCrosshair := ""
        }
    }


    Item := "Cicle Tabs Wheel"
    Snippets_Menu.Insert(, Item, CTWHandler)
    if (Snippets.CicleTabsWheel){
        Snippets_Menu.Check(Item)
    }

    CTWHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.CicleTabsWheel := !Snippets.CicleTabsWheel
        Snippets.CicleTabsWheel? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
    }


    Item := "Internet Monitor"
    Snippets_Menu.Insert(, Item, InternetMonitorHandler)
    if (Snippets.InternetMonitor){
        Snippets_Menu.Check(Item)
    }

    InternetMonitorHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.InternetMonitor := !Snippets.InternetMonitor
        Snippets.InternetMonitor? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
        if Snippets.InternetMonitor
            InternetConnectivityMonitorStart()
    }


    Item := "KDE Drag & Resize`tMButton+Click+Drag"
    Snippets_Menu.Insert(, Item, KDE_DragHandler)
    if (Snippets.KDE_Drag){
    Snippets_Menu.Check(Item)
    }

    KDE_DragHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.KDE_Drag := !Snippets.KDE_Drag
        Snippets.KDE_Drag? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
    }


    Item := "Snap Window  `tMButton+Click"
    Snippets_Menu.Insert(, Item, SnapWindowHandler)
    if (Snippets.SnapWindow){
    Snippets_Menu.Check(Item)
    }

    SnapWindowHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.SnapWindow := !Snippets.SnapWindow
        Snippets.SnapWindow? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
    }



    Item := "AlwaysOnTop `tWin+Alt+Wheel"
    Snippets_Menu.Insert(, Item, AOTHandler)
    if (Snippets.AlwaysOnTop){
        Snippets_Menu.Check(Item)
    }

    AOTHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.AlwaysOnTop := !Snippets.AlwaysOnTop
        Snippets.AlwaysOnTop? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
        AlwaysOnTopStart()
    }


    Item := "The Loupe `tWin+Wheel"
    Snippets_Menu.Insert(, Item, TheLoupeHandler)
    if (Snippets.TheLoupe){
    Snippets_Menu.Check(Item)
    }

    TheLoupeHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.TheLoupe := !Snippets.TheLoupe
        Snippets.TheLoupe? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
    }


    Item := "Toggle Desktop Icons"
    Snippets_Menu.Insert(, Item, DesktopIconsHandler)
    if (Snippets.DesktopIcons){
    Snippets_Menu.Check(Item)
    }

    DesktopIconsHandler(ItemName, ItemPos, MyMenu){
        global Snippets
        Snippets.DesktopIcons := !Snippets.DesktopIcons
        Snippets.DesktopIcons? Snippets_Menu.Check(ItemName) : Snippets_Menu.Uncheck(ItemName)
        SaveINI()
    }



    ; Custom items
/*
    ; INSERT AT POSITION
    TrayMenu.Insert("3&", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
    TrayMenu.Insert("4&", "Volume Mixer", (*) => Run("sndvol.exe"))
    TrayMenu.Insert("5&")
 */

    ; INSERT OVER 'More'
;    TrayMenu.Insert("More", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
;    TrayMenu.Insert("More", "Volume Mixer", (*) => Run("sndvol.exe"))
;    TrayMenu.Insert("More")

    ; Clean up Suspend and Pause
;    if (MoreMenu != "") {
;    try MoreMenu.Delete("4&")
;    try MoreMenu.Delete("Suspend")
;    try MoreMenu.Delete("Pause")
;    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}

;A_TrayMenu.Delete()

