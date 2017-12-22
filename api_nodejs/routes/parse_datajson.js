const fs = require('fs');

var parse_datajson = {
    getDatabyTag: function(tag){
        var rawdata = fs.readFileSync('database.json');
        var data = JSON.parse(rawdata);
        if(typeof data[tag] === 'undefined'){
            return 'Error: Tag not found on database file!';
        }
        return data[tag];
    }
}

module.exports = parse_datajson;
