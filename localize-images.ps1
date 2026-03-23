$ErrorActionPreference = "Stop"

$htmlFile = "index_localized.html"
$imgDir = "assets\img"

New-Item -ItemType Directory -Force -Path $imgDir | Out-Null

$html = Get-Content $htmlFile -Raw -Encoding UTF8

$pattern = 'https://(?:static|thb)\.tildacdn\.(?:one|com)/[^\s"''<>)]+' 
$matches = [regex]::Matches($html, $pattern) | ForEach-Object { $_.Value } | Sort-Object -Unique

Write-Host "Найдено URL:" $matches.Count

$downloadMap = @{}
$counter = 1

foreach ($url in $matches) {
    $cleanUrl = $url -replace '&quot;$',''
    $uri = [System.Uri]$cleanUrl
    $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)

    if ([string]::IsNullOrWhiteSpace($fileName)) {
        $fileName = "file_$counter.bin"
    }

    $safeName = $fileName -replace '[\\/:*?"<>|]', '_'

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($safeName)
    $ext = [System.IO.Path]::GetExtension($safeName)

    if ([string]::IsNullOrWhiteSpace($ext)) {
        $ext = ".bin"
    }

    $targetName = $safeName
    $i = 1
    while (Test-Path (Join-Path $imgDir $targetName)) {
        $targetName = "${baseName}_$i$ext"
        $i++
    }

    $targetPath = Join-Path $imgDir $targetName

    try {
        Invoke-WebRequest -Uri $cleanUrl -OutFile $targetPath
        $relativePath = "assets/img/$targetName"
        $downloadMap[$url] = $relativePath
        $downloadMap[$cleanUrl] = $relativePath
        Write-Host "OK  $cleanUrl -> $relativePath"
    }
    catch {
        Write-Warning "FAIL $cleanUrl"
    }

    $counter++
}

foreach ($key in $downloadMap.Keys | Sort-Object Length -Descending) {
    $escapedKey = [regex]::Escape($key)
    $html = [regex]::Replace($html, $escapedKey, $downloadMap[$key])
}

Set-Content -Path "index_fully_local.html" -Value $html -Encoding UTF8

Write-Host ""
Write-Host "Готово:"
Write-Host " - картинки скачаны в assets\img"
Write-Host " - создан файл index_fully_local.html"