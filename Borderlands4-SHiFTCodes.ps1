$ShiftCodes = @()
$response = (Invoke-RestMethod -uri 'https://thegamepost.com/borderlands-4-all-shift-codes/') -split "`n"
$shiftcodelines = ((($response -match '<figure class="wp-block-table"><table><thead><tr><th>SHiFT Code') -split '</tr>') -match '<tr><td><strong>') -split '</thead><tbody>'

ForEach($shiftcodeline in $shiftcodelines){

    If($shiftcodeline -ne ""){

        $Expiration = (((((($ShiftCodeLine -split "</strong>")[1]) -split "</td><td>")[3] -replace "</td>") -replace "sept","september") -split '(st|nd|rd|th)')[0]
        If($Expiration -ne ''){
            $Expiration = Get-Date($Expiration) -Format MM/dd/yyyy
        }

        $ShiftCodes += @(
            [PSCustomObject]@{
                SHiFTCode = ($ShiftCodeLine -split "</strong>")[0] -replace "<tr><td><strong>"
                Reward =  ((($ShiftCodeLine -split "</strong>")[1]) -split "</td><td>")[1]
                Expiration = $Expiration
            }
        )
    }
}

$ShiftCodes | Where-Object {$_.expiration -gt (get-date) -or $_.expiration -eq ''} | sort-object expiration | Format-Table -AutoSize