
child_process = require('child_process')
task_manager = require('./task_manager')
fs = require('fs')

class SpriteImage
	# @param {String} name the name of the sprite images. this will be used as the selector in the CSS file
	constructor: (@imagePath, @name) ->
		@width = undefined
		@height = undefined
		@yOffset = undefined

###*
# get the dimensions of the image file at the give path
# @param {string} fullPath the full path of the image file
# @param {successCallback} success callback invoked when getting the image dimensions succeeds
# @param {failCallback} fail callback invoked when getting the image dimensions succeeds
# 
# @typedef ImageDimensions
# @type {object}
# @property {number} width the width of the image
# @property {number} height the height of the image
#
# @callback successCallback
# @param {ImageDimensions} dimensions the image dimensions
# @param {string} fullPath the path of the image
#
# @callback failCallback
# @param {*} data the data returned from the failed call
# @param {string} fullPath the path of the image
###
getImageDimensions = (fullPath, success, fail) ->
	convert = child_process.exec "convert #{fullPath} -format %w,%h -ping info:", (err, stdout, stderr) ->
		if err
			fail?(stderr, fullPath)
		else 
			dimensions = stdout.trim().split(',')
			width = parseInt(dimensions[0])
			height = parseInt(dimensions[1])
			success?({
				width:  width
				height: height
			}, fullPath)

###*
# composite each of the images in the given array onto the sprite image
# @param {SpriteImage[]} images the images to be composited on the sprite image
# @param {string} spriteImagePath the path of the sprite image
###
compositeImages = (images, spriteImagePath, done, fail) ->
	createCompositeImageTask = (image) ->
		(success) ->
			composite = child_process.exec "composite -geometry +0+#{image.yOffset} #{image.imagePath} #{spriteImagePath} #{spriteImagePath}", (err, stdout, stderr) ->
				if err
					console.log "Unexpected error occurred", err
					success?()
				else 
					success?()

	tasks = (createCompositeImageTask(image) for image in images)
	task_manager.series tasks, () ->
		console.log "Finished composing sprite image at #{spriteImagePath}"
		done?(images)

###
# creates a transparent image with the specified height and width
###
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

###*
# creates one sprite image at the given path composed of all the other images
# @param {SpriteImage[]} images array of SpriteImage instances to be processed
# @param {string} spriteImagePath the path to the location where the image will be created
# @param {function} done the callback when the sprite image is finished
###
createSpriteImage = (images, spriteImagePath, done, fail) ->
	console.log 'Getting information about images'

	createGetDimensionTask = (image, i) ->
		(success) ->
			handleGetImageDimensions = (dimensions) ->
				image.width = dimensions.width
				image.height = dimensions.height
				success?()

			getImageDimensions(image.imagePath,
				handleGetImageDimensions,
				(data, fullPath) -> console.error "Failed to get dimensions for file: #{image.imagePath}", data, fullPath)

	tasks = (createGetDimensionTask(image, i) for image, i in images)
	task_manager.series tasks, () -> 
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

###*
# creates the css file for use with the sprite image
###
createSpriteCssFile = (images, cssFilePath, done) -> 
	console.log("Generating the CSS at #{cssFilePath}")

	createWriteCssToStreamTask = (stream, encoding, image) ->
		(success) ->
			classBlock = """
				.#{image.name} {
					background-position: 0px -#{image.yOffset}px;
					width: #{image.width}px;
					height: #{image.height}px;
				}

			"""

			stream.write classBlock, encoding, () -> success?()

	stream = fs.createWriteStream(cssFilePath)
	tasks = (createWriteCssToStreamTask(stream, 'utf8', image) for image in images)
	task_manager.series tasks, () ->
		console.log("Finished generating CSS at #{cssFilePath}")
		done?()

module.exports = {
	createSpriteImage: createSpriteImage
	createSpriteCssFile: createSpriteCssFile
	SpriteImage: SpriteImage
}