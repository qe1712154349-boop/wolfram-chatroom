# 创建最简单的交互脚本
@'
Write-Host "测试脚本..." -ForegroundColor Green
$basePath = "lib/pages"

# 显示子目录
$dirs = Get-ChildItem -Path $basePath -Directory
Write-Host "请选择要导出的目录：" -ForegroundColor Yellow
$i = 1
foreach ($dir in $dirs) {
    Write-Host "$i. $($dir.Name)" -ForegroundColor White
    $i++
}

$choice = Read-Host "请输入选择 (1-$($dirs.Count))"
Write-Host "你选择了: $choice" -ForegroundColor Green
'@ | Out-File -FilePath "simple-test.ps1" -Encoding UTF8

# 运行测试
.\simple-test.ps1