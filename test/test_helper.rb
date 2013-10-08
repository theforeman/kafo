require 'minitest/autorun'
require 'minitest/spec'
require 'kafo'

require 'ostruct'
KafoConfigure.root_dir = File.dirname(__FILE__)
KafoConfigure.config = OpenStruct.new(app: { mapping: [],
                                             password: 'secret'})
