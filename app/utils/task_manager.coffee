
module.exports = {

	###*
	# calls each of the tasks given in a sequential order one after the other
	# @param {Function[]} tasks array of tasks to be completed
	# @param {Function} [done] called when all tasks have completed
	###
	series: (tasks, done) ->
		tasksRemaining = tasks.slice()

		processTask = () ->
			if tasksRemaining.length > 0
				thisTask = tasksRemaining[0]
				tasksRemaining = tasksRemaining.slice(1)
				thisTask?(processTask)
			else 
				done?()

		processTask()

	###*
	# calls each of the tasks in parallel in an indeterminant order
	# @param {Function[]} tasks array of tasks to be completed
	# @param {Number} numberOfConsecutive the number of consecutive tasks to be invoked at once
	# @param {Function} [done] called when all tasks have completed
	###
	parallel: (tasks, numberOfConsecutive, done) ->
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
		
}
