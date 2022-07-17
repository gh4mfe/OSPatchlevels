$projectdir = "E:\Ordnung\Marco\Git\OSPatchlevels\"
$Projectdir = $psscriptroot
pushd $projectdir
Import-Module "E:\Ordnung\Marco\Git\x_repos\Join\Join.psm1" -force

function get-MonthlyUpdateKB {
    param (
       [string]$OS,
       [string]$Year,
       [string]$Month      
    )
    $OSpatches = @()
    $OSpatches = Get-MSCatalogUpdate -Search "$Year-$Month $OS" | Where-Object {$_.Products -like "*$OS*" -or $_.Products -like "*Windows Server*" -or $_.Products -like "*Microsoft Server*"} | Where-Object {$_.Title -like "*Monthly*" -or $_.Title -like "*Cumulative*"} | Where-Object {$_.Title -notlike "*.NET*" -and $_.title -notlike "*Preview*"  -and $_.title -notlike "*Internet*"} 
     
    if ($null -ne $OSpatches) {
        $return = @()
        foreach ($patch in $OSpatches) {
            $foundkb = $false
            $matches = ([regex]'\((.*?)\)').Matches($patch.title);
            $foundkb = $Matches | Select-Object -Last 1
            if ($foundkb -ne $false) {
                #$matches[1]
                $match = $foundkb.Value[-8..-2] -Join ''
                }
            else {
                $match = $false
            }
            $return += [PSCustomObject]@{
                Title = $patch.Title
                Products = $patch.Products
                KBFull = $foundkb.Value
                KBShort = $match
            }
        }
    }
    else {
       continue
    }
    return $($return | Sort-Object KBFull -Unique)
 }
 
  
 function get-OSBuildbyKB {
    param (
       $KB,
       [bool]$Deletefile=$false
    )
    if ($null -eq $KB){return $null}
    write-host $KB
    if (-not(test-path .\$KB.csv)){
        #Find csv
        $url = (Invoke-WebRequest https://support.microsoft.com/help/$KB).links| Where-Object {$_.href -like "*$KB.csv"} | select href 
        
        #Download + Save
        $url | ForEach-Object { Invoke-WebRequest $_.href -OutFile $($(Split-Path $_ -Leaf)).Replace('}','') } 
    }
    $OSBuild = get-content .\$KB.csv | select -skip 1 | ConvertFrom-csv -Delimiter ',' | Where-Object {$_.'File name' -like "ntos*.exe" } | select -first 1
    
    #Delete File
    if ($Deletefile) {
       Remove-Item .\$KB.csv
    }
    $return = [PSCustomObject]@{
       OSBuild = $OSBuild.'File version'
       KB = $KB
    }
    return $return
 }

 #https://www.gaijin.at/de/infos/windows-versionsnummern
 $OS = "Server 2019"#"Server 2016","Server 2008 R2"
 $month = "01"
 #$versions = ("Server 2012","Server 2012 R2")
 #$versions = ("Version 2004","Version 20H2",)
 $versions =  ("Version 21H2")
 $Years = ("2020","2021","2022")
 
 
foreach ($OS in $versions) {
    foreach ($Year in $Years) {
        if ($OS -like "*21H2*" -and $Year -eq "2020" ) {continue}
        $allkbs = @()
        for ($i=1; $i -le 9; $i++) {
            $allkbs += get-MonthlyUpdateKB -OS $OS -Year $Year -Month $("0"+$i)
        }
        for ($i=10; $i -le 12; $i++) {
            $allkbs += get-MonthlyUpdateKB -OS $OS -Year $Year -Month $($i)
        }
        $allBuilds  = @()
        foreach ($KB in $allkbs) {
                write-host $Kb.KBFull
            $allbuilds += get-OSBuildbyKB -KB $($kb.KBShort)
        }
        
        
        $buildsandkb = @()
        $buildsandkb =  Join-Object -LeftObject $allkbs -RightObject $allBuilds -On KBShort -Equals KB



        $buildsandkb | ConvertTo-Json | out-file .\$($(($OS).Replace(" ","_"))+"_"+$Year+".json")
    }
}   