# Increment the build number (the +N part of version: X.Y.Z+N) in pubspec.yaml.
# Usage: pwsh -File scripts/bump_version.ps1 [-Major] [-Minor] [-Patch]
# Default: increments build number only (e.g. 1.0.0+3 → 1.0.0+4)

param(
    [switch]$Major,
    [switch]$Minor,
    [switch]$Patch
)

$pubspec = Get-Content pubspec.yaml -Raw
if ($pubspec -notmatch 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    Write-Error "Could not parse version from pubspec.yaml"
    exit 1
}

[int]$maj   = $Matches[1]
[int]$min   = $Matches[2]
[int]$patch = $Matches[3]
[int]$build = $Matches[4]

if ($Major) { $maj++;   $min = 0; $patch = 0; $build = 1 }
elseif ($Minor) { $min++;  $patch = 0; $build = 1 }
elseif ($Patch) { $patch++; $build = 1 }
else            { $build++ }

$newVersion = "$maj.$min.$patch+$build"
$pubspec = $pubspec -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
Set-Content pubspec.yaml $pubspec -NoNewline

Write-Host "Version bumped to $newVersion"

# Optional: create a git tag
# git tag "v$newVersion"
# git push --tags
