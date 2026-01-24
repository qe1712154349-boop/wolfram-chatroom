# ===== Configuration =====
$root = "lib"
$output = "exported_code.txt"

# ===== Check lib directory =====
if (!(Test-Path $root)) {
    Write-Host "lib directory not found"
    exit
}

# ===== List first-level directories =====
$dirs = Get-ChildItem $root -Directory

# 统计lib根目录下的Dart文件数量
$rootFiles = Get-ChildItem $root -Filter "*.dart" -File
$rootFileCount = $rootFiles.Count

Write-Host "========================================"
Write-Host "           Directory Exporter           "
Write-Host "========================================"
Write-Host ""
Write-Host "Select an export option:"
Write-Host "0. Export ENTIRE lib directory (all files recursively)"
Write-Host ""

if ($dirs.Count -gt 0) {
    Write-Host "Or select specific directories (e.g., 1, 1+2, 1-3, 2+4):"
    for ($i = 0; $i -lt $dirs.Count; $i++) {
        # 统计子目录中的Dart文件数量
        $subFiles = Get-ChildItem $dirs[$i].FullName -Recurse -Filter "*.dart" -File
        $subDirCount = (Get-ChildItem $dirs[$i].FullName -Directory).Count
        $info = if ($subDirCount -gt 0) { "[$subDirCount subdirs]" } else { "" }
        Write-Host "$($i + 1). $($dirs[$i].Name) $info ($($subFiles.Count) Dart files)"
    }
} else {
    Write-Host "No subdirectories found in lib"
}

if ($rootFileCount -gt 0) {
    Write-Host ""
    Write-Host "Note: Lib root contains $rootFileCount Dart file(s)"
}

$choice = Read-Host "`nEnter your choice (0-$($dirs.Count), or multiple like 1+2)"

# ===== 函数：解析多选输入 =====
function Parse-MultiChoice {
    param([string]$inputText, [int]$maxIndex)
    
    $selectedIndices = @()
    
    # 处理空输入
    if ([string]::IsNullOrWhiteSpace($inputText)) {
        return $selectedIndices
    }
    
    # 如果是单个数字
    if ($inputText -match '^\d+$') {
        $num = [int]$inputText
        if ($num -ge 0 -and $num -le $maxIndex) {
            return @($num)
        }
        return $selectedIndices
    }
    
    # 分割输入（支持 + - , 空格等分隔符）
    $inputText = $inputText -replace '\s', ''  # 移除空格
    $parts = $inputText -split '[+,]'  # 按 + 或 , 分割
    
    foreach ($part in $parts) {
        # 处理范围 如 1-3
        if ($part -match '^(\d+)-(\d+)$') {
            $start = [int]$matches[1]
            $end = [int]$matches[2]
            
            if ($start -le $end -and $start -ge 0 -and $end -le $maxIndex) {
                for ($i = $start; $i -le $end; $i++) {
                    $selectedIndices += $i
                }
            }
        }
        # 处理单个数字
        elseif ($part -match '^\d+$') {
            $num = [int]$part
            if ($num -ge 0 -and $num -le $maxIndex) {
                $selectedIndices += $num
            }
        }
    }
    
    # 去重并排序
    return $selectedIndices | Sort-Object | Get-Unique
}

# ===== 处理全部导出的选项 =====
if ($choice -eq "0") {
    $targetDirs = @($root)
    Write-Host "Exporting ENTIRE lib directory: $root"
} 
else {
    # 解析多选输入
    $selectedNumbers = Parse-MultiChoice -inputText $choice -maxIndex $dirs.Count
    
    if ($selectedNumbers.Count -eq 0) {
        Write-Host "Invalid selection"
        exit
    }
    
    $targetDirs = @()
    foreach ($num in $selectedNumbers) {
        if ($num -eq 0) {
            # 如果包含0，则只导出整个lib（覆盖其他选择）
            $targetDirs = @($root)
            Write-Host "Selected option 0, exporting ENTIRE lib directory"
            break
        } else {
            $index = $num - 1
            if ($index -lt 0 -or $index -ge $dirs.Count) {
                Write-Host "Warning: Invalid index $num, skipping"
                continue
            }
            $targetDirs += $dirs[$index].FullName
        }
    }
}

# ===== 显示选择结果 =====
Write-Host ""
Write-Host "========================================"
Write-Host "Selected directories to export:"
foreach ($dir in $targetDirs) {
    Write-Host "- $dir"
}
Write-Host "========================================"
Write-Host ""

# 统计要导出的文件数量
$dartFiles = @()
foreach ($targetDir in $targetDirs) {
    $files = Get-ChildItem $targetDir -Recurse -Filter "*.dart" -File
    $dartFiles += $files
}

Write-Host "Found $($dartFiles.Count) Dart file(s) to export"

$confirm = Read-Host "Continue? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Export cancelled"
    exit
}

# ===== Clear output file =====
"" | Out-File $output -Encoding utf8
Write-Host "Exporting files..."

# ===== Traverse dart files =====
$fileCount = 0
foreach ($file in $dartFiles) {
    $fileCount++
    Write-Host "  [$fileCount/$($dartFiles.Count)] $($file.FullName)"
    
    try {
        $content = Get-Content $file.FullName -Encoding UTF8 -Raw
        
        # 添加文件路径作为分隔符
        Add-Content $output "========================================`n" -Encoding UTF8
        Add-Content $output "File: $($file.FullName)`n" -Encoding UTF8
        Add-Content $output "Size: $($file.Length) bytes`n" -Encoding UTF8
        Add-Content $output "Modified: $($file.LastWriteTime)`n" -Encoding UTF8
        Add-Content $output "========================================`n" -Encoding UTF8
        
        # 添加文件内容
        Add-Content $output $content -Encoding UTF8
        
        # 添加文件之间的分隔符
        Add-Content $output "`n`n" -Encoding UTF8
        
    } catch {
        Write-Host "  Error reading file: $($file.FullName)" -ForegroundColor Red
        Add-Content $output "ERROR: Failed to read file $($file.FullName)`n" -Encoding UTF8
    }
}

# ===== 导出完成 =====
Write-Host ""
Write-Host "========================================"
Write-Host "Export completed!"
Write-Host "Output file: $output"
Write-Host "Total files exported: $fileCount"
Write-Host "File size: $((Get-Item $output).Length) bytes"
Write-Host "Selected directories: $($targetDirs.Count)"
Write-Host "========================================"

# 可选：打开输出文件
$openFile = Read-Host "`nOpen output file? (Y/N)"
if ($openFile -eq "Y" -or $openFile -eq "y") {
    Start-Process $output
}