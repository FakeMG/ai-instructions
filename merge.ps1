# merge.ps1
# Place this in the root of your AI instruction repo.
#
# Usage:
#   .\merge.ps1                              # looks for merge.yml in current directory
#   .\merge.ps1 -Dest C:\projects\app-a      # specific destination folder
#   .\merge.ps1 -All C:\projects             # scan all subfolders for merge.yml

param(
    [string]$Dest = "",
    [string]$All  = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Minimal YAML parser
function Parse-MergeYaml {
    param([string]$FilePath)

    $config = @{
        repo_path        = $null
        files            = @()
        output           = "merged-instructions.md"
        title            = $null
        separator        = "`n`n---`n`n"
        add_headers      = $true
        auto_pull        = $true
        fail_on_missing  = $true
    }

    $currentKey = $null

    foreach ($raw in Get-Content $FilePath) {
        $line = $raw.TrimEnd()
        if (-not $line -or $line.TrimStart().StartsWith("#")) { continue }

        # List item
        if ($line -match '^\s*-\s+(.+)$') {
            $val = $Matches[1].Trim().Trim('"').Trim("'")
            if ($currentKey -eq "files") {
                $config.files += $val
            }
            continue
        }

        # Key: value
        if ($line -match '^([a-zA-Z_][a-zA-Z0-9_]*):\s*(.*)$') {
            $currentKey = $Matches[1]
            $val = $Matches[2].Trim().Trim('"').Trim("'")

            switch ($currentKey) {
                "repo_path"       { $config.repo_path       = $val }
                "output"          { if ($val) { $config.output = $val } }
                "title"           { $config.title            = $val }
                "separator"       { $config.separator        = $val -replace '\\n', "`n" }
                "add_headers"     { $config.add_headers      = $val -ne "false" }
                "auto_pull"       { $config.auto_pull        = $val -ne "false" }
                "fail_on_missing" { $config.fail_on_missing  = $val -ne "false" }
                "files"           { $config.files = @() }
            }
        }
    }

    return $config
}

# Run git pull on the repo
function Invoke-GitPull {
    param([string]$RepoPath)
    try {
        $out = & git -C $RepoPath pull --ff-only 2>&1 | Select-Object -First 1
        Write-Host "  [OK] git pull: $out" -ForegroundColor Green
    }
    catch {
        Write-Warning "  [WARN] git pull failed (continuing anyway): $_"
    }
}

# Merge files for one destination folder
function Invoke-Merge {
    param([string]$DestDir)

    $configPath = Join-Path $DestDir "merge.yml"

    if (-not (Test-Path $configPath)) {
        Write-Error "No merge.yml found in: $DestDir"
        exit 1
    }

    $config = Parse-MergeYaml $configPath

    if (-not $config.repo_path) {
        Write-Error "merge.yml is missing required field: repo_path"
        exit 1
    }
    if ($config.files.Count -eq 0) {
        Write-Error "merge.yml is missing required field: files"
        exit 1
    }

    # Resolve repo path relative to the destination folder
    if ([System.IO.Path]::IsPathRooted($config.repo_path)) {
        $resolvedRepo = $config.repo_path
    }
    else {
        $resolvedRepo = [System.IO.Path]::GetFullPath((Join-Path $DestDir $config.repo_path))
    }

    if (-not (Test-Path $resolvedRepo)) {
        Write-Error "repo_path does not exist: $resolvedRepo"
        exit 1
    }

    Write-Host ""
    Write-Host "[>>] Destination : $DestDir"     -ForegroundColor Cyan
    Write-Host "[>>] Repo        : $resolvedRepo" -ForegroundColor Cyan

    if ($config.auto_pull) {
        Write-Host "  [~] Pulling latest..." -ForegroundColor DarkCyan
        Invoke-GitPull $resolvedRepo
    }

    $parts   = [System.Collections.Generic.List[string]]::new()
    $missing = @()

    # Optional title block
    if ($config.title) {
        $ts      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $srcList = $config.files -join ", "
        $parts.Add("# $($config.title)`n`n> Auto-generated on $ts  `n> Sources: $srcList")
    }

    foreach ($file in $config.files) {
        # Search recursively for a file matching this name anywhere in the repo
        $hits = @(Get-ChildItem -Path $resolvedRepo -Filter $file -Recurse -File -ErrorAction SilentlyContinue)

        if ($hits.Count -eq 0) {
            $missing += $file
            Write-Warning "  [SKIP] Not found anywhere in repo: $file"
            continue
        }

        if ($hits.Count -gt 1) {
            $allPaths = ($hits | ForEach-Object { $_.FullName }) -join ", "
            Write-Warning "  [WARN] Multiple matches for '$file' - using first found: $($hits[0].FullName)"
            Write-Warning "         All matches: $allPaths"
        }

        $filePath = $hits[0].FullName
        $relPath  = $filePath.Substring($resolvedRepo.Length).TrimStart([char]'\',[char]'/')
        $content  = (Get-Content $filePath -Raw).TrimEnd()

        if ($config.add_headers) {
            $parts.Add("<!-- SOURCE: $relPath -->`n`n$content")
        }
        else {
            $parts.Add($content)
        }

        Write-Host "  [OK] Merged: $relPath" -ForegroundColor Green
    }

    if ($missing.Count -gt 0 -and $config.fail_on_missing) {
        Write-Error "Aborting - $($missing.Count) file(s) not found. Set fail_on_missing: false to skip."
        exit 1
    }

    $finalContent = ($parts -join $config.separator) + "`n"
    $outputPath   = Join-Path $DestDir $config.output

    [System.IO.File]::WriteAllText($outputPath, $finalContent, [System.Text.Encoding]::UTF8)

    Write-Host ""
    Write-Host "[DONE] Written: $outputPath ($($finalContent.Length) bytes, $($parts.Count) section(s))" -ForegroundColor Green
    Write-Host ""
}

# Entry point
if ($All) {
    $root  = Resolve-Path $All
    $found = @(Get-ChildItem -Path $root -Directory |
             Where-Object { Test-Path (Join-Path $_.FullName "merge.yml") })

    if ($found.Count -eq 0) {
        Write-Error "No subfolders with merge.yml found under: $root"
        exit 1
    }

    Write-Host "[>>] Found $($found.Count) destination(s) under $root" -ForegroundColor Yellow
    foreach ($dir in $found) { Invoke-Merge $dir.FullName }

}
elseif ($Dest) {
    Invoke-Merge (Resolve-Path $Dest)
}
else {
    Invoke-Merge (Get-Location).Path
}