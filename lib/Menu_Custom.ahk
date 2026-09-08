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
        AOTStartOSD()
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


    Item := "Toggle Desktop Icons `tDouble LeftClick"
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


    Links_Menu := Menu()
    A_TrayMenu.Links_Menu := Links_Menu
    TrayMenu.Insert("More", "Links", Links_Menu)

	Links_Menu.Insert(,,)
	Links_Menu.Add("CONTROL PANEL", (*) => TrayMenu.Show())
	Links_Menu.Disable("Control Panel")
	Links_Menu.Insert(,,)

	Links_Menu.Insert(,"Control Panel", (*) => Run('shell:::{21EC2020-3AEA-1069-A2DD-08002B30309D}'))
	Links_Menu.Insert(,"God Mode", (*) => Run('shell:::{ED7BA470-8E54-465E-825C-99712043E01C}'))
	Links_Menu.Insert(,"Devices and Printers", (*) => Run('shell:::{A8A91A66-3A7D-4424-8D24-04E180695C7A}'))
	Links_Menu.Insert(,"Networks", (*) => Run('shell:::{7007ACC7-3202-11D1-AAD2-00805FC1270E}'))
	Links_Menu.Insert(,"Sounds", (*) => Run('shell:::{F8278025-320C-4048-B821-419747A9E533}'))

	Links_Menu.Insert(,,)
	Links_Menu.Insert(,"SYSTEM", (*) => TrayMenu.Show())
	Links_Menu.Disable("SYSTEM")
	Links_Menu.Insert(,,)

	Links_Menu.Insert(,"System Configuration", (*) => Run('msconfig.exe'))
	Links_Menu.Insert(,"Advanced", (*) => Run('SystemPropertiesAdvanced.exe'))
	Links_Menu.Insert(,"About", (*) => Run('shell:::{BB06C0E4-D293-4f75-8A90-CB05B6477EEE}'))
	Links_Menu.Insert(,"Manage Known Networks", (*) => Run('ms-settings:network-wifisettings'))

	Links_Menu.Insert(,,)
	Links_Menu.Insert(,"SYSADMIN", (*) => TrayMenu.Show())
	Links_Menu.Disable("SYSADMIN")
	Links_Menu.Insert(,,)

	Links_Menu.Insert(,"Device Manager", (*) => Run('devmgmt.msc'))
	Links_Menu.Insert(,"Disk Management", (*) => Run('diskmgmt.msc'))
	Links_Menu.Insert(,"Services", (*) => Run('services.msc'))
	Links_Menu.Insert(,"Task Scheduler", (*) => Run('taskschd.msc'))
	Links_Menu.Insert(,"Local Users and Groups", (*) => Run('lusrmgr.msc'))
	Links_Menu.Insert(,"Legacy User Accounts", (*) => Run('netplwiz.exe'))
	Links_Menu.Insert(,"Group Policy Editor", (*) => Run('gpedit.msc'))
	Links_Menu.Insert(,"Event Viewer", (*) => Run('eventvwr.msc'))
	Links_Menu.Insert(,"Firewall", (*) => Run('wf.msc'))
	Links_Menu.Insert(,"Reliability History", (*) => Run('perfmon /rel'))
	Links_Menu.Insert(,"Microsoft Management Console", (*) => Run('mmc.exe'))
	Links_Menu.Insert(,"Power Plans", (*) => Run('shell:::{025A5937-A6BE-4686-A844-36FE4BEC8B6D}'))


	Links_Menu.Insert(,,)
	Links_Menu.Insert(,"USER", (*) => TrayMenu.Show())
	Links_Menu.Disable("USER")
	Links_Menu.Insert(,,)

	Links_Menu.Insert(,"Startup", (*) => Run('shell:Startup'))
	Links_Menu.Insert(,"AppData", (*) => Run('shell:AppData'))
	Links_Menu.Insert(,"Local Appdata", (*) => Run('shell:Local AppData'))
	Links_Menu.Insert(,"User Profile", (*) => Run('shell:Profile'))
	Links_Menu.Insert(,"Apps Folder", (*) => Run('shell:AppsFolder'))
	Links_Menu.Insert(,"Recycle Bin", (*) => Run('shell:::{645FF040-5081-101B-9F08-00AA002F954E}'))


	TrayMenu.Insert("More")

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

