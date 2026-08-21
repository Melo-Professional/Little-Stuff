/************************************************************************
 * @description File or Folder Selector
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/20
 * @version 1.1.0 (Client GUID, Theme, Colors)
 ***********************************************************************/

#Requires AutoHotkey v2.0

; HOW TO USE IT
; path := SelectFileOrFolder(A_Desktop, "Select file or folder")



SelectFileOrFolder(StartPath := "", Title := "Select a file or folder", OwnerHwnd := 0) {
    static CLSID_FileOpenDialog := "{DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7}"
    static IID_IFileOpenDialog := "{D57C7288-D4AD-4768-BE02-9D969532D960}"
    static IID_IFileDialogEvents := "{973510DB-7D7F-452B-8975-74A85828D354}"
    static IID_IFileDialogControlEvents := "{36116642-D713-4B97-9B83-7484A9D00433}"
    static IID_IFileDialogCustomize := "{E6FDD21A-163F-4975-9C8C-A69F1BA37034}"
    static IID_IShellItem := "{43826D1E-E718-42EE-BC55-A1E261C37BFE}"
    static CLIENT_GUID := "{A21E31E5-5353-41BF-8F0E-921471378B99}"

    static FOS_FORCEFILESYSTEM := 0x40
    static FOS_FILEMUSTEXIST := 0x1000
    static SIGDN_FILESYSPATH := 0x80058000

    static S_OK := 0
    static E_NOTIMPL := 0x80004001
    static E_NOINTERFACE := 0x80004002
    static HRESULT_CANCELLED := 0x800704C7

    ; ------------------------------------------------------------
    ; Create IFileOpenDialog
    ; ------------------------------------------------------------

    dialog := ComObject(CLSID_FileOpenDialog, IID_IFileOpenDialog)

    ; GetOptions
    options := 0
    ComCall(10, dialog, "UInt*", &options)

    ; Keep normal modern file-dialog behavior.
    ; Do NOT use FOS_PICKFOLDERS.
    options |= FOS_FORCEFILESYSTEM | FOS_FILEMUSTEXIST

    ; SetOptions
    ComCall(9, dialog, "UInt", options)

    ; ------------------------------------------------------------
    ; Set title
    ; ------------------------------------------------------------

    titleBuf := Buffer(StrPut(Title, "UTF-16"), 0)
    StrPut(Title, titleBuf, "UTF-16")

    ; IFileDialog::SetTitle = 17
    ComCall(17, dialog, "Ptr", titleBuf.Ptr)

    ; Rename "Open" to "OK"
    okText := Buffer(StrPut("Select File", "UTF-16"), 0)
    StrPut("Select File", okText, "UTF-16")
    ComCall(18, dialog, "Ptr", okText.Ptr)  ; IFileDialog::SetOkButtonLabel

    ; ------------------------------------------------------------
    ; Optional starting folder
    ; ------------------------------------------------------------

    if StartPath != "" && DirExist(StartPath) {
        iidShellItem := Buffer(16, 0)

        DllCall(
            "ole32\CLSIDFromString",
            "WStr", IID_IShellItem,
            "Ptr", iidShellItem.Ptr
        )

        shellItemPtr := 0

        hr := DllCall(
            "shell32\SHCreateItemFromParsingName",
            "WStr", StartPath,
            "Ptr", 0,
            "Ptr", iidShellItem.Ptr,
            "Ptr*", &shellItemPtr,
            "UInt"
        )

        if hr = 0 && shellItemPtr {
            shellItem := ComValue(13, shellItemPtr)

            ; IFileDialog::SetFolder = 12
            ComCall(12, dialog, "Ptr", shellItem.Ptr)
        }
    }

    ; ------------------------------------------------------------
    ; Shared state
    ; ------------------------------------------------------------

    state := {
        dialog: dialog,
        result: "",
        folderButtonID: 1001
    }

    ; ------------------------------------------------------------
    ; GUID buffers
    ; ------------------------------------------------------------

    iidUnknown := Buffer(16, 0)
    iidEvents := Buffer(16, 0)
    iidControl := Buffer(16, 0)

    DllCall(
        "ole32\CLSIDFromString",
        "WStr", "{00000000-0000-0000-C000-000000000046}",
        "Ptr", iidUnknown.Ptr
    )

    DllCall(
        "ole32\CLSIDFromString",
        "WStr", IID_IFileDialogEvents,
        "Ptr", iidEvents.Ptr
    )

    DllCall(
        "ole32\CLSIDFromString",
        "WStr", IID_IFileDialogControlEvents,
        "Ptr", iidControl.Ptr
    )

    ; ------------------------------------------------------------
    ; Interface memory
    ;
    ; +0             IFileDialogEvents interface pointer
    ; +PtrSize       IFileDialogControlEvents interface pointer
    ; ------------------------------------------------------------

    sink := Buffer(A_PtrSize * 2, 0)

    ; ------------------------------------------------------------
    ; COM callbacks
    ; ------------------------------------------------------------

    QueryInterface := CallbackCreate(
        (this, riid, ppv) => FileDialog_QueryInterface(
            this,
            riid,
            ppv,
            sink,
            iidUnknown,
            iidEvents,
            iidControl
        ),
        "",
        3
    )

    AddRef := CallbackCreate(
        (this) => 1,
        "",
        1
    )

    Release := CallbackCreate(
        (this) => 1,
        "",
        1
    )

    ; ------------------------------------------------------------
    ; IFileDialogEvents
    ; ------------------------------------------------------------

    OnFileOk := CallbackCreate(
        (this, pfd) => S_OK,
        "",
        2
    )

    OnFolderChanging := CallbackCreate(
        (this, pfd, psiFolder) => S_OK,
        "",
        3
    )

    OnFolderChange := CallbackCreate(
        (this, pfd) => S_OK,
        "",
        2
    )

    OnSelectionChange := CallbackCreate(
        (this, pfd) => S_OK,
        "",
        2
    )

    OnShareViolation := CallbackCreate(
        (this, pfd, psi, response) => E_NOTIMPL,
        "",
        4
    )

    OnTypeChange := CallbackCreate(
        (this, pfd) => S_OK,
        "",
        2
    )

    OnOverwrite := CallbackCreate(
        (this, pfd, psi, response) => E_NOTIMPL,
        "",
        4
    )

    ; ------------------------------------------------------------
    ; IFileDialogControlEvents
    ; ------------------------------------------------------------

    OnItemSelected := CallbackCreate(
        (this, pfdc, idCtl, idItem) => S_OK,
        "",
        4
    )

    OnButtonClicked := CallbackCreate(
        (this, pfdc, idCtl) => (
            idCtl = state.folderButtonID
                ? FileDialog_SelectFolder(state)
                : S_OK
        ),
        "",
        3
    )

    OnCheckButtonToggled := CallbackCreate(
        (this, pfdc, idCtl, checked) => S_OK,
        "",
        4
    )

    OnControlActivating := CallbackCreate(
        (this, pfdc, idCtl) => S_OK,
        "",
        3
    )

    ; ------------------------------------------------------------
    ; IFileDialogEvents vtable
    ; ------------------------------------------------------------

    vtblEvents := Buffer(A_PtrSize * 10, 0)

    eventCallbacks := [
        QueryInterface,
        AddRef,
        Release,
        OnFileOk,
        OnFolderChanging,
        OnFolderChange,
        OnSelectionChange,
        OnShareViolation,
        OnTypeChange,
        OnOverwrite
    ]

    for index, callback in eventCallbacks
        NumPut(
            "Ptr",
            callback,
            vtblEvents,
            (index - 1) * A_PtrSize
        )

    ; ------------------------------------------------------------
    ; IFileDialogControlEvents vtable
    ; ------------------------------------------------------------

    vtblControl := Buffer(A_PtrSize * 7, 0)

    controlCallbacks := [
        QueryInterface,
        AddRef,
        Release,
        OnItemSelected,
        OnButtonClicked,
        OnCheckButtonToggled,
        OnControlActivating
    ]

    for index, callback in controlCallbacks
        NumPut(
            "Ptr",
            callback,
            vtblControl,
            (index - 1) * A_PtrSize
        )

    NumPut(
        "Ptr",
        vtblEvents.Ptr,
        sink,
        0
    )

    NumPut(
        "Ptr",
        vtblControl.Ptr,
        sink,
        A_PtrSize
    )

    ; ------------------------------------------------------------
    ; Advise
    ; ------------------------------------------------------------

    cookie := 0

    hr := ComCall(
        7,                  ; IFileDialog::Advise
        dialog,
        "Ptr", sink.Ptr,
        "UInt*", &cookie
    )

    if hr != 0
        throw OSError(hr, "IFileDialog::Advise failed.")

    ; ------------------------------------------------------------
    ; Add "Select Folder" button
    ; ------------------------------------------------------------

    customize := ComObjQuery(
        dialog,
        IID_IFileDialogCustomize
    )

    if !customize
        throw Error("Unable to obtain IFileDialogCustomize.")

    buttonText := Buffer(
        StrPut("Select Folder", "UTF-16"),
        0
    )

    StrPut(
        "Select Folder",
        buttonText,
        "UTF-16"
    )

    ; IFileDialogCustomize::AddPushButton = 5
    ComCall(
        5,
        customize,
        "UInt", state.folderButtonID,
        "Ptr", buttonText.Ptr
    )

    ; Make the custom button prominent.
    ; IFileDialogCustomize::MakeProminent = 24
    try
        ComCall(
            24,
            customize,
            "UInt", state.folderButtonID
        )

    ; ------------------------------------------------------------
    ; Show dialog
    ; ------------------------------------------------------------

    try {
        ; IModalWindow::Show = 3
        ; Cancel returns HRESULT_CANCELLED (0x800704C7) — treat as empty result.
        try {
            hr := ComCall(
                3,
                dialog,
                "Ptr", OwnerHwnd
            )
        } catch as err {
            ; ComCall throws on failure. Cancel is expected.
            if InStr(err.Message, "0x800704C7") || (err.Number = HRESULT_CANCELLED)
                return ""
            throw
        }

        ; Our Select Folder button closes the dialog and
        ; places the folder path here.
        if state.result != ""
            return state.result

        ; Normal OK button.
        if hr = 0 {
            resultItemPtr := 0

            ; IFileDialog::GetResult = 20
            hr := ComCall(
                20,
                dialog,
                "Ptr*", &resultItemPtr
            )

            if hr = 0 && resultItemPtr {
                resultItem := ComValue(
                    13,
                    resultItemPtr
                )

                return ShellItemToPath(
                    resultItem,
                    SIGDN_FILESYSPATH
                )
            }
        }

        return ""
    }
    finally {
        ; IFileDialog::Unadvise = 8
        if cookie
            try
                ComCall(
                    8,
                    dialog,
                    "UInt",
                    cookie
                )

        ; Keep callbacks alive until Unadvise has completed.
        CallbackFree(QueryInterface)
        CallbackFree(AddRef)
        CallbackFree(Release)

        CallbackFree(OnFileOk)
        CallbackFree(OnFolderChanging)
        CallbackFree(OnFolderChange)
        CallbackFree(OnSelectionChange)
        CallbackFree(OnShareViolation)
        CallbackFree(OnTypeChange)
        CallbackFree(OnOverwrite)

        CallbackFree(OnItemSelected)
        CallbackFree(OnButtonClicked)
        CallbackFree(OnCheckButtonToggled)
        CallbackFree(OnControlActivating)
    }
}


FileDialog_QueryInterface(
    this,
    riid,
    ppv,
    sink,
    iidUnknown,
    iidEvents,
    iidControl
) {
    if GuidEqual(riid, iidUnknown) {
        NumPut(
            "Ptr",
            sink.Ptr,
            ppv
        )

        return 0
    }

    if GuidEqual(riid, iidEvents) {
        NumPut(
            "Ptr",
            sink.Ptr,
            ppv
        )

        return 0
    }

    if GuidEqual(riid, iidControl) {
        NumPut(
            "Ptr",
            sink.Ptr + A_PtrSize,
            ppv
        )

        return 0
    }

    NumPut(
        "Ptr",
        0,
        ppv
    )

    return 0x80004002 ; E_NOINTERFACE
}


GuidEqual(ptr, guidBuffer) {
    loop 16 {
        if NumGet(
            ptr,
            A_Index - 1,
            "UChar"
        ) != NumGet(
            guidBuffer,
            A_Index - 1,
            "UChar"
        )
            return false
    }

    return true
}


FileDialog_SelectFolder(state) {
    static SIGDN_FILESYSPATH := 0x80058000

    path := ""

    ; 1) Prefer highlighted item (GetCurrentSelection = 14)
    ;    Returns E_FAIL when nothing is selected — must not throw.
    try {
        itemPtr := 0
        hr := ComCall(14, state.dialog, "Ptr*", &itemPtr)
        if hr = 0 && itemPtr {
            item := ComValue(13, itemPtr)
            path := ShellItemToPath(item, SIGDN_FILESYSPATH)
            ; Only accept a directory; ignore a highlighted file.
            if path != "" && !DirExist(path)
                path := ""
        }
    }

    ; 2) Fall back to the folder currently shown in the dialog (GetFolder = 19)
    if path = "" {
        try {
            folderPtr := 0
            hr := ComCall(19, state.dialog, "Ptr*", &folderPtr)
            if hr = 0 && folderPtr {
                folderItem := ComValue(13, folderPtr)
                path := ShellItemToPath(folderItem, SIGDN_FILESYSPATH)
            }
        }
    }

    if path != "" && DirExist(path) {
        state.result := path
        ; IFileDialog::Close = 23
        try ComCall(23, state.dialog, "Int", 0)
    }

    return 0
}


ShellItemToPath(item, displayNameType) {
    pathPtr := 0

    ; IShellItem::GetDisplayName = 5
    hr := ComCall(
        5,
        item,
        "UInt",
        displayNameType,
        "Ptr*", &pathPtr
    )

    if hr != 0 || !pathPtr
        return ""

    path := StrGet(
        pathPtr,
        "UTF-16"
    )

    DllCall(
        "ole32\CoTaskMemFree",
        "Ptr",
        pathPtr
    )

    return path
}