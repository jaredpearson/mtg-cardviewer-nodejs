
fs = require('fs')
request = require('request')
download = require('./app/utils/download')
spriter = require('./app/utils/spriter')

# -----------------------------------------------------------------------
# parameters
# -----------------------------------------------------------------------

# the path to which the image files are downloaded
tempPath = './.temp_manaCostSymbols'

# the path to the new sprite image
spriteImagePath = "./public/images/manaCostSymbols.png"

# the path to the new CSS file
cssFilePath = "./public/css/manaCostSymbols.css"

# -----------------------------------------------------------------------
# end parameters 
# -----------------------------------------------------------------------

getManaCostsInUse = (success) ->

	data = JSON.parse(fs.readFileSync('data/AllSets-x.json'))

	manaCosts = []

	for code, set of data when set.cards?
		for card in set.cards when card.manaCost?

			regex = /\{([^\}]*)\}/g
			
			while match = regex.exec(card.manaCost)
				manaCostPart = match[1]

				if manaCosts.indexOf(manaCostPart) == -1
					manaCosts.push manaCostPart

	success?(manaCosts)

downloadAllManaCostImages = (manaCosts, tempPath, success) ->
	downloadInputs = []
	pathToManaCost = {}
	images = []

	for manaCost, i in manaCosts
		cleanManaCost = manaCost.replace('/', '')
		url = "http://mtgimage.com/symbol/mana/#{cleanManaCost}/16.png";
		destination = "#{tempPath}/#{cleanManaCost}_16.png"
		pathToManaCost[destination] = {
			manaCost: manaCost
			cleanManaCost: cleanManaCost
		}
		downloadInputs.push new download.DownloadInput(url, destination)

	handleDownloadAllDoneEach = (result, i) ->
		manaCost = pathToManaCost[result.destination]
		name = "manacost-symbol-#{manaCost.cleanManaCost}"
		images.push new spriter.SpriteImage(result.destination, name)

	handleDownloadAllDone = (results) ->
		success?(images)

	download.downloadAllFiles downloadInputs, handleDownloadAllDone, handleDownloadAllDoneEach

exports.generate = (tempPath, spriteImage, cssFilePath, success) ->

	# make a temporary directory to store all of the files
	try
		fs.mkdirSync(tempPath)
	catch error
		# if the directory already exists, then just continue
		if error?.code != 'EEXIST'
			throw error

	tempSpriteImagePath = "#{tempPath}/symbol.png"
	tempSpriteCssFilePath = "#{tempPath}/symbol.css"

	getManaCostsInUse (manaCosts) -> 
		downloadAllManaCostImages manaCosts, tempPath, (images) ->
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