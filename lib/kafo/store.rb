require 'yaml'

module Kafo
  class Store
    attr_accessor :data

    def initialize(path=nil)
      @data = {}
      load_path(path) if path
    end

    def load_path(path)
      if File.directory?(path)
        add_dir(path)
      else
        add_file(path)
      end
    end

    def add(data)
      @data.merge!(data)
    end

    def add_dir(path)
      Dir.glob(File.join(path, "*.yaml")).sort.each do |file|
        add_file(file)
      end
    end

    def add_file(file)
      add(YAML.load_file(file))
    end

    def get(key)
      @data[key]
    end
  end
end
