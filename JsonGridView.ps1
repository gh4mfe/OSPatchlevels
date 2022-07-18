$AllFiles = @()
$Results = @()
$AllFiles = Get-ChildItem -Path . *.json -Recurse

foreach ($Item in $AllFiles) {
    $Results += Get-Content $Item.FullName -Raw | ConvertFrom-Json
}

$Results | where-object {$_.OSBuild -ne $null -and $_.OSBuild -notlike "*not*"} |Sort-Object KBFULL -Unique | ogv