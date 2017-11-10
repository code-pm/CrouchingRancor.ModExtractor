Param(
    [string]$url
)

$m = [regex]::Match($url, "^https:\/\/swgoh\.gg\/u\/\w+\/")

if (-not $m.Success) {
    Throw "$url is not a valid swgoh.gg user URL"
}

$url = $m.Groups[0].Value + "mods/"

$slotMap = "","square","arrow","diamond","triangle","circle","cross"


# Stop execution on error
$ErrorActionPreference = "Stop"


function Resolve-ModSetName([string]$modname){
    if ($modname.Contains("Health")){
        return "health";
    }
    elseif ($modname.Contains("Offense")){
        return "offense";
    }
    elseif ($modname.Contains("Defense")){
        return "defense";
    }
    elseif ($modname.Contains("Speed")){
        return "speed";
    }
    elseif ($modname.Contains("Crit Chance")){
        return "critchance";
    }
    elseif ($modname.Contains("Crit Damage")){
        return "critdamage";
    }
    elseif ($modname.Contains("Potency")){
        return "potency";
    }
    elseif ($modname.Contains("Tenacity")){
        return "tenacity";
    }
}

function Scrape-ModPage([string]$url) {
    $mods = @();
    $r = Invoke-WebRequest $url
    
    $rows = $r.ParsedHtml.GetElementsByTagName("div") | ? { $_.className -eq "collection-mod" } 
    
    foreach ($row in $rows) {
    
        $mod = @{}
    
        $mod["mod_uid"] = $row.attributes["data-id"].textContent
        
        $slotID = [Int][regex]::Match($row.children[0].className, "pc-statmod-slot(\d+)").Groups[1].Value
        $mod["slot"] = $slotMap[$slotID]
    
        $modname = $row.getElementsByClassName("statmod-img")[0].alt
        $mod["set"] = Resolve-ModSetName $modname
        
        $mod["pips"] = $row.getElementsByClassName("statmod-pip").Length.ToString()
        $mod["level"] = $row.getElementsByClassName("statmod-level")[0].textContent
        $mod["characterName"] = $row.getElementsByClassName("char-portrait")[0].title
    
        $primarystats = $row.getElementsByClassName("statmod-stats-1")[0]
        $mod["primaryBonusType"] = $primarystats.getElementsByClassName("statmod-stat-label")[0].textContent
        $mod["primaryBonusValue"] = $primarystats.getElementsByClassName("statmod-stat-value")[0].textContent
    
        $secondarystats = $row.getElementsByClassName("statmod-stats-2")[0].getElementsByClassName("statmod-stat")
        for ($i = 0; $i -lt $secondarystats.length; $i++) {
            $stat = $secondarystats[$i]
            $mod["secondaryType_$($i+1)"] = $stat.getElementsByClassName("statmod-stat-label")[0].textContent
            $mod["secondaryValue_$($i+1)"] = $stat.getElementsByClassName("statmod-stat-value")[0].textContent
        }
        
        $mods += $mod
    }

    # Get next page Url or quit...
    # <ul class='pagination'>
    #   <li>..<li>
    #   <li><a href="nexturl"></a><li>          <--------
    # </ul>
    $pgr = $r.ParsedHtml.GetElementsByTagName("ul") | ? { $_.className.Contains("pagination") } | select -First 1
    $j = $pgr.children.length - 1
    $nexturl = [string]$pgr.children[$j].children[0].attributes["href"].textContent

    if ($nexturl.StartsWith("/u/")){
        $mods += Scrape-ModPage "https://swgoh.gg$($nexturl)"
    }

    return $mods
}

$mods = Scrape-ModPage $url 
$mods | ConvertTo-Json | Set-Content -Encoding UTF8 -Path "$($PSScriptRoot)\mods.json"