
#
# Creates a new sprite sheet of all of the set symbols. This is useful
# to reduce the couple of hundred symbol images into one image to reduce
# the number of network calls to the server.
#

request = require('request')
fs = require('fs')
setData = require('./app/setData')
child_process = require('child_process')

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

# Helper function that downloads a file from a URL to a path
# @param {String} url the URL of the file to download
# @param {String} path the path to download the file to
# @param {Function} [success] invoked when the file is successfull downloaded
# @param {Function} [fail] invoked when the request fails
downloadFile = (url, path, success, fail) ->

	handleResponse = (res) ->
		if res.statusCode != 200
			fail?({
				message: "Unable to download file from #{url}"
				statusCode: res.statusCode
				url: url
			})
		else 
			console.log "Downloading file to path: #{path}"
			res.pipe fs.createWriteStream(path)
			res.on 'end', () -> success?(path, url)

	console.log "Attempting to download #{url} to #{path}"
	req = request {url: url}
	req.on 'response', handleResponse

# calls each of the tasks given in a sequential order one after the other
# @param {Function[]} tasks array of tasks to be completed
# @param {Function} [done] called when all tasks have completed
series = (tasks, done) ->
	tasksRemaining = tasks.slice()

	processTask = () ->
		if tasksRemaining.length > 0
			thisTask = tasksRemaining[0]
			tasksRemaining = tasksRemaining.slice(1)
			thisTask?(processTask)
		else 
			done?()

	processTask()

parallel = (tasks, numberOfConsecutive, done) ->
	tasksRemaining = tasks.slice()
	parallelTasksRunning = numberOfConsecutive

	doneTask = () ->
		parallelTasksRunning = parallelTasksRunning - 1
		if parallelTasksRunning == 0 then done?()

	processTask = () ->
		if tasksRemaining.length > 0
			thisTask = tasksRemaining[0]
			tasksRemaining = tasksRemaining.slice(1)
			thisTask?(processTask)
		else 
			doneTask()

	processTask() for i in [0 ... parallelTasksRunning]

# downloads the symbol for the given set code
# @param setCode the set code 
# @param rarity the rarity of the image to downlod
# @param tempPath the path to download the photos to
# @param success Function(imagePath, setCode) the callback when the download successfully completes
# @param fail Function()
downloadImage = (setCode, rarity, tempPath, success, fail) ->
	url = "http://mtgimage.com/symbol/all/#{setCode}/#{rarity}/16.png"
	imagePath = "#{tempPath}/#{setCode}_16.png"

	handleSuccess = (path, url) ->
		success?(imagePath, setCode, rarity)
	handleFail = (data) ->
		console.log "Unable to download image: #{url}"
		fail?(data, imagePath, setCode, rarity)

	downloadFile url, imagePath, handleSuccess, handleFail

# is the given filename possibly a PNG
isPng = (fileName) -> fileName.slice(-4).toLowerCase() == '.png'

# get the dimensions of the image file at the give path
# @param fullPath the full path of the image file
# @param success ({width:int, height:int}, fullPath)
# @param fail (failureData, fullPath)
getImageDimensions = (fullPath, success, fail) ->
	convert = child_process.spawn('convert', [fullPath, '-format', '%w,%h', '-ping', 'info:'])
	convert.stdout.setEncoding 'utf8'
	convert.stdout.on 'data', (data) -> 
		dimensions = data.trim().split(',')
		width = parseInt(dimensions[0])
		height = parseInt(dimensions[1])
		success?({
			width:  width
			height: height
		}, fullPath)
	convert.stderr.setEncoding 'utf8'
	convert.stderr.on 'data', (data) -> fail?(data, fullPath)

# creates a transparent image with the specified height and width
createTransparentImage = (spriteImagePath, width, height, success, fail) -> 
	convert = child_process.spawn('convert', ['-size', "#{width}x#{height}", 'xc:none', spriteImagePath])
	convert.stdout.setEncoding 'utf8'
	convert.stdout.on 'data', (data) -> 
		console.log 'Unexpected data', data
		fail?({message: 'Unexpected data'})
	convert.stderr.setEncoding 'utf8'
	convert.stderr.on 'data', (data) -> 
		console.log "Unable to create sprite image at #{spriteImagePath}"
		fail?({message: "Unable to create sprite image at #{spriteImagePath}"})
	convert.on 'close', (code, signal) -> 
		if code == 0
			success?(spriteImagePath, width, height)
		else 
			fail?({message: "Unexpected result when creating image: #{code}", code: code})

# creates one sprite image at the given path
# @param {Object[]} images array of images to be processed
# @param {String} spriteImagePath the path to the location where the image will be created
# @param {Function} done the callback when the sprite image is finished
processImages = (images, spriteImagePath, done, fail) ->
	console.log 'Getting information about images'

	createGetDimensionTask = (image, i) ->
		(success) ->
			handleGetImageDimensions = (dimensions) ->
				image.width = dimensions.width
				image.height = dimensions.height
				success?()

			getImageDimensions(image.imagePath,
				handleGetImageDimensions,
				(data, fullPath) -> console.err "Failed to get dimensions for file: #{image.imagePath}", data, fullPath)

	tasks = (createGetDimensionTask(image, i) for image, i in images)
	series tasks, () -> 
		console.log "Starting to generate sprite image at #{spriteImagePath}"

		# calculate the height and width of the sprite sheet
		width  = -1
		height = 0

		for image, i in images
			if width  == -1 || image.width > width
				width = image.width

			image.yOffset = if i == 0 then 0 else height + 1
			height = image.yOffset + image.height

		handleCreateImageSuccess = (spriteImagePath) ->
			compositeImages images, spriteImagePath, done
		handleCreateImageFail = (err) ->
			console.log "Unable to create sprite image #{spriteImagePath}", err
			fail?(err)

		createTransparentImage spriteImagePath, width, height, handleCreateImageSuccess, handleCreateImageFail

# composites each of the images in the given array onto the sprite image
# @param images Object[] the images to be composited on the sprite image
# @param spriteImagePath String the path of the sprite image
compositeImages = (images, spriteImagePath, done, fail) ->
	createCompositeImageTask = (image) ->
		(success) ->
			composite = child_process.spawn('composite', ['-geometry', "+0+#{image.yOffset}", image.imagePath, spriteImagePath, spriteImagePath])
			composite.stdout.setEncoding 'utf8'
			composite.stdout.on 'data', (data) -> 
				console.log "Unexpected data", data
				success?()
			composite.stderr.setEncoding 'utf8'
			composite.stderr.on 'data', (data) -> success?()
			composite.on 'close', (code, signal) -> 
				if code == 0
					success?()
				else 
					console.log "Unexpected result when compositing image #{image.imagePath}", code
					success?()

	tasks = (createCompositeImageTask(image) for image in images)
	series tasks, () ->
		console.log "Finished composing sprite image at #{spriteImagePath}"
		done?(images)

# downloads all of the images for the set codes given
# @param {Object[]} sets 
downloadAllSetImages = (sets, done) ->
	images = []

	createDownloadImageTask = (set, i) ->
		(success) ->
			handleSuccess = (imagePath, setCode) ->
				console.log("Successfully downloaded #{setCode} to #{imagePath}")
				images[i] = {
					imagePath: imagePath
					setCode: setCode
				}
				success?()
			handleFail = (res) ->
				console.log "Unable to download image so it is being skipped: #{res.url}", res.statusCode
				images[i] = undefined
				success?()

			# if there is at least one rarity, use it to download the image
			if set.rarities? and Array.isArray(set.rarities) and set.rarities.length > 0
				downloadImage set.setCode, set.rarities[0], tempPath, handleSuccess, handleFail
			else 
				console.log "Skipping #{set.setCode} because it doesn't have at least one rarity"
				success?()

	tasks = (createDownloadImageTask(set, i) for set, i in sets)
	parallel tasks, 10, () -> 

		# remove any images that could not be downloaded
		images.splice(i, 1) for i in [images.length ... 0] when !images[i]?

		done(images)

# creates the css file for use with the sprite image
createSymbolCss = (images, cssFilePath, selectorPrefix, selectorSuffix, done) -> 
	console.log("Generating the CSS at #{cssFilePath}")

	createWriteCssToStreamTask = (stream, encoding, image) ->
		(success) ->
			classBlock = """
				#{selectorPrefix}#{image.setCode}#{selectorSuffix} {
					background-position: 0px -#{image.yOffset}px;
					width: #{image.width}px;
					height: #{image.height}px;
				}

			"""

			stream.write classBlock, encoding, () ->
				success?()

	stream = fs.createWriteStream(cssFilePath)
	tasks = (createWriteCssToStreamTask(stream, 'utf8', image) for image in images)
	series tasks, () ->
		console.log("Finished generating CSS at #{cssFilePath}")
		done?()

# downloads the SetSymbol.json file from mtgimage.com
downloadSetSymbolManifest = (tempPath, success, fail) ->
	url = 'http://mtgimage.com/SetSymbols.json'
	manifestPath = "#{tempPath}/SetSymbols.json"

	handleSuccess = (path, url) ->
		console.log 'Downloading set manifest'
		success?(path)

	handleFail = (data) ->
		console.log "Unable to download the set manifest #{manifestPath}"
		fail?(data)

	downloadFile url, manifestPath, handleSuccess, handleFail

# processes the setSymbol file at the given path into an array of set information
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

generate = (tempPath, spriteImagePath, cssFilePath, success) ->
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
			downloadAllSetImages setSymbols, (images) ->
				processImages images, tempSpriteImagePath, (images) ->
					createSymbolCss images, tempSpriteCssFilePath, '.set-symbol-', '', () ->
						console.log 'Moving files from temporary to final destination'

						# move the generated image to the final destination
						fs.renameSync tempSpriteImagePath, spriteImagePath
						console.log "Sprite image moved to #{spriteImagePath}"

						# move the generated css to the final destination
						fs.renameSync tempSpriteCssFilePath, cssFilePath
						console.log "CSS file moved to #{cssFilePath}"

						success?()
		

generate tempPath, spriteImagePath, cssFilePath
	