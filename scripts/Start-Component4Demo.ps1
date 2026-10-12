$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location (Join-Path $projectRoot 'backend')
try {
    if (Test-Path -LiteralPath 'target/stop-demo') { Remove-Item -LiteralPath 'target/stop-demo' }
    & .\mvnw.cmd -B -ntp test-compile dependency:build-classpath '-Dmdep.outputFile=target/test-classpath.txt' '-Dmdep.includeScope=test'
    if ($LASTEXITCODE -ne 0) { throw 'Could not build the disposable demo.' }
    $demoClasspath = 'target/test-classes;target/classes;' + (Get-Content -Raw -LiteralPath 'target/test-classpath.txt').Trim()
    & java '-cp' $demoClasspath com.historia.backend.booking.LocalDemoServer
} finally { Pop-Location }
