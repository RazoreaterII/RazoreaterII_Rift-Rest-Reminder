# RazoreaterII_Rift-Rest-Reminder

A PowerShell script that uses the RIOT API to check the last games of a player (especially ranked - configurable), if the player has lost the last X games (configurable), the Riot Client is closed until a certain time (configurable) has elapsed.
This prevents the player from entering a negative state and losing further games. It has been found that if at least 2 or 3 games have been lost in a row, the further games will probably also be lost, as the player is in a negative mental state.

#windows_task_Scheduling_rift_rest_reminder.xml
Change the following values:
- General: When running the task, use the following user account
- Triggers: upon registration, change the user
- Action: Configure the correct path