function Get-StringHash([String] $string,$hashName = "SHA256")
{
$StringBuilder = New-Object System.Text.StringBuilder
[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
[Void]$StringBuilder.Append($_.ToString("x2"))
}
$StringBuilder.ToString()
}

function Get-HashOfFilesInDirectoryRecursive ([String] $path) {
    $filehashs=""
    $listOfFilesToGatherHashes=$(Get-ChildItem $path -Exclude *.hasha256 -Recurse -File).FullName
    foreach($pathlookup in $listOfFilesToGatherHashes){
        Write-Host $pathlookup
            $filehash=$(Get-FileHash -Algorithm SHA256 -Path $pathlookup).Hash  
            $filehashs="$filehash$filehashs"
    }
    return Get-StringHash -string "$filehashs"
}

function Get-HashOfFilesInDirectoryNonRecursive ([String] $path) {
    $filehashs=""
    $listOfFilesToGatherHashes=$(Get-ChildItem $path -File).FullName
    foreach($pathlookup in $listOfFilesToGatherHashes){
        if($pathlookup -like "*.hasha256*"){
            continue
        }
            $filehash=$(Get-FileHash -Algorithm SHA256 -Path $pathlookup).Hash  
            $filehashs="$filehash$filehashs"
    }
    return Get-StringHash -string "$filehashs"
}

function Get-Subfolders ([String] $path) {
    return  $(Get-ChildItem -Path $path -Recurse -Directory).FullName
}

function Get-HiddenHashFile([String] $path) {
    if(Test-Path $path\.hasha256){
        $hashValue=$(Get-Content -Path $path\.hasha256)
        $hashValue=$hashValue.replace("`n","").replace("`r","")
        return $hashValue
    }
    return
}

(ps -id $pid).PriorityClass = 'RealTime'
$startingDirectory="C:\"
$ElapsedTime = 0
$StartTime = $(get-date)
$ElapsedTime = $(get-date) - $StartTime
$subfolderPaths=Get-Subfolders -path $startingDirectory
foreach($folder in $subfolderPaths){
    $directoryHashExist=$false
    $previousDirectoryHash=Get-HiddenHashFile -path $folder
    $newDirectoryHash=$(Get-HashOfFilesInDirectoryNonRecursive -path $folder | Out-String).replace("`n","").replace("`r","")
    if([string]$previousDirectoryHash -notlike [string]$newDirectoryHash){
        $folder >> $PSScriptRoot\fileschanged.txt
    }
    $newDirectoryHash | Out-File $folder\.hasha256
    $previousDirectoryHash=$null
    $newDirectoryHash=$null

}
$directoryHashExist=$false
$previousDirectoryHash=Get-HiddenHashFile -path $startingDirectory
$newDirectoryHash=$(Get-HashOfFilesInDirectoryNonRecursive -path $startingDirectory | Out-String).replace("`n","").replace("`r","")
if([string]$previousDirectoryHash -notlike [string]$newDirectoryHash){
    $startingDirectory >> $PSScriptRoot\fileschanged.txt
}
$newDirectoryHash | Out-File $startingDirectory\.hasha256


<#
foreach($directoryPath in $(Get-ChildItem -Path $startingDirectory -Directory).FullName | Get-Unique){
    $directoryHashExist=$false
    $previousDirectoryHash=Get-HiddenHashFile -path $directoryPath
    $newDirectoryHash=$(Get-HashOfDirectory -path $directoryPath | Out-String).replace("`n","").replace("`r","")

    $newDirectoryHash | Out-File $path\.hasha256
    #$newhash=$(Get-StringHash -string $directoryHash | Out-String).replace("`n","").replace("`r","")
    #
    #1.3997% increase if moved out and using mercle for determing changes
    if([string]$previousDirectoryHash -notlike [string]$newDirectoryHash){
        $path >> $PSScriptRoot\fileschanged.txt
    }
}
#>

$ElapsedTime = ($(get-date) - $StartTime).TotalSeconds
Write-Host "$ElapsedTime seconds"