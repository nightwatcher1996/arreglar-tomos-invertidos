@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Arreglar Tomos Invertidos

set "scriptDir=%~dp0"
set "parentDir=%scriptDir:..\=%"
if "!parentDir!"=="!scriptDir!" (
    for %%A in ("%scriptDir:~0,-1%") do set "parentDir=%%~dpA"
)
cd /d "%scriptDir%"
set "logFile=%parentDir%%~n0.undo.log"
set "tmpList=%parentDir%arreglar_tomos_list_%RANDOM%.txt"

:menu
cls
echo ================================
echo     Arreglar Tomos Invertidos
echo ================================
echo.
echo 1) Intercambiar nombres
echo 2) Deshacer cambios
echo 3) Salir
echo.
set /p "opcion=Seleccione una opcion: "

if /I "%opcion%"=="1" goto Intercambiar
if /I "%opcion%"=="2" goto Deshacer
if /I "%opcion%"=="3" exit /b
echo Opcion invalida.
ping -n 2 127.0.0.1 >nul
goto menu

:Intercambiar
set "logFile=%parentDir%%~n0.undo.log"
if exist "%logFile%" del /f /q "%logFile%"

REM Crear un archivo temporal con la lista ordenada en el directorio superior
set "tmpList=%parentDir%arreglar_tomos_list_%RANDOM%.txt"
dir /b /a-d "%scriptDir%" > "%tmpList%"

REM Contar archivos válidos
set "count=0"
for /f "delims=" %%F in ('type "%tmpList%"') do (
    set "nombre=%%F"
    if /I not "!nombre!"=="%~nx0" if /I not "!nombre!"=="%~n0.undo.log" (
        set /a count+=1
        set "archivos[!count!]=!nombre!"
    )
)

del /f /q "%tmpList%"

if "%count%"=="0" (
    echo No hay archivos para intercambiar en esta carpeta.
    echo.
    pause
    goto menu
)

if "%count%"=="1" (
    echo Solo hay un archivo, no se puede intercambiar.
    echo.
    pause
    goto menu
)

set "pares=0"
for /L %%I in (1,2,%count%) do (
    set /a next=%%I+1
    if not %%I GTR %count% if not !next! GTR %count% (
        set "a=!archivos[%%I]!"
        set "b=!archivos[!next!]!"
        if not "!a!"=="" if not "!b!"=="" (
            if /I not "!a!"=="!b!" (
                set "tmp=%parentDir%__arreglar_tomos_tmp_!RANDOM!"
                
                echo Intercambiando: !a! ^<-^> !b!
                
                if exist "!a!" (
                    ren "!a!" "!tmp!"
                    if exist "!b!" (
                        ren "!b!" "!a!"
                    )
                    ren "!tmp!" "!b!"
                    
                    echo !a!^|!b!>> "%logFile%"
                    set /a pares+=1
                ) else (
                    echo Advertencia: No se encontro "!a!"
                )
            )
        )
    )
)

if "%pares%"=="0" (
    echo Los nombres ya estaban en el orden correcto.
) else (
    echo.
    echo Se intercambiaron !pares! pares de archivos.
    echo Se ha creado un registro para poder deshacer.
)
echo.
pause
goto menu

:Deshacer
set "logFile=%parentDir%%~n0.undo.log"
if not exist "%logFile%" (
    echo No hay cambios para deshacer.
    echo.
    pause
    goto menu
)

set "restaurados=0"
for /f "usebackq tokens=1,2 delims=|" %%A in ("%logFile%") do (
    set "orig1=%%~A"
    set "orig2=%%~B"
    if not "!orig1!"=="" if not "!orig2!"=="" (
        if exist "!orig2!" (
            set "tmp=%parentDir%__arreglar_tomos_undo_!RANDOM!"
            
            echo Restaurando: !orig2! ^<-^> !orig1!
            
            ren "!orig2!" "!tmp!"
            if exist "!orig1!" (
                ren "!orig1!" "!orig2!"
            )
            ren "!tmp!" "!orig1!"
            
            set /a restaurados+=1
        )
    )
)

if "%restaurados%"=="0" (
    echo No se pudo restaurar ningun archivo.
) else (
    echo.
    echo Se restauraron !restaurados! pares de archivos.
    del /f /q "%logFile%"
)
echo.
pause
goto menu
