#Requires AutoHotkey v2.0

;#Include _SelectFileOrFolder.ahk
; Launch the GUI function
;IntegrityCheck()

IntegrityCheck() {
    ; ==========================================================================
    ; Local Configuration & State Variables
    ; ==========================================================================
    DefaultPath  := A_Desktop
    isCancelling := false
    isComparing  := false

    lastBrowseP1 := DefaultPath
    lastBrowseP2 := DefaultPath
    ComparisonData := []

    HashAlgorithms := Map(
        "SHA-256", 0x800c,
        "SHA-512", 0x800e,
        "SHA-384", 0x800d,
        "SHA-1",   0x8004,
        "MD5",     0x8003
    )

    ; ==========================================================================
    ; GUI Initialization
    ; ==========================================================================
    mainGui := Gui("+Resize +MinSize850x520", "Integrity Check")
    mainGui.MarginX := 20
    mainGui.MarginY := 20
    mainGui.SetFont("s9", "Segoe UI")

    ; Top Controls - Path 1
    mainGui.AddText("vTxtP1 x20 y20 w90", "Path 1:")
    editPath1  := mainGui.AddEdit("vEditP1 x120 y16 w680")
    btnBrowse1 := mainGui.AddButton("vBtnB1 x+10 y15 w90", "Browse...")

    ; Top Controls - Path 2
    mainGui.AddText("vTxtP2 x20 y55 w90", "Path 2:")
    editPath2  := mainGui.AddEdit("vEditP2 x120 y51 w680")
    btnBrowse2 := mainGui.AddButton("vBtnB2 x+10 y50 w90", "Browse...")

    ; Hash Algorithm Selector
    mainGui.AddText("vTxtAlgo x20 y92 w90", "Algorithm:")
    ddlAlgo := mainGui.AddDropDownList("vDDLAlgo x120 y88 w150 Choose1", ["SHA-256", "SHA-512", "SHA-384", "SHA-1", "MD5"])

    ; Result Filter Selector
    mainGui.AddText("vTxtFilter x290 y92 w50", "Filter:")
    ddlFilter := mainGui.AddDropDownList("vDDLFilter x340 y88 w160 Choose1", ["All Results", "Match", "Differ", "Missing"])

    ; GUI Clean Results View
    lvResults := mainGui.AddListView("vLV x20 y125 w890 h370 +Grid", [
        "Result", 
        "File Name", 
        "#1 Hash", 
        "#2 Hash"
    ])

    ; Bottom Action Controls
    btnExport  := mainGui.AddButton("vBtnExport x20 y510 w120 h32 Disabled", "Export CSV")
    btnCancel  := mainGui.AddButton("vBtnCancel x150 y510 w110 h32 Disabled", "Cancel")
    btnClose   := mainGui.AddButton("vBtnClose x270 y510 w100 h32", "Close")
    btnCompare := mainGui.AddButton("vBtnStart x770 y510 w140 h32 Default", "Start Comparison")

    status := mainGui.AddStatusBar()
    status.SetText("Ready. Select/drag paths or files to run automatically. Tip: Right-click rows for actions.")

    ; Control Event Bindings
    btnBrowse1.OnEvent("Click", (*) => PickPath(editPath1, 1))
    btnBrowse2.OnEvent("Click", (*) => PickPath(editPath2, 2))
    btnCompare.OnEvent("Click", StartComparison)
    btnCancel.OnEvent("Click", CancelComparison)
    btnExport.OnEvent("Click", ExportCSV)
    btnClose.OnEvent("Click", (*) => mainGui.Destroy())
    ddlFilter.OnEvent("Change", (*) => ApplyFilter())

    lvResults.OnEvent("DoubleClick", CopyRowHashes)
    lvResults.OnEvent("ContextMenu", ShowContextMenu)

    ; Hook CustomDraw directly to the ListView control
    lvResults.OnNotify(-12, LV_CustomDraw)

    ; Window Events
    mainGui.OnEvent("Size", GuiSize)
    mainGui.OnEvent("DropFiles", HandleDropFiles)
    mainGui.OnEvent("Close", (*) => mainGui.Destroy())

    mainGui.Show("w930 h600")

    ; ==========================================================================
    ; Inner Functions & Closures
    ; ==========================================================================

    GuiSize(thisGui, minMax, guiWidth, guiHeight) {
        if (minMax = -1)
            return

        margin := 20
        btnWidth := 90
        labelWidth := 90
        
        rightBtnX := guiWidth - margin - btnWidth
        editX := margin + labelWidth + 10
        editWidth := rightBtnX - 10 - editX

        editPath1.Move(editX, , editWidth)
        btnBrowse1.Move(rightBtnX)
        editPath2.Move(editX, , editWidth)
        btnBrowse2.Move(rightBtnX)

        lvWidth := guiWidth - (margin * 2)
        lvHeight := guiHeight - 200
        if (lvHeight < 100)
            lvHeight := 100
        lvResults.Move(margin, 125, lvWidth, lvHeight)

        btnY := guiHeight - 55
        btnExport.Move(margin, btnY)
        btnCancel.Move(margin + 130, btnY)
        btnClose.Move(margin + 250, btnY)
        btnCompare.Move(guiWidth - margin - 140, btnY)
    }

    PickPath(editCtrl, pathNum) {
        startPath := (pathNum = 1) ? lastBrowseP1 : lastBrowseP2
        if (editCtrl.Value != "") {
            if DirExist(editCtrl.Value)
                startPath := editCtrl.Value
            else if FileExist(editCtrl.Value) {
                SplitPath(editCtrl.Value, , &parentDir)
                startPath := parentDir
            }
        }

        selected := SelectFileOrFolder(startPath, "Select File or Folder for Path " pathNum)

        if selected {
            if (pathNum = 1)
                lastBrowseP1 := selected
            else
                lastBrowseP2 := selected

            ; IF results exist from a previous run: Reset session and wait for second path
            if (ComparisonData.Length > 0) {
                ComparisonData := []
                lvResults.Delete()
                btnExport.Enabled := false

                if (pathNum = 1) {
                    editPath1.Value := selected
                    editPath2.Value := ""
                    status.SetText("Path 1 set. Drag or select Path 2 to compare.")
                } else {
                    editPath2.Value := selected
                    editPath1.Value := ""
                    status.SetText("Path 2 set. Drag or select Path 1 to compare.")
                }
            } else {
                editCtrl.Value := selected

                if (editPath1.Value != "" && editPath2.Value != "")
                    StartComparison()
            }
        }
    }

    HandleDropFiles(guiObj, controlObj, fileArray, x, y) {
        if (fileArray.Length = 0)
            return

        if (ComparisonData.Length > 0 || editPath1.Value = "") {
            editPath1.Value := fileArray[1]
            lastBrowseP1    := fileArray[1]
            
            editPath2.Value := ""
            lvResults.Delete()
            ComparisonData := []
            btnExport.Enabled := false

            if (fileArray.Length >= 2) {
                editPath2.Value := fileArray[2]
                lastBrowseP2    := fileArray[2]
                StartComparison()
            } else {
                status.SetText("Path 1 set. Drag or select Path 2 to compare.")
            }
        } else {
            editPath2.Value := fileArray[1]
            lastBrowseP2    := fileArray[1]

            if (editPath1.Value != "" && editPath2.Value != "")
                StartComparison()
        }
    }

    StartComparison(*) {
        p1 := RTrim(editPath1.Value, "\")
        p2 := RTrim(editPath2.Value, "\")

        if (!p1 || !p2) {
            MsgBox("Please specify both paths before running the comparison.", "Missing Path", "Icon!")
            return
        }

        if (!FileExist(p1) && !DirExist(p1)) || (!FileExist(p2) && !DirExist(p2)) {
            MsgBox("One or both selected paths do not exist.", "Invalid Path", "Icon!")
            return
        }

        algoName := ddlAlgo.Text
        algID := HashAlgorithms.Has(algoName) ? HashAlgorithms[algoName] : 0x800c

        isCancelling := false
        isComparing  := true
        btnCompare.Enabled := false
        btnCancel.Enabled  := true
        btnExport.Enabled  := false
        ddlAlgo.Enabled    := false
        
        lvResults.Delete()
        ComparisonData := []

        status.SetText("Scanning Path 1 structure...")
        map1 := ScanPath(p1, "Path 1", algID)

        if (isCancelling) {
            FinishComparison("Comparison cancelled by user.")
            return
        }

        status.SetText("Scanning Path 2 structure...")
        map2 := ScanPath(p2, "Path 2", algID)

        if (isCancelling) {
            FinishComparison("Comparison cancelled by user.")
            return
        }

        status.SetText("Comparing file hashes...")
        
        for relPath, data1 in map1 {
            if (isCancelling)
                break

            path1 := data1.FullPath
            hash1 := data1.Hash

            if map2.Has(relPath) {
                path2 := map2[relPath].FullPath
                hash2 := map2[relPath].Hash

                if (hash1 == hash2) {
                    AddResultStore("Match", relPath, hash1, hash2, path1, path2, hash1, hash2)
                } else {
                    AddResultStore("Differ", relPath, hash1, hash2, path1, path2, hash1, hash2)
                }
            } else {
                AddResultStore("Missing in Path 2", relPath, hash1, "-", path1, "-", hash1, "-")
            }
        }

        for relPath, data2 in map2 {
            if (isCancelling)
                break

            if !map1.Has(relPath) {
                path2 := data2.FullPath
                hash2 := data2.Hash
                AddResultStore("Missing in Path 1", relPath, "-", hash2, "-", path2, "-", hash2)
            }
        }

        ApplyFilter()

        if (isCancelling)
            FinishComparison("Comparison cancelled by user.")
        else
            FinishComparison("Comparison complete! (" ComparisonData.Length " total entries processed)")
    }

    AddResultStore(resultStr, fileName, displayHash1, displayHash2, fullPath1, fullPath2, fullHash1, fullHash2) {
        ComparisonData.Push({
            Result:       resultStr,
            FileName:     fileName,
            DisplayHash1: displayHash1,
            DisplayHash2: displayHash2,
            FullPath1:    fullPath1,
            FullPath2:    fullPath2,
            Hash1:        fullHash1,
            Hash2:        fullHash2
        })
    }

    ApplyFilter() {
        lvResults.Delete()
        filterVal := ddlFilter.Text

        for item in ComparisonData {
            if (filterVal = "All Results" 
                || (filterVal = "Match" && item.Result = "Match")
                || (filterVal = "Differ" && item.Result = "Differ")
                || (filterVal = "Missing" && InStr(item.Result, "Missing"))) {
                
                lvResults.Add(, item.Result, item.FileName, item.DisplayHash1, item.DisplayHash2)
            }
        }

        lvResults.ModifyCol(1, 130)
        lvResults.ModifyCol(2, 380)
        lvResults.ModifyCol(3, 150)
        lvResults.ModifyCol(4, 150)
    }

    ScanPath(targetPath, pathLabel, algID) {
        files := Map()

        if !DirExist(targetPath) {
            SplitPath(targetPath, &fileName)
            status.SetText("Hashing " pathLabel ": " fileName)
            files[fileName] := { FullPath: targetPath, Hash: GetFileHash(targetPath, algID) }
            return files
        }

        baseLen := StrLen(RTrim(targetPath, "\")) + 2
        fileList := []
        Loop Files, targetPath "\*.*", "R" {
            fileList.Push(A_LoopFileFullPath)
        }

        total := fileList.Length
        for index, fullPath in fileList {
            if (isCancelling)
                break

            relPath := SubStr(fullPath, baseLen)
            status.SetText("Hashing " pathLabel " (" index "/" total "): " relPath)
            
            Sleep(1)
            files[relPath] := { FullPath: fullPath, Hash: GetFileHash(fullPath, algID) }
        }
        return files
    }

    CancelComparison(*) {
        isCancelling := true
        status.SetText("Cancelling process...")
    }

    FinishComparison(msg) {
        isComparing := false
        btnCompare.Enabled := true
        btnCancel.Enabled  := false
        btnExport.Enabled  := (ComparisonData.Length > 0)
        ddlAlgo.Enabled    := true
        status.SetText(msg)
    }

    LV_CustomDraw(guiCtrl, lParam, *) {
        static CDDS_PREPAINT := 0x1, CDRF_NOTIFYITEMDRAW := 0x20
        static CDDS_ITEMPREPAINT := 0x10001, CDRF_NEWFONT := 0x2

        drawStage := NumGet(lParam, 3 * A_PtrSize, "UInt")
        if (drawStage == CDDS_PREPAINT)
            return CDRF_NOTIFYITEMDRAW

        if (drawStage == CDDS_ITEMPREPAINT) {
            rowOff := (3 * A_PtrSize) + (A_PtrSize = 8 ? 32 : 24)
            row := NumGet(lParam, rowOff, "UPtr") + 1

            if (row > 0 && row <= lvResults.GetCount()) {
                res := lvResults.GetText(row, 1)

                bgColor := 0xFFFFFF   ; Default White
                textColor := 0x000000 ; Black

                if (res = "Match") {
                    bgColor := 0xDCF5DC  ; Soft Green (BGR)
                } else if (res = "Differ") {
                    bgColor := 0xDCDCFF  ; Soft Red (BGR)
                } else if InStr(res, "Missing") {
                    bgColor := 0xC7F5FF  ; Soft Yellow/Orange (BGR)
                }

                offClrText   := (A_PtrSize = 8) ? 80 : 48
                offClrTextBk := offClrText + 4

                NumPut("UInt", textColor, lParam, offClrText)
                NumPut("UInt", bgColor, lParam, offClrTextBk)
                return CDRF_NEWFONT
            }
        }
        return 0
    }

    ShowContextMenu(lv, rowNum, isRightClick, x, y) {
        if (rowNum == 0)
            return

        pt := Buffer(16, 0)
        DllCall("GetCursorPos", "Ptr", pt)
        DllCall("ScreenToClient", "Ptr", lv.Hwnd, "Ptr", pt)

        htInfo := Buffer(32, 0)
        NumPut("Int", NumGet(pt, 0, "Int"), htInfo, 0)
        NumPut("Int", NumGet(pt, 4, "Int"), htInfo, 4)

        colIndex := 1
        if (SendMessage(0x1039, 0, htInfo, lv.Hwnd) != -1) {
            colIndex := NumGet(htInfo, 16, "Int") + 1
        }

        colHeaders := ["Result", "File Name", "#1 Hash", "#2 Hash"]
        colName := (colIndex <= 4) ? colHeaders[colIndex] : "Cell"
        cellVal := lv.GetText(rowNum, colIndex)

        fileName := lv.GetText(rowNum, 2)
        matchedItem := ""
        for item in ComparisonData {
            if (item.FileName = fileName) {
                matchedItem := item
                break
            }
        }

        ctx := Menu()
        
        cellDisp := SubStr(cellVal, 1, 25) (StrLen(cellVal) > 25 ? "..." : "")
        ctx.Add("Copy " colName " (" cellDisp ")", (*) => A_Clipboard := cellVal)
        
        ctx.Add("Copy Entire Row Details", (*) => CopyRowHashes(lv, rowNum))
        ctx.Add()

        if (matchedItem) {
            if (colIndex = 3 || colIndex = 1) {
                ctx.Add("Browse Path 1 Location", (*) => OpenInExplorer(matchedItem.FullPath1))
            } else if (colIndex = 4) {
                ctx.Add("Browse Path 2 Location", (*) => OpenInExplorer(matchedItem.FullPath2))
            } else {
                if (matchedItem.FullPath1 != "-")
                    ctx.Add("Browse Path 1 Location", (*) => OpenInExplorer(matchedItem.FullPath1))
                if (matchedItem.FullPath2 != "-")
                    ctx.Add("Browse Path 2 Location", (*) => OpenInExplorer(matchedItem.FullPath2))
            }
        }

        ctx.Add()
        ctx.Add("Export CSV...", ExportCSV)
        ctx.Show(x, y)
    }

    OpenInExplorer(fullPath) {
        if (fullPath != "-" && FileExist(fullPath)) {
            Run('explorer.exe /select,"' . fullPath . '"')
        } else if (fullPath != "-") {
            SplitPath(fullPath, , &parentDir)
            if DirExist(parentDir)
                Run('explorer.exe "' parentDir '"')
            else
                MsgBox("Target location could not be found.", "Error", "Icon!")
        }
    }

    ExportCSV(*) {
        if (ComparisonData.Length == 0)
            return

        suggestedPath := GetNumberedFilename(DefaultPath . "\HashReport.csv")

        filePath := FileSelect("S16", suggestedPath, "Save Comparison Report", "CSV Files (*.csv)")
        if (!filePath)
            return

        if !(SubStr(filePath, -4) = ".csv")
            filePath .= ".csv"

        try {
            if FileExist(filePath)
                FileDelete(filePath)

            algoName := ddlAlgo.Text
            fileObj := FileOpen(filePath, "w", "UTF-8")
            
            fileObj.WriteLine('"Path 1 Full Path","' algoName '","Path 2 Full Path","' algoName '","Status"')

            for item in ComparisonData {
                p1 := EscapeCSV(item.FullPath1)
                h1 := EscapeCSV(item.Hash1)
                p2 := EscapeCSV(item.FullPath2)
                h2 := EscapeCSV(item.Hash2)
                st := EscapeCSV(item.Result)
                fileObj.WriteLine('"' p1 '","' h1 '","' p2 '","' h2 '","' st '"')
            }
            fileObj.Close()

            Run('explorer.exe /select,"' . filePath . '"')
        } catch Error as err {
            MsgBox("Failed to save CSV file:`n" err.Message, "Export Error", "Icon!")
        }
    }

    GetNumberedFilename(fullPath) {
        if !FileExist(fullPath)
            return fullPath

        SplitPath(fullPath, &name, &dir, &ext, &nameNoExt)
        counter := 1
        loop {
            newPath := dir "\" nameNoExt " (" counter ")." ext
            if !FileExist(newPath)
                return newPath
            counter++
        }
    }

    EscapeCSV(str) {
        return StrReplace(str, '"', '""')
    }

    CopyRowHashes(LV, RowNum) {
        if (RowNum == 0)
            return

        fileName := LV.GetText(RowNum, 2)
        matchedItem := ""
        for item in ComparisonData {
            if (item.FileName = fileName) {
                matchedItem := item
                break
            }
        }

        if (!matchedItem)
            return

        algoName := ddlAlgo.Text
        clipData := "File: " matchedItem.FileName "`nResult: " matchedItem.Result "`nPath 1: " matchedItem.FullPath1 "`nPath 1 " algoName ": " matchedItem.Hash1 "`nPath 2: " matchedItem.FullPath2 "`nPath 2 " algoName ": " matchedItem.Hash2
        
        A_Clipboard := clipData
        ToolTip("Copied row details & hashes to clipboard!")
        SetTimer(() => ToolTip(), -2000)
    }

    GetFileHash(filePath, algID := 0x800c) {
        static PROV_RSA_AES := 24, CRYPT_VERIFYCONTEXT := 0xF0000000
        hProv := 0, hHash := 0, hashVal := ""

        if !DllCall("advapi32\CryptAcquireContextW", "Ptr*", &hProv, "Ptr", 0, "Ptr", 0, "UInt", PROV_RSA_AES, "UInt", CRYPT_VERIFYCONTEXT)
            return ""

        if DllCall("advapi32\CryptCreateHash", "Ptr", hProv, "UInt", algID, "Ptr", 0, "UInt", 0, "Ptr*", &hHash) {
            fileObj := FileOpen(filePath, "r")
            if fileObj {
                bufSize := 65536
                buf := Buffer(bufSize)
                while !fileObj.AtEOF {
                    bytesRead := fileObj.RawRead(buf, bufSize)
                    DllCall("advapi32\CryptHashData", "Ptr", hHash, "Ptr", buf, "UInt", bytesRead, "UInt", 0)
                }
                fileObj.Close()

                hashLen := 0
                if DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", 0, "UInt*", &hashLen, "UInt", 0) {
                    hashBuf := Buffer(hashLen)
                    if DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", hashBuf, "UInt*", &hashLen, "UInt", 0) {
                        Loop hashLen
                            hashVal .= Format("{:02x}", NumGet(hashBuf, A_Index - 1, "UChar"))
                    }
                }
            }
            DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
        }
        DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
        return hashVal
    }
}