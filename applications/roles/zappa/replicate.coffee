@include = ->

  config = null
  require('ccnq3').config (c) ->
    config = c

  request = require('request').defaults jar:false

  # Start replication from user's database back to a main database.
  @post '/ccnq3/roles/replicate/push/:target': ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    # Validate the target name format.
    # Note: this does not allow all the possible names allowed by CouchDB.
    target = @params.target
    if not target.match /^[_a-z]+$/
      return @send error:'Invalid target'

    ctx =
      name: @session.logged_in
      roles: @session.roles

    replication_req =
      method: 'POST'
      uri: config.users.replicate_uri
      json:
        source: @session.user_database
        target: target
        filter: "#{target}/user_push" # Found in the userdb
        query_params:
          ctx: JSON.stringify ctx

    # Note: This will fail if the user database does not contain
    #       the proper design document for the specified target,
    #       so that restrictions are enforced.
    request replication_req, (e,r,json) =>
      @send json ? error:r.statusCode

  # Start replication from a main database to the user's database
  @post '/ccnq3/roles/replicate/pull/:source': ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    # Validate the source name format.
    # Note: this does not allow all the possible names allowed by CouchDB.
    source = @params.source
    if not source.match /^[_a-z]+$/
      return @send error:'Invalid source'

    ctx =
      name: @session.logged_in
      roles: @session.roles

    replication_req =
      method: 'POST'
      uri: config.users.replicate_uri
      json:
        source: source
        target: @session.user_database
        filter: "replicate/user_pull" # Found in the source db
        query_params:
          ctx: JSON.stringify ctx

    # Note: The source replicate/user_pull filter is responsible for
    #       enforcing access restrictions.
    request replication_req, (e,r,json) =>
      @send json ? error:r.statusCode
