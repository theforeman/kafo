# Find default values for variables specified as args
#
module Puppet::Parser::Functions
  newfunction(:dump_values) do |args|
    options = []
    options<< false if Puppet::PUPPETVERSION.start_with?('2.6')
    data = args.map do |arg|
      found_value = lookupvar(arg, *options)
      [arg, found_value]
    end
    data = Hash[data]

    dump_dir = lookupvar('temp_dir')
    file_name = "#{dump_dir}/default_values.yaml"

    File.open(file_name, File::WRONLY|File::CREAT|File::EXCL, 0600) { |file| file.write(YAML.dump(data)) }
  end
end
