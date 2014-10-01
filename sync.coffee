
#
# Downloads the latest copy of the data from the MTGJson.com website
# and unzips it to the data directory
#

request = require('request')
fs = require('fs')
unzip = require('unzip')

(-> 
	req = request {
		url: 'http://mtgjson.com/json/AllSets-x.json.zip'
	}

	req.on 'response', (res) -> 
		res.pipe(unzip.Extract({path: 'data'}))
)()