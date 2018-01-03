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

## Using the ruby extractor

If you have ruby installed on your computer, you can use the ruby script to download the mod info into a JSON file.

First you need to install the  [nokogiri](https://github.com/sparklemotion/nokogiri), gem which does most of the
heavy lifting of the HTML parsing.

```bash
$ cd ruby
$ bundle install
```

Once you do that, you can run the script to download your data, specifying your user name

```bash
$ cd ruby
$ bundle exec ruby get_mods.rb sirrobindabrave
Downloaded page 1 for user sirrobindabrave, got 36 mods
Downloaded page 2 for user sirrobindabrave, got 36 mods
Downloaded page 3 for user sirrobindabrave, got 31 mods
Found 103 mods, wrote to sirrobindabrave.json
```

## Using the docker image

The ruby extractor has been bundled up in a docker image.

```bash
$ docker run jonmoter/rancor-mod-extractor:latest YOUR_USER_NAME > output.json
```

If you want the JSON to be more readable:

```bash
$ docker run -e PRETTY=1 jonmoter/rancor-mod-extractor:latest YOUR_USER_NAME > output.json
```
