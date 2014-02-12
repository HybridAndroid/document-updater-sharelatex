StatsD = require('lynx')
statsd = new StatsD('localhost', 8125, {on_error:->})

buildKey = (key)-> "doc-updater.#{process.env.NODE_ENV}.#{key}"

module.exports =
	set : (key, value, sampleRate = 1)->
		statsd.set buildKey(key), value, sampleRate

	inc : (key, sampleRate = 1)->
		statsd.increment buildKey(key), sampleRate

	Timer : class
		constructor :(key, sampleRate = 1)->
			this.start = new Date()
			this.key = buildKey(key)
		done:->
			timeSpan = new Date - this.start
			statsd.timing(this.key, timeSpan, this.sampleRate)

	gauge : (key, value, sampleRate = 1)->
		statsd.gauge key, value, sampleRate

