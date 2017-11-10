// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.
const $ = require('jquery')
const axios = require('axios');
const cheerio = require('cheerio');
const jsonfile = require('jsonfile');
const { dialog } = require('electron').remote;
const slotMap = new Map([
    [1, "square"],
    [2, "arrow"],
    [3, "diamond"],
    [4, "triangle"],
    [5, "circle"],
    [6, "cross"]
]);

const crawlModPages = async url => {
    try {
        const response = await axios.get(url);
        const html = response.data;
        const $o = cheerio.load(html);
        let lastpage = 1;
        let data = [];

        // Parse the pagination text to determine total # of pages
        const pages = $o("ul.pagination").children("li").first().text().match(/Page \d+ of (\d+)/);
        if (pages != null && pages.length == 2) {
            lastpage = pages[1];
        }

        // Get the first page's data
        data = data.concat(scrapeModPage(html));

        //Retrieve the rest of the mod html pages
        for (let i = 2; i <= lastpage; i++) {
            const response = await axios.get(url + "?page=" + i.toString());
            const html = response.data;
            data = data.concat(scrapeModPage(html));
        }

        return data;
    } catch (error) {
        console.log(error);
    }
};

function resolveSetName(fullname){
    if (fullname.includes("Health")){
        return "health";
    }
    else if (fullname.includes("Offense")){
        return "offense";
    }
    else if (fullname.includes("Defense")){
        return "defense";
    }
    else if (fullname.includes("Speed")){
        return "speed";
    }
    else if (fullname.includes("Crit Chance")){
        return "critchance";
    }
    else if (fullname.includes("Crit Damage")){
        return "critdamage";
    }
    else if (fullname.includes("Potency")){
        return "potency";
    }
    else if (fullname.includes("Tenacity")){
        return "tenacity";
    }
}

function scrapeModPage(html) {
    const $o = cheerio.load(html);

    const $mods = $o(".statmod.pc-statmod");

    const dataArray = $mods.map((i, elem) => {
        var $mod = cheerio(elem);
        var data = {};  // Mod data record

        data.mod_uid = $mod.parent().attr("data-id");
        
        const slotID = parseInt(elem.attribs.class.match(/pc-statmod-slot(\d+)/)[1]);
        data.slot = slotMap.get(slotID);

        const modname = $mod.find(".statmod-img").attr("alt");
        data.set = resolveSetName(modname);
        
        data.pips = $mod.find(".statmod-pip").length.toString();
        data.level = $mod.find(".statmod-level").text();
        data.characterName = $mod.find(".char-portrait")[0].attribs.title;

        data.primaryBonusType = $mod.find(".statmod-stats-1 .statmod-stat-label").text();
        data.primaryBonusValue = $mod.find(".statmod-stats-1 .statmod-stat-value").text();

        for(let j = 1; j<=4; j++){
            data[`secondaryType_${j}`] = "";
            data[`secondaryValue_${j}`] = "";
        }

        $mod.find(".statmod-stats-2 .statmod-stat").each((j, elem2) => {
            var $stat = cheerio(elem2);
            data[`secondaryType_${j+1}`] = $stat.find(".statmod-stat-label").text();
            data[`secondaryValue_${j+1}`] = $stat.find(".statmod-stat-value").text();
        })

        return data;
    });


    return dataArray.toArray();

}

$(() => {

    const rgx = /^https:\/\/swgoh\.gg\/u\/\w+\//

    $("#btnExport").click(() => {

        try {
            const input = $("#txtGuildUrl").val();
            const m = rgx.exec(input);

            if (m == null) {
                throw "Not a valid swgoh.gg guild URL!";
            }

            const file = dialog.showSaveDialog({
                title: "Save mods data to file...",
                defaultPath: "mods.json"
            });

            const url = m[0] + "mods/";
            const data = crawlModPages(url);

            data.then(d => {
                jsonfile.writeFile(file, d, function (err) {
                    console.error(err)
                    throw err.message
                })
            })

        }
        catch (error) {
            dialog.showMessageBox({
                type: "error",
                title: "uh oh...",
                message: error
            })
        }

    })
});
