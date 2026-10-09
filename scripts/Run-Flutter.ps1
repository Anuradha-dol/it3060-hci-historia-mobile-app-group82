[CmdletBinding()]
param(
    [ValidateSet('emulator', 'usb', 'chrome', 'wifi')]
    [string]$Target = 'emulator',

    [string]$DeviceId,

    [string]$ApiBaseUrl,

    [string]$LaptopIp,

    [string]$GoogleWebClientId,

    [int]$WebPort = 5300,

    [switch]$SkipPubGet
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$frontendDir = Join-Path $projectRoot 'frontend'

function Get-HostIpv4Address {
    $addresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.AddressState -eq 'Preferred' -and
            $_.IPAddress -notmatch '^(127\.|169\.254\.)'
        } |
        Sort-Object -Property @{
            Expression = {
                if ($_.InterfaceAlias -match 'Wi-Fi|Wireless|WLAN') { 0 } else { 1 }
            }
        }, InterfaceMetric

    return $addresses | Select-Object -ExpandProperty IPAddress -First 1
}

function Invoke-AdbReverse {
    param([string]$Serial)

    $adbArgs = @()

    if (-not [string]::IsNullOrWhiteSpace($Serial)) {
        $adbArgs += @('-s', $Serial)
    }

    $adbArgs += @('reverse', 'tcp:8081', 'tcp:8081')

    & adb @adbArgs

    if ($LASTEXITCODE -ne 0) {
        throw 'adb reverse failed. Connect one Android device, or pass -DeviceId from flutter devices.'
    }
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    switch ($Target) {
        'chrome' {
            $ApiBaseUrl = 'http://localhost:8081'
        }
        'emulator' {
            $ApiBaseUrl = 'http://10.0.2.2:8081'
        }
        'usb' {
            $ApiBaseUrl = 'http://127.0.0.1:8081'
        }
        'wifi' {
            if ([string]::IsNullOrWhiteSpace($LaptopIp)) {
                $LaptopIp = Get-HostIpv4Address
            }

            if ([string]::IsNullOrWhiteSpace($LaptopIp)) {
                throw 'Could not detect a LAN IPv4 address. Pass -LaptopIp 192.168.x.x or -ApiBaseUrl http://192.168.x.x:8081.'
            }

            $ApiBaseUrl = "http://$LaptopIp`:8081"
        }
    }
}

$ApiBaseUrl = $ApiBaseUrl.Trim().TrimEnd('/')

if ($Target -eq 'usb') {
    Invoke-AdbReverse -Serial $DeviceId
}

Write-Host "Using API_BASE_URL=$ApiBaseUrl"

Push-Location $frontendDir
try {
    if (-not $SkipPubGet) {
        & flutter pub get

        if ($LASTEXITCODE -ne 0) {
            throw 'flutter pub get failed.'
        }
    }

    $flutterArgs = @(
        'run',
        "--dart-define=API_BASE_URL=$ApiBaseUrl"
    )

    if (-not [string]::IsNullOrWhiteSpace($GoogleWebClientId)) {
        $flutterArgs += "--dart-define=GOOGLE_WEB_CLIENT_ID=$($GoogleWebClientId.Trim())"
    }

    if ($Target -eq 'chrome') {
        $flutterArgs += @('-d', 'chrome', '--web-port', $WebPort.ToString())
    } elseif (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
        $flutterArgs += @('-d', $DeviceId)
    }

    & flutter @flutterArgs

    if ($LASTEXITCODE -ne 0) {
        throw 'flutter run failed.'
    }
} finally {
    Pop-Location
}
