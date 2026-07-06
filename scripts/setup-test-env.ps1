$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$template = Join-Path $root "test-template"
$target = Join-Path $root "Test"

if (-not (Test-Path $template)) {
	throw "test-template folder not found at $template"
}

if (Test-Path $target) {
	Write-Host "Syncing test-template -> Test/"
	robocopy $template $target /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
	if ($LASTEXITCODE -ge 8) {
		throw "Failed to sync test-template to Test/"
	}
} else {
	Copy-Item -Path $template -Destination $target -Recurse
	Write-Host "Created Test/ from test-template/"
}

Push-Location $target
try {
	if (Get-Command rokit -ErrorAction SilentlyContinue) {
		Write-Host "Running rokit install in Test/..."
		rokit install
	} else {
		Write-Warning "rokit not found in PATH. Install from https://github.com/rojo-rbx/rokit"
		Write-Warning "Or run: rokit install   (inside Test/) after installing rokit"
	}
} finally {
	Pop-Location
}

Write-Host ""
Write-Host "Ready. Run:"
Write-Host "  cd Test"
Write-Host "  rojo serve"
