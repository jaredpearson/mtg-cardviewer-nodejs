
#
# Creates a new sprite sheet of all of the set symbols. This is useful
# to reduce the couple of hundred symbol images into one image to reduce
# the number of network calls to the server.
#

fs = require('fs')
download = require('./app/utils/download')
spriter = require('./app/utils/spriter')
task_manager = require('./app/utils/task_manager')


# -----------------------------------------------------------------------
# parameters for 
# -----------------------------------------------------------------------

# the path to which the image files are downloaded
tempPath = './.temp_setSymbols'

# the path to the new sprite image
spriteImagePath = "./public/images/setSymbols.png"

# the path to the new CSS file
cssFilePath = "./public/css/setSymbols.css"

# -----------------------------------------------------------------------
# end parameters
# -----------------------------------------------------------------------

###*
# downloads all of the images for the set codes given
# @param {Object[]} sets 
###
downloadAllSetImages = (sets, tempPath, done) ->
	images = []
	downloadInputs = []
	pathToSet = {}

	for set in sets
		if set.rarities? and Array.isArray(set.rarities) and set.rarities.length > 0
			rarity = set.rarities[0]
			url = "http://mtgimage.com/symbol/all/#{set.setCode}/#{rarity}/16.png"
			destination = "#{tempPath}/#{set.setCode}_16.png"
			downloadInputs.push new download.DownloadInput(url, destination)

			pathToSet[destination] = set
		else 
			console.log "Skipping #{set.setCode} because it doesn't have at least one rarity"

	handleDownloadEach = (result, i) ->
		imagePath = result.destination
		set = pathToSet[imagePath]

		if result.success
			console.log "Successfully downloaded #{set.setCode} to #{imagePath}"
			images.push new spriter.SpriteImage(imagePath, "set-symbol-#{set.setCode}")
		else 
			console.log "Unable to download image so it is being skipped: #{result.url}", result.statusCode

	handleDownloadDone = (results) ->
		done images

	download.downloadAllFiles downloadInputs, handleDownloadDone, handleDownloadEach

###*
# downloads the SetSymbol.json file from mtgimage.com
###
downloadSetSymbolManifest = (tempPath, success, fail) ->
	url = 'http://mtgimage.com/SetSymbols.json'
	manifestPath = "#{tempPath}/SetSymbols.json"

	handleSuccess = (path, url) ->
		console.log 'Downloaded set manifest'
		success?(path)

	handleFail = (data) ->
		console.log "Unable to download the set manifest #{manifestPath}"
		fail?(data)

	download.downloadFile url, manifestPath, handleSuccess, handleFail

###*
# processes the setSymbol file at the given path into an array of set information
###
processSetSymbolManifest = (path, success) ->
	fs.readFile path, (err, data) ->
		if err then throw err

		dataAsJson = JSON.parse(data)

		# flatten the map into an array of objects
		setSymbols = ({
			setCode: setCode
			rarities: rarities
		} for own setCode, rarities of dataAsJson)
		success?(setSymbols)

exports.generate = (tempPath, spriteImagePath, cssFilePath, success) ->
	# make a temporary directory to store all of the files
	try
		fs.mkdirSync(tempPath)
	catch error
		# if the directory already exists, then just continue
		if error?.code != 'EEXIST'
			throw error

	tempSpriteImagePath = "#{tempPath}/sprite.png"
	tempSpriteCssFilePath = "#{tempPath}/sprite.css"

	# download the manifest of all available set symbol images
	downloadSetSymbolManifest tempPath, (path) ->
		processSetSymbolManifest path, (setSymbols) ->
			downloadAllSetImages setSymbols, tempPath, (images) ->
				spriter.createSpriteImage images, tempSpriteImagePath, (images) ->
					spriter.createSpriteCssFile images, tempSpriteCssFilePath, () ->
						console.log 'Moving files from temporary to final destination'

						# move the generated image to the final destination
						fs.renameSync tempSpriteImagePath, spriteImagePath
						console.log "Sprite image moved to #{spriteImagePath}"

						# move the generated css to the final destination
						fs.renameSync tempSpriteCssFilePath, cssFilePath
						console.log "CSS file moved to #{cssFilePath}"

						success?()
		
if require.main == module
	exports.generate tempPath, spriteImagePath, cssFilePath
	