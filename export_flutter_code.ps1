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
    Write-Host "Or select a specific directory:"
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

$choice = Read-Host "`nEnter your choice (0-$($dirs.Count))"

# ===== 处理全部导出的选项 =====
if ($choice -eq "0") {
    $targetDir = $root
    Write-Host "Exporting ENTIRE lib directory: $targetDir"
} 
# ===== 检查是否要查看子目录 =====
elseif ($choice.EndsWith("/")) {
    $index = [int]$choice.TrimEnd('/') - 1
    if ($index -lt 0 -or $index -ge $dirs.Count) {
        Write-Host "Invalid selection"
        exit
    }
    
    $selectedDir = $dirs[$index]
    $subDirs = Get-ChildItem $selectedDir.FullName -Directory
    
    if ($subDirs.Count -eq 0) {
        Write-Host "$($selectedDir.Name) has no subdirectories"
        $targetDir = $selectedDir.FullName
    } else {
        Write-Host "`nSubdirectories of $($selectedDir.Name):"
        for ($i = 0; $i -lt $subDirs.Count; $i++) {
            Write-Host "$($i + 1). $($subDirs[$i].Name)"
        }
        
        Write-Host "0. Export parent directory ($($selectedDir.Name))"
        $subChoice = Read-Host "`nSelect subdirectory number"
        
        if ($subChoice -eq "0") {
            $targetDir = $selectedDir.FullName
        } else {
            $subIndex = [int]$subChoice - 1
            if ($subIndex -lt 0 -or $subIndex -ge $subDirs.Count) {
                Write-Host "Invalid selection"
                exit
            }
            $targetDir = $subDirs[$subIndex].FullName
        }
    }
} 
# ===== 正常选择子目录 =====
else {
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $dirs.Count) {
        Write-Host "Invalid selection"
        exit
    }
    $targetDir = $dirs[$index].FullName
}

# ===== 确认导出 =====
Write-Host ""
Write-Host "========================================"
Write-Host "Exporting from: $targetDir"
Write-Host "Output file: $output"
Write-Host "========================================"
Write-Host ""

# 统计要导出的文件数量
$dartFiles = Get-ChildItem $targetDir -Recurse -Filter "*.dart" -File
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
Get-ChildItem $targetDir -Recurse -Filter "*.dart" | ForEach-Object {
    $fileCount++
    Write-Host "  [$fileCount/$($dartFiles.Count)] $($_.FullName)"
    
    try {
        $content = Get-Content $_.FullName -Encoding UTF8 -Raw
        
        # 添加文件路径作为分隔符
        Add-Content $output "========================================`n" -Encoding UTF8
        Add-Content $output "File: $($_.FullName)`n" -Encoding UTF8
        Add-Content $output "Size: $($_.Length) bytes`n" -Encoding UTF8
        Add-Content $output "Modified: $($_.LastWriteTime)`n" -Encoding UTF8
        Add-Content $output "========================================`n" -Encoding UTF8
        
        # 添加文件内容
        Add-Content $output $content -Encoding UTF8
        
        # 添加文件之间的分隔符
        Add-Content $output "`n`n" -Encoding UTF8
        
    } catch {
        Write-Host "  Error reading file: $($_.FullName)" -ForegroundColor Red
        Add-Content $output "ERROR: Failed to read file $($_.FullName)`n" -Encoding UTF8
    }
}

# ===== 导出完成 =====
Write-Host ""
Write-Host "========================================"
Write-Host "Export completed!"
Write-Host "Output file: $output"
Write-Host "Total files exported: $fileCount"
Write-Host "File size: $((Get-Item $output).Length) bytes"
Write-Host "========================================"

# 可选：打开输出文件
$openFile = Read-Host "`nOpen output file? (Y/N)"
if ($openFile -eq "Y" -or $openFile -eq "y") {
    Start-Process $output
}