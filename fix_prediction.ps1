# ===== 修复 PowerShell 命令预测功能脚本 =====
Write-Host "开始修复 PowerShell 命令预测（灰色补全）功能..." -ForegroundColor Cyan

# 1. 为当前用户安装或更新 PSReadLine 模块（确保版本够新）
Write-Host "`n1. 检查/更新 PSReadLine 模块..." -ForegroundColor Yellow
if (Get-Command Install-Module -ErrorAction SilentlyContinue) {
    Install-Module -Name PSReadLine -Force -Scope CurrentUser -AllowClobber
    Write-Host "   PSReadLine 模块已更新。" -ForegroundColor Green
} else {
    Write-Host "   跳过模块更新（旧版PowerShell）。" -ForegroundColor Yellow
}

# 2. 确保当前会话已启用预测
Write-Host "`n2. 在当前会话中启用预测..." -ForegroundColor Yellow
Import-Module PSReadLine -Force -ErrorAction SilentlyContinue
try {
    Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
    Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction Stop
    Write-Host "   当前会话预测已启用。" -ForegroundColor Green
} catch {
    Write-Host "   当前PSReadLine版本不支持预测参数，请升级到PowerShell 7。" -ForegroundColor Red
}

# 3. 修复配置文件
Write-Host "`n3. 修复配置文件 (\$PROFILE)..." -ForegroundColor Yellow
$profileContent = @"

# ===== 命令历史预测 (灰色自动补全) =====
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
"@

# 将启用预测的命令添加到配置文件末尾
Add-Content -Path $PROFILE -Value "`n$profileContent" -Encoding UTF8
Write-Host "   预测配置已添加到配置文件: $PROFILE" -ForegroundColor Green

# 4. 重新加载配置文件
Write-Host "`n4. 重新加载配置文件使更改生效..." -ForegroundColor Yellow
. $PROFILE

Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "修复完成！" -ForegroundColor Green
Write-Host "="*50 -ForegroundColor Cyan
Write-Host "请关闭并重新打开VSCode，以使灰色预测功能完全生效。" -ForegroundColor Yellow