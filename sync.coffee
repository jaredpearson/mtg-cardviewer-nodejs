
#
# Downloads the latest copy of the data from the MTGJson.com website
# and unzips it to the data directory
#

http = require('http')
fs = require('fs')
unzip = require('unzip')
url_parse = require('url').parse

do ->
	options = url_parse('http://mtgjson.com/json/AllSets-x.json.zip') 
	req = http.request options, (res) ->
		res.pipe(unzip.Extract({path: 'data'}))
	req.end()