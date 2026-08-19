/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.0.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.GitHubRepo := "https://github.com/Melo-Professional/Little-Stuff"
;App.NameCutted			:= "Template`nBigName"

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

;Debug := true
;ResetSettings       := Settings.Clone()
;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()
Settings.SplashScreen := "Icon"
;Debug := true
;@endregion

;@region INI
SaveToINI := []
;SaveToINI.Push("Settings.SplashScreen")     ; add more to INI file
SaveToINI.Push("Snippets.SnapWindow", "Snippets.MBVaio", "Snippets.InternetMonitor", "Snippets.AlwaysOnTop", "Snippets.TheLoupe")     ; add more to INI file
SaveToINI.Push("Settings.DesiredTheme", "Snippets.SnapWindow", "Snippets.MBVaio",
                "Snippets.InternetMonitor", "Snippets.AlwaysOnTop", "Snippets.TheLoupe",
                "Snippets.KDE_Drag", "Snippets.MouseCrossHair", "Snippets.CicleTabsWheel",
				"Snippets.DesktopIcons"
				)

if App.HasOwnProp("GitHubRepo")
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
if (IsSet(INIManager) && (SaveToINI != [])) {
	IsSet(RegisterArrayItems) ? RegisterArrayItems(SaveToINI) : 0
	IsSet(LoadINI) ? LoadINI() : 0
}
;@endregion
