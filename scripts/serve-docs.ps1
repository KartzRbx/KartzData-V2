$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command moonwave -ErrorAction SilentlyContinue)) {
	Write-Host "Installing moonwave..."
	npm i -g moonwave@latest
}

Push-Location $root
try {
	Write-Host "Starting docs at http://localhost:3000/KartzDataService/"
	moonwave dev
} finally {
	Pop-Location
}
