<#
.SYNOPSIS
This script monitors the recent ranked games of a League of Legends player and suggests taking a break if the player has lost a certain number of games within a specified timeframe.

.DESCRIPTION
The bot interfaces with the Riot Games API to fetch a player's match history and determine if they are on a losing streak. 
If the conditions are met (i.e., a specified number of games lost within a specified timeframe), the script will prompt the user to take a break 
and automatically close the League of Legends client.

.PARAMETER apiKey
The personal API key for accessing the Riot Games API.

.PARAMETER playerName
The username of the League of Legends player whose statistics are being monitored.

.PARAMETER gameTag
The region or tag associated with the player's account.

.PARAMETER hoursToCheck
The duration in hours to look back for games. For example, if set to 2, it will check if the player has lost games in the last 2 hours.

.PARAMETER gamesToCheck
The number of recent games you want to evaluate to determine a losing streak. It is best to set this to 2 or 3.

.PARAMETER rankedOnly
A boolean value to indicate whether only ranked games should be checked. Valid values are $true or $false.

#>

# Get API Key
$textFilePath= Join-Path -Path $PSScriptRoot -ChildPath "Api_key.key"
$apiKey  = Get-Content -Path $textFilePath
Write-Host "Your API Key: $apiKey"

# Define user-configurable parameters
$playerName = 'Raz0reater' # The player's summoner name
$gameTag = "EUW" # The player's region or game tag (e.g., EUW, NA)
$hoursToCheck = 1 # Check for losses in the last 1 hours
$gamesToCheck = 2 # Number of games to evaluate for a losing streak
$rankedOnly = $true # Check only ranked games (true/false)



# Create LogFolder and logfile
New-Item -Path "$env:LOCALAPPDATA\RiftRestReminder" -ItemType Directory -ErrorAction SilentlyContinue
$logFile = "$env:LOCALAPPDATA\RiftRestReminder\log.txt"

function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}



function ShowMessage {
    param (
        [string]$message,
        [int]$duration = 3000  # Dauer in Millisekunden
    )

    # Erstellen Sie ein neues Form
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Information"
    $form.Size = New-Object System.Drawing.Size(300, 150)
    $form.StartPosition = "CenterScreen"

    # Fügen Sie ein Label hinzu
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10,10)
    $form.Controls.Add($label)

    # Zeigen Sie das Form an
    $form.Show()

    # Schließen Sie das Form nach der angegebenen Dauer
    Start-Sleep -Milliseconds $duration
    $form.Close()
}

ShowMessage -message "League Rest Reminder was succesfully started." -duration 3000

function Get-RecentGames {
    param (
        [string]$playerName,
        [string]$apiKey,
        [int]$hoursToCheck,
        [int]$gamesToCheck,
        [string]$gameTag,
        [bool]$rankedOnly
    )

    # Set URL parameters for ranked games if specified
    $rankedParam = if ($rankedOnly) { "type=ranked&" } else { "" }

    # Get the summoner ID (PUUID) of the player
    $puuidUrl = "https://europe.api.riotgames.com/riot/account/v1/accounts/by-riot-id/" + $playerName + "/" + $gameTag + "?api_key=" +$apiKey
    $summonerResponse = Invoke-RestMethod -Uri $puuidUrl -Method Get
    $mypuuid = $summonerResponse.puuid

    Write-Output "$(Get-TimeStamp) Puuid for player $playerName with tag $gameTag : $mypuuid" | Out-file $logFile -append
    Write-Output "$(Get-TimeStamp) Checking the last $hoursToCheck hours for $gamesToCheck games (Ranked Only: $rankedOnly)" | Out-file $logFile -append


    # Get the last match IDs
    $matchHistoryUrl = "https://europe.api.riotgames.com/lol/match/v5/matches/by-puuid/$mypuuid/ids?" + $rankedParam + "start=0&count=$gamesToCheck&api_key=$apiKey"
    $matchHistoryResponse = Invoke-RestMethod -Uri $matchHistoryUrl -Method Get

    $lostGames = @()
    $validGamesCount = 0

    foreach ($matchId in $matchHistoryResponse) {
        $matchUrl = "https://europe.api.riotgames.com/lol/match/v5/matches/" + $matchId + "?api_key=" + $apiKey
        $matchInfo = Invoke-RestMethod -Uri $matchUrl -Method Get

        if (CheckGameTimeValidity $matchInfo $hoursToCheck) {
            $validGamesCount++
            $lostGames += CheckGameOutcome $matchInfo $mypuuid
        } 
    }

    if ($lostGames.Count -eq $gamesToCheck -and $lostGames -notcontains $true) {
        Write-Output "$(Get-TimeStamp) All games were lost within the last $hoursToCheck hours." | Out-file $logFile -append
        QuitLeagueClient
    } else {
        Write-Output "$(Get-TimeStamp) Not all games were lost within the specified time. Keep playing!" | Out-file $logFile -append
    }
}

 

function CheckGameTimeValidity {
    param (
        $matchInfo,
        [int]$hoursToCheck
    )

    # Ensure matchInfo and gameEndTimestamp are provided
    if (-not $matchInfo -or -not $matchInfo.info.gameEndTimestamp) {
        Write-Output "$(Get-TimeStamp) Invalid matchInfo provided. Ensure it contains the gameEndTimestamp." | Out-file $logFile -append
        return $false
    }

    $gameEndTimestamp = $matchInfo.info.gameEndTimestamp

    # Convert the game end timestamp to DateTime
    try {
        $gameEndDateTime = [datetimeoffset]::FromUnixTimeMilliseconds($gameendtimestamp)
    } catch {
        Write-Output "$(Get-TimeStamp) [ERROR] Error converting gameEndTimestamp to DateTime: $_" | Out-file $logFile -append
        return $false
    }

    $currentDateTime = Get-Date

    # Check if the game end time is within the specified range
    return ($gameEndDateTime -ge $currentDateTime.AddHours(-$hoursToCheck))
}

function CheckGameOutcome {
    param (
        [Parameter(Mandatory = $true)]
        $matchInfo,

        [Parameter(Mandatory = $true)]
        $mypuuid
    )

    $participant = $matchinfo.info.participants | Where-Object { $_.puuid -eq  $mypuuid }

    if ($participant) {
        $winStatus = $participant.win
        if ($winStatus -eq $false) {
            Write-Output "$(Get-TimeStamp) Game $match was lost." | Out-file $logFile -append
            $lostgame  += $false
        } else {
            Write-Output "$(Get-TimeStamp) The game $match was won." | Out-file $logFile -append                   
            $lostgame += $true
        }

    } else {
        Write-Output "$(Get-TimeStamp) Participant with puuid '$mypuuid' not found."| Out-file $logFile -append
    }
}

function QuitLeagueClient {
    $processName = "LeagueClient"
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

    if ($process) {
        Stop-Process -Name $processName -Force
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("You have lost $gamesToCheck games in a row. It's time for a break! The League client will be closed. Break time: $hoursToCheck Hour(s).", 
        "League Mental Health Alert", [System.Windows.Forms.MessageBoxButtons]::OK)
    } else {
        Write-Output "$(Get-TimeStamp) $processName is not running."| Out-file $logFile -append
    }
}

while ($true) {
    Get-RecentGames -playerName $playerName -apiKey $apiKey -hoursToCheck $hoursToCheck -gamesToCheck $gamesToCheck -gameTag $gameTag -rankedOnly $rankedOnly
    Write-Output "$(Get-TimeStamp) Sleeping for 60 seconds before the next check."| Out-file $logFile -append
    Start-Sleep -Seconds 60
}