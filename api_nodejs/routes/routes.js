'use strict';
var parse = require('jsonfile')
var datajson = require('./parse_datajson.js')
var async = require('async')
var jsonfile = require('jsonfile')

exports.get = function(req, res) {
    var scname = req.params.sn;
	var key = datajson.getDatabyTag(scname);
	
	async.series({
	    facebook: function(callback) {
	        var file_path = './facebook/' + key.faceid  + '.json'

	        jsonfile.readFile(file_path, function(err, obj) {
	          callback(null, obj)
	        })
	    },

	    twitter: function(callback){
	        var file_path = './twitter/' + key.screen_name  + '.json'
	        jsonfile.readFile(file_path, function(err, obj) {
	        	// console.log(obj)
	          callback(null, obj)
	        })
	    },

	    instagram: function(callback){
	        var file_path = './instagram/' + key.instagramid  + '.json'
	        jsonfile.readFile(file_path, function(err, obj) {
	          callback(null, obj)
	        })
	    }
	},
	function(err, results){
		if(err) {
			res.send({code: false, message: 'Get data failed ! '});
			return;
		}

		res.send(results);
	});
};
