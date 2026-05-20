@echo off
setlocal enabledelayedexpansion

echo ============================================
echo  DataSam - Launch
echo ============================================
echo.

REM --- Check venv ---
if not exist ".venv\Scripts\activate.bat" (
    echo [ERROR] Virtual environment not found.
    echo         Please run setup_windows.bat first.
    pause
    exit /b 1
)

REM --- Check sam3.pt ---
if not exist "sam3.pt" (
    echo [ERROR] sam3.pt is missing.
    echo         Place sam3.pt at the root of the folder and try again.
    pause
    exit /b 1
)

call .venv\Scripts\activate.bat

REM --- Input parameters ---
echo Enter the paths below. You can drag and drop a file or folder
echo directly into this window to fill in the path automatically.
echo.

set /p VIDEO_PATH="Source video path   : "
set /p FOLDER_PATH="Dataset output folder: "

REM --- Strip quotes (from drag and drop) ---
set VIDEO_PATH=!VIDEO_PATH:"=!
set FOLDER_PATH=!FOLDER_PATH:"=!

REM --- Check video exists ---
if not exist "!VIDEO_PATH!" (
    echo.
    echo [ERROR] Video not found: !VIDEO_PATH!
    pause
    exit /b 1
)

echo.
echo Starting...
echo   Video : !VIDEO_PATH!
echo   Output: !FOLDER_PATH!
echo.

python main.py --video "!VIDEO_PATH!" --folder "!FOLDER_PATH!"

echo.
echo Session ended.
pause
