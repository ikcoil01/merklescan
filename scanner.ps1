function Get-StringHash([String] $string,$hashName = "SHA256")
{
$StringBuilder = New-Object System.Text.StringBuilder
[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
[Void]$StringBuilder.Append($_.ToString("x2"))
}
$StringBuilder.ToString()
}

function Get-HashOfDirectory ([String] $path) {
    foreach($path in $(Get-ChildItem -Exclude *.hasha256).FullName){
        if((Get-Item $path) -is [System.IO.DirectoryInfo]){
            Get-StringHash -String $path
        }else {
            $(Get-FileHash -Algorithm SHA256 $path).Hash    
        }
    }  
}

$startingDirectory="C:\"

foreach($path in $(Get-ChildItem -Path $startingDirectory -Recurse -Directory).FullName | Get-Unique){
    $directoryHashExist=$false
    $previoushash=$null
    if(Test-Path $path\.hasha256){
        $directoryHashExist=$true
        $previoushash=$(Get-Content -Path $path\.hasha256)
    }
    $directoryHash=$(Get-HashOfDirectory -path $path | Out-String)
    $directoryHash=$directoryHash.replace("`n","").replace("`r","")
    $newhash=$(Get-StringHash -string $directoryHash | Out-String).replace("`n","").replace("`r","")
    $newhash | Out-File $path\.hasha256
    if([string]$previoushash -notlike [string]$newhash){
        write-host File has changed
    }
}