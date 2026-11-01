# Configuration du port COM
$portName = "COM3"
$baudRate = 9600
$refreshRate = 1 # Every 1 seconds

# Initialisation du chronomètre global
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Mémoire vive en temps réel pour les 3 slots (0, 1, 2)
$djiData = @{
    0 = @{ "soc" = "--"; "temp" = "--"; "vbat" = "--"; "ibat" = "--"; "status" = "Absent"; "refreshMs" = 0 }
    1 = @{ "soc" = "--"; "temp" = "--"; "vbat" = "--"; "ibat" = "--"; "status" = "Absent"; "refreshMs" = 0 }
    2 = @{ "soc" = "--"; "temp" = "--"; "vbat" = "--"; "ibat" = "--"; "status" = "Absent"; "refreshMs" = 0 }
}


# Fonction d'affichage (appelée toutes les 5 secondes ou sur alerte immédiate)
function Draw-Interface {
    $currentMs = $sw.ElapsedMilliseconds
    
    # --- PHASE DE NETTOYAGE DYNAMIQUE AVANT AFFICHAGE ---

    for ($i = 0; $i -le 2; $i++) {
        if ($djiData[$i].status -ne "Absent") {
            $ageMs = $currentMs - $djiData[$i].refreshMs
            
            # Si le signal a plus de 5 secondes (5000 ms), on purge le slot
            if ($ageMs -gt 5000) {
                $djiData[$i].status    = "Absent"
                $djiData[$i].soc       = "--"
                $djiData[$i].vbat      = "--"
                $djiData[$i].temp      = "--"
                $djiData[$i].ibat      = "--"
                $djiData[$i].refreshMs = 0
            }
        }
    }


    # Calcul final des chaînes d'affichage pour la ligne "Signal"
    $age2 = if ($djiData[2].status -eq "Absent") { "--" } else { ($currentMs - $djiData[2].refreshMs).ToString() + " ms" }
    $age1 = if ($djiData[1].status -eq "Absent") { "--" } else { ($currentMs - $djiData[1].refreshMs).ToString() + " ms" }
    $age0 = if ($djiData[0].status -eq "Absent") { "--" } else { ($currentMs - $djiData[0].refreshMs).ToString() + " ms" }

    # --- RENDU DE L'INTERFACE ASCII ---
    Clear-Host
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "                     MONITEUR DOCK DJI NEO               " -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "  [ SLOT 2 ]              [ SLOT 1 ]              [ SLOT 0 ]" -ForegroundColor Yellow
    Write-Host "---------------------------------------------------------"
    
    Write-Host ("  Statut : {0,-12}   Statut : {1,-12}   Statut : {2,-12}" -f $djiData[2].status, $djiData[1].status, $djiData[0].status)
    Write-Host ("  Charge : {0,-12}   Charge : {1,-12}   Charge : {2,-12}" -f ($djiData[2].soc + " %"), ($djiData[1].soc + " %"), ($djiData[0].soc + " %"))
    Write-Host ("  Volts  : {0,-12}   Volts  : {1,-12}   Volts  : {2,-12}" -f ($djiData[2].vbat + " V"), ($djiData[1].vbat + " V"), ($djiData[0].vbat + " V"))
    Write-Host ("  Temp   : {0,-12}   Temp   : {1,-12}   Temp   : {2,-12}" -f ($djiData[2].temp + " °C"), ($djiData[1].temp + " °C"), ($djiData[0].temp + " °C"))
    Write-Host ("  Courant: {0,-12}   Courant: {1,-12}   Courant: {2,-12}" -f ($djiData[2].ibat + " mA"), ($djiData[1].ibat + " mA"), ($djiData[0].ibat + " mA"))
    
    Write-Host "---------------------------------------------------------"
    Write-Host ("  Signal: {0,-12}    Signal: {1,-12}    Signal: {2,-12}" -f $age2, $age1, $age0) -ForegroundColor Gray
    
    Write-Host "---------------------------------------------------------"
    if (($djiData[2].soc -ge 58) -or ($djiData[1].soc -ge 58) -or ($djiData[0].soc -ge 58) ) {
        Write-Host "  ⚠️ SEUIL DE 58% ATTEINT ! Débranchez le chargeur. ⚠️" -ForegroundColor Red
        Write-Host "---------------------------------------------------------"
        [Console]::Beep(1000, 300); Start-Sleep -Milliseconds 500;[Console]::Beep(1000, 300); Start-Sleep -Milliseconds 500;[Console]::Beep(1000, 300)
    }
    Write-Host " Appuyez sur [Ctrl+C] pour quitter le script." -ForegroundColor DarkGray
}

# Ouverture du port COM
try {
    $port = New-Object System.IO.Ports.SerialPort($portName, $baudRate, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
    $port.ReadTimeout = 10 
    $port.Open()
    $port.DiscardInBuffer() 
    Write-Host "Connexion Live sur $portName active..." -ForegroundColor Green
    #Start-Sleep -Seconds 1
}
catch {
    Write-Error "Erreur d'ouverture du port $portName."
    exit
}

$lastDisplayTime = [DateTime]::MinValue

try {
    while ($port.IsOpen) {
        # 1. LECTURE EN CONTINU 
        while ($port.BytesToRead -gt 0) {
            try {
                $line = $port.ReadLine().Trim()
                
                if ($line -match "bat:(\d+),soc:(\d+),vbat:(\d+),ibat:(-?\d+),temp:(\d+)") {
                    $idx  = [int]$Matches[1]
                    $soc  = [int]$Matches[2]
                    $vbat = [math]::Round(([int]$Matches[3] / 1000), 2).ToString("F2")
                    $ibat = $Matches[4]
                    $temp = [math]::Round(([int]$Matches[5] / 10), 1).ToString("F1")

                    $status = "Présente"
                    if ([int]$ibat -gt 20) { $status = "En charge" }
                    elseif ([int]$ibat -lt -20) { $status = "Décharge" }

                    if ($djiData.ContainsKey($idx)) {
                        $djiData[$idx].soc       = $soc.ToString()
                        $djiData[$idx].vbat      = $vbat
                        $djiData[$idx].ibat      = $ibat
                        $djiData[$idx].temp      = $temp
                        $djiData[$idx].status    = $status
                        $djiData[$idx].refreshMs = $sw.ElapsedMilliseconds
                    }


                }
            }
            catch {
                # Ignore les lignes partielles
            }
        }

        # 2. HORLOGE D'AFFICHAGE CADENCÉE (Toutes les 5 secondes)
        if (([DateTime]::Now - $lastDisplayTime).TotalSeconds -ge $refreshRate) {
            Draw-Interface
            $lastDisplayTime = [DateTime]::Now
        }

        Start-Sleep -Milliseconds 10
    }
}
finally {
    if ($port -and $port.IsOpen) {
        $port.Close()
        Write-Host "`nPort COM fermé." -ForegroundColor Yellow
    }
    $sw.Stop()
}
