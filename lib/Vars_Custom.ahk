/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.0.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.Github := "https://github.com/Melo-Professional/Little-Stuffa"
if (App.HasOwnProp("Github")  && App.Github != "" && App.Github != "https://github.com/Melo-Professional/") {
	App.UpdateAuto := true
	App.UpdateFrequencyDays := 3
	App.UpdateLastCheck := ""
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
}

Snippets := {
    SnapWindow:				true,
    MBVaio:					false,
    InternetMonitor:		true,
    AlwaysOnTop:			true,
    TheLoupe:				true,
    KDE_Drag:				true,
    MouseCrossHair:			false,
    CicleTabsWheel:			false,
    DesktopIcons:			true,
}

;ResetSettings       := Settings.Clone()
;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()

;SaveToINI := [""] ; what to save to INI file
SaveToINI.Push("Settings.DesiredTheme", "Snippets.SnapWindow", "Snippets.MBVaio",
                "Snippets.InternetMonitor", "Snippets.AlwaysOnTop", "Snippets.TheLoupe",
                "Snippets.KDE_Drag", "Snippets.MouseCrossHair", "Snippets.CicleTabsWheel",
				"Snippets.DesktopIcons"
				)
RegisterArrayItems(SaveToINI)
LoadINI()

;App.NameCutted := "Template`nBigName"
;Debug := true


;ResetSettings       := Settings.Clone()


;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()

;App.NameCutted := "Template`nBigName"
;Settings.SplashScreen := "Icon"
;Debug := true
;@endregion


;@region INI
SaveToINI.Push("Snippets.SnapWindow", "Snippets.MBVaio", "Snippets.InternetMonitor", "Snippets.AlwaysOnTop", "Snippets.TheLoupe")     ; add more to INI file
RegisterArrayItems(SaveToINI)
LoadINI()
;@endregion