$AllFiles = @()
$Results = @()
$AllFiles = Get-ChildItem -Path . *.json -Recurse

foreach ($Item in $AllFiles) {
    $Results += Get-Content $Item.FullName -Raw | ConvertFrom-Json
}

$resultplus = $Results | select *,@{Name='Date';Expression={(get-date -Year ($_.Title).SubString(0,4) -Month ($_.Title).SubString(5,2) -Day 1)}} | select *,@{Name='Build';Expression={([version]$_.OSBuild).Build}}  | select *,@{Name='Revision';Expression={([version]$_.OSBuild).Revision}}

$resultplus | Sort-Object Revision | ogv

$Results  | Sort-Object OSBuild -Unique | Export-Csv -NoClobber -NoTypeInformation .\result-osbuild.csv


where-object {$_.OSBuild -ne $null -and $_.OSBuild -notlike "*not*"}
|Sort-Object KBFULL -Unique 

[version]"2.0.50727.5446"

($_.Title).SubString(0,4)
($_.Title).SubString(5,2)

(get-date -Year ($_.Title).SubString(0,4) -Month ($_.Title).SubString(5,2) -Day 1)
Get-Date -Month 