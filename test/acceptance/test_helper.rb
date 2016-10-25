require 'test_helper'
require 'fileutils'

TMPDIR = File.expand_path('../../tmp', __FILE__)
INSTALLER_HOME = File.join(TMPDIR, 'installer')
KAFO_CONFIG = File.join(INSTALLER_HOME, 'config', 'installer-scenarios.d', 'default.yaml')
KAFO_ANSWERS = File.join(INSTALLER_HOME, 'config', 'installer-scenarios.d', 'default-answers.yaml')

def run_command(command, opts = {})
  opts = {:be => true, :capture => true, :dir => INSTALLER_HOME}.merge(opts)
  command = "bundle exec #{command}" if opts[:be]

  ret = Dir.chdir(opts[:dir]) do
          if opts[:capture]
            capture_subprocess_io do
              Bundler.with_clean_env { system(command) }
            end
          else
            Bundler.with_clean_env { system(command) }
          end
        end
  [$?, *ret]
end

# Creates a Gemfile and Gemfile.lock cached in TMPDIR, to be copied into each
# installer to minimise calls to bundle install
def generate_gemfile
  unless File.exist?(File.join(TMPDIR, 'Gemfile')) && File.exist?(File.join(TMPDIR, 'Gemfile.lock'))
    File.open(File.join(TMPDIR, 'Gemfile'), 'w') do |gemfile|
      kafo_gemfile = File.read(File.expand_path('../../../Gemfile', __FILE__))
      gemfile.write kafo_gemfile.sub(/^gemspec$/, "gem 'kafo', :path => '#{Dir.pwd}'")
    end
    run_command 'bundle install', :dir => TMPDIR, :be => false
  end
end

def generate_installer
  FileUtils.rm_rf INSTALLER_HOME if File.exist?(INSTALLER_HOME)
  FileUtils.mkdir_p INSTALLER_HOME

  generate_gemfile
  FileUtils.cp Dir["#{TMPDIR}/Gemfile*"], INSTALLER_HOME

  run_command 'kafofy'
  config = YAML.load_file(KAFO_CONFIG)
  config[:log_dir] = INSTALLER_HOME
  File.open(KAFO_CONFIG, 'w') { |f| f.write(config.to_yaml) }
end

def add_manifest(name = 'basic')
  manifest_path = File.join(INSTALLER_HOME, 'modules', 'testing', 'manifests')
  FileUtils.mkdir_p manifest_path
  FileUtils.cp File.expand_path("../../fixtures/manifests/#{name}.pp", __FILE__), File.join(manifest_path, 'init.pp')
  unless File.exist?(KAFO_ANSWERS) && File.read(KAFO_ANSWERS).include?('testing:')
    File.open(KAFO_ANSWERS, 'a') do |answers|
      answers.write "testing:\n  base_dir: #{INSTALLER_HOME}\n"
    end
  end
end
