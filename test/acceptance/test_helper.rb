require 'test_helper'
require 'fileutils'

tmp = File.expand_path('../../tmp', __FILE__)
Dir.mkdir(tmp) unless File.exist?(tmp)
TMPDIR = Dir.mktmpdir('kafo', tmp)
INSTALLER_HOME = File.join(TMPDIR, 'installer')
KAFO_CONFIG_DIR = File.join(INSTALLER_HOME, 'config', 'installer-scenarios.d')
KAFO_CONFIG = File.join(INSTALLER_HOME, 'config', 'installer-scenarios.d', 'default.yaml')
KAFO_ANSWERS = File.join(INSTALLER_HOME, 'config', 'installer-scenarios.d', 'default-answers.yaml')
TEST_MODULE_PATH = File.join(INSTALLER_HOME, 'modules', 'testing')
MANIFEST_PATH = File.join(TEST_MODULE_PATH, 'manifests')

def run_command(command, opts = {})
  opts = {:be => true, :capture => true, :dir => INSTALLER_HOME}.merge(opts)
  env = {
    'FACTER_kafo_test_tmpdir' => TMPDIR,
  }

  if opts[:be]
    env['BUNDLE_GEMFILE'] = File.join(TMPDIR, 'Gemfile')
    command = "bundle exec #{command}" if opts[:be]
  end

  ret = Dir.chdir(opts[:dir]) do
          if opts[:capture]
            capture_subprocess_io do
              Bundler.with_clean_env { system(env, command) }
            end
          else
            Bundler.with_clean_env { system(env, command) }
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
    run_command 'bundle install --path bundle', :dir => TMPDIR, :be => false
  end
end

def generate_installer
  FileUtils.rm_rf INSTALLER_HOME if File.exist?(INSTALLER_HOME)
  FileUtils.mkdir_p INSTALLER_HOME

  generate_gemfile
  FileUtils.cp Dir["#{TMPDIR}/Gemfile*"], INSTALLER_HOME

  run_command "kafofy -c #{KAFO_CONFIG_DIR}", :dir => TMPDIR
  config = YAML.load_file(KAFO_CONFIG)
  config[:log_dir] = INSTALLER_HOME
  config[:hook_dirs] = ['additional_hooks']
  File.open(KAFO_CONFIG, 'w') { |f| f.write(config.to_yaml) }
  add_hooks
end

def add_manifest(name = 'basic')
  FileUtils.mkdir_p MANIFEST_PATH
  FileUtils.cp File.expand_path("../../fixtures/manifests/#{name}.pp", __FILE__), File.join(MANIFEST_PATH, 'init.pp')
  unless File.exist?(KAFO_ANSWERS) && File.read(KAFO_ANSWERS).include?('testing:')
    File.open(KAFO_ANSWERS, 'a') do |answers|
      answers.write "testing:\n  base_dir: #{INSTALLER_HOME}\n"
    end
  end
end

def add_module_data(name = 'basic')
  FileUtils.mkdir_p TEST_MODULE_PATH
  FileUtils.cp_r File.expand_path("../../fixtures/module_data/#{name}", __FILE__) + '/.', TEST_MODULE_PATH
end

def add_metadata(name = 'basic')
  FileUtils.mkdir_p TEST_MODULE_PATH
  FileUtils.cp File.expand_path("../../fixtures/metadata/#{name}.json", __FILE__), File.join(TEST_MODULE_PATH, 'metadata.json')
end

def add_hooks
  FileUtils.cp_r File.expand_path("../../fixtures/hooks", __FILE__), INSTALLER_HOME
  FileUtils.cp_r File.expand_path("../../fixtures/additional_hooks", __FILE__), INSTALLER_HOME
end
