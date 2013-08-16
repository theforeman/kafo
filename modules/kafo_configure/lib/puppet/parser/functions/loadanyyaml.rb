module Puppet::Parser::Functions

  # convert nil values to :undefined recursively
  newfunction(:convert, :type => :rvalue) do |args|
    hash = args[0]
    data = {}

    hash.each do |key, value|
      if value.is_a?(Hash)
        data[key] = function_convert([value])
      else
        data[key] = value.nil? ? :undef : value
      end
    end

    data
  end

  newfunction(:loadanyyaml, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Load a YAML file containing an array, string, or hash, and return the data
    in the corresponding native data type.

    For example:

        $myhash = loadanyyaml('/etc/puppet/data/myhash.yaml')
    ENDHEREDOC

    args.delete_if { |filename| not File.exist? filename }

    if args.length == 0
      raise Puppet::ParseError, ("loadanyyaml(): No files to load")
    end

    function_convert([YAML.load_file(args[0])])
  end

end
