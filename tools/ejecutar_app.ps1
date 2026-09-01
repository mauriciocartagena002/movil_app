param(
  [string]$Dispositivo = "emulator-5554",
  [switch]$ConDebug,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ArgumentosExtra
)

$ErrorActionPreference = "Stop"

function Read-EnvLocal {
  $envPath = Join-Path $PSScriptRoot "..\.env.local"
  if (-not (Test-Path $envPath)) {
    throw "No existe .env.local en la raiz del proyecto."
  }

  $values = @{}
  Get-Content $envPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) {
      return
    }

    $parts = $line.Split("=", 2)
    if ($parts.Length -eq 2) {
      $values[$parts[0].Trim()] = $parts[1].Trim().Trim("'").Trim('"')
    }
  }

  return $values
}

$envValues = Read-EnvLocal
$supabaseUrl = $envValues["SUPABASE_URL"]
$publishableKey = $envValues["SUPABASE_PUBLISHABLE_KEY"]

if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
  throw "Falta SUPABASE_URL en .env.local."
}

if ([string]::IsNullOrWhiteSpace($publishableKey)) {
  throw "Falta SUPABASE_PUBLISHABLE_KEY en .env.local."
}

$defineFile = Join-Path ([System.IO.Path]::GetTempPath()) "gympro_dart_defines.env"
@(
  "SUPABASE_URL=$supabaseUrl",
  "SUPABASE_PUBLISHABLE_KEY=$publishableKey"
) | Set-Content -Path $defineFile -Encoding UTF8

try {
  $env:DEBUG = ""
  if ($ConDebug) {
    $flutterArgs = @(
      "run",
      "--dart-define-from-file=$defineFile"
    )

    if (-not [string]::IsNullOrWhiteSpace($Dispositivo)) {
      $flutterArgs += @("-d", $Dispositivo)
    }

    if ($ArgumentosExtra) {
      $flutterArgs += $ArgumentosExtra
    }

    & "C:\flutter\flutter\bin\flutter.bat" @flutterArgs
    exit $LASTEXITCODE
  }

  & "C:\flutter\flutter\bin\flutter.bat" build apk --debug "--dart-define-from-file=$defineFile"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  $adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  if (-not (Test-Path $adb)) {
    throw "No se encontro adb.exe en $adb."
  }

  $devicesOutput = & $adb devices
  $deviceLine = $devicesOutput | Where-Object { $_ -match "^$([regex]::Escape($Dispositivo))\s+" } | Select-Object -First 1

  if ([string]::IsNullOrWhiteSpace($deviceLine)) {
    throw "No se encontro el dispositivo $Dispositivo. Inicia el emulador con: .\tools\ejecutar_emulador.ps1"
  }

  if ($deviceLine -match "\boffline\b") {
    throw "El dispositivo $Dispositivo esta offline. Cierra el emulador e inicialo con: .\tools\ejecutar_emulador.ps1"
  }

  & $adb -s $Dispositivo install --no-streaming -r ".\build\app\outputs\flutter-apk\app-debug.apk"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  & $adb -s $Dispositivo shell am start -n "com.example.aplicacion_movil/.MainActivity"
} finally {
  Remove-Item -LiteralPath $defineFile -Force -ErrorAction SilentlyContinue
}
