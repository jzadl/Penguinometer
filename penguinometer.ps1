$letmesee = $args -contains "--letmesee"
$downloadDb = $args -contains "--download-db"

$DATABASE_URL = "https://cdn.jzadl.xyz/penguinometer/programs.json"
$LOCAL_DATABASE_FILE = "programs.json"

function Download-Database {

    Invoke-WebRequest `
        -Uri $DATABASE_URL `
        -OutFile $LOCAL_DATABASE_FILE `
        -UseBasicParsing

    Write-Host ""
    Write-Host "Downloaded database -> $LOCAL_DATABASE_FILE"
    Write-Host ""

    exit
}

function Load-Database {

    try {

        $response = Invoke-WebRequest `
            -Uri $DATABASE_URL `
            -UseBasicParsing `
            -TimeoutSec 5

        return $response.Content | ConvertFrom-Json

    } catch {

        if (Test-Path $LOCAL_DATABASE_FILE) {

            return Get-Content $LOCAL_DATABASE_FILE -Raw | ConvertFrom-Json
        }

        Write-Host ""
        Write-Host "Could not download database and no local database exists."
        Write-Host ""

        exit
    }
}

function Get-InstalledPrograms {

    $programs = @()

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {

        try {

            $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue

            foreach ($app in $apps) {

                if ($app.DisplayName) {

                    $programs += $app.DisplayName.ToLower()
                }
            }

        } catch {}
    }

    return $programs | Sort-Object -Unique
}

function Calculate-Penguin($programs, $database) {

    $results = @()
    $matches = @()

    foreach ($installed in $programs) {

        foreach ($property in $database.PSObject.Properties) {

            $appName = $property.Name.ToLower()
            $supported = [bool]$property.Value

            if ($installed.Contains($appName)) {

                $matches += [PSCustomObject]@{
                    Name = $installed
                    Compatible = $supported
                }

                if ($supported) {
                    $results += 100
                }
                else {
                    $results += 0
                }
            }
        }
    }

    if ($results.Count -eq 0) {

        return @{
            Score = 50
            Matches = $matches
        }
    }

    $average = [math]::Round(
        ($results | Measure-Object -Average).Average
    )

    return @{
        Score = $average
        Matches = $matches
    }
}

function Show-Penguin($score) {

    $width = $Host.UI.RawUI.WindowSize.Width
    $text = "$score% Penguin"

    $padding = [math]::Max(
        [math]::Floor(($width - $text.Length) / 2),
        0
    )

    Write-Host "`n`n`n"
    Write-Host (" " * $padding + $text)
    Write-Host "`n`n`n"
}

function Show-Details($matches) {

    if ($matches.Count -eq 0) {

        Write-Host ""
        Write-Host "No matching programs found."
        Write-Host ""

        return
    }

    Write-Host ""

    $longest = (
        $matches |
        ForEach-Object { $_.Name.Length } |
        Measure-Object -Maximum
    ).Maximum

    foreach ($match in $matches | Sort-Object Name) {

        $dotCount = [math]::Max(
            ($longest - $match.Name.Length) + 5,
            1
        )

        $dots = "." * $dotCount

        $status = if ($match.Compatible) {
            "YES"
        }
        else {
            "NO"
        }

        Write-Host "$($match.Name) $dots $status"
    }

    Write-Host ""
}

if ($downloadDb) {
    Download-Database
}

$database = Load-Database

$installedPrograms = Get-InstalledPrograms

$result = Calculate-Penguin `
    $installedPrograms `
    $database

Show-Penguin $result.Score

if ($letmesee) {
    Show-Details $result.Matches
}
