###
  Original source: https://raw.github.com/quirkey/action/master/js/sammy.couch.js
  Javascript was identical to sammy.couch-0.1.0 from https://github.com/quirkey/soca/blob/master/lib/soca/templates/js/vendor/sammy.couch-0.1.0.js
  With modifications:
    Added "remove"
    viewDocs should not expect the dbname to be the same as the design document
    Added "changes"
###

sammy_couch = ($, Sammy) ->

  Sammy ?= {}

  Sammy.Couch = (app, dbname) ->

    # set the default dbname from the URL
    dbname = dbname or window.location.pathname.split('/')[1]

    db = ->
      if not dbname
        throw "Please define a db to load from"
      @_db ?= $.couch.db(dbname)

    timestamp = ->
      new Date().getTime()

    @db = db()

    @createModel = (type, options) ->
      default_options =
        defaultDocument: ->
          return {
            type: type,
            updated_at: timestamp()
          }
        errorHandler: (response) ->
          app.trigger 'error.' + type, {error: response}

      options = $.extend default_options, options ? {}

      mergeCallbacks = (callback) ->
        base = {error: options.errorHandler}
        if $.isFunction callback
          $.extend base, {success: callback}
        else
          $.extend base, callback ? {}

      mergeDefaultDocument = (doc) ->
        $.extend {}, options.defaultDocument(), doc

      model =
        timestamp: timestamp

        extend: (obj) ->
          $.extend model, obj

        all: (callback) ->
          app.db.allDocs $.extend mergeCallbacks(callback),
            include_docs: true

        get: (id, options, callback) ->
          if $.isFunction options
            callback = options
            options  = {}
          app.db.openDoc id, $.extend(mergeCallbacks(callback), options)

        create: (doc, callback) ->
          model._save mergeDefaultDocument(doc), callback

        # An application really should only use "create" or "update", never "save".
        _save: (doc, callback) ->
          if $.isFunction model.beforeSave
            doc = model.beforeSave doc
          app.db.saveDoc doc, mergeCallbacks(callback)

        update: (id, doc, callback) ->
          model.get id, (original_doc) ->
            doc = $.extend original_doc, doc
            doc.updated_at = timestamp()
            model._save doc, callback

        remove: (id, doc, callback) ->
          app.db.removeDoc doc, mergeCallbacks(callback)

        view: (name, options, callback) ->
          if $.isFunction options
            callback = options
            options  = {}
          app.db.view name, $.extend(mergeCallbacks(callback), options)

        viewDocs: (name, options, callback) ->
          if $.isFunction options
            callback = options
            options  = {}
          wrapped_callback = (json) ->
            docs = []
            docs.push(row.doc) for row in json.rows
            callback docs
          options = $.extend
            include_docs: true
          , mergeCallbacks(wrapped_callback)
          , options
          app.db.view(name, options)

        ###
          The array of records passed to the callback may contain:
            seq: sequence number
            id: record ID
            changes: [{rev:..},..]
            deleted:  true if record was deleted
        ###
        changes: (options, callback) ->
          if $.isFunction options
            callback = options
            options  = {}
          changes = app.db.changes()
          buffer = ''
          changes.onChange (p) ->
            if p.results?
              try
                callback p.results
              catch error
                console.log "callback failed: #{error}"
          return changes

    this.helpers
      db: db()

sammy_couch jQuery, window.Sammy
