#!/usr/bin/env ruby
# encoding: utf-8

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'json'

class DefaultAuthorizer
  class << self

    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
    CLIENT_SECRET_ENV_VAR="GDD_GOOGLE_CLIENT_SECRET"
    CLIENT_SECRET_FILE_PATH=File.expand_path("secrets/client_secret.json",GramV1Extractor::ROOT)

    def authorize
      user_id="admin"
      scope = 'https://www.googleapis.com/auth/admin.directory.user'

      authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

      credentials = authorizer.get_credentials(user_id)
      if credentials.nil?
        url = authorizer.get_authorization_url(base_url: OOB_URI )
        puts "Open #{url} in your browser and enter the resulting code:"
        code = gets
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: OOB_URI)
      end

      credentials
    end

    # Set client id if not defined
    # If GDD_CLIENT_SECRET environment variable is set use this value
    # else use JSON file to retrieve client credentials
    def client_id
      @client_id ||= ENV[CLIENT_SECRET_ENV_VAR] ? parse_client_secret_env_variable : parse_client_secret_file
    end

    # Retrieve client credentials from GDD_CLIENT_SECRET and parse it
    # GDD_CLIENT_SECRET should be valid JSON put inside a string
    # ex: "{\"key\":\"value\"}"
    def parse_client_secret_env_variable
      begin
        Google::Auth::ClientId.from_hash(JSON.parse(ENV[CLIENT_SECRET_ENV_VAR]))
      rescue JSON::ParserError => e
        LOGGER.fatal "#{CLIENT_SECRET_ENV_VAR} env variable is not a parsable JSON. Ensure that this is a parsable JSON in a string"
        raise e
      end
    end

    # Retrieve lient credentials from secrets/client_secret.json
    # This JSON file is provided by Google in the developer console
    def parse_client_secret_file
      Google::Auth::ClientId.from_file(CLIENT_SECRET_FILE_PATH)
    end

    # Set token_store if not defined
    def token_store
      @token_store||=Google::Auth::Stores::FileTokenStore.new( :file => File.expand_path("secrets/tokens.yaml",GramV1Extractor::ROOT))
    end

  end
end

