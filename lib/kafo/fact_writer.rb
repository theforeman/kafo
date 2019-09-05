module Kafo
  class FactWriter
    DATA_FILENAME = 'kafo.yaml'
    WRAPPER_FILENAME = 'kafo.rb'

    def self.write_facts(facts, directory)
      Dir.mkdir(directory)

      # Write a data file containing all the facts encoded as YAML
      File.open(File.join(directory, DATA_FILENAME), 'w') { |f| f.write(YAML.dump(facts)) }

      # Write a Ruby wrapper since only those are executed within puppet
      File.open(File.join(directory, 'kafo.rb'), 'w') { |f| f.write(wrapper) }
    end

    def self.wrapper
      # Ruby 2.0 doesn't have <<~ heredocs
      <<-WRAPPER
      require 'yaml'
      Facter.add(:kafo) { setcode { YAML.load_file(File.join(__dir__, '#{DATA_FILENAME}')) } }
      WRAPPER
    end
  end
end
