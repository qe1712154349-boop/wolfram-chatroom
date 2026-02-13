cd D:\D\my_new_app
$files = Get-ChildItem .\lib -Recurse -Filter *.dart -File | Where-Object { $_.FullName -notmatch '\\theme\\' }
$results = @()
$p1 = 'Color\(0x[0-9A-Fa-f]{6,8}\)|Color\.fromARGB\(|Color\.fromRGBO\('
$p2 = 'Colors\.[a-zA-Z]+(\[?\d*\]?)?'
$p3 = 'Theme\.of\(context\)\.(primaryColor|accentColor|backgroundColor|cardColor|colorScheme\.[a-zA-Z]+)'
$p4 = 'isDark\s*\?\s*.*(Color\(0x|Color\.from|Colors\.)'
$ex = @('context\.themeColor','ref\.themeColor','themeColor\(','ColorSemantic\.','userBubbleBackground','aiBubbleBackground')
foreach ($f in $files) {
    $lines = Get-Content $f.FullName
    $i = 0
    foreach ($l in $lines) {
        $i++
        $c = ''
        if ($l -match $p4) { $c = 'C4' } elseif ($l -match $p1) { $c = 'C1' } elseif ($l -match $p2) { $c = 'C2' } elseif ($l -match $p3) { $c = 'C3' }
        if ($c) {
            $skip = $false
            foreach ($k in $ex) { if ($l -match $k) { $skip = $true; break } }
            if (-not $skip) {
                $results += [PSCustomObject]@{ FilePath = $f.FullName.Replace((Get-Location).Path+'\',''); Line = $i; Code = $l.Trim(); Cat = $c; Confirmed = $false }
            }
        }
    }
}
$results | Export-Csv .\hardcode.csv -NoTypeInformation -Encoding UTF8
$results | ConvertTo-Json | Out-File .\hardcode.json -Encoding UTF8
Write-Host "完成，共 $($results.Count) 处" -ForegroundColor Green