#!/usr/bin/env ruby
# encoding: utf-8

require 'google/apis/admin_directory_v1'

class DirectoryService < Google::Apis::AdminDirectoryV1::DirectoryService

  def initialize
    super
    self.client_options.application_name = "test"
    authorizer = DefaultAuthorizer
    self.authorization = authorizer.authorize

    self
  end
end