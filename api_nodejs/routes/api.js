'use strict';
// init library
var FB = require('fb');
var Twitter = require('twitter');
var jsonfile = require('jsonfile')
var fs = require('fs')

var api = {
	rootData: function() {
		var rawdata = fs.readFileSync('../database.json');
        var data = JSON.parse(rawdata);

        return data
	},

	facebook: function(data) {
		FB.setAccessToken("407659513029485|JV5AH7X5P5GaRtGQTu6Lf-ZDcRU")

		Object.keys(data).forEach(function(element) {
            var node = '/' + data[element].faceid;

	        FB.api(node, { fields: ['id', 'name', 'picture']}, function (res) {
	            if (!res || res.error) {
	                console.log(!res ? 'error occurred' : res.error);
	                return;
	            }

	            var file_path = '../facebook/' + data[element].faceid  + '.json'

	            var encoding = "utf8";

	            fs.writeFile(file_path, '', encoding, (err) => {
	                if (err) throw err;

	                console.log("The file was succesfully saved!");
	            });

	            jsonfile.writeFile(file_path, res, function (err) {
	              if (err) {
	              	console.log(err);
	                return;
	              }
	            })

	            console.log("Get data succesfully ! ");
	        });
        });
	},

	twitter: function(data) {
        var client = new Twitter({
            consumer_key: 'VJfXCaUO6lnweMeKJ2x25Mfkj',
            consumer_secret: '3iCoAMncWtR6igEPCdXLoJF04RuGXdqDDLXAr4dVQ445y4AyBy',
            access_token_key: '3146759460-1b0oYOdBhmHYMO12nsUisiwVOJf1v6QRXI7qI6M',
            access_token_secret: 'sCngfc1Yu1tEFmlzcNaFqhNq2iLqj8gu3CX8p9EOWp2uv'
        });

        Object.keys(data).forEach(function(element) {
        	var params = {screen_name: data[element].screen_name};

	        client.get('users/show', params, function(error, tweets, response) {
	            if (error) {
	                console.log(error);
	                return;
	            }

	            var file_path = '../twitter/' + data[element].screen_name  + '.json'

	            var encoding = "utf8";

	            fs.writeFile(file_path, '', encoding, (err) => {
	                if (err) throw err;

	                console.log("The file was succesfully saved!");
	            });

	            jsonfile.writeFile(file_path, tweets, function (err) {
	              if (err) {
	              	console.log(err);
	                return;
	              }
	            })

	            console.log("Get data succesfully ! ");
	        });
	    })
	},

	instagram: function(data) {
		var request = require("request");

		Object.keys(data).forEach(function(element) {
			// You can use callbacks or promises
			var file_path = '../instagram/' + data[element].instagramid  + '.json'

	        var encoding = "utf8";

	     	var target = "https://www.instagram.com/" + data[element].igname + "/?__a=1"

	     	request({
			    url: target,
			    json: true
			}, function (error, response, body) {
				    if (!error && response.statusCode === 200) {
				        fs.writeFile(file_path, '', encoding, (err) => {
		                if (err) throw err;

		                console.log("The file was succesfully saved!");
		            });

		            jsonfile.writeFile(file_path, body, function (err) {
		              if (err) {
		              	console.log(err);
		                return;
		              }
		            });
			    }
			});
		});
	}

}

// module.exports = api;
var data = api.rootData();

api.instagram(data)
api.facebook(data)
api.twitter(data)


