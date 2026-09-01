param(
  [string]$Contrasena = $env:GYMPRO_INITIAL_PASSWORD,
  [string]$CorreoAdmin = "admin@gympro.local",
  [string]$CorreoUsuario = "usuario@gympro.local"
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

function New-Headers {
  param([string]$ServiceRoleKey)

  return @{
    "apikey" = $ServiceRoleKey
    "Authorization" = "Bearer $ServiceRoleKey"
    "Content-Type" = "application/json"
  }
}

function Get-ExistingAuthUser {
  param(
    [string]$BaseUrl,
    [hashtable]$Headers,
    [string]$Email
  )

  $response = Invoke-RestMethod `
    -Method Get `
    -Uri "$BaseUrl/auth/v1/admin/users?per_page=100&page=1" `
    -Headers $Headers

  return $response.users | Where-Object { $_.email -eq $Email } | Select-Object -First 1
}

function New-AuthUser {
  param(
    [string]$BaseUrl,
    [hashtable]$Headers,
    [string]$Email,
    [string]$Password,
    [string]$Nombre
  )

  $body = @{
    email = $Email
    password = $Password
    email_confirm = $true
    user_metadata = @{
      nombre_completo = $Nombre
    }
  } | ConvertTo-Json -Depth 5

  try {
    return Invoke-RestMethod `
      -Method Post `
      -Uri "$BaseUrl/auth/v1/admin/users" `
      -Headers $Headers `
      -Body $body
  } catch {
    $existingUser = Get-ExistingAuthUser -BaseUrl $BaseUrl -Headers $Headers -Email $Email
    if ($null -eq $existingUser) {
      throw
    }

    return $existingUser
  }
}

function Update-AuthUserMetadata {
  param(
    [string]$BaseUrl,
    [hashtable]$Headers,
    [string]$UserId,
    [string]$Rol,
    [string]$Nombre
  )

  $body = @{
    app_metadata = @{
      rol = $Rol
    }
    user_metadata = @{
      nombre_completo = $Nombre
    }
  } | ConvertTo-Json -Depth 5

  Invoke-RestMethod `
    -Method Put `
    -Uri "$BaseUrl/auth/v1/admin/users/$UserId" `
    -Headers $Headers `
    -Body $body | Out-Null
}

function Get-PublicId {
  param(
    [string]$BaseUrl,
    [hashtable]$Headers
  )

  return Invoke-RestMethod `
    -Method Post `
    -Uri "$BaseUrl/rest/v1/rpc/generar_id_publico" `
    -Headers $Headers `
    -Body "{}"
}

function Update-Profile {
  param(
    [string]$BaseUrl,
    [hashtable]$Headers,
    [string]$UserId,
    [string]$Email,
    [string]$Nombre,
    [string]$Rol
  )

  $profileHeaders = $Headers.Clone()
  $profileHeaders["Prefer"] = "return=representation"

  $body = @{
    nombre_completo = $Nombre
    correo = $Email
    rol = $Rol
  } | ConvertTo-Json

  $updated = Invoke-RestMethod `
    -Method Patch `
    -Uri "$BaseUrl/rest/v1/perfiles?id=eq.$UserId" `
    -Headers $profileHeaders `
    -Body $body

  if ($updated.Count -gt 0) {
    return $updated[0]
  }

  $publicId = Get-PublicId -BaseUrl $BaseUrl -Headers $Headers
  $createBody = @{
    id = $UserId
    id_publico = $publicId
    nombre_completo = $Nombre
    correo = $Email
    rol = $Rol
  } | ConvertTo-Json

  return Invoke-RestMethod `
    -Method Post `
    -Uri "$BaseUrl/rest/v1/perfiles" `
    -Headers $profileHeaders `
    -Body $createBody
}

if ([string]::IsNullOrWhiteSpace($Contrasena)) {
  throw "Pasa la contrasena con -Contrasena o con GYMPRO_INITIAL_PASSWORD."
}

$envValues = Read-EnvLocal
$baseUrl = $envValues["SUPABASE_URL"].TrimEnd("/")
$serviceRoleKey = $envValues["SUPABASE_SERVICE_ROLE_KEY"]

if ([string]::IsNullOrWhiteSpace($baseUrl)) {
  throw "Falta SUPABASE_URL en .env.local."
}

if ([string]::IsNullOrWhiteSpace($serviceRoleKey)) {
  throw "Falta SUPABASE_SERVICE_ROLE_KEY en .env.local."
}

$headers = New-Headers -ServiceRoleKey $serviceRoleKey

$admin = New-AuthUser `
  -BaseUrl $baseUrl `
  -Headers $headers `
  -Email $CorreoAdmin `
  -Password $Contrasena `
  -Nombre "Administrador GymPro"

Update-AuthUserMetadata `
  -BaseUrl $baseUrl `
  -Headers $headers `
  -UserId $admin.id `
  -Rol "administrador" `
  -Nombre "Administrador GymPro"

Update-Profile `
  -BaseUrl $baseUrl `
  -Headers $headers `
  -UserId $admin.id `
  -Email $CorreoAdmin `
  -Nombre "Administrador GymPro" `
  -Rol "administrador" | Out-Null

$usuario = New-AuthUser `
  -BaseUrl $baseUrl `
  -Headers $headers `
  -Email $CorreoUsuario `
  -Password $Contrasena `
  -Nombre "Usuario GymPro"

Update-AuthUserMetadata `
  -BaseUrl $baseUrl `
  -Headers $headers `
  -UserId $usuario.id `
  -Rol "usuario" `
  -Nombre "Usuario GymPro"

Update-Profile `
  -BaseUrl $baseUrl `
  -Headers $headers `
  -UserId $usuario.id `
  -Email $CorreoUsuario `
  -Nombre "Usuario GymPro" `
  -Rol "usuario" | Out-Null

Write-Host "Usuarios iniciales listos:"
Write-Host "Admin: $CorreoAdmin"
Write-Host "Usuario: $CorreoUsuario"
