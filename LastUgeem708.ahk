; ┌─────────────────────────────────────────────────────────┐
; │  🎨 CSP ugee M708 — SCRIPT PRINCIPAL  (v17)             │
; │                                                         │
; │  1. DIRECTIVAS GLOBALES                                 │
; │  2. VARIABLES GLOBALES                                  │
; │  3. RECARGA AUTOMÁTICA + TIMERS                         │
; │  4. HOTKEYS GLOBALES (fuera de CSP)                     │
; │  5. HOTKEYS CSP                                         │
; │     a) Selección y reselección                          │
; │     b) Deshacer / Rehacer                               │
; │     c) Herramientas (A E W Q S O V R)                   │
; │     d) Atajos con clic derecho                          │
; │     e) Modificadores de capa                            │
; │  6. FUNCIONES                                           │
; └─────────────────────────────────────────────────────────┘



; ┌───────────────────────────────────────────────────────┐
; │  1. DIRECTIVAS GLOBALES                               │
; └───────────────────────────────────────────────────────┘
#SingleInstance Force
#Persistent
#NoEnv
#UseHook
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
SetKeyDelay, -1, -1
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
SetTitleMatchMode, 2



; ┌─────────────────────────┐
; │  2. VARIABLES GLOBALES  │
; └─────────────────────────┘

; --- Auto-recarga ---
global lastModTime := ""

; --- Stylus ---
global stylusAltActive := false

; --- Selección / borde ---
global estado     := 0
global estadoAltX := false
global estadoC    := 0

; --- Herramienta E (borrador) ---
global lastE             := 0
global eTimerRunning     := 0
global colorTransparente := false
global procesando        := false

; --- Herramienta W (aerógrafo) ---
global lastW         := 0
global wTimerRunning := 0
global wAlpha        := false

; --- Herramienta Q ---
global lastQ            := 0
global qColorSecundario := false

; --- Estabilización (CSP, RButton+Q) ---
global estadoEstabilizacion := 0

; --- Tecla A ---
global lastAPress := 0

; --- Tecla S ---
global estadoCaracter := 0
global skipNextS      := false

; --- Numpad6 (escala de grises) ---
global estadoEscala := 0

; --- V (círculo + deslizador de colores) ---
global ColorToggle := false
global _vActivo    := false   ; true cuando el sistema está inicializado
global _vOculto    := false   ; true = todo oculto, false = modo hover
; Deslizador
global _dsID       := 0
global _dsVisible  := false
; Círculo de colores
global _ccID       := 0
global _ccVisible  := false

; --- Tecla O ---
global cicloO := 0

; --- Botones emergentes LEFT ---
global BotonArriba := false
global BotonAbajo  := false

; --- Historial de color ---
global historialAbierto := false
global modoHistorial    := 1    ; 1 = interactivo | 2 = fijo

; --- Acceso rápido (Shift+Q) ---
global _arID      := 0
global _arActivo  := false
global _arOculto  := false
global _arVisible := false

; --- Acceso rápido emergente (Alt+Q de CSP) ---
global _ar2ID      := 0
global _ar2Visible := false



; ┌──────────────────────────────────────────────────────────────────────┐
; │  3. RECARGA AUTOMÁTICA + TIMERS                                      │
; └──────────────────────────────────────────────────────────────────────┘

SetTimer, CheckReload,           600
SetTimer, ChequearZonaHistorial, 200
SetTimer, ChequearZonaAltA,       30
SetTimer, LoopColorV,             40
SetTimer, LoopAccesoRapido,       40
SetTimer, LoopAccesoRapidoEmerg,  40
return

; -------------------------------------------------------------
; CheckReload
; -------------------------------------------------------------
CheckReload:
{
    FileGetTime, newTime, %A_ScriptFullPath%, M
    if (lastModTime = "") {
        lastModTime := newTime
        return
    }
    if (newTime != lastModTime) {
        lastModTime := newTime
        x := (A_ScreenWidth  // 2) - 120
        y := (A_ScreenHeight // 2) - 20
        ToolTip, 💾 Script actualizado y recargado, %x%, %y%
        SoundPlay, %A_WinDir%\Media\Windows Battery Low.wav, wait
        SoundPlay, %A_WinDir%\Media\Windows Navigation Start.wav
        Sleep, 300
        ToolTip
        Reload
    }
}
return

; -------------------------------------------------------------
; ChequearZonaHistorial
; -------------------------------------------------------------
ChequearZonaHistorial:
    if !WinActive("ahk_exe CLIPStudioPaint.exe")
        return
    if (modoHistorial = 2)
        return

    MouseGetPos, mx, my
    enZona := (mx >= 79 && mx <= 1168 && my >= 626 && my <= 762)

    if (enZona && !historialAbierto)
    {
        historialAbierto := true
        Send, {Numpad9}
        ; No tocar transparencia del deslizador — LoopDeslizador lo maneja
    }
    else if (!enZona && historialAbierto)
    {
        historialAbierto := false
        Send, {Numpad9}
        ; No tocar transparencia del deslizador — LoopDeslizador lo maneja
    }
return

; -------------------------------------------------------------
; ChequearZonaAltA — botones emergentes izquierda
; -------------------------------------------------------------
ChequearZonaAltA:
    MouseGetPos, mx, my

    enZonaAltA := (mx >= 5 && mx <= 34 && my >= 105 && my <= 125)
    if (enZonaAltA && !BotonArriba) {
        BotonArriba := true
        Click
    } else if (!enZonaAltA && BotonArriba) {
        BotonArriba := false
    }

    enZonaAltA2 := (mx >= 7 && mx <= 34 && my >= 73 && my <= 95)
    if (enZonaAltA2 && !BotonAbajo) {
        BotonAbajo := true
        Click
    } else if (!enZonaAltA2 && BotonAbajo) {
        BotonAbajo := false
    }
return

; -------------------------------------------------------------
; LoopColorV — hover unificado para círculo de colores + deslizador
;   Gestiona dos ventanas independientes con sus propios bordes
;   Círculo  → borde verde  (00CC66), GUIs BordeCC_*
;   Deslizador → borde naranja (FF8C00), GUIs BordeDS_*
; -------------------------------------------------------------
LoopColorV:
    if (!_vActivo || _vOculto)
        return
    if !WinActive("ahk_exe CLIPStudioPaint.exe")
    {
        if (_dsVisible) {
            _dsVisible := false
            WinSet, Transparent, 1,    ahk_id %_dsID%
            WinSet, ExStyle,    +0x20, ahk_id %_dsID%
        }
        if (_ccVisible) {
            _ccVisible := false
            WinSet, Transparent, 1,    ahk_id %_ccID%
            WinSet, ExStyle,    +0x20, ahk_id %_ccID%
        }
        Gui, BordeDS_T:Hide
        Gui, BordeDS_B:Hide
        Gui, BordeDS_L:Hide
        Gui, BordeDS_R:Hide
        Gui, BordeCC_T:Hide
        Gui, BordeCC_B:Hide
        Gui, BordeCC_L:Hide
        Gui, BordeCC_R:Hide
        return
    }

    MouseGetPos, mx, my

    ; ── Deslizador ──────────────────────────────────────────────
    if (_dsID && WinExist("ahk_id " _dsID))
    {
        WinGetPos, dsX, dsY, dsW, dsH, ahk_id %_dsID%
        dentrods := (mx >= dsX && mx <= dsX+dsW && my >= dsY && my <= dsY+dsH)
        if (dentrods)
        {
            if (!_dsVisible)
            {
                _dsVisible := true
                WinSet, Transparent, 255,  ahk_id %_dsID%
                WinSet, ExStyle,    -0x20, ahk_id %_dsID%
                Gui, BordeDS_T:Hide
                Gui, BordeDS_B:Hide
                Gui, BordeDS_L:Hide
                Gui, BordeDS_R:Hide
            }
        }
        else
        {
            if (_dsVisible)
            {
                _dsVisible := false
                WinSet, Transparent, 1,    ahk_id %_dsID%
                WinSet, ExStyle,    +0x20, ahk_id %_dsID%
            }
            g := 1
            Gui, BordeDS_T:Show, % "x" dsX         " y" dsY         " w" dsW " h" g   " NoActivate"
            Gui, BordeDS_B:Show, % "x" dsX         " y" (dsY+dsH-g) " w" dsW " h" g   " NoActivate"
            Gui, BordeDS_L:Show, % "x" dsX         " y" dsY         " w" g   " h" dsH " NoActivate"
            Gui, BordeDS_R:Show, % "x" (dsX+dsW-g) " y" dsY         " w" g   " h" dsH " NoActivate"
        }
    }
    else if (_dsID)
    {
        ; Ventana cerrada externamente — limpiar
        _dsID      := 0
        _dsVisible := false
        Gui, BordeDS_T:Hide
        Gui, BordeDS_B:Hide
        Gui, BordeDS_L:Hide
        Gui, BordeDS_R:Hide
    }

    ; ── Círculo de colores ───────────────────────────────────────
    if (_ccID && WinExist("ahk_id " _ccID))
    {
        WinGetPos, ccX, ccY, ccW, ccH, ahk_id %_ccID%
        dentrocc := (mx >= ccX && mx <= ccX+ccW && my >= ccY && my <= ccY+ccH)
        if (dentrocc)
        {
            if (!_ccVisible)
            {
                _ccVisible := true
                WinSet, Transparent, 255,  ahk_id %_ccID%
                WinSet, ExStyle,    -0x20, ahk_id %_ccID%
                Gui, BordeCC_T:Hide
                Gui, BordeCC_B:Hide
                Gui, BordeCC_L:Hide
                Gui, BordeCC_R:Hide
            }
        }
        else
        {
            if (_ccVisible)
            {
                _ccVisible := false
                WinSet, Transparent, 1,    ahk_id %_ccID%
                WinSet, ExStyle,    +0x20, ahk_id %_ccID%
            }
            g := 1
            Gui, BordeCC_T:Show, % "x" ccX         " y" ccY         " w" ccW " h" g   " NoActivate"
            Gui, BordeCC_B:Show, % "x" ccX         " y" (ccY+ccH-g) " w" ccW " h" g   " NoActivate"
            Gui, BordeCC_L:Show, % "x" ccX         " y" ccY         " w" g   " h" ccH " NoActivate"
            Gui, BordeCC_R:Show, % "x" (ccX+ccW-g) " y" ccY         " w" g   " h" ccH " NoActivate"
        }
    }
    else if (_ccID)
    {
        ; Ventana cerrada externamente — limpiar
        _ccID      := 0
        _ccVisible := false
        Gui, BordeCC_T:Hide
        Gui, BordeCC_B:Hide
        Gui, BordeCC_L:Hide
        Gui, BordeCC_R:Hide
    }
return

; -------------------------------------------------------------
; LoopAccesoRapido — transparencia + borde hover acceso rápido
;   _arOculto = true  → modo oculto total (sin borde, no clickeable)
;   _arOculto = false → modo hover (visible dentro, borde cian fuera)
; -------------------------------------------------------------
LoopAccesoRapido:
    if (!_arActivo || _arOculto)
        return
    if !WinActive("ahk_exe CLIPStudioPaint.exe")
    {
        if (_arVisible) {
            _arVisible := false
            WinSet, Transparent, 1,    ahk_id %_arID%
            WinSet, ExStyle,    +0x20, ahk_id %_arID%
        }
        Gui, BordeAR_T:Hide
        Gui, BordeAR_B:Hide
        Gui, BordeAR_L:Hide
        Gui, BordeAR_R:Hide
        return
    }
    if (!WinExist("ahk_id " _arID))
    {
        _arActivo  := false
        _arOculto  := false
        _arID      := 0
        _arVisible := false
        Gui, BordeAR_T:Hide
        Gui, BordeAR_B:Hide
        Gui, BordeAR_L:Hide
        Gui, BordeAR_R:Hide
        return
    }
    WinGetPos, arX, arY, arW, arH, ahk_id %_arID%
    MouseGetPos, mx, my
    dentro := (mx >= arX && mx <= arX+arW && my >= arY && my <= arY+arH)

    ; DENTRO — visible y clickeable
    if (dentro)
    {
        if (!_arVisible)
        {
            _arVisible := true
            WinSet, Transparent, 255,  ahk_id %_arID%
            WinSet, ExStyle,    -0x20, ahk_id %_arID%
            Gui, BordeAR_T:Hide
            Gui, BordeAR_B:Hide
            Gui, BordeAR_L:Hide
            Gui, BordeAR_R:Hide
        }
        return
    }

    ; FUERA — casi invisible, no clickeable, borde cian
    if (_arVisible)
    {
        _arVisible := false
        WinSet, Transparent, 1,    ahk_id %_arID%
        WinSet, ExStyle,    +0x20, ahk_id %_arID%
    }
    g := 1
    Gui, BordeAR_T:Show, % "x" arX         " y" arY         " w" arW " h" g   " NoActivate"
    Gui, BordeAR_B:Show, % "x" arX         " y" (arY+arH-g) " w" arW " h" g   " NoActivate"
    Gui, BordeAR_L:Show, % "x" arX         " y" arY         " w" g   " h" arH " NoActivate"
    Gui, BordeAR_R:Show, % "x" (arX+arW-g) " y" arY         " w" g   " h" arH " NoActivate"
return

; -------------------------------------------------------------
; LoopAccesoRapidoEmerg — hover para el acceso rápido emergente (Alt+Q)
;   Solo afecta ventanas con título [Acceso rápido] que no sean _arID
;   F y otros emergentes sin ese título no son tocados
; -------------------------------------------------------------
LoopAccesoRapidoEmerg:
    if !WinActive("ahk_exe CLIPStudioPaint.exe")
    {
        if (_ar2Visible) {
            _ar2Visible := false
            WinSet, Transparent, 1, ahk_id %_ar2ID%
        }
        return
    }
    WinGet, _ar2List, List, ahk_exe CLIPStudioPaint.exe
    Loop, %_ar2List%
    {
        _ar2Tmp := _ar2List%A_Index%
        if (_ar2Tmp = _arID)
            continue
        WinGetTitle, _ar2T, ahk_id %_ar2Tmp%
        if (InStr(_ar2T, "Acceso r") && InStr(_ar2T, "pido"))
        {
            _ar2ID := _ar2Tmp
            break
        }
        _ar2ID := 0
    }

    if (!_ar2ID)
    {
        _ar2Visible := false
        return
    }

    WinGetPos, ar2X, ar2Y, ar2W, ar2H, ahk_id %_ar2ID%
    MouseGetPos, mx, my
    dentro2 := (mx >= ar2X && mx <= ar2X+ar2W && my >= ar2Y && my <= ar2Y+ar2H)

    if (dentro2)
    {
        if (!_ar2Visible)
        {
            _ar2Visible := true
            WinSet, Transparent, 255,  ahk_id %_ar2ID%
            WinSet, ExStyle,    -0x20, ahk_id %_ar2ID%
        }
    }
    else
    {
        if (_ar2Visible)
        {
            _ar2Visible := false
            WinSet, Transparent, 1,    ahk_id %_ar2ID%
        }
        else
        {
            ; Primera detección fuera del área — poner opaco de entrada
            WinSet, Transparent, 255,  ahk_id %_ar2ID%
            WinSet, ExStyle,    -0x20, ahk_id %_ar2ID%
        }
    }
return



; ┌──────────────────────────────────────────────────────┐
; │  4. HOTKEYS GLOBALES (activas en cualquier ventana)  │
; └──────────────────────────────────────────────────────┘

; -------------------------------------------------------------
; Numpad0 — alternar modo historial: interactivo ↔ fijo
; -------------------------------------------------------------
Numpad0::
    modoHistorial := (modoHistorial = 1) ? 2 : 1
    if (modoHistorial = 1)
        ToolTip, 🟢 HISTORIAL INTERACTIVO
    else
        ToolTip, 🔒 HISTORIAL FIJO
    SetTimer, OcultarToolTip, -10000
return

OcultarToolTip:
    ToolTip
return

; -------------------------------------------------------------
; | — modo escritura / modo comandos AHK
; -------------------------------------------------------------
|::
    Suspend, Permit
    modoEscritura := !modoEscritura
    if (modoEscritura) {
        Suspend, On
        MostrarIndicador("🔴📝 MODO ESCRITURA — puedes escribir libremente 📝🔴")
    } else {
        Suspend, Off
        MostrarIndicador("🟢✅ MODO AHK ACTIVO — hotkeys habilitadas ✅🟢")
    }
return

; -------------------------------------------------------------
; Space + RButton — voltear horizontal | RButton solo — passthrough
; -------------------------------------------------------------
Space & RButton::
    SendInput, !g
    ToolTip, 🎨 Space + RButton
    SoundBeep, 800, 100
    SetTimer, OcultarToolTipAltG, -700
return

RButton::
    SendInput, {RButton}
return

OcultarToolTipAltG:
    ToolTip
return

; -------------------------------------------------------------
; Tab — clic en dos puntos fijos del panel
; -------------------------------------------------------------
SendMode Input
SetBatchLines, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0

Tab::
    MouseGetPos, origX, origY
    MouseMove, 32, 64, 0
    Sleep, 8
    Click
    Sleep, 12
    MouseMove, 1400, 65, 0
    Sleep, 8
    Click
    Sleep, 12
    MouseMove, origX, origY, 0
return

; -------------------------------------------------------------
; Ctrl+S — guardar con sonido
; -------------------------------------------------------------
^s::
    SendInput, ^s
    ToolTip, 💾 GUARDADO Y MODIFICADO 💾
    SetTimer, QuitarToolTip, -800
    SetTimer, BeepGuardado, -50
return

BeepGuardado:
    SoundPlay, %A_WinDir%\Media\Windows Battery Low.wav, wait
    SoundPlay, %A_WinDir%\Media\Windows Navigation Start.wav
return

; -------------------------------------------------------------
; ~!b / ~!b up — stylus Alt+B
; -------------------------------------------------------------
~!b::    stylusAltActive := true
~!b up:: stylusAltActive := false



; ┌──────────────────┐
; │  5. HOTKEYS CSP  │
; └──────────────────┘
#IfWinActive ahk_exe CLIPStudioPaint.exe

; ┌───────────────────────────────┐
; │  5a. SELECCIÓN Y RESELECCIÓN  │
; └───────────────────────────────┘

!x::
    if estadoAltX {
        MostrarMiniTexto("👁 MOSTRAR BORDE", "2ECC71", 1200)
        estadoAltX := false
    } else {
        MostrarMiniTexto("🚫 OCULTAR BORDE", "E74C3C", 1200)
        estadoAltX := true
    }
    Send, {Alt down}{x}{Alt up}
    SetTimer, ResetEstadoAltX, -3000
return

ResetEstadoAltX:
    estadoAltX := false
return

c::
    if (estadoC = 0) {
        MostrarMiniTexto("🔄 INV. ÁREA SELECC.", "FF6F61", 900)
        estadoC := 1
    } else {
        MostrarMiniTexto("🔁 INV. ÁREA SELECC.", "000000", 900)
        estadoC := 0
    }
    Send, c
return

x::
    if (estado = 0) {
        MostrarMiniTexto("❌ DESELECCIÓN", "C0392B", 700)
        Send, x
        estado := 1
    } else {
        MostrarMiniTexto("✅ RESELECCIÓN", "27AE60", 1200)
        Send, {F10}
        estado := 0
    }
return


; ┌──────────────────────────┐
; │  5b. DESHACER / REHACER  │
; └──────────────────────────┘

^z::
    SendInput, ^z
    ToolTipCS("🔴 DESHACER", 300)
return

!z::
    SendInput, ^y
    ToolTipCS("🟢 REHACER", 600)
return

#If stylusAltActive
z::
    SendInput, ^y
    ToolTipCS("🟢 REHACER", 600)
return
#If

#IfWinActive ahk_exe CLIPStudioPaint.exe


; ┌────────────────────┐
; │  5c. HERRAMIENTAS  │
; └────────────────────┘

; ╔═══╗
; ║ A ║  simple, doble tap, Alt+A
; ╚═══╝
$a::
    now := A_TickCount
    if (now - lastAPress < 2400) {
        lastAPress := 0
        SendInput, {F7}
        ToolTip, TODAS LAS CAPAS (2)
        SetTimer, QuitarToolTip, -4300
    } else {
        lastAPress := now
        SendInput, {Blind}a
        ToolTip, CAPA ACTUAL (1)
        SetTimer, QuitarToolTip, -1300
    }
return

!a::
    Send, ñ
    ToolTip, CAPA REFERIDA (3)
    SetTimer, QuitarToolTip, -2300
return

; ╔═══╗
; ║ E ║  simple, doble tap, RButton+E
; ╚═══╝
$e::
    now := A_TickCount
    if (GetKeyState("Shift")) {
        Send, e
        return
    }
    if (now - lastE < 300) {
        SetTimer, __E_SEND_NORMAL, Off
        eTimerRunning := 0
        Send, l
        MostrarToolTipE("BORRADOR SUAVE  (2)")
        lastE := 0
        return
    }
    lastE := now
    eTimerRunning := 1
    SetTimer, __E_SEND_NORMAL, -250
return

__E_SEND_NORMAL:
    if (eTimerRunning) {
        Send, e
        MostrarToolTipE("BORRADOR NORMAL  (1)")
        eTimerRunning := 0
        lastE := 0
    }
return

RButton & e::
    if (procesando)
        return
    procesando := true
    if (colorTransparente) {
        colorTransparente := false
        MostrarToolTipE("🔴🔴COLOR🔴🔴")
    } else {
        colorTransparente := true
        MostrarToolTipE("⚪ ALPHA ⚪")
        SoundPlay, %A_WinDir%\Media\chimes.wav
    }
    Send, k
    SetTimer, ResetProcesando, -50
return

ResetProcesando:
    procesando := false
return

^e::
    ToolTip, BORRADOR DE TODAS LAS CAPAS
    Send, {F5}
    SetTimer, QuitarToolTip, -800
return

; ╔═══╗
; ║ W ║  simple, doble tap
; ╚═══╝
$w::
    now := A_TickCount
    if (now - lastW < 300) {
        SetTimer, __W_SEND_NORMAL, Off
        wTimerRunning := 0
        if (!wAlpha) {
            SendInput, k
            wAlpha := true
        }
        SendInput, {Blind}w
        MostrarToolTipE("⚪ AERÓGRAFO ALPHA")
        SoundPlay, %A_WinDir%\Media\chimes.wav
        lastW := 0
        return
    }
    lastW := now
    wTimerRunning := 1
    SetTimer, __W_SEND_NORMAL, -250
return

__W_SEND_NORMAL:
    if (wTimerRunning) {
        if (wAlpha) {
            SendInput, k
            wAlpha := false
        }
        SendInput, {Blind}w
        MostrarToolTipE("💨 AERÓGRAFO")
        wTimerRunning := 0
        lastW := 0
    }
return

; ╔═══╗
; ║ Q ║  simple, doble tap, RButton+Q (estabilización)
; ╚═══╝

$q::
    now := A_TickCount
    if (now - lastQ < 300) {
        lastQ := 0
        SetTimer, __Q_SEND_NORMAL, Off
        SendInput, ^2
        qColorSecundario := !qColorSecundario
        if (qColorSecundario) {
            MostrarToolTipE("🟡 COLOR SECUNDARIO")
            SoundPlay, %A_WinDir%\Media\Windows Battery Low.wav
        } else {
            MostrarToolTipE("🔵 COLOR PRINCIPAL")
        }
        return
    }
    lastQ := now
    if GetKeyState("RButton", "P") {
        Gosub, AlternarEstabilizacion
        return
    }
    SetTimer, __Q_SEND_NORMAL, -50
return

__Q_SEND_NORMAL:
    SendInput, q
return


; ╔═══╗
; ║ - ║  alternar estabilización alta ↔ baja
; ╚═══╝
-::
    Gosub, AlternarEstabilizacion
return

AlternarEstabilizacion:
    if (estadoEstabilizacion = 0) {
        estadoEstabilizacion := 1
        mensaje   := "🟢 Estabilización Alta"
        duracionTT := 1600
    } else {
        estadoEstabilizacion := 0
        mensaje   := "🔵 Estabilización Baja"
        duracionTT := 400
        SoundPlay, %A_WinDir%\Media\Windows Battery Low.wav
    }
    ToolTip, %mensaje%
    SetTimer, OcultarToolTipQ, -%duracionTT%
    if (estadoEstabilizacion = 1) {
        SetKeyDelay, -1, -1
        SendEvent, {Blind}{- 64}
    } else {
        SetKeyDelay, -1, -1
        SendEvent, {Blind}{j 64}
    }
return

OcultarToolTipQ:
    ToolTip
return

; ╔══════════╗
; ║ Shift+Q  ║  acceso rápido — hover invisible / modo oculto
; ╚══════════╝
;   1ª pulsación → busca "Acceso rápido", crea los 4 GUIs de borde
;                  y activa modo hover (visible dentro, borde fuera)
;   Siguientes   → alterna hover ↔ oculto total
+q::
    ; ── Primera activación: buscar la ventana ──────────────────
    if (!_arActivo)
    {
        WinGet, _arList, List, ahk_exe CLIPStudioPaint.exe
        Loop, %_arList%
        {
            _arTmpID := _arList%A_Index%
            WinGetTitle, _arTmpT, ahk_id %_arTmpID%
            if (InStr(_arTmpT, "Acceso r") && InStr(_arTmpT, "pido"))
            {
                _arID := _arTmpID
                break
            }
        }
        if (!_arID)
        {
            ToolTip, Abre primero el panel Acceso rapido en CSP
            SetTimer, QuitarToolTip, -1800
            return
        }
        _arActivo  := true
        _arOculto  := false
        _arVisible := false
        color := "00FFFF"
        Gui, BordeAR_T:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeAR_T:Color, %color%
        Gui, BordeAR_T:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeAR_T
        Gui, BordeAR_B:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeAR_B:Color, %color%
        Gui, BordeAR_B:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeAR_B
        Gui, BordeAR_L:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeAR_L:Color, %color%
        Gui, BordeAR_L:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeAR_L
        Gui, BordeAR_R:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeAR_R:Color, %color%
        Gui, BordeAR_R:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeAR_R
        ToolTip, ACCESO RAPIDO - modo hover ON
        SetTimer, QuitarToolTip, -1200
        return
    }

    ; ── Pulsaciones siguientes: alternar hover ↔ oculto ────────
    _arOculto := !_arOculto

    if (_arOculto)
    {
        Gui, BordeAR_T:Hide
        Gui, BordeAR_B:Hide
        Gui, BordeAR_L:Hide
        Gui, BordeAR_R:Hide
        WinSet, Transparent, 1,    ahk_id %_arID%
        WinSet, ExStyle,    +0x20, ahk_id %_arID%
        _arVisible := false
        ToolTip, ACCESO RAPIDO - oculto
    }
    else
    {
        WinSet, Transparent, 255,  ahk_id %_arID%
        WinSet, ExStyle,    -0x20, ahk_id %_arID%
        _arVisible := true
        ToolTip, ACCESO RAPIDO - modo hover ON
    }
    SetTimer, QuitarToolTip, -1200
return

; ╔═══╗
; ║ S ║  simple, doble tap, Espacio+S
; ╚═══╝
$s::
    if (A_PriorHotkey = "$s" && A_TimeSincePriorHotkey < 250) {
        skipNextS := true
        MostrarMiniGUI("🟢 ÁREA CON COLOR", "27AE60")
        SendInput, ^x
        SendInput, !x
        SoundPlay, %A_WinDir%\Media\Windows Exclamation.wav
        return
    }
    if GetKeyState("Space", "P") {
        skipNextS := true
        if (estadoCaracter = 0) {
            Send, ,
            MostrarTooltipToggle("AGREGAR A SELECCION", "+", "verde")
            estadoCaracter := 1
        } else {
            Send, .
            MostrarTooltipToggle("ELIMINAR SELECCIÓN", "–", "rojo")
            estadoCaracter := 0
        }
        SetTimer, QuitarTooltipToggle, -1500
        return
    }
    if (skipNextS) {
        skipNextS := false
        return
    }
    Send, s
return

; ╔═══╗
; ║ O ║  ciclo 3 estados
; ╚═══╝
$o::
    cicloO := Mod(cicloO, 3) + 1
    if (cicloO = 1) {
        Send, h
        ToolTip, BUSCAR CAPAS (1/3)
    } else if (cicloO = 2) {
        SendInput, {Ctrl down}{Numpad1}{Ctrl up}
        ToolTip, COLOR CAPA (2/3)
    } else {
        SendInput, {Ctrl down}{Numpad2}{Ctrl up}
        ToolTip, BORRAR COLOR CAPA (3/3)
    }
    SetTimer, QuitarToolTip, -2000
return

$Escape::
    if (cicloO != 0) {
        cicloO := 0
        ToolTip, CICLO O RESETADO
        SetTimer, QuitarToolTip, -1000
    }
    Send, {Escape}
return

; ╔═══╗
; ║ V ║  círculo de colores + deslizador — hover unificado
; ╚═══╝
;   v (1er tap) → abre ambas ventanas en CSP + activa hover
;   v (2do tap) → toggle hover ↔ oculto total (antes era !v)
v::
    ; ── Siempre: enviar a CSP ──────────────────────────────────────────
    Send, v
    Sleep, 30
    SendInput, {Blind}{Alt down}v{Alt up}
    Sleep, 120

    ; ── Siempre: buscar/actualizar IDs ─────────────────────────────────
    if (!_dsID || !WinExist("ahk_id " _dsID))
    {
        _dsID      := 0
        _dsVisible := false
        WinGet, _tmpList, List, ahk_exe CLIPStudioPaint.exe
        Loop, %_tmpList%
        {
            _tmpID := _tmpList%A_Index%
            WinGetTitle, _tmpT, ahk_id %_tmpID%
            if (InStr(_tmpT, "eslizador") && InStr(_tmpT, "colores"))
            {
                _dsID := _tmpID
                break
            }
        }
    }

    if (!_ccID || !WinExist("ahk_id " _ccID))
    {
        _ccID      := 0
        _ccVisible := false
        WinGet, _tmpList, List, ahk_exe CLIPStudioPaint.exe
        Loop, %_tmpList%
        {
            _tmpID := _tmpList%A_Index%
            WinGetTitle, _tmpT, ahk_id %_tmpID%
            if (InStr(_tmpT, "rculo") && InStr(_tmpT, "colores"))
            {
                _ccID := _tmpID
                break
            }
        }
    }

    ; ── 1er tap: crear GUIs de borde y activar hover ───────────────────
    if (!_vActivo)
    {
        _vActivo := true
        _vOculto := false

        color1 := "FF8C00"
        Gui, BordeDS_T:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeDS_T:Color, %color1%
        Gui, BordeDS_T:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeDS_T
        Gui, BordeDS_B:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeDS_B:Color, %color1%
        Gui, BordeDS_B:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeDS_B
        Gui, BordeDS_L:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeDS_L:Color, %color1%
        Gui, BordeDS_L:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeDS_L
        Gui, BordeDS_R:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeDS_R:Color, %color1%
        Gui, BordeDS_R:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeDS_R

        color2 := "00CC66"
        Gui, BordeCC_T:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeCC_T:Color, %color2%
        Gui, BordeCC_T:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeCC_T
        Gui, BordeCC_B:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeCC_B:Color, %color2%
        Gui, BordeCC_B:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeCC_B
        Gui, BordeCC_L:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeCC_L:Color, %color2%
        Gui, BordeCC_L:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeCC_L
        Gui, BordeCC_R:-Caption +AlwaysOnTop +ToolWindow +E0x20
        Gui, BordeCC_R:Color, %color2%
        Gui, BordeCC_R:Show, w0 h0 NoActivate
        WinSet, Transparent, 180, BordeCC_R
    }

    ; ── 2do tap+: toggle hover ↔ oculto (antes era !v) ─────────────────
    else
    {
        _vOculto := !_vOculto

        if (_vOculto)
        {
            Gui, BordeDS_T:Hide
            Gui, BordeDS_B:Hide
            Gui, BordeDS_L:Hide
            Gui, BordeDS_R:Hide
            Gui, BordeCC_T:Hide
            Gui, BordeCC_B:Hide
            Gui, BordeCC_L:Hide
            Gui, BordeCC_R:Hide
            if (_dsID && WinExist("ahk_id " _dsID))
            {
                WinSet, Transparent, 1,    ahk_id %_dsID%
                WinSet, ExStyle,    +0x20, ahk_id %_dsID%
            }
            if (_ccID && WinExist("ahk_id " _ccID))
            {
                WinSet, Transparent, 1,    ahk_id %_ccID%
                WinSet, ExStyle,    +0x20, ahk_id %_ccID%
            }
            _dsVisible := false
            _ccVisible := false
            CustomToolTip("⚫ COLOR — oculto")
            return
        }
        else
        {
            _dsVisible := false
            _ccVisible := false
            if (_dsID && WinExist("ahk_id " _dsID))
            {
                WinSet, Transparent, 1,    ahk_id %_dsID%
                WinSet, ExStyle,    -0x20, ahk_id %_dsID%
            }
            if (_ccID && WinExist("ahk_id " _ccID))
            {
                WinSet, Transparent, 1,    ahk_id %_ccID%
                WinSet, ExStyle,    -0x20, ahk_id %_ccID%
            }
        }
    }

    ; ── Transparencia inicial — el loop toma el control ────────────────
    if (_dsID)
        WinSet, Transparent, 1, ahk_id %_dsID%
    if (_ccID)
        WinSet, Transparent, 1, ahk_id %_ccID%

    CustomToolTip("🟠 COLOR — hover ON")
return

; ╔═══╗
; ║ R ║  reflejar horizontalmente
; ╚═══╝
+r::
    CustomToolTip("REFLEJAR HORIZONTALMENTE")
    Send, +r
return

#IfWinActive


; ┌─────────────────────────────────────┐
; │  5d. ATAJOS CON CLIC DERECHO        │
; └─────────────────────────────────────┘

RButton & v::
    ToolTip, RELLENO DE COLOR
    Send, {F11}
    SetTimer, QuitarToolTip, -800
return

RButton & s::
    ToolTip, LAZO CON AUTORELLENO
    Send, {F9}
    SetTimer, QuitarToolTip, -1200
return

RButton & 1::
RButton & 2::
RButton & 3::
RButton & 4::
RButton & 5::
RButton & 6::
RButton & 7::
RButton & 8::
RButton & 9::
RButton & 0::
{
    key        := SubStr(A_ThisHotkey, 0)
    porcentaje := (key = 0 ? 100 : key * 10)
    ToolTip, % "OPACIDAD " porcentaje "%"
    Send, +%key%
    SetTimer, QuitarToolTip, -1500
    return
}


; ┌─────────────────────────────────────┐
; │  5e. MODIFICADORES DE CAPA          │
; └─────────────────────────────────────┘

~Space & NumpadAdd:: Send, +p
~Space & NumpadSub:: Send, ^+p

~Space & Numpad1::
~Space & Numpad2::
~Space & Numpad3::
~Space & Numpad4::
~Space & Numpad5::
~Space & Numpad6::
{
    tecla := SubStr(A_ThisHotkey, 0)
    tipos := {1: "HSV (Hue / Sat / Val)"
            , 2: "Brillo / Contraste"
            , 3: "Equilibrio de color"
            , 4: "Curva de tonos"
            , 5: "Corrección de nivel"
            , 6: "Degradado"}
    ToolTip, % "Capa: " tipos[tecla]
    Send, ^!%tecla%
    SetTimer, QuitarToolTip, -500
    return
}

$Numpad6::
    if (estadoEscala = 0) {
        Send, 7
        ToolTip, CAPA ESCALA DE GRISES
        estadoEscala := 1
    } else {
        Send, 8
        ToolTip, BORRAR CAPA DE CORRECCIÓN
        estadoEscala := 0
    }
    SetTimer, QuitarToolTip, -1200
return

*Backspace::
    if GetKeyState("Space", "P") {
        Send, 8
        ToolTip, BORRAR CAPA DE CORRECCIÓN
        SetTimer, QuitarToolTip, -1200
        estadoEscala := 0
        return
    } else {
        Send, {Backspace}
    }
return

~Space::return

#IfWinActive



; ┌────────────────────────────────────────────────────────────────┐
; │  6. FUNCIONES                                                  │
; └────────────────────────────────────────────────────────────────┘

MostrarIndicador(texto) {
    ToolTip, %texto%
    SetTimer, OcultarIndicador, -2500
}
OcultarIndicador:
    ToolTip
return

MostrarToolTipE(texto, duracion := 10050) {
    x := A_ScreenWidth // 2
    y := 115
    ToolTip, %texto%, %x%, %y%
    SetTimer, QuitarToolTip, -%duracion%
}

ToolTipCS(texto, duracion := 800) {
    WinGetPos, wx, wy, ww, wh, A
    x := wx + (ww // 2)
    y := wy + 125
    ToolTip, %texto%, %x%, %y%
    SetTimer, QuitarToolTip, -%duracion%
}

CustomToolTip(text, duration := 1500) {
    ToolTip, % text, , , 2
    SetTimer, RemoveCustomToolTip, % -duration
}
RemoveCustomToolTip:
    ToolTip, , , , 2
return

MostrarMiniTexto(texto, colorHex := "222222", duracion := 800) {
    Gui, MiniTip:Destroy
    Gui, MiniTip:-Caption +AlwaysOnTop +ToolWindow +E0x20
    Gui, MiniTip:Color, %colorHex%
    Gui, MiniTip:Font, s6.5 Bold, Segoe UI
    Gui, MiniTip:Add, Text, cFFFFFF Center, %texto%
    Gui, MiniTip:Show, NoActivate AutoSize
    WinSet, Transparent, 200, MiniTip
    SysGet, sw, 78
    SysGet, sh, 79
    WinGetPos, , , w, h, MiniTip
    x := (sw - w) // 2
    y := (sh * 0.82)
    WinMove, MiniTip,, x, y
    if (w > 300)
        Gui, MiniTip:Show, w300, h%h%
    SetTimer, OcultarMiniTip, -%duracion%
}
OcultarMiniTip:
    Gui, MiniTip:Destroy
return

MostrarMiniGUI(texto, colorHex := "222222", duracion := 1200) {
    Gui, MiniGUI:Destroy
    Gui, MiniGUI:-Caption +AlwaysOnTop +ToolWindow +E0x20
    Gui, MiniGUI:Color, %colorHex%
    Gui, MiniGUI:Font, s6.5 Bold, Segoe UI
    Gui, MiniGUI:Add, Text, cFFFFFF Center, %texto%
    Gui, MiniGUI:Show, AutoSize NoActivate
    WinSet, Transparent, 200, ahk_class AutoHotkeyGUI
    SysGet, sw, 0
    SysGet, sh, 1
    WinGetPos, , , w, h, MiniGUI
    x := (sw - w) // 2
    y := Round(sh * 0.02)
    WinMove, MiniGUI,, x, y
    SetTimer, OcultarMiniGUI, -%duracion%
}
OcultarMiniGUI:
    Gui, MiniGUI:Destroy
return

MostrarTooltipToggle(titulo, simbolo, color) {
    Gui, TooltipToggle:Destroy
    Gui, TooltipToggle:+AlwaysOnTop -Caption +ToolWindow +E0x20
    if (color = "verde") {
        Gui, TooltipToggle:Color, 0x1F4D3A
        Gui, TooltipToggle:Font, s7.5 Bold cWhite, Segoe UI
        simboloColor := "Lime"
    } else {
        Gui, TooltipToggle:Color, 0xD92B2B
        Gui, TooltipToggle:Font, s7.5 Bold cWhite, Segoe UI
        simboloColor := "White"
    }
    Gui, TooltipToggle:Add, Text, x6 y4 w130 h14 Center, %titulo%
    Gui, TooltipToggle:Font, s8.5 Bold c%simboloColor%
    Gui, TooltipToggle:Add, Text, x140 y2 w14 h14 Center, %simbolo%
    Gui, TooltipToggle:Show, w155 h20 Center NoActivate
}
QuitarTooltipToggle:
    Gui, TooltipToggle:Destroy
return

SendKeyWithBoost(key, startTick) {
    global HoldDelay, MaxBoost
    elapsed := A_TickCount - startTick
    if (elapsed < HoldDelay)
        return
    ratio := (elapsed - HoldDelay) / 100
    if (ratio > 1)
        ratio := 1
    boost := Round(MaxBoost * (ratio ** 0.1))
    if (boost < 1)
        boost := 1
    Loop % boost
        SendInput {Blind}%key%
}

QuitarToolTip:
    ToolTip
return
