# Configuration de l'environnement matériel graphique
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CRÉATION DE LA FENÊTRE PRINCIPALE ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "DJI Neo Dock Monitor - GUI Stable"
$form.Size = New-Object System.Drawing.Size(680, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(244, 246, 249)

# --- PANEL DE CONFIGURATION ---
$topPanel = New-Object System.Windows.Forms.Panel
$topPanel.Size = New-Object System.Drawing.Size(640, 60)
$topPanel.Location = New-Object System.Drawing.Point(12, 12)
$topPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($topPanel)

$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "Port COM :"
$lblPort.Location = New-Object System.Drawing.Point(15, 22)
$lblPort.AutoSize = $true
$lblPort.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$topPanel.Controls.Add($lblPort)

$comboPort = New-Object System.Windows.Forms.ComboBox
$comboPort.Location = New-Object System.Drawing.Point(90, 18)
$comboPort.Size = New-Object System.Drawing.Size(80, 25)
$comboPort.DropDownStyle = "DropDownList"
[System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { [void]$comboPort.Items.Add($_) }
if ($comboPort.Items.Count -gt 0) { $comboPort.SelectedIndex = 0 }
$topPanel.Controls.Add($comboPort)

$lblRef = New-Object System.Windows.Forms.Label
$lblRef.Text = "Rafraîchissement :"
$lblRef.Location = New-Object System.Drawing.Point(190, 22)
$lblRef.AutoSize = $true
$lblRef.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$topPanel.Controls.Add($lblRef)

$comboRefresh = New-Object System.Windows.Forms.ComboBox
$comboRefresh.Location = New-Object System.Drawing.Point(310, 18)
$comboRefresh.Size = New-Object System.Drawing.Size(70, 25)
$comboRefresh.DropDownStyle = "DropDownList"
@("1 s", "2 s", "5 s", "10 s") | ForEach-Object { [void]$comboRefresh.Items.Add($_) }
$comboRefresh.SelectedIndex = 2
$topPanel.Controls.Add($comboRefresh)

$btnAction = New-Object System.Windows.Forms.Button
$btnAction.Text = "Démarrer l'écoute"
$btnAction.Location = New-Object System.Drawing.Point(420, 15)
$btnAction.Size = New-Object System.Drawing.Size(140, 30)
$btnAction.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$btnAction.ForeColor = [System.Drawing.Color]::White
$btnAction.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnAction.FlatStyle = "Flat"
$topPanel.Controls.Add($btnAction)

# --- PANEL CENTRAL POUR LES BATTERIES ---
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Size = New-Object System.Drawing.Size(640, 360)
$mainPanel.Location = New-Object System.Drawing.Point(12, 85)
$form.Controls.Add($mainPanel)

$slots = @{}

function Creer-SlotUI ([int]$id, [int]$posX, [string]$titre) {
    $p = New-Object System.Windows.Forms.Panel
    $p.Size = New-Object System.Drawing.Size(200, 320)
    $p.Location = New-Object System.Drawing.Point($posX, 0)
    $p.BackColor = [System.Drawing.Color]::White
    $mainPanel.Controls.Add($p)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $titre
    $lbl.Location = New-Object System.Drawing.Point(0, 10)
    $lbl.Size = New-Object System.Drawing.Size(200, 25)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::DimGray
    $p.Controls.Add($lbl)

    $prog = New-Object System.Windows.Forms.ProgressBar
    $prog.Size = New-Object System.Drawing.Size(160, 20)
    $prog.Location = New-Object System.Drawing.Point(20, 45)
    $p.Controls.Add($prog)

    $txtPct = New-Object System.Windows.Forms.Label
    $txtPct.Text = "--"
    $txtPct.Location = New-Object System.Drawing.Point(0, 75)
    $txtPct.Size = New-Object System.Drawing.Size(200, 30)
    $txtPct.TextAlign = "MiddleCenter"
    $txtPct.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $p.Controls.Add($txtPct)

    $stat = New-Object System.Windows.Forms.Label -Property @{ Text = "Statut: Absent"; Location = New-Object System.Drawing.Point(15, 120); AutoSize = $true; Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) }
    $volt = New-Object System.Windows.Forms.Label -Property @{ Text = "Tension: -- V"; Location = New-Object System.Drawing.Point(15, 150); AutoSize = $true }
    $temp = New-Object System.Windows.Forms.Label -Property @{ Text = "Temp: -- °C"; Location = New-Object System.Drawing.Point(15, 180); AutoSize = $true }
    $curr = New-Object System.Windows.Forms.Label -Property @{ Text = "Courant: -- mA"; Location = New-Object System.Drawing.Point(15, 210); AutoSize = $true }
    $sign = New-Object System.Windows.Forms.Label -Property @{ Text = "Signal: --"; Location = New-Object System.Drawing.Point(15, 240); AutoSize = $true; ForeColor = [System.Drawing.Color]::Gray }

    $p.Controls.Add($stat); $p.Controls.Add($volt); $p.Controls.Add($temp); $p.Controls.Add($curr); $p.Controls.Add($sign)

    $slots[$id] = @{ Prog = $prog; TxtPct = $txtPct; TxtStat = $stat; TxtVolt = $volt; TxtTemp = $temp; TxtCur = $curr; TxtSign = $sign; LastSeen = 0 }
}

# Alignement physique inversé : Slot 2 à gauche, Slot 0 à droite
Creer-SlotUI -id 2 -posX 10   -titre "SLOT 2"
Creer-SlotUI -id 1 -posX 220  -titre "SLOT 1"
Creer-SlotUI -id 0 -posX 430  -titre "SLOT 0"

# --- MOTEUR DE TRAITEMENT ---
$script:portSerial = $null
$script:isListening = $false
$sw = [System.Diagnostics.Stopwatch]::StartNew()

function Reset-SlotVisuals ([int]$i) {
    $slots[$i].Prog.Value = 0
    $slots[$i].TxtPct.Text = "--"
    $slots[$i].TxtStat.Text = "Statut: Absent"
    $slots[$i].TxtVolt.Text = "Tension: -- V"
    $slots[$i].TxtTemp.Text = "Temp: -- °C"
    $slots[$i].TxtCur.Text = "Courant: -- mA"
    $slots[$i].TxtSign.Text = "Signal: --"
}

# Timer asynchrone synchrone avec l'UI
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 40

$timer.Add_Tick({
    if ($script:isListening -and $script:portSerial -and $script:portSerial.IsOpen) {
        while ($script:portSerial.BytesToRead -gt 0) {
            try {
                $line = $script:portSerial.ReadLine().Trim()
                if ($line -match "bat:(\d+),soc:(\d+),vbat:(\d+),ibat:(-?\d+),temp:(\d+)") {
                    $idx  = [int]$Matches[1]
                    $soc  = [int]$Matches[2]
                    $vbat = [math]::Round(([int]$Matches[3] / 1000), 2).ToString("F2")
                    $ibat = $Matches[4]
                    $temp = [math]::Round(([int]$Matches[5] / 10), 1).ToString("F1")

                    $status = "Présente"
                    if ([int]$ibat -gt 20) { 
                        $status = "En charge" 
                        if ($soc -ge 58) { [Console]::Beep(1000, 200) }
                    }
                    elseif ([int]$ibat -lt -20) { $status = "Décharge" }

                    $slots[$idx].LastSeen = $sw.ElapsedMilliseconds
                    $slots[$idx].Prog.Value = $soc
                    $slots[$idx].TxtPct.Text = "$soc%"
                    $slots[$idx].TxtStat.Text = "Statut: $status"
                    $slots[$idx].TxtVolt.Text = "Tension: $vbat V"
                    $slots[$idx].TxtTemp.Text = "Temp: $temp °C"
                    $slots[$idx].TxtCur.Text = "Courant: $ibat mA"
                    $slots[$idx].TxtSign.Text = "Signal: 0 ms"
                }
            } catch {}
        }
        
        # Nettoyage Heartbeat
        $currentMs = $sw.ElapsedMilliseconds
        for ($i = 0; $i -le 2; $i++) {
            if ($slots[$i].LastSeen -gt 0) {
                $age = $currentMs - $slots[$i].LastSeen
                if ($age -gt 5000) {
                    Reset-SlotVisuals($i)
                    $slots[$i].LastSeen = 0
                } else {
                    $slots[$i].TxtSign.Text = "Signal: $age ms"
                }
            }
        }
    }
})

# Évènement du bouton d'action
$btnAction.Add_Click({
    if (-not $script:isListening) {
        if ([string]::IsNullOrEmpty($comboPort.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Aucun port COM disponible ou sélectionné.", "Erreur")
            return
        }
        try {
            $script:portSerial = New-Object System.IO.Ports.SerialPort($comboPort.Text, 9600, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
            $script:portSerial.ReadTimeout = 10
            $script:portSerial.Open()
            $script:portSerial.DiscardInBuffer()

            $script:isListening = $true
            $btnAction.Text = "Arrêter"
            $btnAction.BackColor = [System.Drawing.Color]::Firebrick
            $timer.Start()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Impossible d'accéder au port $($comboPort.Text).", "Erreur")
        }
    }
    else {
        $script:isListening = $false
        $timer.Stop()
        if ($script:portSerial) { $script:portSerial.Close(); $script:portSerial.Dispose() }
        for ($i = 0; $i -le 2; $i++) { Reset-SlotVisuals($i) }
        $btnAction.Text = "Démarrer l'écoute"
        $btnAction.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    }
})

$form.Add_Closing({
    $script:isListening = $false
    $timer.Stop()
    if ($script:portSerial) { $script:portSerial.Close(); $script:portSerial.Dispose() }
    $sw.Stop()
})

[void]$form.ShowDialog()
