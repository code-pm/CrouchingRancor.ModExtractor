// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.
const $ = require('jquery')
const axios = require('axios');
const cheerio = require('cheerio');
const jsonfile = require('jsonfile');
const {dialog} = require('electron').remote;

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

function scrapeModPage(html) {
    const $o = cheerio.load(html);

    const $mods = $o(".statmod.pc-statmod");

    const dataArray = $mods.map((i, elem) => {
        var $mod = cheerio(elem);
        var data = {};  // Mod data record

        data.name = $mod.find(".statmod-img").attr("alt");
        data.pips = $mod.find(".statmod-pip").length;
        data.level = parseInt($mod.find(".statmod-level").text());
        data.character = $mod.find(".char-portrait")[0].attribs.title;
        data.slot = parseInt(elem.attribs.class.match(/pc-statmod-slot(\d+)/)[1]);


        data.primarystat = {
            "Name": $mod.find(".statmod-stats-1 .statmod-stat-label").text(),
            "Value": $mod.find(".statmod-stats-1 .statmod-stat-value").text()
        };

        data.secondarystats = $mod.find(".statmod-stats-2 .statmod-stat").map((j, elem2) => {
            var $stat = cheerio(elem2);
            return {
                "Name": $stat.find(".statmod-stat-label").text(),
                "Value": $stat.find(".statmod-stat-value").text()
            };
        }).toArray()

        return data;
    });


    return dataArray.toArray();

}

$(() => {

    const rgx = /^https:\/\/swgoh\.gg\/u\/\w+\//

    $("#btnExport").click(() => {

        try{
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
                })    
            })
            
            console.log(data);
    
        }
        catch (error){
            dialog.showMessageBox({
                type: "error",
                title: "uh oh...",
                message: error
            })
        }
        
    })
});
