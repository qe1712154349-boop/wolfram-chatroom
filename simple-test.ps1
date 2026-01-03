Write-Host "娴嬭瘯鑴氭湰..." -ForegroundColor Green
$basePath = "lib/pages"

# 鏄剧ず瀛愮洰褰?
$dirs = Get-ChildItem -Path $basePath -Directory
Write-Host "璇烽€夋嫨瑕佸鍑虹殑鐩綍锛? -ForegroundColor Yellow
$i = 1
foreach ($dir in $dirs) {
    Write-Host "$i. $($dir.Name)" -ForegroundColor White
    $i++
}

$choice = Read-Host "璇疯緭鍏ラ€夋嫨 (1-$($dirs.Count))"
Write-Host "浣犻€夋嫨浜? $choice" -ForegroundColor Green
