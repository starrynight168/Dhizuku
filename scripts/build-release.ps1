$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$propertiesPath = Join-Path $repoRoot 'local.properties'

if (-not (Test-Path -LiteralPath $propertiesPath)) {
    throw 'Create local.properties from local.properties.example and set sdk.dir, java.home, and flutter.sdk.'
}

$properties = @{}
foreach ($line in Get-Content -LiteralPath $propertiesPath) {
    if ($line -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
        $properties[$matches[1].Trim()] = $matches[2].Trim()
    }
}

foreach ($key in @('sdk.dir', 'java.home', 'flutter.sdk')) {
    if (-not $properties[$key]) { throw "Missing '$key' in local.properties." }
}

$sdk = [System.IO.Path]::GetFullPath($properties['sdk.dir'])
$java = [System.IO.Path]::GetFullPath($properties['java.home'])
$flutter = [System.IO.Path]::GetFullPath($properties['flutter.sdk'])

foreach ($path in @("$sdk\platform-tools\adb.exe", "$java\bin\java.exe", "$flutter\bin\flutter.bat")) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Tool not found: $path" }
}

$gradleText = Get-Content -LiteralPath (Join-Path $repoRoot 'app/build.gradle.kts') -Raw
$ndkMatch = [regex]::Match($gradleText, 'ndkVersion\s*=\s*"([^"]+)"')
if (-not $ndkMatch.Success) { throw 'Could not read ndkVersion from app/build.gradle.kts.' }
$ndk = Join-Path $sdk "ndk\$($ndkMatch.Groups[1].Value)"
if (-not (Test-Path -LiteralPath (Join-Path $ndk 'ndk-build.cmd'))) {
    throw "Pinned NDK not found: $ndk"
}

$modulePropertiesPath = Join-Path $repoRoot 'flutter_ui/.android/local.properties'
if (-not (Test-Path -LiteralPath $modulePropertiesPath)) {
    throw 'Flutter module setup is missing; run flutter pub get from flutter_ui.'
}
$moduleFlutterLine = Select-String -LiteralPath $modulePropertiesPath -Pattern '^flutter\.sdk=' | Select-Object -First 1
if (-not $moduleFlutterLine) { throw 'flutter.sdk is missing from flutter_ui/.android/local.properties.' }
$moduleFlutter = $moduleFlutterLine.Line.Substring('flutter.sdk='.Length).Replace('\\', '\')
if ([System.IO.Path]::GetFullPath($moduleFlutter) -ine $flutter) {
    throw 'Flutter SDK paths differ; run flutter pub get from flutter_ui to refresh module setup.'
}

$env:JAVA_HOME = $java
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_NDK_HOME = $ndk
$env:NDK_ROOT = $ndk
$env:PATH = "$java\bin;$flutter\bin;$sdk\platform-tools;$ndk;$env:PATH"

Push-Location $repoRoot
try {
    & (Join-Path $repoRoot 'gradlew.bat') :app:assembleRelease --no-daemon --no-configuration-cache
    $buildExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $buildExitCode
