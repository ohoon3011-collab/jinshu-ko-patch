$ErrorActionPreference = 'Stop'

function Write-Status([string]$Message) {
    Write-Host ('[JINSHU KO] ' + $Message)
}

function Install-OnlineUpdate([string[]]$LauncherArgs) {
    # This stable manifest is intentionally separate from the game updater.
    # Failure to reach it never blocks offline play with the installed patch.
    $manifestUrl = 'https://raw.githubusercontent.com/ohoon3011-collab/jinshu-ko-patch/main/update/manifest.json'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing -TimeoutSec 12
        $localVersionPath = Join-Path (Join-Path $PSScriptRoot 'ko_payload') 'payload_version.txt'
        $localVersion = if (Test-Path -LiteralPath $localVersionPath) {
            (Get-Content -LiteralPath $localVersionPath -Raw).Trim()
        } else { '0.0.0' }
        if ([version]$manifest.version -le [version]$localVersion) {
            Write-Status ('Korean patch is current: v' + $localVersion)
            return
        }

        Write-Status ('Downloading Korean patch v' + $manifest.version + '...')
        $stageRoot = Join-Path ([IO.Path]::GetTempPath()) ('jinshu_ko_' + [Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($stageRoot) | Out-Null
        foreach ($entry in @($manifest.files)) {
            $relative = ([string]$entry.path).Replace('/', [IO.Path]::DirectorySeparatorChar)
            if ([IO.Path]::IsPathRooted($relative) -or $relative.Split([IO.Path]::DirectorySeparatorChar) -contains '..') {
                throw 'Update manifest contained an unsafe path.'
            }
            $staged = Join-Path $stageRoot $relative
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($staged)) | Out-Null
            Invoke-WebRequest -Uri ([string]$entry.url) -UseBasicParsing -TimeoutSec 60 -OutFile $staged
            $actualHash = (Get-FileHash -LiteralPath $staged -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actualHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
                throw ('Downloaded update checksum did not match: ' + $entry.path)
            }
        }
        $versionFile = Join-Path (Join-Path $stageRoot 'ko_payload') 'payload_version.txt'
        if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf) -or
            (Get-Content -LiteralPath $versionFile -Raw).Trim() -ne [string]$manifest.version) {
            throw 'Downloaded update version could not be verified.'
        }

        Get-ChildItem -LiteralPath $stageRoot -Recurse -File | ForEach-Object {
            $relative = $_.FullName.Substring($stageRoot.Length).TrimStart('\','/')
            $destination = Join-Path $PSScriptRoot $relative
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
        }
        Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status ('Korean patch updated to v' + $manifest.version + '. Restarting launcher...')

        $childArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + (Join-Path $PSScriptRoot 'ko_autopatch.ps1') + '"'))
        if ($LauncherArgs -contains '-PatchOnly') { $childArgs += '-PatchOnly' }
        $child = Start-Process -FilePath 'powershell.exe' -ArgumentList $childArgs -WorkingDirectory $PSScriptRoot -Wait -PassThru
        exit $child.ExitCode
    } catch {
        Write-Status ('Online update check skipped: ' + $_.Exception.Message)
    }
}

function Get-LuaParts([string]$WrapperText) {
    $keyMatch = [regex]::Match($WrapperText, 'local _K=string\.char\(([^)]*)\)')
    if (-not $keyMatch.Success) { throw 'Lua encryption key was not found.' }
    $keyNumbers = $keyMatch.Groups[1].Value.Split(',')
    [byte[]]$key = @($keyNumbers | ForEach-Object { [byte]([int]$_.Trim()) })

    $hStart = $WrapperText.IndexOf('local _H=')
    $sStart = $WrapperText.IndexOf('local _S=_D', $hStart)
    if ($hStart -lt 0 -or $sStart -lt 0) { throw 'Encrypted Lua payload was not found.' }
    $payloadArea = $WrapperText.Substring($hStart, $sStart - $hStart)
    $hexMatches = [regex]::Matches($payloadArea, '["'']([0-9A-Fa-f]+)["'']')
    if ($hexMatches.Count -eq 0) { throw 'Encrypted Lua hex data was not found.' }
    $hexBuilder = [Text.StringBuilder]::new()
    foreach ($match in $hexMatches) { [void]$hexBuilder.Append($match.Groups[1].Value) }
    return [pscustomobject]@{
        Key = $key
        Hex = $hexBuilder.ToString()
        PayloadStart = $hStart
        SourceLoaderStart = $sStart
    }
}

function ConvertFrom-LuaWrapper([string]$WrapperText) {
    $parts = Get-LuaParts $WrapperText
    [byte[]]$key = $parts.Key
    [string]$hex = $parts.Hex
    [byte[]]$plain = [byte[]]::new($hex.Length / 2)
    for ($i = 0; $i -lt $plain.Length; $i++) {
        $encrypted = [Convert]::ToByte($hex.Substring($i * 2, 2), 16)
        $plain[$i] = [byte]($encrypted -bxor $key[$i % $key.Length] -bxor ($i % 256))
    }
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    return $utf8.GetString($plain)
}

function ConvertTo-LuaWrapper([string]$SourceText, [string]$OriginalWrapper) {
    $parts = Get-LuaParts $OriginalWrapper
    [byte[]]$key = $parts.Key
    [int]$hStart = $parts.PayloadStart
    [int]$sStart = $parts.SourceLoaderStart
    [byte[]]$plain = [Text.UTF8Encoding]::new($false).GetBytes($SourceText)
    $hexBuilder = [Text.StringBuilder]::new($plain.Length * 2)
    for ($i = 0; $i -lt $plain.Length; $i++) {
        $encrypted = [byte]($plain[$i] -bxor $key[$i % $key.Length] -bxor ($i % 256))
        [void]$hexBuilder.Append($encrypted.ToString('X2'))
    }
    $hex = $hexBuilder.ToString()
    $chunkSize = 240000
    $chunks = [Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $hex.Length; $i += $chunkSize) {
        $length = [Math]::Min($chunkSize, $hex.Length - $i)
        $chunks.Add($hex.Substring($i, $length))
    }
    $separator = '"..' + "`n" + '"'
    $assignment = 'local _H="' + ($chunks -join $separator) + '"' + "`n"
    return $OriginalWrapper.Substring(0, $hStart) + $assignment + $OriginalWrapper.Substring($sStart)
}

function Install-KoreanPayload([string]$Root) {
    $scriptDir = Join-Path $Root 'script'
    $payloadDir = Join-Path $PSScriptRoot 'ko_payload'
    if (-not (Test-Path -LiteralPath $scriptDir -PathType Container)) {
        throw 'script folder was not found. Extract this package into the game folder.'
    }
    $sourceVersion = (Get-Content -LiteralPath (Join-Path $payloadDir 'payload_version.txt') -Raw).Trim()
    $installedVersionPath = Join-Path $scriptDir '_ko_payload_version.txt'
    $installedVersion = if (Test-Path -LiteralPath $installedVersionPath) {
        (Get-Content -LiteralPath $installedVersionPath -Raw).Trim()
    } else { '' }
    if ($installedVersion -ne $sourceVersion) {
        Get-ChildItem -LiteralPath $payloadDir -Filter 'kotrans*.lua' | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $scriptDir $_.Name) -Force
        }
        [IO.File]::WriteAllText($installedVersionPath, $sourceVersion, [Text.UTF8Encoding]::new($false))
        Write-Status ('Korean translation data installed: v' + $sourceVersion)
    }
}

function Install-KoreanAssets([string]$Root) {
    $sourceFont = Join-Path (Join-Path (Join-Path $PSScriptRoot 'ko_assets') 'FONT') 'korean.ttf'
    if (-not (Test-Path -LiteralPath $sourceFont -PathType Leaf)) {
        throw 'Bundled Korean font was not found.'
    }
    $fontDir = Join-Path $Root 'FONT'
    [IO.Directory]::CreateDirectory($fontDir) | Out-Null
    $targetFont = Join-Path $fontDir 'korean.ttf'
    $copyFont = -not (Test-Path -LiteralPath $targetFont -PathType Leaf)
    if (-not $copyFont) {
        $copyFont = (Get-Item -LiteralPath $sourceFont).Length -ne (Get-Item -LiteralPath $targetFont).Length
    }
    if ($copyFont) {
        Copy-Item -LiteralPath $sourceFont -Destination $targetFont -Force
        Write-Status 'Bundled Korean font installed.'
    }
}

function Get-UpdateVersion([string]$Root) {
    $path = Join-Path (Join-Path $Root 'script') 'update_version'
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        return (Get-Content -LiteralPath $path -Raw).Trim()
    }
    return 'unknown'
}

function Get-ChineseStringSnapshot([string]$Root) {
    $scriptDir = Join-Path $Root 'script'
    $targets = @('tianfu.lua', 'kungfu.lua', 'jymenu.lua', 'jywar.lua', 'kdef.lua')
    $entries = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    # Display strings use double quotes. Keep this PowerShell file ASCII-only
    # so Windows PowerShell 5.1 can parse it regardless of the system codepage.
    $pattern = '"(?<text>[^"\r\n]*[\u3400-\u9FFF][^"\r\n]*)"'
    foreach ($name in $targets) {
        $path = Join-Path $scriptDir $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        try {
            $wrapper = [IO.File]::ReadAllText($path, $utf8)
            $source = ConvertFrom-LuaWrapper $wrapper
            foreach ($match in [regex]::Matches($source, $pattern)) {
                $value = $match.Groups['text'].Value.Trim()
                if ($value.Length -ge 2 -and $value.Length -le 500) {
                    [void]$entries.Add($name + "`t" + $value)
                }
            }
        } catch {
            Write-Status ('New-text scan skipped for ' + $name + ': ' + $_.Exception.Message)
        }
    }
    return @($entries | Sort-Object)
}

function Update-NewChineseReport([string]$Root) {
    $version = Get-UpdateVersion $Root
    $stateDir = Join-Path $Root '_ko_auto_state'
    $versionPath = Join-Path $stateDir 'scan_version.txt'
    $baselinePath = Join-Path $stateDir 'cjk_baseline.txt'
    $reportPath = Join-Path $Root '_ko_new_chinese_report.txt'
    $oldVersion = if (Test-Path -LiteralPath $versionPath) {
        (Get-Content -LiteralPath $versionPath -Raw).Trim()
    } else { '' }
    if ($oldVersion -eq $version -and (Test-Path -LiteralPath $baselinePath)) { return }

    Write-Status ('Scanning talent/martial-art text for new Chinese strings: ' + $version)
    $current = @(Get-ChineseStringSnapshot $Root)
    [IO.Directory]::CreateDirectory($stateDir) | Out-Null
    if (Test-Path -LiteralPath $baselinePath) {
        $old = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($line in (Get-Content -LiteralPath $baselinePath -Encoding UTF8)) { [void]$old.Add($line) }
        $added = @($current | Where-Object { -not $old.Contains($_) })
        if ($added.Count -gt 0) {
            $header = @(
                'JINSHU Korean Patch - New Chinese Text Report',
                ('Previous version: ' + $oldVersion),
                ('Current version: ' + $version),
                ('New candidates: ' + $added.Count),
                'Send this report to update the Korean translation database.',
                ''
            )
            [IO.File]::WriteAllLines($reportPath, @($header + $added), [Text.UTF8Encoding]::new($true))
            Write-Status ('New Chinese text found: ' + $added.Count + ' (see _ko_new_chinese_report.txt)')
        }
    } else {
        Write-Status 'Chinese-text baseline initialized. Future FIX additions will be reported.'
    }
    [IO.File]::WriteAllLines($baselinePath, $current, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($versionPath, $version, [Text.UTF8Encoding]::new($false))
}

function Get-ReviewedChangelogFix {
    $path = Join-Path (Join-Path $PSScriptRoot 'ko_payload') 'reviewed_changelog_fix.txt'
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $value = (Get-Content -LiteralPath $path -Raw).Trim()
        if ($value -match '^\d+$') { return [int]$value }
    }
    return 147
}

function Update-TranslationRequest([string]$Root) {
    # The official changelog is plain UTF-8 and lives beside the game EXE.
    # Extract only FIX sections newer than our last human-reviewed release.
    # This keeps the user from finding/copying update.lua and changelog by hand.
    $changelogPath = Join-Path $Root 'changelog'
    if (-not (Test-Path -LiteralPath $changelogPath -PathType Leaf)) { return }

    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    try {
        $text = [IO.File]::ReadAllText($changelogPath, $utf8)
    } catch {
        Write-Status ('Changelog scan skipped: ' + $_.Exception.Message)
        return
    }

    $reviewedFix = Get-ReviewedChangelogFix
    $sections = [Collections.Generic.List[object]]::new()
    $pattern = '(?ms)^fix(?<fix>\d+)[ \t]+(?<date>[^\r\n]*)\r?\n(?<body>.*?)(?=^-{3,}[ \t]*\r?$|^fix\d+[ \t]|\z)'
    foreach ($match in [regex]::Matches($text, $pattern)) {
        $fix = [int]$match.Groups['fix'].Value
        if ($fix -gt $reviewedFix) {
            $body = $match.Groups['body'].Value.Trim()
            $sections.Add([pscustomobject]@{
                Fix = $fix
                Date = $match.Groups['date'].Value.Trim()
                Body = $body
            })
        }
    }

    $newChinesePath = Join-Path $Root '_ko_new_chinese_report.txt'
    $hasNewChinese = Test-Path -LiteralPath $newChinesePath -PathType Leaf
    if ($hasNewChinese) {
        $reviewedGameVersionPath = Join-Path (Join-Path $PSScriptRoot 'ko_payload') 'reviewed_game_version.txt'
        $reviewedGameVersion = if (Test-Path -LiteralPath $reviewedGameVersionPath -PathType Leaf) {
            (Get-Content -LiteralPath $reviewedGameVersionPath -Raw).Trim()
        } else { '0' }
        $reportHeader = [IO.File]::ReadAllText($newChinesePath, $utf8)
        $reportVersionMatch = [regex]::Match($reportHeader, '(?m)^Current version:\s*(\d+)\s*$')
        if ($reportVersionMatch.Success -and
            [decimal]$reportVersionMatch.Groups[1].Value -le [decimal]$reviewedGameVersion) {
            $hasNewChinese = $false
        }
    }
    if ($sections.Count -eq 0 -and -not $hasNewChinese) { return }

    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('JINSHU Korean Patch - Translation Request')
    $lines.Add(('Last reviewed changelog: fix' + $reviewedFix))
    $lines.Add(('Current game version: ' + (Get-UpdateVersion $Root)))
    $lines.Add('Paste this entire text into the existing ChatGPT patch conversation.')
    $lines.Add('')
    if ($sections.Count -gt 0) {
        $lines.Add('[NEW CHANGELOG SECTIONS]')
        foreach ($section in @($sections | Sort-Object Fix -Descending)) {
            $lines.Add(('fix' + $section.Fix + ' ' + $section.Date))
            foreach ($line in ($section.Body -split '\r?\n')) { $lines.Add($line) }
            $lines.Add('')
        }
    }
    if ($hasNewChinese) {
        $lines.Add('[NEW GAME TEXT CANDIDATES]')
        foreach ($line in [IO.File]::ReadAllLines($newChinesePath, $utf8)) { $lines.Add($line) }
    }

    $requestPath = Join-Path $Root '_ko_translation_request.txt'
    $content = [string]::Join("`r`n", $lines)
    $stateDir = Join-Path $Root '_ko_auto_state'
    [IO.Directory]::CreateDirectory($stateDir) | Out-Null
    $hashPath = Join-Path $stateDir 'translation_request_sha256.txt'
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($content)))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
    $oldHash = if (Test-Path -LiteralPath $hashPath) { (Get-Content -LiteralPath $hashPath -Raw).Trim() } else { '' }
    [IO.File]::WriteAllText($requestPath, $content, [Text.UTF8Encoding]::new($true))
    if ($hash -ne $oldHash) {
        [IO.File]::WriteAllText($hashPath, $hash, [Text.UTF8Encoding]::new($false))
        try {
            Set-Clipboard -Value $content
            Write-Status 'New translation request copied to the clipboard.'
        } catch {
            Write-Status 'New translation request is ready in _ko_translation_request.txt.'
        }
        Write-Status ('Official changelog additions found after fix' + $reviewedFix + ': ' + $sections.Count + ' section(s).')
    }
}

function Patch-JyMain([string]$Root) {
    $target = Join-Path (Join-Path $Root 'script') 'jymain.lua'
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw 'script\\jymain.lua was not found.' }
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $wrapper = [IO.File]::ReadAllText($target, $utf8)
    $source = ConvertFrom-LuaWrapper $wrapper
    if ($source.Contains('require("kotrans")') -or $source.Contains("require('kotrans')")) {
        Write-Status 'Korean hook is already active.'
        return
    }

    $anchor = [regex]::new('(?m)^(\s*)require\(["'']update["'']\)')
    $matches = $anchor.Matches($source)
    if ($matches.Count -ne 1) {
        throw ('Safe update anchor count was ' + $matches.Count + '; jymain.lua was not changed.')
    }
    $indent = $matches[0].Groups[1].Value
    $injection = $indent + '-- JINSHU_KO_AUTO_HOOK' + "`n" + $indent + 'require("kotrans")' + "`n" + $matches[0].Value
    $patchedSource = $source.Substring(0, $matches[0].Index) + $injection + $source.Substring($matches[0].Index + $matches[0].Length)

    $backupDir = Join-Path $Root '_ko_auto_backup'
    [IO.Directory]::CreateDirectory($backupDir) | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ('jymain_' + $stamp + '.lua')) -Force

    $patchedWrapper = ConvertTo-LuaWrapper $patchedSource $wrapper
    $temp = $target + '.ko_tmp'
    [IO.File]::WriteAllText($temp, $patchedWrapper, [Text.UTF8Encoding]::new($false))
    $verifyWrapper = [IO.File]::ReadAllText($temp, $utf8)
    $verifySource = ConvertFrom-LuaWrapper $verifyWrapper
    if (-not $verifySource.Contains('JINSHU_KO_AUTO_HOOK')) {
        Remove-Item -LiteralPath $temp -Force
        throw 'Verification failed; original jymain.lua was preserved.'
    }
    Move-Item -LiteralPath $temp -Destination $target -Force
    Write-Status 'Korean hook applied to the current game version.'
}

function Patch-JyConst([string]$Root) {
    $font = Join-Path (Join-Path $Root 'FONT') 'korean.ttf'
    if (-not (Test-Path -LiteralPath $font -PathType Leaf)) {
        throw 'FONT\\korean.ttf was not found. Apply the original Korean patch once, then run this launcher again.'
    }

    $target = Join-Path (Join-Path $Root 'script') 'jyconst.lua'
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw 'script\\jyconst.lua was not found.' }
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $wrapper = [IO.File]::ReadAllText($target, $utf8)
    $source = ConvertFrom-LuaWrapper $wrapper

    $fontPattern = 'FONT/(?:0|1|1-1|2-1|3|4|5|6|7|8|9)\.ttf'
    $fontMatches = [regex]::Matches($source, $fontPattern)
    if ($fontMatches.Count -eq 0) {
        if ($source.Contains('FONT/korean.ttf')) {
            Write-Status 'Korean font hook is already active.'
            return
        }
        throw 'Safe font anchors were not found; jyconst.lua was not changed.'
    }
    if ($fontMatches.Count -lt 10) {
        throw ('Only ' + $fontMatches.Count + ' font anchors were found; jyconst.lua was not changed.')
    }

    $patchedSource = [regex]::Replace($source, $fontPattern, 'FONT/korean.ttf')
    $backupDir = Join-Path $Root '_ko_auto_backup'
    [IO.Directory]::CreateDirectory($backupDir) | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ('jyconst_' + $stamp + '.lua')) -Force

    $patchedWrapper = ConvertTo-LuaWrapper $patchedSource $wrapper
    $temp = $target + '.ko_tmp'
    [IO.File]::WriteAllText($temp, $patchedWrapper, [Text.UTF8Encoding]::new($false))
    $verifyWrapper = [IO.File]::ReadAllText($temp, $utf8)
    $verifySource = ConvertFrom-LuaWrapper $verifyWrapper
    if ([regex]::Matches($verifySource, 'FONT/korean\.ttf').Count -lt 10) {
        Remove-Item -LiteralPath $temp -Force
        throw 'Korean font verification failed; original jyconst.lua was preserved.'
    }
    Move-Item -LiteralPath $temp -Destination $target -Force
    Write-Status 'Korean font hook applied to all game UI fonts.'
}

function Decode-Utf8([string]$Base64) {
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64))
}

function Patch-LuaTextAssembly([string]$Root, [string]$FileName, $Pairs, [string]$MarkerBase64) {
    $target = Join-Path (Join-Path $Root 'script') $FileName
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        Write-Status ('Direct UI patch skipped; file not found: ' + $FileName)
        return
    }
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $wrapper = [IO.File]::ReadAllText($target, $utf8)
    $source = ConvertFrom-LuaWrapper $wrapper
    $changed = 0
    foreach ($pair in $Pairs) {
        $oldText = Decode-Utf8 $pair[0]
        $newText = Decode-Utf8 $pair[1]
        if ($source.Contains($oldText)) {
            $source = $source.Replace($oldText, $newText)
            $changed++
        }
    }
    $marker = Decode-Utf8 $MarkerBase64
    if ($changed -eq 0) {
        if ($source.Contains($marker)) {
            Write-Status ('Direct Korean UI text is already active: ' + $FileName)
        } else {
            Write-Status ('Direct UI anchors changed in this FIX; display-layer fallback remains active: ' + $FileName)
        }
        return
    }

    $backupDir = Join-Path $Root '_ko_auto_backup'
    [IO.Directory]::CreateDirectory($backupDir) | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir (($FileName -replace '\.lua$','') + '_' + $stamp + '.lua')) -Force

    $patchedWrapper = ConvertTo-LuaWrapper $source $wrapper
    $temp = $target + '.ko_tmp'
    [IO.File]::WriteAllText($temp, $patchedWrapper, [Text.UTF8Encoding]::new($false))
    $verifySource = ConvertFrom-LuaWrapper ([IO.File]::ReadAllText($temp, $utf8))
    if (-not $verifySource.Contains($marker)) {
        Remove-Item -LiteralPath $temp -Force
        throw ('Direct Korean UI verification failed; original was preserved: ' + $FileName)
    }
    Move-Item -LiteralPath $temp -Destination $target -Force
    Write-Status ('Direct Korean UI text patched: ' + $FileName + ' (' + $changed + ' anchors)')
}

function Patch-TimeAndSaveUI([string]$Root) {
    $mainPairs = @(
        ,@('dGltZSA9ICLmuLjmiI/ml7bpl7TvvJoiIC4uIHQyIC4uICLml7YiIC4uIHQxIC4uICLliIYiIC4uIHQgLi4gIuenkiI=', 'dGltZSA9ICLtlIzroIjsnbQg7Iuc6rCEOiAiIC4uIHQyIC4uICLsi5zqsIQgIiAuLiB0MSAuLiAi67aEICIgLi4gdCAuLiAi7LSIIg==')
        ,@('dGltZSA9ICLmuLjmiI/ml7bplb/vvJoiIC4uIHQyIC4uICLml7YiIC4uIHQxIC4uICLliIYiIC4uIHQzIC4uICLnp5Ii', 'dGltZSA9ICLtlIzroIjsnbQg7Iuc6rCEOiAiIC4uIHQyIC4uICLsi5zqsIQgIiAuLiB0MSAuLiAi67aEICIgLi4gdDMgLi4gIuy0iCI=')
        ,@('Z2FtZXRpbWUgPSAi5a2Y5qGj5pe26Ze077yaIiAuLiB0aW1lMSAuLiAi5pyIIiAuLiB0aW1lMiAuLiAi5pelIiAuLiB0aW1lMyAuLiAi5pe2IiAuLiB0aW1lNCAuLiAi5YiGIg==', 'Z2FtZXRpbWUgPSAi7KCA7J6lIOyLnOqwhDogIiAuLiB0aW1lMSAuLiAi7JuUICIgLi4gdGltZTIgLi4gIuydvCAiIC4uIHRpbWUzIC4uICLsi5wgIiAuLiB0aW1lNCAuLiAi67aEIg==')
        ,@('bG9jYWwgYnd6ID0geyLkuIAiLCAi5LqMIiwgIuS4iSIsICLlm5siLCAi5LqUIiwgIuWFrSIsICLkuIMiLCAi5YWrIiwgIuS5nSIsICLljYEifQ==', 'bG9jYWwgYnd6ID0geyIxIiwgIjIiLCAiMyIsICI0IiwgIjUiLCAiNiIsICI3IiwgIjgiLCAiOSIsICIxMCJ9')
        ,@('bG9jYWwgbW5hbWUgPSAi5a2Y5qGj5LmdIg==', 'bG9jYWwgbW5hbWUgPSAi7KCA7J6lIDki')
        ,@('bWVudVtpXSA9IHsi5a2Y5qGjIiAuLiBid3pbaV0s', 'bWVudVtpXSA9IHsi7KCA7J6lICIgLi4gYnd6W2ldLA==')
        ,@('bWVudVtpXSA9IHsi6Ieq5Yqo5qGjIiAuLiB6ZCw=', 'bWVudVtpXSA9IHsi7J6Q64+ZIOyggOyepSAiIC4uIHpkLA==')
        ,@('bG9jYWwgbXgsIG15ID0gZHggKyAoYngqNCkgKiBteWZvbnQsIHkzXzIgKyBieSo1MA==', 'bG9jYWwgbXgsIG15ID0gZHggKyBDQy5NZW51Qm9yZGVyUGl4ZWwgKyBDQy5TY3JlZW5XIC8gNjguNCArIG15Zm9udCAqIDQsIHkzXzIgKyBieSo1MA==')
        ,@('bG9jYWwgbXgsIG15ID0gZHggKyAoYngqNSkgKiBteWZvbnQsIHkzXzIgKyBieSo1MA==', 'bG9jYWwgbXgsIG15ID0gZHggKyBDQy5NZW51Qm9yZGVyUGl4ZWwgKyBDQy5TY3JlZW5XIC8gNjguNCArIG15Zm9udCAqIDQsIHkzXzIgKyBieSo1MA==')
        ,@('bXggPSBkeCArIDQgKiBteWZvbnQ=', 'bXggPSBkeCArIENDLk1lbnVCb3JkZXJQaXhlbCArIENDLlNjcmVlblcgLyA2OC40ICsgbXlmb250ICogNA==')
        ,@('bXggPSBkeCArIDUgKiBteWZvbnQ=', 'bXggPSBkeCArIENDLk1lbnVCb3JkZXJQaXhlbCArIENDLlNjcmVlblcgLyA2OC40ICsgbXlmb250ICogNA==')
    )
    Patch-LuaTextAssembly $Root 'jymain.lua' $mainPairs 'dGltZSA9ICLtlIzroIjsnbQg7Iuc6rCEOiAi'

    $menuPairs = @(
        # Shared shop labels.  These are rendered with lib.DrawStr rather than
        # the KOTR-aware DrawString path, so translate them at their common
        # source anchors before any of the shop variants draw the UI.
        ,@('5a2YIOasvu+8mg==', '7JiI7LmY6riIOiA=')
        ,@('6aG15pWw77ya', '7Y6Y7J207KeAOiA=')
        ,@('6aG1IOaVsO+8mg==', '7Y6Y7J207KeAOiA=')
        ,@('6LStIOeJqSDovaY=', '7J6l67CU6rWs64uI')
        ,@('5oC7IOS7t++8mg==', '7LSd7JWhOiA=')
        ,@('eyLnu5PotKYiLCAi6YCA5Ye6In0=', 'eyLqsrDsoJwiLCAi7KKF66OMIn0=')
        ,@('eyLnu5PotKYiLCLpgIDlh7oifQ==', 'eyLqsrDsoJwiLCLsooXro4wifQ==')
        ,@('eyAi57uT6LSmIiwgIumAgOWHuiIgfQ==', 'eyAi6rKw7KCcIiwgIuyiheujjCIgfQ==')
        ,@('54mp5ZOB5ZCN56ewOiA=', '7JWE7J207YWcIOydtOumhDog')
        ,@('54mp5ZOB5ZCN56ew77ya', '7JWE7J207YWcIOydtOumhDog')
        ,@('5Y2V5Lu377ya', '64uo6rCAOiA=')
        ,@('5pWI5p6c77ya', '7Zqo6rO8OiA=')
        ,@('5ZGoIOebriDllYYg5bqX', '7ZqM7LCoIOyDgeygkA==')
        ,@('ZnVuY3Rpb24gTGdTaG9wKG1lbnUsIEN1cnJlbmN5LCBDdXJyZW5jeV93eikK', 'ZnVuY3Rpb24gTGdTaG9wKG1lbnUsIEN1cnJlbmN5LCBDdXJyZW5jeV93eikKCUN1cnJlbmN5X3d6ID0gS09UUihDdXJyZW5jeV93eiBvciAiIikK')
        # Talent point totals/costs are quantities, not localized prose.
        ,@('TnVtYmVyVG9DaGluZXNlKEpZLlBlcnNvbltpZF1bIuWkqei1i+eCueaVsCJdKQ==', 'dG9zdHJpbmcoSlkuUGVyc29uW2lkXVsi5aSp6LWL54K55pWwIl0p')
        ,@('TnVtYmVyVG9DaGluZXNlKEpZLlBlcnNvbltpZF1bIuWkqei1i+eCueaVsCJdLDEp', 'dG9zdHJpbmcoSlkuUGVyc29uW2lkXVsi5aSp6LWL54K55pWwIl0p')
        ,@('TnVtYmVyVG9DaGluZXNlKHRmX2Rlc2NfY2FjaGUuY29zdCwxKQ==', 'dG9zdHJpbmcodGZfZGVzY19jYWNoZS5jb3N0KQ==')
        ,@('bG9jYWwgdGltZXR4dCA9IFlZIC4uIuW5tCIgLi4gTU0gLi4gIuaciCIgLi4gREQgLi4gIuaXpSIgLi4gSEggLi4gIuaXtiI=', 'bG9jYWwgdGltZXR4dCA9IFlZIC4uIuuFhCAiIC4uIE1NIC4uICLsm5QgIiAuLiBERCAuLiAi7J28ICIgLi4gSEggLi4gIuyLnCI=')
        ,@('X3N0YXR1c1N0ckNhY2hlLnRpbWVzdHIgPSAi5aSp5LmmIiAuLiBZWSAuLiAi5bm0IiAuLiBNTSAuLiAi5pyIIiAuLiBERCAuLiAi5pelIiAuLiBISCAuLiAi5pe2IiAuLiAi4pSCIg==', 'X3N0YXR1c1N0ckNhY2hlLnRpbWVzdHIgPSAi7LKc7IScICIgLi4gWVkgLi4gIuuFhCAiIC4uIE1NIC4uICLsm5QgIiAuLiBERCAuLiAi7J28ICIgLi4gSEggLi4gIuyLnCIgLi4gIuKUgiI=')
        ,@('X3N0YXR1c1N0ckNhY2hlLndtYXBEYXRlID0gTU0gLi4gIuaciCIgLi4gREQgLi4gIuaXpSIgLi4gSEggLi4gIuaXtiI=', 'X3N0YXR1c1N0ckNhY2hlLndtYXBEYXRlID0gTU0gLi4gIuyblCAiIC4uIEREIC4uICLsnbwgIiAuLiBISCAuLiAi7IucIg==')
        ,@('CQlsaWIuTG9hZFBORyg5MSx6bWVudVtwYWdlXVszXSoyLC0xLC0xLDEpCgoJCS0t6aG156CB', 'CQlsaWIuTG9hZFBORyg5MSx6bWVudVtwYWdlXVszXSoyLC0xLC0xLDEpCgoJCS0tIERyYXcgdGhlIG5hbWUgYWZ0ZXIgcGFnZSBiYWNrZ3JvdW5kcyBzbyB0aGUgcGxhcXVlIGNhbm5vdCBjb3ZlciBpdC4KCQlsaWIuRHJhd1N0cihDQy5TY3JlZW5XLzItc3RyaW5nbGVuKEpZLlBlcnNvbltpZF1bIuWnk+WQjSJdKS80KnNpemUyKjEuOSwgYnkqMTc4LCBKWS5QZXJzb25baWRdWyLlp5PlkI0iXSwgQ19XSElURSwgc2l6ZTIqMS44LCBDT05GSUcuQ3VycmVudFBhdGggLi4gIkZPTlQvMC50dGYiLENDLlNyY0NoYXJTZXQsIENDLk9TQ2hhclNldCkKCgkJLS3pobXnoIE=')
        ,@('CQkJaWYgYXR0ckNhY2hlLmZ0eHQgdGhlbgoJCQkJRHJhd1N0cmluZyhieCozMCwgQ0MuU2NyZWVuSCAtIHNpemUyKjQsICLljZXmrKE6ICIuLmF0dHJDYWNoZS5mdHh0LCBDX0dPTEQsIHNpemUyKjAuOCwgQ0MuRk9OVDEpCgkJCWVuZAoJCWVuZAoKCQlTaG93U2NyZWVuKCk=', 'CQkJaWYgYXR0ckNhY2hlLmZ0eHQgdGhlbgoJCQkJRHJhd1N0cmluZyhieCozMCwgQ0MuU2NyZWVuSCAtIHNpemUyKjQsICLljZXmrKE6ICIuLmF0dHJDYWNoZS5mdHh0LCBDX0dPTEQsIHNpemUyKjAuOCwgQ0MuRk9OVDEpCgkJCWVuZAoJCWVuZAoKCQktLSBGaW5hbCBjaGFyYWN0ZXItbmFtZSBwYXNzOiBubyBsYXRlciBkcmF3IGNhbGwgY2FuIGNvdmVyIHRoZSBwbGFxdWUuCgkJbG9jYWwga29EaXNwbGF5TmFtZSA9IEtPVFIoSlkuUGVyc29uW2lkXVsi5aeT5ZCNIl0gb3IgIiIpCgkJRHJhd1N0cmluZyhDQy5TY3JlZW5XLzIgLSBHZXRTdHJMZW4oa29EaXNwbGF5TmFtZSkgKiBzaXplMiAqIDAuOSwgYnkqMTc4LAoJCQlrb0Rpc3BsYXlOYW1lLCBDX1dISVRFLCBzaXplMioxLjgsIENDLkZPTlQyKQoKCQlTaG93U2NyZWVuKCk=')
    )
    Patch-LuaTextAssembly $Root 'jymenu.lua' $menuPairs 'X3N0YXR1c1N0ckNhY2hlLnRpbWVzdHIgPSAi7LKc7IScICI='
}

function Patch-DefaultPlayerName([string]$Root) {
    # Korean IME input is not available in the legacy name box.  Preserve a
    # user-supplied name, but make every new-game path use the canonical hero
    # name when CONFIG.PlayName is empty/whitespace or contains the Korean
    # display spelling, which the legacy person-data encoding cannot store.
    $namePairs = @(
        ,@('Q0MuTmV3UGVyc29uTmFtZT1DT05GSUcuUGxheU5hbWU7', 'Q0MuTmV3UGVyc29uTmFtZT0oQ09ORklHLlBsYXlOYW1lIGFuZCBDT05GSUcuUGxheU5hbWU6bWF0Y2goIiVTIikpIGFuZCBDT05GSUcuUGxheU5hbWUgb3IgIuWwj+iZvuexsyI7')
        ,@('Q0MuTmV3UGVyc29uTmFtZT0oQ09ORklHLlBsYXlOYW1lIGFuZCBDT05GSUcuUGxheU5hbWU6bWF0Y2goIiVTIikpIGFuZCBDT05GSUcuUGxheU5hbWUgb3IgIuWwj+iZvuexsyI7', 'Q0MuTmV3UGVyc29uTmFtZT0oQ09ORklHLlBsYXlOYW1lIGFuZCBDT05GSUcuUGxheU5hbWU6bWF0Y2goIiVTIikgYW5kIENPTkZJRy5QbGF5TmFtZX49IuyGjO2VmOuvuCIpIGFuZCBDT05GSUcuUGxheU5hbWUgb3IgIuWwj+iZvuexsyI7')
    )
    Patch-LuaTextAssembly $Root 'jyconst.lua' $namePairs 'Q0MuTmV3UGVyc29uTmFtZT0oQ09ORklHLlBsYXlOYW1lIGFuZCBDT05GSUcuUGxheU5hbWU6bWF0Y2goIiVTIikgYW5kIENPTkZJRy5QbGF5TmFtZX49IuyGjO2VmOuvuCIp'
}

function Patch-JyMenuHardcodedFonts([string]$Root) {
    # Several shop/menu functions bypass CC.FONT0..9 and open numbered TTF
    # files directly.  Korean labels patched into those paths render as square
    # glyphs, so redirect every such literal UI font to the bundled font.
    $target = Join-Path (Join-Path $Root 'script') 'jymenu.lua'
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        throw 'script\jymenu.lua was not found.'
    }
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $wrapper = [IO.File]::ReadAllText($target, $utf8)
    $source = ConvertFrom-LuaWrapper $wrapper
    $fontPattern = 'CONFIG\.CurrentPath\s*\.\.\s*["'']FONT/[0-9]\.[Tt][Tt][Ff]["'']'
    $fontMatches = [regex]::Matches($source, $fontPattern)
    if ($fontMatches.Count -eq 0) {
        if ($source.Contains('CONFIG.CurrentPath .. "FONT/korean.ttf"')) {
            Write-Status 'Hardcoded jymenu fonts are already redirected.'
            return
        }
        throw 'Hardcoded jymenu font anchors were not found; jymenu.lua was not changed.'
    }

    $patchedSource = [regex]::Replace($source, $fontPattern, 'CONFIG.CurrentPath .. "FONT/korean.ttf"')
    $backupDir = Join-Path $Root '_ko_auto_backup'
    [IO.Directory]::CreateDirectory($backupDir) | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ('jymenu_font_' + $stamp + '.lua')) -Force

    $patchedWrapper = ConvertTo-LuaWrapper $patchedSource $wrapper
    $temp = $target + '.ko_tmp'
    [IO.File]::WriteAllText($temp, $patchedWrapper, [Text.UTF8Encoding]::new($false))
    $verifySource = ConvertFrom-LuaWrapper ([IO.File]::ReadAllText($temp, $utf8))
    if ([regex]::Matches($verifySource, $fontPattern).Count -ne 0 -or
        -not $verifySource.Contains('CONFIG.CurrentPath .. "FONT/korean.ttf"')) {
        Remove-Item -LiteralPath $temp -Force
        throw 'Hardcoded jymenu font verification failed; original was preserved.'
    }
    Move-Item -LiteralPath $temp -Destination $target -Force
    Write-Status ('Hardcoded jymenu fonts redirected: ' + $fontMatches.Count)
}

function Patch-DescriptionSources([string]$Root) {
    # Translate complete descriptions before any UI splits them into glyphs/rows.
    # Base64 keeps this launcher parseable by Windows PowerShell 5.1 on every locale.
    $talentPairs = @(
        ,@('TnVtYmVyVG9DaGluZXNlKHRmY29zdCwxKQ==', 'dG9zdHJpbmcodGZjb3N0KQ==')
        ,@('TnVtYmVyVG9DaGluZXNlKFRGX2Nvc3QodGZpZCwgaWQpLCAxKQ==', 'dG9zdHJpbmcoVEZfY29zdCh0ZmlkLCBpZCkp')
        ,@('ICAgIHJldHVybiBkZXNjDQplbmQNCg0KLS0g5LiOIFRpYW5mdV9UWA==', 'ICAgIHJldHVybiBLT1RSKGRlc2MpDQplbmQNCg0KLS0g5LiOIFRpYW5mdV9UWA==')
        ,@('ICAgICAgICAgICAgcGFydHNbI3BhcnRzICsgMV0gPSB0cmFpdFs0XQ==', 'ICAgICAgICAgICAgcGFydHNbI3BhcnRzICsgMV0gPSBLT1RSKHRyYWl0WzRdKQ==')
        ,@('ICAgIGxvY2FsIGRlc2MgPSAjcGFydHMgPiAwIGFuZCB0YWJsZS5jb25jYXQocGFydHMsICIq77ytIikgb3IgKGNmZ1syXSBvciAiIik=', 'ICAgIGxvY2FsIGRlc2MgPSAjcGFydHMgPiAwIGFuZCB0YWJsZS5jb25jYXQocGFydHMsICIq77ytIikgb3IgS09UUihjZmdbMl0gb3IgIiIp')
        ,@('ICAgICAgICAgICAgaWYgdHlwZSh0ZXh0KSA9PSAic3RyaW5nIiBhbmQgdGV4dCB+PSAiIiB0aGVuIHJvd3NbI3Jvd3MgKyAxXSA9ICLil4YiIC4uIHRleHQgZW5k', 'ICAgICAgICAgICAgaWYgdHlwZSh0ZXh0KSA9PSAic3RyaW5nIiBhbmQgdGV4dCB+PSAiIiB0aGVuIHJvd3NbI3Jvd3MgKyAxXSA9ICLil4YiIC4uIEtPVFIodGV4dCkgZW5k')
        ,@('ICAgIGxvY2FsIGZ1bmN0aW9uIGNlbnRlclRleHQoeCwgeSwgdGV4dCwgY29sb3IsIGZvbnRTaXplLCBmb250KQ0KICAgICAgICBEcmF3U3RyaW5nKHggLSBHZXRTdHJMZW4odGV4dCkgKiBmb250U2l6ZSAvIDIsIHksIHRleHQsIGNvbG9yLCBmb250U2l6ZSwgZm9udCBvciBDQy5GT05UMykNCiAgICBlbmQ=', 'ICAgIGxvY2FsIGZ1bmN0aW9uIGNlbnRlclRleHQoeCwgeSwgdGV4dCwgY29sb3IsIGZvbnRTaXplLCBmb250KQ0KICAgICAgICB0ZXh0ID0gS09UUih0ZXh0KQ0KICAgICAgICBEcmF3U3RyaW5nKHggLSBHZXRTdHJMZW4odGV4dCkgKiBmb250U2l6ZSAvIDIsIHksIHRleHQsIGNvbG9yLCBmb250U2l6ZSwgZm9udCBvciBDQy5GT05UMykNCiAgICBlbmQ=')
        ,@('ICAgICAgICAgICAgICAgIGkgPT0gMSBhbmQgIiDkuIrkuIDpobUgUGdVcCIgb3IgIiDkuIvkuIDpobUgUGdEbiIsIHBhZ2VDb2xvciwgc2l6ZSAqIDAuOCwgQ0MuRk9OVDMp', 'ICAgICAgICAgICAgICAgIGkgPT0gMSBhbmQgIuS4iuS4gOmhtSBQZ1VwIiBvciAi5LiL5LiA6aG1IFBnRG4iLCBwYWdlQ29sb3IsIHNpemUgKiAwLjY4LCBDQy5GT05UMyk=')
    )
    Patch-LuaTextAssembly $Root 'tianfu.lua' $talentPairs 'ICAgIHJldHVybiBLT1RSKGRlc2Mp'

    $kungfuPairs = @(
        ,@('ICAgIHJldHVybiB0YWJsZS5jb25jYXQocGFydHMpDQplbmQNCg0KZnVuY3Rpb24gS3VuZ2Z1X3pzZWZmZWN0X21hcA==', 'ICAgIHJldHVybiBLT1RSKHRhYmxlLmNvbmNhdChwYXJ0cykpDQplbmQNCg0KZnVuY3Rpb24gS3VuZ2Z1X3pzZWZmZWN0X21hcA==')
        ,@('ICAgIHJldHVybiBkZXNjLi4iKu+8oi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIg0KZW5kDQoNCi0t5q2m5Yqf5ZCN56ew', 'ICAgIHJldHVybiBLT1RSKGRlc2MuLiIq77yiLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0iKQ0KZW5kDQoNCi0t5q2m5Yqf5ZCN56ew')
        ,@('ICAgIGt1bmdmdS5kZXNjID0gaXRlbURhdGFbIueJqeWTgeivtOaYjiJdIG9yICLml6Ai', 'ICAgIGt1bmdmdS5kZXNjID0gS09UUihpdGVtRGF0YVsi54mp5ZOB6K+05piOIl0gb3IgIuaXoCIp')
        ,@('ICAgIGxvY2FsIHdnbmFtZSA9IChteVRoaW5nIGFuZCBteVRoaW5nWyLlkI3np7AiXSkgb3Iga3VuZ2Z1RGF0YVsi5ZCN56ewIl0NCiAgICBsb2NhbCBuYW1lMSA9IHN0cmluZ3N1Yih3Z25hbWUsIDEsIDIpDQogICAgbG9jYWwgbmFtZTIgPSBzdHJpbmdzdWIod2duYW1lLCAzLCA0KQ==', 'ICAgIGxvY2FsIHdnbmFtZSA9IEtPVFIoKG15VGhpbmcgYW5kIG15VGhpbmdbIuWQjeensCJdKSBvciBrdW5nZnVEYXRhWyLlkI3np7AiXSkNCiAgICBsb2NhbCBuYW1lMSA9IHN0cmluZ3N1Yih3Z25hbWUsIDEsIDIpDQogICAgbG9jYWwgbmFtZTIgPSBzdHJpbmdzdWIod2duYW1lLCAzLCA0KQ==')
        ,@('ZnVuY3Rpb24gS3VuZ2Z1X25hbWUod3Vnb25nKQ0KICAgIHJldHVybiBKWS5XdWdvbmdbd3Vnb25nXVsi5ZCN56ewIl0NCmVuZA==', 'ZnVuY3Rpb24gS3VuZ2Z1X25hbWUod3Vnb25nKQ0KICAgIHJldHVybiBLT1RSKEpZLld1Z29uZ1t3dWdvbmddWyLlkI3np7AiXSkNCmVuZA==')
    )
    Patch-LuaTextAssembly $Root 'kungfu.lua' $kungfuPairs 'ICAgIHJldHVybiBLT1RSKHRhYmxlLmNvbmNhdChwYXJ0cykp'
}

function Invoke-KoreanPatch([string]$Root) {
    Install-KoreanPayload $Root
    Install-KoreanAssets $Root
    Patch-JyMain $Root
    Patch-JyConst $Root
    Patch-DefaultPlayerName $Root
    Patch-TimeAndSaveUI $Root
    Patch-JyMenuHardcodedFonts $Root
    Patch-DescriptionSources $Root
    Update-NewChineseReport $Root
    Update-TranslationRequest $Root
}

function Find-GameExe([string]$Root) {
    foreach ($name in @('jinshuqunxiazhuan.exe', 'qunxia52.exe')) {
        $candidate = Join-Path $Root $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

try {
    $gameRoot = $PSScriptRoot
    Install-OnlineUpdate $args
    Invoke-KoreanPatch $gameRoot
    if ($args -contains '-PatchOnly') {
        Write-Status 'Patch-only mode completed.'
        exit 0
    }

    $gameExe = Find-GameExe $gameRoot
    if (-not $gameExe) {
        throw 'Game executable was not found (jinshuqunxiazhuan.exe or qunxia52.exe).'
    }
    Write-Status ('Starting ' + [IO.Path]::GetFileName($gameExe))
    Start-Process -FilePath $gameExe -WorkingDirectory $gameRoot | Out-Null

    do {
        Start-Sleep -Milliseconds 700
        $running = @(Get-Process -Name 'jinshuqunxiazhuan','qunxia52' -ErrorAction SilentlyContinue).Count -gt 0
    } while ($running)

    Write-Status 'Game closed. Checking for an official update...'
    Invoke-KoreanPatch $gameRoot
    Write-Status 'Done. A newly installed FIX was patched automatically.'
    exit 0
} catch {
    Write-Host ('[JINSHU KO] ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
