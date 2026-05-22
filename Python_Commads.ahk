; =============================================================
; 🔄 AUTO-RECARGA + TOOLTIP + SONIDO (PYTHON AHK)
; =============================================================

#SingleInstance Force
#Persistent
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; ------------------------------------------------------------
SetTimer, CheckReload, 600
global lastModTime := ""

CheckReload:
    FileGetTime, newTime, %A_ScriptFullPath%, M
    if (lastModTime = "") {
        lastModTime := newTime
        return
    }
    if (newTime != lastModTime) {
        lastModTime := newTime

        ; 📌 Tooltip centrado
        x := (A_ScreenWidth // 2) - 170
        y := (A_ScreenHeight // 2) - 20
        ToolTip, 🐍 Python AHK actualizado y recargado, %x%, %y%

        ; 🔔 Sonido confirmación (modo código / ejecución)
        SoundBeep, 800, 80
        SoundBeep, 1000, 80
        SoundBeep, 1200, 80
        SoundBeep, 1000, 80
        SoundBeep, 1400, 120

        Sleep, 400
        ToolTip
        Reload
    }
return
; ------------------------------------------------------------
; 🔻 HOTKEYS PYTHON (DESDE AQUÍ)
;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#UseHook
SendMode Input
#MaxThreadsPerHotkey 1
;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; -------------------------------------------------------------
; Ctrl+G — commit + push a GitHub
; -------------------------------------------------------------
^g::
    FormatTime, ts,, yyyy-MM-dd_HH-mm-ss
    repoPath := "C:\Users\JOSUE BG\Documents\autohotkeys\Comandos Globales AHK"
    cmd := "git -C """ . repoPath . """ add -A && git -C """ . repoPath . """ commit -m ""auto_" . ts . """ && git -C """ . repoPath . """ push"
    Run, cmd /c %cmd%, , Hide
    ToolTip, ⏳ Guardando en GitHub...
    SetTimer, _CheckGitDone, -3000
return

_CheckGitDone:
    ToolTip, ✅ GitHub actualizado
    SoundPlay, %A_WinDir%\Media\Windows Navigation Start.wav
    SetTimer, QuitarToolTip, -2000
return

QuitarToolTip:
    ToolTip
return

;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; 🚀 Alt + P → Pegar paquete de librerías Encoders de Python
; ------------------------------------------------------------
!p::  ; Alt + P
Clipboard := "
(
# paquete librerias basicas y de sklearn
import pandas as pd
import numpy as np
import seaborn as sea
import matplotlib.pyplot as plt

from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline

from sklearn.preprocessing import OneHotEncoder
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import OrdinalEncoder
from sklearn.preprocessing import StandardScaler

from sklearn.model_selection import train_test_split as tts
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier, KNeighborsRegressor
from sklearn.tree import DecisionTreeClassifier, DecisionTreeRegressor
from sklearn.ensemble import RandomForestClassifier


from sklearn.metrics import r2_score
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.metrics import classification_report

)"
Send ^v  ; Pega automáticamente
return

;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; 🚀 Alt + A → ENVOLVER CON DISPLAY
; ------------------------------------------------------------
$!a::
    SendInput, {Home}
    SendInput, display(
    SendInput, {End}
    SendInput, )
return

;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; 🚀 Ctrl + I → Inserta bloque de IPython Image
; ------------------------------------------------------------
^i::
    SendInput, from IPython.display import Image, display`n
    SendInput, ruta = r""`n
    SendInput, display(Image(filename=ruta))`n
    Send, {Up}
    Send, {End}
    Send, {Left 1}
return

;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; 🚀 Alt + , → Insertar "", "" y colocar cursor dentro del primer par de comillas
; ------------------------------------------------------------
!,:: 
    Send, "",      
    Send, {Left 2} 
return

;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; 🚀 Ctrl + Enter → Ejecutar celda
; ------------------------------------------------------------
^!Enter:: SendInput, ^{Enter}

;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; 🚀 Alt + C → Calidad de líneas
; ------------------------------------------------------------
!c::  ; Alt + C
Clipboard := "
(
calidad = pd.DataFrame({
    'Duplicados':df.duplicated().mean(),
    'Nulos': df.isnull().sum(),
    'Porcentaje_nulos': df.isnull().mean() * 100,
    'Valores_unicos': df.nunique(),
    'dtypes': df.dtypes,
    
}) # esta presentado sobre % de las columnas

display(calidad)
)"
Send ^v
return

;■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
