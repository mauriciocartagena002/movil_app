param(
  [string]$Avd = "Pixel_5",
  [switch]$ConSnapshot
)

$ErrorActionPreference = "Stop"

$emulator = Join-Path $env:LOCALAPPDATA "Android\Sdk\emulator\emulator.exe"

if (-not (Test-Path $emulator)) {
  throw "No se encontro emulator.exe en $emulator"
}

$argumentos = @(
  "-avd",
  $Avd,
  "-use-keycode-forwarding"
)

if (-not $ConSnapshot) {
  $argumentos += @("-no-snapshot-load", "-no-snapshot-save")
}

Start-Process -FilePath $emulator -ArgumentList $argumentos
