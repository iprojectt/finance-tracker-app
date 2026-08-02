# Windows PowerShell Launcher Script for FastAPI Backend
Param(
    [switch]$HostNetwork
)

Set-Location $PSScriptRoot

if (-not (Test-Path "venv")) {
    Write-Host "Creating Virtual Environment..." -ForegroundColor Cyan
    python -m venv venv
}

& "venv\Scripts\Activate.ps1"
pip install -r requirements.txt --quiet

if ($HostNetwork) {
    Write-Host "Starting server on 0.0.0.0:8000 (accessible from phone on same WiFi)..." -ForegroundColor Green
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
} else {
    Write-Host "Starting server on 127.0.0.1:8000 (localhost only)..." -ForegroundColor Green
    uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
}
