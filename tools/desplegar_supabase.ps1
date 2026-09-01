param(
  [switch]$SoloFunciones,
  [switch]$SoloBaseDatos
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

function Invoke-SupabaseCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CliArgs)

  if (Get-Command supabase -ErrorAction SilentlyContinue) {
    & supabase @CliArgs
    if ($LASTEXITCODE -ne 0) {
      throw "Supabase CLI fallo con codigo $LASTEXITCODE."
    }
    return
  }

  $npxCommand = Get-Command npx.cmd -ErrorAction SilentlyContinue
  if ($npxCommand) {
    & $npxCommand.Source supabase @CliArgs
    if ($LASTEXITCODE -ne 0) {
      throw "Supabase CLI fallo con codigo $LASTEXITCODE."
    }
    return
  }

  if (Get-Command npx -ErrorAction SilentlyContinue) {
    & npx supabase @CliArgs
    if ($LASTEXITCODE -ne 0) {
      throw "Supabase CLI fallo con codigo $LASTEXITCODE."
    }
    return
  }

  throw "No se encontro Supabase CLI ni npx."
}

$envValues = Read-EnvLocal
$supabaseUrl = $envValues["SUPABASE_URL"]

if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
  throw "Falta SUPABASE_URL en .env.local."
}

$projectRef = ([Uri]$supabaseUrl).Host.Split(".")[0]

Invoke-SupabaseCli link --project-ref $projectRef

if (-not $SoloFunciones) {
  Invoke-SupabaseCli db push
}

if (-not $SoloBaseDatos) {
  Invoke-SupabaseCli functions deploy registrar-cliente --project-ref $projectRef
}

Write-Host "Supabase actualizado."
