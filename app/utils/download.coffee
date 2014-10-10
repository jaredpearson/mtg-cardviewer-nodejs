
http = require('http')
fs = require('fs')
url_parse = require('url').parse
task_manager = require('./task_manager')

handleDownloadResponse = (res, url, path, lastModifiedDate, success, fail) ->
	if res.statusCode != 200
		fail?({
			message: "Unable to download file from #{url}"
			statusCode: res.statusCode
			url: url
		})
	else 
		# check the local file to see if it is newer than the server file
		if lastModifiedDate? and res.headers['last-modified']
			responseLastModified = new Date(res.headers['last-modified'])
			if responseLastModified <= lastModifiedDate
				console.log "Found cached file at #{path}; no need to update"
				res.emit 'end'
				success?(path, url)
				return
			else 
				console.log "Found outdated file at #{path}; redownloading"
				fs.unlinkSync path

		res.on 'data', (chunk) ->
			console.log "receive data for #{path}"
			fs.appendFile path, chunk, (err) ->
				if err
					res.emit 'end'
					fail?({
						message: "Unable to write file to #{path}"
						url: url
					})

		res.on 'end', () ->
			success?(path, url)

doDownload = (url, path, lastModifiedDate, success, fail) ->
	console.log "Attempting to download #{url} to #{path}"

	options = url_parse url
	options.method = 'GET'
	options.agent = agent
	req = http.request options, (res, err) ->
		if err
			fail?({
				message: "Unable to download file from #{url}"
				statusCode: res.statusCode
				url: url
			})
		else 
			handleDownloadResponse res, url, path, lastModifiedDate, success, fail
	req.end()

class DownloadInput
	constructor: (@url, @destination) ->

class DownloadResult
	constructor: (@input, @success) ->
		@url = @input.url
		@destination = @input.destination
		@statusCode = undefined

###*
# Helper function that downloads a file from a URL to a path
# @param {string} url the URL of the file to download
# @param {string} path the path to download the file to
# @param {Function} [success] invoked when the file is successfull downloaded
# @param {Function} [fail] invoked when the request fails
###
downloadFile = (url, path, success, fail) ->

	# if the file already exists at the path, then we can pull
	# the modified date to see if it is before the last-modified
	fs.exists path, (exists) ->
		if exists
			console.log "Checking existing local file #{path}"

			fs.stat path, (err, stat) ->
				doDownload url, path, stat.mtime, success, fail
		else
			doDownload url, path, undefined, success, fail

###*
# downloads all of the specified files
# @param {DownloadInput[]} inputs array of the items to be downloaded
# @param {downloadAllFileCallback} done callback invoked when all of the inputs have been downloaded
# @param {eachDoneCallback} eachDone callback invoked after each input is done being downloaded
#
# @callback downloadAllFileCallback
#
# @callback eachDoneCallback
###
downloadAllFiles = (inputs, done, eachDone) ->
	results = []

	createDownloadFileTask = (input, i) ->
		(success) ->
			handleDownloadFileSuccess = () ->
				results[i] = new DownloadResult(input, true)
				eachDone?(results[i], i)
				success?()

			handleDownloadFileFail = (res) ->
				results[i] = new DownloadResult(input, false)
				results[i].statusCode = res.statusCode
				eachDone?(results[i], i)
				success?()

			downloadFile input.url, input.destination, handleDownloadFileSuccess, handleDownloadFileFail

	tasks = (createDownloadFileTask(input, i) for input, i in inputs)
	task_manager.parallel tasks, 25, () ->
		done?(results)

# create a global agent for http
agent = new http.Agent()
agent.maxSockets = 5

module.exports = {
	DownloadInput: DownloadInput
	DownloadResult: DownloadResult
	downloadFile: downloadFile
	downloadAllFiles: downloadAllFiles
}
