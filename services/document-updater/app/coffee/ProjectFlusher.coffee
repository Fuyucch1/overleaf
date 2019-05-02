request = require("request")
Settings = require('settings-sharelatex')
RedisManager = require("./RedisManager")
rclient = RedisManager.rclient
docUpdaterKeys = Settings.redis.documentupdater.key_schema
async = require("async")
ProjectManager = require("./ProjectManager")
_ = require("lodash")

ProjectFlusher = 

	# iterate over keys asynchronously using redis scan (non-blocking)
	# handle all the cluster nodes or single redis server
	_getKeys: (pattern, limit, callback) ->
		nodes = rclient.nodes?('master') || [ rclient ];
		doKeyLookupForNode = (node, cb) ->
			ProjectFlusher._getKeysFromNode node, pattern, limit, cb
		async.concatSeries nodes, doKeyLookupForNode, callback

	_getKeysFromNode: (node, pattern, limit = 1000, callback) ->
		cursor = 0  # redis iterator
		keySet = {} # use hash to avoid duplicate results
		batchSize = if limit? then Math.min(limit, 1000) else 1000
		# scan over all keys looking for pattern
		doIteration = (cb) ->
			node.scan cursor, "MATCH", pattern, "COUNT", batchSize, (error, reply) ->
				return callback(error) if error?
				[cursor, keys] = reply
				for key in keys
					keySet[key] = true
				keys = Object.keys(keySet)
				noResults = cursor == "0" # redis returns string results not numeric
				limitReached = (limit? && keys.length >= limit)
				if noResults || limitReached
					return callback(null, keys)
				else
					setTimeout doIteration, 10 # avoid hitting redis too hard
		doIteration()

	# extract ids from keys like DocsWithHistoryOps:57fd0b1f53a8396d22b2c24b
	# or docsInProject:{57fd0b1f53a8396d22b2c24b} (for redis cluster)
	_extractIds: (keyList) ->
		ids = for key in keyList
			m = key.match(/:\{?([0-9a-f]{24})\}?/) # extract object id
			m[1]
		return ids

	flushAllProjects: (limit, concurrency = 5, callback)->
		ProjectFlusher._getKeys docUpdaterKeys.docsInProject({project_id:"*"}), limit, (error, project_keys) ->
			if error?
				logger.err err:error, "error getting keys for flushing"
				return callback(error)
			project_ids = ProjectFlusher._extractIds(project_keys)
			jobs = _.map project_ids, (project_id)->
				return (cb)->
					ProjectManager.flushAndDeleteProjectWithLocks project_id, cb
			async.parallelLimit jobs, concurrency, (error)->
				return callback(error, project_ids)


module.exports = ProjectFlusher