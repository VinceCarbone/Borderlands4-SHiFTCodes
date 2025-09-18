The easiest way to use this is to simply view the current list of codes by [checking out the CSV file in this repo](Borderlands4 SHiFT Codes.csv)
<br>
<img width="533" height="195" alt="image" src="https://github.com/user-attachments/assets/5ddb7090-65ba-42f8-bba3-b46d69378279" />

Execute this script with PowerShell and it will scrape the interweb for SHiFT codes. It checks a few different sites and combines the results. It'll sort the output by expiration date and filter out expired codes as well.

## Parameters
```-ExportCSV```
<br>This will export a CSV of the SHiFT codes to the current directory

```-git```
<br>This is simply so my scheduled task will merge any CSV changes with the repo
