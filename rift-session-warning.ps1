Add-Type -AssemblyName System.Windows.Forms

# Variablen definieren
$prozessName = "LeagueClient"  # Name des Prozesses, den du überwachen möchtest
$laufzeitLimit = New-TimeSpan -hours 4
$muteTime = New-TimeSpan -Minutes 10
$mutedUntil = $null

while ($true) {
    # Überprüfen, ob der Prozess läuft
    $prozess = Get-Process -Name $prozessName -ErrorAction SilentlyContinue

    if ($prozess) {
        # Überprüfen, wie lange der Prozess bereits läuft
        $laufzeit = (Get-Date) - $prozess.StartTime

        if ($laufzeit -ge $laufzeitLimit) {
            # Benachrichtigung anzeigen, falls nicht stummgeschaltet
            if ($null -eq $mutedUntil -or (Get-Date) -ge $mutedUntil) {
                # Fenster anzeigen
                $dialogResult = [System.Windows.Forms.MessageBox]::Show(
                    "League laeuft seit mehr als 4 Stunden! Mute die naechsten 10 Minuten?",
                    "Rift Session Warning",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo
                )

                if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $mutedUntil = (Get-Date).Add($muteTime)
                }
            }

            # Warten für 60 Sekunden, bevor die nächste Überprüfung stattfindet
            Start-Sleep -Seconds 60
        } else {
            # Wenn der Prozess noch nicht das Limit erreicht hat, wechsle zur nächsten Überprüfung
            Start-Sleep -Seconds 60
        }
    } else {
        # Wenn der Prozess nicht mehr läuft, Skript beenden
        Write-Host "Der Prozess '$prozessName' läuft nicht mehr."
    }
}