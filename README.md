# RazoreaterII_Rift-Rest-Reminder
This script monitors the recent ranked games of a League of Legends player and suggests taking a break if the player has lost a certain number of games within a specified timeframe.

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



#windows_task_Scheduling_rift_rest_reminder.xml
Change the following values:
- General: When running the task, use the following user account
- Triggers: upon registration, change the user
- Action: Configure the correct path