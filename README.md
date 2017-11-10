# CrouchingRancor.ModExtractor

**A simple set of tools to extract your swgoh.gg mods data to import into http://apps.crouchingrancor.com/Mods/Manager**

## Using the Powershell extractor
1. Download/copy the powershell script to your machine in a file called 'swgoh-mods.ps1'
2. Open powershell and navigate to the directory where the script is
3. Run the following command:

. .\swgoh-mods.ps1 "https://swgoh.gg/u/your-user-name/"

4. This will create a file called 'mods.json' in the same directory where the script is located.
5. Take that file and upload it to http://apps.crouchingrancor.com/Mods/Manager


## Using the Electron extractor
If you are familiar with nodejs/electron go ahead and clone the repo to your machine and run it with your debugger of choice (I used VS Code). We had originally intended to compile it and share as an EXE but the file size was ridiculously too large.