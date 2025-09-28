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

if (Test-Path 'Borderlands4 SHiFT Codes.csv'){
    $CSVImport = Import-Csv 'Borderlands4 SHiFT Codes.csv'
} else {
    $CSVImport = $null
}

#mentalmars
Try{
    $response = Invoke-RestMethod -Uri 'https://mentalmars.com/game-news/borderlands-4-shift-codes/' -ErrorAction Stop
}Catch{
    $response = $null
}

If($null -ne $response){
    $shiftcodelines = ((($response -split "`n") -like "*reward*expire date*") -split "<strong>") -replace '</td><td class="has-text-align-left" data-align="left">'
    $i = 0
    ForEach($line in $shiftcodelines){    
        If($line -like "*golden key*"){
            If($line -like "*<br>*"){
                $line = $shiftcodelines[$i] + $shiftcodelines[$i+1]            
            }
            
            Try{
                $Expiration = get-date(((($line -split "</strong>")[1] -split "<code>")[0] -replace "expires: ") -replace "jan","january" -replace "feb","february" -replace "mar","march" -replace "apr","april" -replace "jun","june" -replace "jul","july" -replace "aug","august" -replace "sept","september" -replace "oct","october" -replace "nov","november" -replace "dec","december") -ErrorAction Stop -format MM/dd/yyyy
            } catch {
                $Expiration = ''
            }
            
            $code = ((($line -split "<code>")[1]) -split "</code>")[0]

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
        If($line -match '([A-Z0-9]+-){3}[A-Z0-9]+$'){
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
    $shiftcodelines = ((((($response -match '<figure class="wp-block-table"><table><thead><tr><th>SHiFT Code') -split '</tr>') -match '<tr><td><strong>') -split '</thead><tbody>') -match '.*([A-Z0-9]+-){3}[A-Z0-9]+.*') -replace "<strong><strong>","<strong>" -replace '&nbsp;' -replace "`n" -replace "`r"

    ForEach($shiftcodeline in $shiftcodelines){

        If($shiftcodeline -ne ""){
            $Expiration = (((((($ShiftCodeLine -split "</strong>")[-1]) -split "</td><td>")[3] -replace "</td>") -replace "sept","september") -split '(st|nd|rd|th)')[0]
            If($Expiration -ne ''){
                $Expiration = Get-Date($Expiration) -Format MM/dd/yyyy
            }

            $code = ($ShiftCodeLine -split "</strong>")[0] -replace "<tr><td><strong>"

            If($ShiftCodes.shiftcode -notcontains $code){
                $ShiftCodes += @(
                    [PSCustomObject]@{
                        Added = Get-Date -Format MM/dd/yyyy
                        SHiFTCode = $code.trim()
                        Reward =  (((($ShiftCodeLine -split "</strong>")[-1]) -split "</td><td>")[1]) -replace "<br>", " "
                        Expiration = $Expiration
                        Source = "thegamepost.com"
                    }
                )
            }
        }
    }
}

$Output = $ShiftCodes | Where-Object {$_.expiration -gt ((get-date).adddays(-1)) -or $_.expiration -eq ''} | sort-object shiftcode -Unique | sort-object Added, Expiration

# Comapres the results it scraped from the web to what's already in the CSV
ForEach($code in $output){
    if ($CSVImport.shiftcode -notcontains $code.shiftcode){
        $validCodes += $code
        $NewCodes += $code
    } else {
        $validCodes += $CSVImport | Where-Object shiftcode -eq $code.SHiFTCode
    }
}

$ValidCodes = $ValidCodes |  Where-Object {$_.expiration -gt ((get-date).adddays(-1)) -or $_.expiration -eq ''} | Sort-Object added, expiration -Descending

if ($ExportCSV){
    If($null -ne $ValidCodes){
        if (-not($ValidCodes -ceq $CSVImport)){
            $ValidCodes | Export-Csv -Path "Borderlands4 SHiFT Codes.csv" -NoTypeInformation -Force

            if ($null -ne $DiscordWebhook){
                Start-Transcript -Path "..\transcript.txt"
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
                Stop-Transcript
            }

            if ($git){
                & git add "Borderlands4 SHiFT Codes.csv"
                & git commit -m "SHiFT code update $(get-date -format MM/dd/yyyy)"
                & git push
            }
        }
    }
} else {
    $ValidCodes | Sort-Object Added, Expiration -Descending | Format-Table -AutoSize
}