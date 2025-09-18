$ShiftCodes = @()

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
                $Expiration = get-date(((($line -split "</strong>")[1] -split "<code>")[0] -replace "expires: ") -replace "sept","september") -ErrorAction Stop -format MM/dd/yyyy
            } catch {
                $Expiration = ''
            }
            
            $code = ((($line -split "<code>")[1]) -split "</code>")[0]

            If($ShiftCodes.shiftcode -notcontains $code){
                $ShiftCodes += @(
                    [PSCustomObject]@{
                        SHiFTCode = $code
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
                        SHiFTCode = $response[$i]
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
    $shiftcodelines = (((($response -match '<figure class="wp-block-table"><table><thead><tr><th>SHiFT Code') -split '</tr>') -match '<tr><td><strong>') -split '</thead><tbody>') -match '.*([A-Z0-9]+-){3}[A-Z0-9]+.*'

    ForEach($shiftcodeline in $shiftcodelines){

        If($shiftcodeline -ne ""){

            $Expiration = (((((($ShiftCodeLine -split "</strong>")[1]) -split "</td><td>")[3] -replace "</td>") -replace "sept","september") -split '(st|nd|rd|th)')[0]
            If($Expiration -ne ''){
                $Expiration = Get-Date($Expiration) -Format MM/dd/yyyy
            }

            $code = ($ShiftCodeLine -split "</strong>")[0] -replace "<tr><td><strong>"

            If($ShiftCodes.shiftcode -notcontains $code){
                $ShiftCodes += @(
                    [PSCustomObject]@{
                        SHiFTCode = $code
                        Reward =  (((($ShiftCodeLine -split "</strong>")[1]) -split "</td><td>")[1]) -replace "<br>", " "
                        Expiration = $Expiration
                        Source = "thegamepost.com"
                    }
                )
            }
        }
    }
}

$ShiftCodes | Where-Object {$_.expiration -gt (get-date) -or $_.expiration -eq ''} | sort-object shiftcode -Unique | sort-object expiration | Export-Csv -Path "Borderlands4 SHiFT Codes.csv" -NoTypeInformation -Force

& git add -A
& git commit -m "SHiFT code update $(get-date -format MM/dd/yyyy)"
& git push