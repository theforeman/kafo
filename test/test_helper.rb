require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'minitest/spec'

require 'manifest_file_factory'
require 'kafo'

require 'ostruct'
KafoConfigure.root_dir = File.dirname(__FILE__)
KafoConfigure.config = OpenStruct.new(app: { mapping: [],
                                             password: 'secret'})
