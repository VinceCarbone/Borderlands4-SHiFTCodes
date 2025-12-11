Param(

    [Parameter(Mandatory=$false)]
    [Switch]
    $ExportCSV,

    [Parameter(Mandatory=$false)]
    [string]
    $DiscordWebhook,

    [Parameter(Mandatory=$false)]
    [Switch]
    $git
)

$ShiftCodes = @()
$ValidCodes = @()
$NewCodes = @()
$DiscordMessage = $null
$pattern = '\b[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}\b'

if (Test-Path "$PSScriptRoot\Borderlands4 SHiFT Codes.csv"){
    $CSVImport = Import-Csv -path "$PSScriptRoot\Borderlands4 SHiFT Codes.csv"
} else {
    $CSVImport = $null
}

# expired codes
if (Test-Path "$PSScriptRoot\ExpiredSHiFTCodes.csv"){
    $ExpiredCodes = Import-Csv "$PSScriptRoot\ExpiredSHiFTCodes.csv"
} else {
    $ExpiredCodes = $null
}

#mentalmars
Try{
    $response = Invoke-RestMethod -Uri 'https://mentalmars.com/game-news/borderlands-4-shift-codes/' -ErrorAction Stop
}Catch{
    $response = $null
}

If($null -ne $response){
    $shiftcodelines = (((($response -split "`n") -like "*reward*expire date*") -split "<strong>") -replace '</td><td class="has-text-align-left" data-align="left">') -match $pattern
    $i = 0
    ForEach($line in $shiftcodelines){        
        If($line -match $pattern){
            
            Try{               
                $Expiration = get-date(($line -replace '</tr><tr><td class="has-text-align-left" data-align="left">','' -replace "jan","january" -replace "feb","february" -replace "mar","march" -replace "apr","april" -replace "jun","june" -replace "jul","july" -replace "aug","august" -replace "sept","september" -replace "oct","october" -replace "nov","november" -replace "dec","december" -split "</strong>" -split "<code>" -split "</code>" -split "</td>")[3] -replace "<s>" -replace "</s>") -format MM/dd/yyyy
            } catch {
                $Expiration = ''
            }
            
            $code = ((($line -split "<code>")[1]) -split "</code>")[0]
            if ($code -notlike "<s>*"){
                If($ShiftCodes.shiftcode -notcontains $code){
                    $ShiftCodes += @(
                        [PSCustomObject]@{
                            Added = Get-Date -Format MM/dd/yyyy
                            SHiFTCode = $code.trim()
                            Reward = ($line -split "</strong>")[0]
                            Expiration = $Expiration
                            Source = "mentalmars.com"
                        }
                    )
                }
            }
        }
        $i++
    }
}

#gamingnews
Try{
    $response = ((((((invoke-RestMethod -uri 'https://gaming.news/codex/borderlands-4-shift-codes-list-guide-and-troubleshooting/' -ErrorAction Stop) -split "<h2")[2]) -split "`n") -like "*<p>*") -replace '(<p>|</p>|</div>)','').trim()
}Catch{
    $response = $null
}

If($null -ne $response){
    $i = 0
    ForEach($line in $response){    
        If($line -match $pattern){
            $Expiration = $response[$i+2]

            If($Expiration -ne 'No information'){
                $Expiration = get-date($Expiration) -format MM/dd/yyyy
            }Else{
                $Expiration = ''
            }

            If($ShiftCodes.shiftcode -notcontains $response[$i]){
                $ShiftCodes += @(
                    [PSCustomObject]@{
                        Added = Get-Date -Format MM/dd/yyyy
                        SHiFTCode = ($response[$i]).trim()
                        Reward = $response[$i+1] -replace ":"
                        Expiration = $Expiration
                        Source = "gaming.news"
                    }
                )
                }
        }
        $i++
    }
}

# thegamepost
Try{
    $response = (Invoke-RestMethod -uri 'https://thegamepost.com/borderlands-4-all-shift-codes/' -ErrorAction Stop) -split "`n"
}Catch{
    $response = $null
}

If($null -ne $response){
    $shiftcodelines = ((((($response -match '<figure class="wp-block-table"><table><thead><tr><th>SHiFT Code')[0] -split '</tr>') -match '<tr><td><strong>') -split '</thead><tbody>') -match '.*([A-Z0-9]+-){3}[A-Z0-9]+.*') -replace "<strong><strong>","<strong>" -replace '&nbsp;' -replace "`n" -replace "`r"

    ForEach($shiftcodeline in $shiftcodelines){

        If($shiftcodeline -ne ""){
            $Expiration = ((((((($ShiftCodeLine -split "</strong>")[-1]) -split "</td><td>")[-1] -replace "</td>") -replace "jan","january" -replace "feb","february" -replace "mar","march" -replace "apr","april" -replace "jun","june" -replace "jul","july" -replace "aug","august" -replace "sept","september" -replace "oct","october" -replace "nov","november" -replace "dec","december") -split '(st|nd|rd|th)')[0]).replace('.','')
            if(((((((($ShiftCodeLine -split "</strong>")[-1]) -split "</td><td>")[-1] -replace "</td>") -replace "jan","january" -replace "feb","february" -replace "mar","march" -replace "apr","april" -replace "jun","june" -replace "jul","july" -replace "aug","august" -replace "sept","september" -replace "oct","october" -replace "nov","november" -replace "dec","december") -split '(st|nd|rd|th)')[-1]).replace('.','') -match ', 20[0-9][0-9]'){
                $Expiration = $expiration + ((((((($ShiftCodeLine -split "</strong>")[-1]) -split "</td><td>")[-1] -replace "</td>") -replace "jan","january" -replace "feb","february" -replace "mar","march" -replace "apr","april" -replace "jun","june" -replace "jul","july" -replace "aug","august" -replace "sept","september" -replace "oct","october" -replace "nov","november" -replace "dec","december") -split '(st|nd|rd|th)')[-1]).replace('.','') -replace ","
            }
            If($Expiration -ne ''){
                $Expiration = Get-Date($Expiration) -Format MM/dd/yyyy
            }

            $code = ($ShiftCodeLine -split "</strong>")[0] -replace "<tr><td><strong>"

            If($ShiftCodes.shiftcode -notcontains $code.trim()){
                $ShiftCodes += @(
                    [PSCustomObject]@{
                        Added = Get-Date -Format MM/dd/yyyy
                        SHiFTCode = $code.trim()
                        Reward =  (((($ShiftCodeLine -split "</strong>")[-1]) -split "</td><td>")[1]) -replace "<br>", " " -replace "&#8217;","'" -replace "&#8220;","'" -replace "&#8221;","'"
                        Expiration = $Expiration
                        Source = "thegamepost.com"
                    }
                )
            }
        }
    }
}

# This is here to prevent an issue where for whatever reason a code isn't on the website anymore but is still valid, so it adds the codes from the CSV to the current array if not present
ForEach($csvCode in $CSVImport){
    if($shiftcodes.shiftcode -notcontains $csvcode.shiftcode){        
        $shiftcodes += $csvcode
    }
}

$Output = $ShiftCodes | Where-Object {$_.expiration -gt ((get-date).adddays(-1)) -or $_.expiration -eq ''} | sort-object shiftcode -Unique | sort-object Added, Expiration

# finds expired codes, and adds newly expired ones to the expired csv file before re-importing it
$OutputExpired = $ShiftCodes | Where-Object {$_.expiration -ne '' -and $_.expiration -lt ((get-date).adddays(-1))} | sort-object shiftcode -Unique | sort-object Added, Expiration

if ($ExportCSV){
    ForEach($ExpiredCode in $OutputExpired){
        if ($ExpiredCodes.SHiFTCode -notcontains $ExpiredCode.SHiFTCode){
            $ExpiredCode | Export-Csv -Path "$PSScriptRoot\ExpiredSHiFTCodes.csv" -Append -NoTypeInformation -Force
        }
    }

    if (Test-Path "$PSScriptRoot\ExpiredSHiFTCodes.csv"){
        $ExpiredCodes = Import-Csv -Path "$PSScriptRoot\ExpiredSHiFTCodes.csv"
    } else {
        $ExpiredCodes = $null
    }
}

# Comapres the results it scraped from the web to what's already in the CSV files
ForEach($code in $output){
    if ($ExpiredCodes.SHiFTCode -notcontains $code.shiftcode){ # this prevents erroneously adding codes back that have already expired (as websites seem to have inconsistencies with dates)
        if ($CSVImport.shiftcode -notcontains $code.shiftcode){
            $validCodes += $code
            $NewCodes += $code
        } else {
            $validCodes += $CSVImport | Where-Object shiftcode -eq $code.SHiFTCode
        }
    }
}

#$ValidCodes = $ValidCodes |  Where-Object {$_.expiration -gt ((get-date).adddays(-2)) -or $_.expiration -eq ''} | Sort-Object added, expiration -Descending
$date = get-date -Format yyyyMMddhhmmss
$ValidCodes = $ValidCodes |  Sort-Object added, expiration -Descending

if ($ExportCSV){
    If($null -ne $ValidCodes){
        if (-not($ValidCodes -ceq $CSVImport)){
            $ValidCodes | Export-Csv -Path "$PSScriptRoot\Borderlands4 SHiFT Codes.csv" -NoTypeInformation -Force

            if ($null -ne $DiscordWebhook){
                if($newcodes){
                    Start-Transcript -Path "..\$date-transcript.txt"
                    if($newcodes.count -eq 1 ){
                        write-host "Sending $($newcodes.count) new codes to $DiscordWebhook"
                        ForEach($NewCode in $NewCodes){

$DiscordMessage = @"
$($NewCode.SHiFTCode)
"@            
                            $payload = [PSCustomObject]@{content = $DiscordMessage}                
                            Try{
                                Invoke-RestMethod -Uri "$DiscordWebhook" -Method Post -Body ($payload | ConvertTo-Json) -ContentType 'Application/Json' -ErrorAction Stop
                            } catch {
                                Write-Host "Failed to send to Discord webhook"
                            }
                        }
                    } else {
                        Write-Host "New code count is greater than 2, please review"
                        ForEach($newcode in $NewCodes){
                            Write-Host $newcode.shiftcode
                            Write-Host "Expired codes contains code: $($expiredcodes.shiftcode -contains $newcode.shiftcode)"
                            Write-Host "Valid codes contains code: $($csvimport.shiftcode -contains $newcode.shiftcode)"
                        }
                    }
                    Stop-Transcript
                }
            }

            if ($git){
                & git add "Borderlands4 SHiFT Codes.csv"
                & git add "ExpiredSHiFTCodes.csv"
                & git commit -m "SHiFT code update $(get-date -format MM/dd/yyyy)"
                & git push
            }
        }
    }
} else {
    $ValidCodes | Sort-Object Added, Expiration -Descending | Format-Table -AutoSize
}