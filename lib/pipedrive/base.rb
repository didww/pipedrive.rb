# frozen_string_literal: true

module Pipedrive
  class Base
    attr_reader :faraday_options, :client_options

    def initialize(*args)
      options = args.extract_options!
      @client_id = options[:client_id]
      @client_secret = options[:client_secret]
      @access_token = options[:access_token]
      @refresh_token = options[:refresh_token]
      @domain_url = options[:domain_url]
      @authentication_callback = options[:authentication_callback]
      @client_options = options[:client_options] || {}
    end

    def make_api_call(*args)
      params = args.extract_options!
      method = args[0]
      raise 'method param missing' unless method.present?

      url = build_url(args, params.delete(:fields_to_select))
      params = params.to_json unless method.to_sym == :get
      params = nil if method.to_sym == :delete
      can_refresh = true
      begin
        res = connection.__send__(method.to_sym, url, params)
      rescue Errno::ETIMEDOUT
        retry
      rescue Faraday::ParsingError
        sleep 5
        retry
      rescue Faraday::UnauthorizedError
        refresh_access_token if can_refresh
        can_refresh = false
        retry
      end

      process_response(res)
    end

    def refresh_access_token
      res = connection.post 'https://oauth.pipedrive.com/oauth/token' do |req|
        req.body = URI.encode_www_form(
          grant_type: 'refresh_token',
          refresh_token: @refresh_token
        )
        req.headers = {
          'Authorization': "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}").strip}",
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      end

      if res.success?
        @access_token = res.body.access_token
        @refresh_token = res.body.refresh_token
        @connection = nil # clear connection in cache to use new tokens
        @authentication_callback.call(res.body) if @authentication_callback.present?
      end
    end

    def build_url(args, fields_to_select = nil)
      url = +"/v1/#{entity_name}"
      url << "/#{args[1]}" if args[1]
      url << ":(#{fields_to_select.join(',')})" if fields_to_select.is_a?(::Array) && fields_to_select.size.positive?
      url
    end

    def process_response(res)
      if res.success?
        data = if res.body.is_a?(::Hashie::Mash)
                 res.body.merge(success: true)
               else
                 ::Hashie::Mash.new(success: true)
               end
        return data
      end
      failed_response(res)
    end

    def failed_response(res)
      failed_res = res.body.merge(success: false, not_authorized: false,
                                  failed: false)
      case res.status
      when 401
        failed_res[:not_authorized] = true
      when 420
        failed_res[:failed] = true
      end
      failed_res
    end

    def entity_name
      class_name = self.class.name.split('::')[-1].downcase.pluralize
      class_names = { 'people' => 'persons', 'calllogs' => 'callLogs' }
      class_names[class_name] || class_name
    end

    def faraday_options
      {
        url: @domain_url,
        headers: {
          authorization: "Bearer #{@access_token}",
          accept:       'application/json',
          content_type: 'application/json',
          user_agent:   ::Pipedrive.user_agent
        }
      }.merge(client_options)
    end


    # This method smells of :reek:TooManyStatements
    # :nodoc
    def connection
      @connection ||= Faraday.new(faraday_options) do |conn|
        conn.request :url_encoded
        conn.response :mashify
        conn.response :json, content_type: /\bjson$/
        conn.use FaradayMiddleware::ParseJson
        conn.response :logger, ::Pipedrive.logger if ::Pipedrive.debug
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
