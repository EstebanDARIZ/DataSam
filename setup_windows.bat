@echo off
setlocal enabledelayedexpansion

echo ============================================
echo  DataSam - Windows Setup
echo ============================================
echo.

REM --- Check Python ---
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Download Python 3.12 from https://python.org
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version') do echo [OK] %%i detected.

REM --- Create virtual environment ---
if not exist ".venv" (
    echo.
    echo Creating virtual environment...
    python -m venv .venv
    echo [OK] Virtual environment created.
) else (
    echo [OK] Existing virtual environment detected.
)

REM --- Activate venv ---
call .venv\Scripts\activate.bat

REM --- Detect NVIDIA GPU ---
set CUDA_URL=https://download.pytorch.org/whl/cpu
nvidia-smi >nul 2>&1
if errorlevel 1 (
    echo.
    echo [INFO] No NVIDIA GPU detected. Installing CPU-only PyTorch.
    echo        SAM3 performance will be limited.
) else (
    echo [OK] NVIDIA GPU detected. Installing PyTorch with CUDA 12.x.
    set CUDA_URL=https://download.pytorch.org/whl/cu128
)

REM --- Install PyTorch ---
echo.
echo Installing PyTorch from !CUDA_URL!...
pip install torch --index-url !CUDA_URL!
if errorlevel 1 (
    echo [ERROR] PyTorch installation failed.
    echo Check your internet connection and try again.
    pause
    exit /b 1
)
echo [OK] PyTorch installed.

REM --- Install remaining dependencies ---
echo.
echo Installing remaining dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Dependency installation failed.
    pause
    exit /b 1
)
echo [OK] Dependencies installed.

REM --- Check sam3.pt ---
echo.
if not exist "sam3.pt" (
    echo [WARNING] sam3.pt is MISSING.
    echo           Place sam3.pt at the root of the folder before running the tool.
) else (
    echo [OK] sam3.pt detected.
)

echo.
echo ============================================
echo  Setup complete!
echo  Run run_windows.bat to start the tool.
echo ============================================
pause
