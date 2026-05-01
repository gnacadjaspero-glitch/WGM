@echo off
setlocal enabledelayedexpansion
title WINNER GAME MANAGER - Systeme de Build Intelligent

:: =======================================================
:: SYSTEME DE DETECTION AUTOMATIQUE D'INNO SETUP
:: =======================================================
set "ISCC_EXE="
set "SEARCH_PATHS="C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "C:\Program Files\Inno Setup 6\ISCC.exe" "C:\Users\%USERNAME%\AppData\Local\Programs\Inno Setup 6\ISCC.exe""

for %%P in (%SEARCH_PATHS%) do (
    if exist %%P (
        set "ISCC_EXE=%%P"
        goto :found_inno
    )
)

:: Tentative via le registre Windows si non trouve dans les chemins standards
for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1" /v "InstallLocation" 2^>nul') do (
    set "INNO_REG_PATH=%%B"
    if exist "!INNO_REG_PATH!ISCC.exe" (
        set "ISCC_EXE="!INNO_REG_PATH!ISCC.exe""
        goto :found_inno
    )
)

:found_inno
:: =======================================================

:menu
cls
echo =======================================================
echo        WINNER GAME MANAGER - GESTION DES BUILDS
echo =======================================================
echo.
echo [ ENVIRONNEMENT ANDROID ]
echo   1. Generer l'APK (Fichier unique pour mobile)
echo.
echo [ ENVIRONNEMENT WINDOWS ]
echo   2. Compiler les fichiers Windows (Release)
echo   3. Creer l'Installateur EXE (Fichier unique)
echo.
echo [ MAINTENANCE ]
echo   4. Pub Get (Reparer les dependances)
echo   5. Clean Build (Nettoyage complet)
echo   6. Quitter
echo.
echo =======================================================
if defined ISCC_EXE (
    echo [INFO] Inno Setup detecte : !ISCC_EXE!
) else (
    echo [ALERTE] Inno Setup non detecte. L'option 3 sera indisponible.
)
echo.
set /p choice="Choisissez une action (1-6) : "

if "%choice%"=="1" goto android_build
if "%choice%"=="2" goto windows_files
if "%choice%"=="3" goto windows_setup
if "%choice%"=="4" goto pub_get
if "%choice%"=="5" goto clean_project
if "%choice%"=="6" exit
goto menu

:android_build
cls
echo.
echo === PHASE : CONSTRUCTION ANDROID ===
echo.
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] La compilation Android a echoue.
    pause
    goto menu
)
echo.
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo [SUCCES] APK genere avec succes.
    echo Chemin : build\app\outputs\flutter-apk\app-release.apk
)
echo.
pause
goto menu

:windows_files
cls
echo.
echo === PHASE : COMPILATION WINDOWS (FICHIERS) ===
echo.
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] La compilation Windows a echoue.
    pause
    goto menu
)
echo.
if exist "build\windows\x64\runner\Release\wgm.exe" (
    echo [SUCCES] Fichiers Windows compiles.
    echo Chemin : build\windows\x64\runner\Release\
)
echo.
pause
goto menu

:windows_setup
cls
echo.
echo === PHASE : CREATION DE L'INSTALLATEUR WINDOWS ===
echo.
if not defined ISCC_EXE (
    echo [ERREUR] Inno Setup n'est pas installe.
    echo Veuillez l'installer depuis : https://jrsoftware.org/isdl.php
    pause
    goto menu
)

if not exist "build\windows\x64\runner\Release\wgm.exe" (
    echo [ERREUR] Les fichiers Windows ne sont pas prets.
    echo Compilation automatique en cours...
    call flutter build windows --release
)

echo.
echo Generation de l'installateur unique...
!ISCC_EXE! "winner_setup.iss"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCES] L'installateur unique est pret.
    echo Destination : build\windows\installer\WinnerGameManager_Setup.exe
) else (
    echo.
    echo [ERREUR] Inno Setup a rencontre un probleme lors de la generation.
)
echo.
pause
goto menu

:pub_get
cls
echo.
echo === REPARATION DES DEPENDANCES ===
echo.
call flutter pub get
echo.
echo Dependances actualisees.
pause
goto menu

:clean_project
cls
echo.
echo === NETTOYAGE COMPLET ===
echo.
call flutter clean
echo.
echo Projet nettoye.
pause
goto menu
