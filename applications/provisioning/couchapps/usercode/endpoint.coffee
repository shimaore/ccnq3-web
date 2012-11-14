do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  ## Endpoint

  endpoint_selector = '#endpoint_record'

  endpoint_tpl = $.compile_template ->
    form id:'endpoint_record', method:'post', action:'#/endpoint', class:'validate', ->

      if not @user_ip?
        @username = @endpoint

      # Static
      textbox
        id:'user_ip'
        title:'Static IP Address'
        class:'ip'
        value: @user_ip

      textbox
        id:'user_port'
        title:'Static Port'
        class:'integer'
        value:@user_port

      # Register
      textbox
        id:'username'
        title:'Register Username'
        class:'email'   # in the form user@domain
        value: @username

      textbox
        id:'password'
        title:'Register Password'
        class:'text'
        value:@password

      textbox
        id:'account'
        title:'Account'
        class:'required text'
        value:@account

      textbox
        id:'location'
        title:'Location'
        class:'text'
        value:@location

      textbox
        id:'outbound_route'
        title:'Outbound Route'
        class:'integer'
        value:@outbound_route

      checkbox
        id:'disabled'
        title:'Blacklist IP'
        value:@disabled

      checkbox
        id:'dst_disabled'
        title:'Block inbound calls'
        value:@dst_disabled

      checkbox
        id:'src_disabled'
        title:'Block outbound calls'
        value:@src_disabled

      checkbox
        id:'strip_digit'
        title:'Remove first digit'
        value:@strip_digit

      checkbox
        id:'user_force_mp'
        title:'Attempt to force media_proxy insertion'
        value:@user_force_mp

      textbox
        id:'user_srv'
        title:'Final user domain (compatible with via SBC)'
        class:'domain'
        value:@user_srv

      textbox
        id:'user_via'
        title:'Route via this SBC'
        class:'domain'
        value:@user_via

      textbox
        id:'dialog_timer'
        title:'Maximum outbound call duration (sec)'
        class:'integer'
        value:@dialog_timer

      checkbox
        id:'check_from'
        title:'Verify calling number'
        value:@check_from

      textbox
        id:'sbc'
        title:'Outbound SBC type'
        class:'integer'
        value:@sbc

      textbox
        id:'inbound_sbc'
        title:'Inbound SBC type'
        class:'integer'
        value:@inbound_sbc

       textbox
        id:'emergency_domain'
        title:'Emergency domain'
        class:'text'
        value:@emergency_domain

      # Exclude obsolete "dest_domain" and "allow_onnet"

      input type:'submit'

    form method:'delete', action:'#/endpoint', ->
      input type:'submit', value:'Delete'

    coffeescript ->
      $('#endpoint_record').delegate '#user_ip', 'change', ->
        if $(@).val()?
          $('#username').disable()
          $('#password').disable()
          $('#user_port').enable()
        else
          $('#username').enable()
          $('#password').enable()
          $('#user_port').disable()

    $('form.validate').validate()

  $(document).ready ->

    app = $.sammy container, ->

      endpoint = @createModel 'endpoint'

      endpoint.extend
        beforeSave: (doc) ->

          if doc.user_ip?
            doc.endpoint = doc.user_ip
          else
            doc.endpoint = doc.username

          delete doc.username
          doc._id = make_id 'endpoint', doc.endpoint

          if doc.password?
            [user,domain] = doc.endpoint.split /@/
            challenge = domain
            doc.ha1 = hex_md5 [user,challenge,doc.password].join ':'
            doc.ha1b = hex_md5 [doc.endpoint,challenge,doc.password].join(':')
          else
            delete doc.ha1
            delete doc.ha1b

          return doc

      @bind 'error.endpoint', (notice) ->
        console.log "Endpoint error: #{notice.error}"

      @get '#/endpoint', ->
        @swap endpoint_tpl

      @get '#/endpoint/:id', ->
        if not @params.id?
          @swap host_tpl
          return

        @send endpoint.get, @params.id,
          success: (doc) =>
            @swap endpoint_tpl doc
            $(endpoint_selector).data 'doc', doc
          error: =>
            doc = {}
            @swap endpoint_tpl
            $(endpoint_selector).data 'doc', doc

      @bind 'save-endpoint', (event) ->

        doc = $(endpoint_selector).data('doc') ? {}
        $.extend doc, $(endpoint_selector).toDeepJson()

        push = ->
          $.ccnq3.push_document 'provisioning'

        if doc._rev?
          endpoint.update doc._id, doc,
            success: (resp) ->
              endpoint.get resp.id, (doc)->
                $(endpoint_selector).data 'doc', doc
                do push
        else
          endpoint.create doc,
            success: (resp) ->
              endpoint.get resp.id, (doc)->
                $(endpoint_selector).data 'doc', doc
                do push

      @post '#/endpoint', ->
        form_is_valid = $(endpoint_selector).valid()

        if form_is_valid
          @trigger 'save-endpoint'

        return

      @del '#/endpoint', ->

        doc = $(endpoint_selector).data('doc') ? {}

        @send endpoint.remove, doc, ->
          $('#endpoint_form').data 'doc', {}

        return

  Inbox.register 'endpoint',

    list: (doc) ->
      return "Endpoint #{doc.endpoint}"

    form: (doc) ->
      id = encodeURIComponent doc._id
      """
        <p><a href="#/endpoint/#{id}">Edit</a></p>
      """

  ## Number

  number_selector = '#number_record'

  number_tpl = $.compile_template ->
    form id:'number_record', method:'post', action:'#/number', class:'validate', ->

      textbox
        id:'number'
        title:'Number (global number: E.164-without-plus; local number: local_number@number_domain)'
        class:'text'
        value: @number

      textbox
        id:'account'
        title:'Account'
        class:'required text'
        value:@account

      textbox
        id:'inbound_uri'
        title:'Inbound URI (global)'
        class:'uri'
        value:@inbound_uri

      textbox
        id:'outbound_route'
        title:'Outbound Route (global)'
        class:'integer'
        value: @outbound_route

      textbox
        id:'registrant_password'
        title:'Registrant Password (global)'
        class:'text'
        value:@registrant_password

      ###
      # registrant_host actually might be string or array FIXME
      textbox
        id:'registrant_host'
        title:'Registrant Host (global)'
        class:'text'
        value:@registrant_host
      ###

      textbox
        id:'endpoint'
        title:'Endpoint (local)'
        class:'text'
        value:@endpoint

      textbox
        id:'location'
        title:'Location (local)'
        class:'text'
        value:@location

      textbox
        id:'cfa'
        title:'CFA (local)'
        class:'uri'
        value:@cfa

      textbox
        id:'cfb'
        title:'CFB (local)'
        class:'uri'
        value:@cfb

      textbox
        id:'cfda'
        title:'CFDA (local)'
        class:'uri'
        value:@cfda

      textbox
        id:'cfnr'
        title:'CFNR (local)'
        class:'uri'
        value:@cfnr

      textbox
        id:'dialog_timer'
        title:'Maximum Call Duration'
        class:'integer'
        value:@dialog_timer

      textbox
        id:'inv_timer'
        title:'Maximum Ringback Duration'
        class:'integer'
        value:@inv_timer

      checkbox
        id:'privacy'
        title:'Privacy'
        value:@privacy

      textbox
        id:'asserted_number'
        title:'Asserted Number'
        class:'text'
        value:@asserted_number

      checkbox
        id:'reject_anonymous'
        title:'Reject anonymous (inbound)'
        value:@reject_anonymous

      checkbox
        id:'use_blacklist'
        title:'Use blacklist (inbound)'
        value:@use_blacklist

      checkbox
        id:'use_whitelist'
        title:'Use whitelist (inbound)'
        value:@use_whitelist

      textbox
        id:'user_database'
        title:'User Database (voicemail)'
        class:'text'
        value:@user_database

      textbox
        id:'voicemail_sender'
        title:'Notification Sender (voicemail)'
        class:'email'
        value:@voicemail_sender

      input type:'submit'

    form method:'delete', action:'#/number', ->
      input type:'submit', value:'Delete'

    $('form.validate').validate()

  $(document).ready ->

    app = $.sammy container, ->

      number = @createModel 'number'

      number.extend
        beforeSave: (doc) ->

          doc._id = make_id 'number', doc.number

          return doc

      @bind 'error.number', (notice) ->
        console.log "Number error: #{notice.error}"

      @get '#/number', ->
        @swap number_tpl

      @get '#/number/:id', ->
        if not @params.id?
          @swap host_tpl
          return

        @send number.get, @params.id,
          success: (doc) =>
            @swap number_tpl doc
            $(number_selector).data 'doc', doc
          error: =>
            doc = {}
            @swap number_tpl
            $(number_selector).data 'doc', doc

      @bind 'save-number', (event) ->

        doc = $(number_selector).data('doc') ? {}
        $.extend doc, $(number_selector).toDeepJson()

        push = ->
          $.ccnq3.push_document 'provisioning'

        if doc._rev?
          number.update doc._id, doc,
            success: (resp) ->
              number.get resp.id, (doc)->
                $(number_selector).data 'doc', doc
                do push
        else
          number.create doc,
            success: (resp) ->
              number.get resp.id, (doc)->
                $(number_selector).data 'doc', doc
                do push

      @post '#/number', ->
        form_is_valid = $(number_selector).valid()

        if form_is_valid
          @trigger 'save-number'

        return

      @del '#/number', ->

        doc = $(number_selector).data('doc') ? {}

        @send number.remove, doc, ->
          $('#number_form').data 'doc', {}

        return

  Inbox.register 'number',

    list: (doc) ->
      return "Number #{doc.number}"

    form: (doc) ->
      id = encodeURIComponent doc._id
      """
        <p><a href="#/number/#{id}">Edit</a></p>
      """
