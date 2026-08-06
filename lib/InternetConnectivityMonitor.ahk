#Requires AutoHotkey v2.0.0+
;==============================================================
; InternetConnectivityMonitor — Internet connect/disconnect event monitor (NLM events + connectivity query)
;
; GitHub: https://github.com/SevenKeyboard/internet-connectivity-monitor
; Author: SevenKeyboard Ltd. (2025)
; License: MIT License
;
; Documentation / References:
;   IConnectionPoint interface (ocidl.h)
;   IConnectionPointContainer interface (ocidl.h)
;     C:\Program Files (x86)\Windows Kits\10\Include\10.0.xxxxx.0\um\ocidl.h
;     https://learn.microsoft.com/en-us/windows/win32/api/ocidl/nn-ocidl-iconnectionpoint
;     https://learn.microsoft.com/en-us/windows/win32/api/ocidl/nn-ocidl-iconnectionpointcontainer
;   INetworkListManagerEvents interface (netlistmgr.h)
;     C:\Program Files (x86)\Windows Kits\10\Include\10.0.xxxxx.0\um\netlistmgr.h
;     https://learn.microsoft.com/en-us/windows/win32/api/netlistmgr/nn-netlistmgr-inetworklistmanagerevents
;
;   Alert on internet connect or disconnect
;     https://www.autohotkey.com/boards/viewtopic.php?t=113844
;==============================================================

/*
Example Usage:

    persistent(true)
    InternetConnectivityMonitor.onEvent(onInternetConnectivityChanged)
    onInternetConnectivityChanged(connectivity)    {
        msgbox(connectivity)
    }
    
    F2::msgbox(InternetConnectivityMonitor.isConnected())
    F3::msgbox(InternetConnectivityMonitor.isConnected(true))
*/

class VersionManager_InternetConnectivityMonitor
{
    static _ := this._init()
    static _init()    {
        global
        INTERNETCONNECTIVITYMONITOR_VERSION := "1.0.3"
    }
}
class InternetConnectivityMonitor
{
    static _isConnected := false
        ,_callbacks := []
        ,_activeCallbackInvoker     := objBindMethod(this, "_invokeCallbacks", true)
        ,_inactiveCallbackInvoker   := objBindMethod(this, "_invokeCallbacks", false)
    static isConnected(useCache := false)    {
        static NLM_CONNECTIVITY_IPV4_INTERNET   := 0x40
            ,NLM_CONNECTIVITY_IPV6_INTERNET     := 0x400
        switch (!!useCache)
        {
            case true:
                if (!this._initNetworkMonitoring())
                    return false
                return this._isConnected
            default:
                if (!this._initNetworkListManager())
                    return false
                try  {
                    connectivity := this._networkListManager.getConnectivity()
                }  catch  {
                    return false
                }
                return !!(connectivity & NLM_CONNECTIVITY_IPV4_INTERNET || connectivity & NLM_CONNECTIVITY_IPV6_INTERNET)
        }
    }
    static onEvent(callback, addRemove := 1)    {
        ok := this._initNetworkMonitoring()
        for i, v in this._callbacks    {
            if (v == callback)    {
                this._callbacks.removeAt(i)
                break
            }
        }
        switch (addRemove)
        {
            case 1:     this._callbacks.push(callback)
            case -1:    this._callbacks.insertAt(1, callback)
        }
        return ok
    }
    static isEventRegistered(callback)    {
        for v in this._callbacks    {
            if (v == callback)
                return true
        }
        return false
    }
    ;------------------------------------
    static _delayedInvokeTimer(connectivity, delayTick := 1)    {
        this._isConnected := connectivity
        switch (connectivity)
        {
            case true:  setTimer(this._activeCallbackInvoker, -abs(delayTick))
            default:    setTimer(this._inactiveCallbackInvoker, -abs(delayTick))
        }
    }
    static _invokeCallbacks(connectivity)    {
        for v in this._callbacks
            v.call(connectivity)
    }
    static _initNetworkListManager()    {
        static CLSID_NetworkListManager := "{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"
        if (!this.hasProp("_networkListManager"))    {
            try  {
                this._networkListManager := comObject(CLSID_NetworkListManager)
            }  finally  {
                if (this.hasProp("_networkListManager") && this._networkListManager == "")
                    this.deleteProp("_networkListManager")
            }
        }
        return (this.hasProp("_networkListManager"))
    }
    static _initNetworkMonitoring()    {
        static isInitialized := false
            ,IID_IConnectionPointContainer  := "{B196B284-BAB4-101A-B69C-00AA00341D07}"
            ,IID_INetworkListManagerEvents  := "{DCB00001-570F-4A9B-8D69-199FDBA5723B}"
            ,NLM_CONNECTIVITY_IPV4_INTERNET := 0x40
            ,NLM_CONNECTIVITY_IPV6_INTERNET := 0x400
            ,GMEM_FIXED := 0x0000
            ,S_OK := 0x00000000
        if (isInitialized)
            return true
        if (!this._initNetworkListManager())
            return false
        try  {
            connectivity := this._networkListManager.getConnectivity()
        }  catch  {
            return false
        }
        internetExist:= this._isConnected:= !!(connectivity & NLM_CONNECTIVITY_IPV4_INTERNET || connectivity & NLM_CONNECTIVITY_IPV6_INTERNET)
        events := [3    ;  QueryInterface
            ,1          ;  AddRef
            ,1          ;  Release
            ,2]         ;  ConnectivityChanged
        this._callbackTable := buffer(byteSize := A_PtrSize * events.Length, 0)
        for i, paramCount in events    {
            numPut("Ptr"
                ,callbackCreate(objBindMethod(this, "_networkListManagerEventsSink", methodIndex := i - 1), "Fast", paramCount)
                ,this._callbackTable.Ptr
                ,A_PtrSize * (i - 1))
        }
        pSink := dllCall("Kernel32.dll\GlobalAlloc", "UInt",GMEM_FIXED, "UPtr",A_PtrSize + 8, "Ptr")
        if (!pSink)    {
            this._freeCallbackTable()
            return false
        }
        numPut("Ptr",this._callbackTable.Ptr    ,pSink + 0, 0)
        numPut("UInt",internetExist             ,pSink + 0, A_PtrSize)
        numPut("UInt",refCount := 0             ,pSink + 0, A_PtrSize + 4)
        try  {
            connectionPointContainer := comObjQuery(this._networkListManager, IID_IConnectionPointContainer)
        }  catch  {
            connectionPointContainer := ""
        }
        if (!connectionPointContainer)    {
            dllCall("Kernel32.dll\GlobalFree", "Ptr",pSink, "Ptr")
            this._freeCallbackTable()
            return false
        }
        clsid := buffer(16, 0)
        dllCall("Ole32.dll\CLSIDFromString", "WStr",IID_INetworkListManagerEvents, "Ptr",clsid.Ptr, "Int")
        ;  IConnectionPointContainer::FindConnectionPoint
        hr := comCall(4, connectionPointContainer, "Ptr",clsid.Ptr, "Ptr*",&(connectionPoint := 0), "Int")
        connectionPointContainer := ""
        if (hr !== S_OK || !connectionPoint)    {
            dllCall("Kernel32.dll\GlobalFree", "Ptr",pSink, "Ptr")
            this._freeCallbackTable()
            return false
        }
        ;  IConnectionPoint::Advise
        hr := comCall(5, connectionPoint, "Ptr",pSink, "UInt*",&(nCookie := 0), "Int")
        if (hr !== S_OK || !nCookie)    {
            objRelease(connectionPoint)
            dllCall("Kernel32.dll\GlobalFree", "Ptr",pSink, "Ptr")
            this._freeCallbackTable()
            return false
        }
        this._connectionPoint := connectionPoint
        this._nCookie := nCookie        
        onExit(objBindMethod(this, "_onApplicationExit"))
        isInitialized := true
        return true
    }
    static _freeCallbackTable()    {
        if (this.hasProp("_callbackTable") && this._callbackTable)    {
            loop (this._callbackTable.Size // A_PtrSize)    {
                addr := numGet(this._callbackTable.Ptr, A_PtrSize * (A_Index - 1), "Ptr")
                if (addr)
                    callbackFree(addr)
            }
            this._callbackTable := ""
        }
    }
    static _onApplicationExit(exitReason, exitCode)    {
        connectionPoint := this._connectionPoint
        nCookie := this._nCookie
        this._connectionPoint := 0
        this._nCookie := 0
        if (connectionPoint)    {
            ;  IConnectionPoint::Unadvise
            comCall(6, connectionPoint, "UInt",nCookie, "Int")
            objRelease(connectionPoint)
        }
    }
    static _ := this._initGuidBuffers()
    static _initGuidBuffers()    {
        static IID_IUnknown                 := "{00000000-0000-0000-C000-000000000046}"
            ,IID_INetworkListManagerEvents  := "{DCB00001-570F-4A9B-8D69-199FDBA5723B}"
        this._guidIUnknown := buffer(16, 0)
        this._guidINetworkListManagerEvents := buffer(16, 0)
        dllCall("Ole32.dll\CLSIDFromString", "WStr",IID_IUnknown, "Ptr",this._guidIUnknown.Ptr, "Int")
        dllCall("Ole32.dll\CLSIDFromString", "WStr",IID_INetworkListManagerEvents, "Ptr",this._guidINetworkListManagerEvents.Ptr, "Int")
    }
    static _networkListManagerEventsSink(methodIndex, pSink, arg2?, arg3?)    {
        static NLM_CONNECTIVITY_IPV4_INTERNET   := 0x40
            ,NLM_CONNECTIVITY_IPV6_INTERNET     := 0x400
            ,E_NOINTERFACE := 0x80004002
        switch (methodIndex)
        {
            case 0: ;  INetworkListManagerEvents::QueryInterface
                riid := arg2
                ppvObject := arg3
                if (dllCall("Ole32.dll\IsEqualGUID", "Ptr",riid, "Ptr",this._guidIUnknown.Ptr, "Int") || dllCall("Ole32.dll\IsEqualGUID", "Ptr",riid, "Ptr",this._guidINetworkListManagerEvents.Ptr, "Int"))    {
                    numPut("Ptr",pSink, ppvObject + 0, 0)
                    refCount := numGet(pSink + 0, A_PtrSize + 4, "UInt")
                    numPut("UInt",++refCount, pSink + 0, A_PtrSize + 4)
                    return 0
                }  else  {
                    numPut("Ptr",0, ppvObject + 0, 0)
                    return E_NOINTERFACE
                }
            case 1: ;  INetworkListManagerEvents::AddRef
                refCount := numGet(pSink + 0, A_PtrSize + 4, "UInt")
                numPut("UInt",++refCount, pSink + 0, A_PtrSize + 4)
                return refCount
            case 2: ;  INetworkListManagerEvents::Release
                refCount := numGet(pSink + 0, A_PtrSize + 4, "UInt")
                if (0 < refCount)    {
                    numPut("UInt",--refCount, pSink + 0, A_PtrSize + 4)
                    if (refCount == 0)
                        dllCall("Kernel32.dll\GlobalFree", "Ptr",pSink, "Ptr")
                }
                return refCount
            case 3: ;  INetworkListManagerEvents::ConnectivityChanged
                newConnectivity := arg2
                internetExist := numGet(pSink + 0, A_PtrSize, "UInt")
                if (newConnectivity & NLM_CONNECTIVITY_IPV4_INTERNET || newConnectivity & NLM_CONNECTIVITY_IPV6_INTERNET)    {
                    if (!internetExist)
                        this._delayedInvokeTimer(internetExist := true)
                }  else  {
                    if (internetExist)
                        this._delayedInvokeTimer(internetExist := false)
                }
                numPut("UInt",internetExist, pSink + 0, A_PtrSize)
                return 0
        }
    }
}