# merge.ps1
# Fetches AI instruction files directly from a remote GitHub repo and merges them.
# No git install required. Uses GitHub's REST API over HTTPS.
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

# ---------------------------------------------------------------------------
# YAML parser
# ---------------------------------------------------------------------------
function Parse-MergeYaml {
    param([string]$FilePath)

    $config = @{
        repo         = $null
        branch       = "main"
        token        = $null
        files        = @()
        output       = "merged-instructions.md"
        title        = $null
        separator    = "`n`n---`n`n"
        add_headers  = $true
        fail_on_missing = $true
    }

    $currentKey = $null

    foreach ($raw in Get-Content $FilePath) {
        $line = $raw.TrimEnd()
        if (-not $line -or $line.TrimStart().StartsWith("#")) { continue }

        if ($line -match '^\s*-\s+(.+)$') {
            $val = $Matches[1].Trim().Trim('"').Trim("'")
            if ($currentKey -eq "files") { $config.files += $val }
            continue
        }

        if ($line -match '^([a-zA-Z_][a-zA-Z0-9_]*):\s*(.*)$') {
            $currentKey = $Matches[1]
            $val = $Matches[2].Trim().Trim('"').Trim("'")

            switch ($currentKey) {
                "repo"            { $config.repo            = $val -replace "^https?://github\.com/", "" -replace "/$", "" }
                "branch"          { if ($val) { $config.branch = $val } }
                "token"           { $config.token           = $val }
                "output"          { if ($val) { $config.output = $val } }
                "title"           { $config.title           = $val }
                "separator"       { $config.separator       = $val -replace '\\n', "`n" }
                "add_headers"     { $config.add_headers     = $val -ne "false" }
                "fail_on_missing" { $config.fail_on_missing = $val -ne "false" }
                "files"           { $config.files = @() }
            }
        }
    }

    return $config
}

# ---------------------------------------------------------------------------
# Fetch the full file tree from GitHub (one API call, cached per run)
# ---------------------------------------------------------------------------
function Get-RepoTree {
    param(
        [string]$Repo,
        [string]$Branch,
        [string]$Token
    )

    $url     = "https://api.github.com/repos/$Repo/git/trees/${Branch}?recursive=1"
    $headers = @{ "User-Agent" = "ai-merge-ps" }
    if ($Token) { $headers["Authorization"] = "token $Token" }

    try {
        $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    }
    catch {
        $msg = $_.Exception.Message
        if ($msg -match "404") {
            Write-Error "Repo or branch not found: $Repo @ $Branch`nCheck your 'repo' and 'branch' settings in merge.yml."
        }
        elseif ($msg -match "401|403") {
            Write-Error "GitHub API access denied. Add a 'token' to merge.yml for private repos."
        }
        else {
            Write-Error "GitHub API error: $msg"
        }
        exit 1
    }

    # Return hashtable: filename -> full path in repo
    $index = @{}
    foreach ($item in $resp.tree) {
        if ($item.type -eq "blob") {
            $name = [System.IO.Path]::GetFileName($item.path)
            if (-not $index.ContainsKey($name)) {
                $index[$name] = @($item.path)
            }
            else {
                $index[$name] += $item.path
            }
        }
    }
    return $index
}

# ---------------------------------------------------------------------------
# Fetch raw file content from GitHub
# ---------------------------------------------------------------------------
function Get-FileContent {
    param(
        [string]$Repo,
        [string]$Branch,
        [string]$FilePath,
        [string]$Token
    )

    $url     = "https://raw.githubusercontent.com/$Repo/$Branch/$FilePath"
    $headers = @{ "User-Agent" = "ai-merge-ps" }
    if ($Token) { $headers["Authorization"] = "token $Token" }

    return Invoke-RestMethod -Uri $url -Headers $headers -Method Get
}

# ---------------------------------------------------------------------------
# Core merge logic for one destination folder
# ---------------------------------------------------------------------------
function Invoke-Merge {
    param([string]$DestDir)

    $configPath = Join-Path $DestDir "merge.yml"
    if (-not (Test-Path $configPath)) {
        Write-Error "No merge.yml found in: $DestDir"
        exit 1
    }

    $config = Parse-MergeYaml $configPath

    if (-not $config.repo) {
        Write-Error "merge.yml is missing required field: repo (e.g. owner/repo-name)"
        exit 1
    }
    if ($config.files.Count -eq 0) {
        Write-Error "merge.yml is missing required field: files"
        exit 1
    }

    # Token can also come from environment variable GITHUB_TOKEN
    $token = $config.token
    if (-not $token -and $env:GITHUB_TOKEN) { $token = $env:GITHUB_TOKEN }

    Write-Host ""
    Write-Host "[>>] Destination : $DestDir"                          -ForegroundColor Cyan
    Write-Host "[>>] Repo        : $($config.repo) @ $($config.branch)" -ForegroundColor Cyan
    Write-Host "  [~] Fetching file tree from GitHub..."              -ForegroundColor DarkCyan

    $tree = Get-RepoTree -Repo $config.repo -Branch $config.branch -Token $token

    $parts   = [System.Collections.Generic.List[string]]::new()
    $missing = @()

    if ($config.title) {
        $ts      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $srcList = $config.files -join ", "
        $parts.Add("# $($config.title)`n`n> Auto-generated on $ts`n> Source: $($config.repo) @ $($config.branch)`n> Files: $srcList")
    }

    foreach ($file in $config.files) {
        if (-not $tree.ContainsKey($file)) {
            $missing += $file
            Write-Warning "  [SKIP] Not found in repo: $file"
            continue
        }

        $paths = $tree[$file]

        if ($paths.Count -gt 1) {
            Write-Warning "  [WARN] Multiple matches for '$file' - using first found: $($paths[0])"
            Write-Warning "         All matches: $($paths -join ', ')"
        }

        $repoFilePath = $paths[0]

        try {
            $content = (Get-FileContent -Repo $config.repo -Branch $config.branch -FilePath $repoFilePath -Token $token).TrimEnd()
        }
        catch {
            Write-Warning "  [SKIP] Failed to fetch $repoFilePath : $_"
            $missing += $file
            continue
        }

        if ($config.add_headers) {
            $parts.Add("<!-- SOURCE: $repoFilePath -->`n`n$content")
        }
        else {
            $parts.Add($content)
        }

        Write-Host "  [OK] Fetched & merged: $repoFilePath" -ForegroundColor Green
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

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if ($All) {
    $root  = Resolve-Path $All
    # Search all nested subfolders for merge.yml in one pass.
    # Get-ChildItem -Recurse -Filter finds only the files we care about,
    # avoiding a separate Test-Path call per directory.
    $found = @(Get-ChildItem -Path $root -Filter "merge.yml" -Recurse -File -ErrorAction SilentlyContinue |
               ForEach-Object { $_.DirectoryName })

    if ($found.Count -eq 0) {
        Write-Error "No subfolders with merge.yml found under: $root"
        exit 1
    }

    Write-Host "[>>] Found $($found.Count) destination(s) under $root" -ForegroundColor Yellow
    foreach ($dir in $found) { Invoke-Merge $dir }

}
elseif ($Dest) {
    Invoke-Merge (Resolve-Path $Dest)
}
else {
    Invoke-Merge (Get-Location).Path
}
Read-Host "Press Enter to close"