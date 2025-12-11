Just want the current codes? [Check out the CSV file](https://github.com/VinceCarbone/Borderlands4-SHiFTCodes/blob/main/Borderlands4%20SHiFT%20Codes.csv)
<br><br>
You can also download the script and run it locally in PowerShell
<br><br>
<img width="612" height="186" alt="image" src="https://github.com/user-attachments/assets/ad6d28f5-6f69-49b8-823b-72fd6bad2530" />
<br><br>
This script will scrape the interweb for SHiFT codes. It checks a few different sites and combines the results. It'll sort the output by expiration date and filter out expired codes as well.

## Parameters
```-ExportCSV```
<br>This will export a CSV of the currently valid SHiFT codes to the current working directory
<br><br>

```-DiscordWebhook```
<br>If you specify a webhook, the script will automatically send any new SHiFT codes (codes that aren't present in the CSV file yet) to your Discord server. Right now it only sends the actual code, no other details (no reward info, no expiration, etc). This is so that it's easier to copy/paste. If you specify this parameter without also using the `-ExportCSV` parameter, it will be ignored. The idea here is to run this as a scheduled task and have it run on a regular basis automatically. Here's a quick example
<br>
```
.\Borderlands4-SHiFTCodes.ps1 -ExportCSV -DiscordWebhook "https://discordapp.com/api/webhooks/[some value]/[some other value]"
```
<br>

```-git```
<br>This is simply so my scheduled task will merge any CSV changes with the repo automatically. You probably don't need to worry about this one.
