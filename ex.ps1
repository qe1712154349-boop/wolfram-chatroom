# ===== Configuration =====
$root = "lib"
$output = "exported_code.txt"

# ===== Function to generate directory tree =====
function Get-DirectoryTree {
    param(
        [string]$basePath,
        [int]$maxDepth = 3,
        [switch]$showAllExtensions = $false
    )
    
    $treeLines = @()
    $treeLines += "项目结构 (lib/):"
    $treeLines += ""
    
    function Get-TreeRecursive {
        param(
            [string]$currentPath,
            [int]$currentDepth,
            [string]$prefix
        )
        
        if ($currentDepth -gt $maxDepth) { return @() }
        
        $items = Get-ChildItem $currentPath -ErrorAction SilentlyContinue | Sort-Object Name
        $lines = @()
        
        $visibleItems = $items.Where({
            if ($_.PSIsContainer) {
                $_.Name -notin 'build','.git','.idea','__pycache__','node_modules'
            }
            else {
                $showAllExtensions -or $_.Extension -in '.dart','.json','.yaml','.yml','.xml','.md','.txt'
            }
        })
        
        for ($i = 0; $i -lt $visibleItems.Count; $i++) {
            $item = $visibleItems[$i]
            $isLast = ($i -eq $visibleItems.Count - 1)
            
            $linePrefix = $prefix
            if ($currentDepth -gt 0) {
                $linePrefix += if ($isLast) { "└── " } else { "├── " }
            }
            
            $itemName = $item.Name
            if ($item.PSIsContainer) { $itemName += "/" }
            
            $comment = switch -Regex ($item.Name) {
                '^main\.dart$'              { " # 入口文件" }
                '^app\.dart$'  { if ($currentPath -like "*\app") { " # MyBunnyApp" } }
                'theme\.dart$'              { " # 主题配置" }
                '.*_page\.dart$'            { " # 页面" }
                '.*_service\.dart$'         { " # 服务" }
                '.*_model\.dart$'           { " # 数据模型" }
                '.*_(widget|component)\.dart$' { " # 组件" }
                default                     { "" }
            }
            
            $lines += "$linePrefix$itemName$comment"
            
            if ($item.PSIsContainer) {
                $childPrefix = $prefix
                if ($currentDepth -gt 0) {
                    $childPrefix += if ($isLast) { "    " } else { "│   " }
                }
                $lines += Get-TreeRecursive -currentPath $item.FullName -currentDepth ($currentDepth + 1) -prefix $childPrefix
            }
        }
        return $lines
    }
    
    $treeLines += Get-TreeRecursive -currentPath $basePath -currentDepth 0 -prefix ""
    
    $dartFilesCount = (Get-ChildItem $basePath -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue).Count
    
    $treeLines += ""
    $treeLines += "=" * 50
    $treeLines += "项目统计:"
    $treeLines += "  总Dart文件数: $dartFilesCount"
    $treeLines += "  最大深度限制: $maxDepth"
    $treeLines += "  生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $treeLines += "=" * 50
    
    return $treeLines -join "`n"
}

# ===================== 主程序开始 =====================

if (!(Test-Path $root -PathType Container)) {
    Write-Host "错误：找不到 lib 目录" -ForegroundColor Red
    exit 1
}

Write-Host "正在生成项目目录树..." -ForegroundColor Cyan
$directoryTree = Get-DirectoryTree -basePath $root -maxDepth 4
Write-Host "目录树生成完成" -ForegroundColor Green

# 列出一级目录供选择
$dirs = Get-ChildItem $root -Directory
if ($dirs.Count -eq 0) {
    Write-Host "lib 目录下没有子目录" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n请选择要导出的目录："
Write-Host "(输入序号选择目录，输入如 4/ 可查看 4 号目录的子目录)" -ForegroundColor DarkCyan

for ($i = 0; $i -lt $dirs.Count; $i++) {
    $subCount = (Get-ChildItem $dirs[$i].FullName -Directory).Count
    $info = if ($subCount -gt 0) { "[$subCount 个子目录]" } else { "" }
    Write-Host "$($i+1). $($dirs[$i].Name) $info"
}

$choice = Read-Host "`n请输入序号"

# ===== 检查是否要查看子目录 =====
if ($choice.EndsWith("/")) {
    $index = [int]$choice.TrimEnd('/') - 1
    if ($index -lt 0 -or $index -ge $dirs.Count) {
        Write-Host "无效选择" -ForegroundColor Red
        exit 1
    }
    
    $selectedDir = $dirs[$index]
    $subDirs = Get-ChildItem $selectedDir.FullName -Directory
    
    if ($subDirs.Count -eq 0) {
        Write-Host "$($selectedDir.Name) 没有子目录" -ForegroundColor Yellow
        $targetDirs = @($selectedDir.FullName)
    } else {
        Write-Host "`n$($selectedDir.Name) 的子目录：" -ForegroundColor Cyan
        for ($i = 0; $i -lt $subDirs.Count; $i++) {
            Write-Host "$($i + 1). $($subDirs[$i].Name)"
        }
        
        Write-Host "`n选择子目录（示例）:" -ForegroundColor DarkCyan
        Write-Host "  2          = 只选择目录 2"
        Write-Host "  1+3+5     = 选择目录 1、3 和 5（使用 + 分隔）"
        Write-Host "  1,3,5     = 选择目录 1、3 和 5（使用 , 分隔）"
        Write-Host "  2-4       = 选择目录 2、3 和 4"
        Write-Host "  all       = 选择所有子目录"
        Write-Host "  0         = 选择父目录（全部）"
        
        $subChoice = Read-Host "`n请输入选择"
        
        # ===== 解析多重选择 =====
        $targetDirs = @()
        
        if ($subChoice -eq "0") {
            # 导出父目录
            $targetDirs = @($selectedDir.FullName)
        }
        elseif ($subChoice -eq "all") {
            # 导出所有子目录
            $targetDirs = $subDirs.FullName
        }
        else {
            # 将 + 替换为 , 以便解析
            $subChoice = $subChoice -replace '\+', ','
            
            # 解析多重选择
            $selections = @()
            
            # 按逗号分割
            $parts = $subChoice.Split(',')
            foreach ($part in $parts) {
                $part = $part.Trim()
                
                # 检查范围（如 2-4）
                if ($part -match '^(\d+)-(\d+)$') {
                    $start = [int]$matches[1] - 1
                    $end = [int]$matches[2] - 1
                    
                    for ($i = $start; $i -le $end; $i++) {
                        if ($i -ge 0 -and $i -lt $subDirs.Count) {
                            $selections += $i
                        }
                    }
                }
                elseif ($part -match '^\d+$') {
                    # 单个数字
                    $idx = [int]$part - 1
                    if ($idx -ge 0 -and $idx -lt $subDirs.Count) {
                        $selections += $idx
                    }
                }
            }
            
            # 去除重复并排序
            $selections = $selections | Sort-Object -Unique
            
            if ($selections.Count -eq 0) {
                Write-Host "没有有效的选择" -ForegroundColor Red
                exit 1
            }
            
            # 显示将要导出的内容
            Write-Host "`n将从以下位置导出：" -ForegroundColor Green
            foreach ($idx in $selections) {
                $relativePath = $subDirs[$idx].FullName.Replace((Get-Location).Path + "\", "")
                Write-Host "  - $relativePath"
            }
            
            # 添加选中的目录
            foreach ($idx in $selections) {
                $targetDirs += $subDirs[$idx].FullName
            }
        }
    }
} else {
    # ===== 正常选择 =====
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $dirs.Count) {
        Write-Host "无效选择" -ForegroundColor Red
        exit 1
    }
    $targetDirs = @($dirs[$index].FullName)
    Write-Host "将导出目录: $($dirs[$index].Name)" -ForegroundColor Green
}

# ===== 清空输出文件并写入目录树 =====
Write-Host "`n正在生成目录树到输出文件..." -ForegroundColor Cyan
$directoryTree | Out-File $output -Encoding utf8

# ===== 添加章节分隔符 =====
Add-Content $output ""
Add-Content $output "=" * 60 -Encoding UTF8
Add-Content $output "导出的代码文件" -Encoding UTF8
Add-Content $output "=" * 60 -Encoding UTF8
Add-Content $output "" -Encoding UTF8

# ===== 添加导出摘要 =====
Add-Content $output "导出摘要:" -Encoding UTF8
Add-Content $output "  选中的目录:" -Encoding UTF8
foreach ($dir in $targetDirs) {
    $relativePath = $dir.Replace((Get-Location).Path + "\", "")
    Add-Content $output "    - $relativePath" -Encoding UTF8
}
Add-Content $output "  导出时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8
Add-Content $output "" -Encoding UTF8
Add-Content $output "=" * 60 -Encoding UTF8
Add-Content $output "" -Encoding UTF8

# ===== 遍历所有选中目录中的dart文件 =====
$totalFiles = 0

foreach ($targetDir in $targetDirs) {
    $files = Get-ChildItem $targetDir -Recurse -Filter "*.dart"
    $fileCount = $files.Count
    $totalFiles += $fileCount
    
    if ($fileCount -eq 0) {
        Write-Host "  在 $($targetDir.Split('\')[-1]) 中没有找到 .dart 文件" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  在 $($targetDir.Split('\')[-1]) 中找到 $fileCount 个 .dart 文件" -ForegroundColor Green
    
    foreach ($file in $files) {
        try {
            $content = Get-Content $file.FullName -Encoding UTF8 -Raw -ErrorAction Stop
            
            # 添加文件分隔符
            Add-Content $output "=" * 40 -Encoding UTF8
            Add-Content $output "文件: $($file.FullName)" -Encoding UTF8
            Add-Content $output "大小: $([math]::Round($file.Length/1024,2)) KB" -Encoding UTF8
            Add-Content $output "修改时间: $($file.LastWriteTime)" -Encoding UTF8
            Add-Content $output "=" * 40 -Encoding UTF8
            Add-Content $output "" -Encoding UTF8
            
            Add-Content $output $content -Encoding UTF8
            Add-Content $output "`n`n" -Encoding UTF8
        }
        catch {
            Write-Host "  读取 $($file.Name) 时出错: $_" -ForegroundColor Red
            Add-Content $output "读取 $($file.FullName) 时出错: $_" -Encoding UTF8
        }
    }
}

# ===== 添加最终摘要 =====
Add-Content $output "" -Encoding UTF8
Add-Content $output "=" * 60 -Encoding UTF8
Add-Content $output "导出完成" -Encoding UTF8
Add-Content $output "  导出的总文件数: $totalFiles" -Encoding UTF8
Add-Content $output "  总大小: $([math]::Round((Get-Item $output).Length/1024,2)) KB" -Encoding UTF8
Add-Content $output "=" * 60 -Encoding UTF8

Write-Host "`n导出完成: $output" -ForegroundColor Cyan
Write-Host "导出的总文件数: $totalFiles" -ForegroundColor Green
Write-Host "导出总大小: $([math]::Round((Get-Item $output).Length/1024,2)) KB" -ForegroundColor Green

# ===== 显示预览 =====
Write-Host "`n输出文件预览 (前20行):" -ForegroundColor Cyan
Write-Host "-" * 50
Get-Content $output -TotalCount 20 | ForEach-Object { Write-Host $_ }
Write-Host "-" * 50
Write-Host "完整文件请查看: $((Get-Item $output).FullName)" -ForegroundColor Cyan