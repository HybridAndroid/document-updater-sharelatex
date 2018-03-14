Settings = require('settings-sharelatex')
projectHistoryKeys = Settings.redis?.project_history?.key_schema
rclient = require("redis-sharelatex").createClient(Settings.redis.documentupdater)
logger = require('logger-sharelatex')

module.exports = ProjectHistoryRedisManager =
	queueOps: (project_id, ops..., callback) ->
		rclient.rpush projectHistoryKeys.projectHistoryOps({project_id}), ops..., callback

	queueRenameEntity: (project_id, entity_type, entity_id, user_id, update, callback) ->
		update =
			pathname: update.pathname
			new_pathname: update.newPathname
			meta:
				user_id: user_id
				ts: new Date()
		update[entity_type] = entity_id

		logger.log {project_id, update}, "queue rename operation to project-history"
		jsonUpdate = JSON.stringify(update)

		ProjectHistoryRedisManager.queueOps project_id, jsonUpdate, callback

	queueAddEntity: (project_id, entity_type, entitiy_id, user_id, update, callback = (error) ->) ->
		update =
			pathname: update.pathname
			docLines: update.docLines
			url: update.url
			meta:
				user_id: user_id
				ts: new Date()
		update[entity_type] = entitiy_id

		logger.log {project_id, update}, "queue add operation to project-history"
		jsonUpdate = JSON.stringify(update)

		ProjectHistoryRedisManager.queueOps project_id, jsonUpdate, callback

	queueResyncProjectStructure: (project_id, docs, files, callback) ->
		logger.log {project_id, docs, files}, "queue project structure resync"
		update =
			resyncProjectStructure: { docs, files }
			meta:
				ts: new Date()
		jsonUpdate = JSON.stringify update
		ProjectHistoryRedisManager.queueOps project_id, jsonUpdate, callback

	queueResyncDocContent: (project_id, doc_id, lines, version, pathname, callback) ->
		logger.log {project_id, doc_id, lines, version, pathname}, "queue doc content resync"
		update =
			resyncDocContent:
				content: lines.join("\n"),
				version: version
			path: pathname
			doc: doc_id
			meta:
				ts: new Date()
		jsonUpdate = JSON.stringify update
		ProjectHistoryRedisManager.queueOps project_id, jsonUpdate, callback