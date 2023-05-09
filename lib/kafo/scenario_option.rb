module Kafo
  # A class containing constants for all scenario options
  class ScenarioOption
    # @group Basic

    # Human readable scenario name
    NAME = :name

    # Description of the installer scenario and its purpose
    DESCRIPTION = :description

    # Path to answer file, if the file does not exist a $pwd/config/answers.yaml is used as a fallback
    ANSWER_FILE = :answer_file

    # The version of the answer file schema being used
    ANSWER_FILE_VERSION = :answer_file_version

    # Enable colors? If you don't touch this, we'll autodetect terminal capabilities
    COLORS = :colors
    # Color scheme, we support :bright and :dark (first is better for white background, dark for black background)
    COLOR_OF_BACKGROUND = :color_of_background

    # @group Logging

    # Destination for the log files
    LOG_DIR = :log_dir
    LOG_NAME = :log_name
    LOG_LEVEL = :log_level
    LOG_OWNER = :log_owner
    LOG_GROUP = :log_group

    # Whether verbose logging is enabled
    VERBOSE = :verbose

    # When verbose logging is enabled, which level (and up) is shown.
    VERBOSE_LOG_LEVEL = :verbose_log_level

    # @group State

    # Custom storage is handy if you use hooks and you must store some
    # configuration which should persist among installer runs. It can be also
    # used for passing value from one hook to another.
    CUSTOM = :custom

    FACTS = :facts

    # @group Advanced

    # Checks, implemented as executable files, are loaded from the listed
    # directories.
    CHECK_DIRS = :check_dirs

    # Hooks in these extra directories will be loaded, by default they are
    # loaded from $installer_dir/hooks/$type when you specify your directory,
    # it will be search for $yourdir/$type/*.rb
    HOOK_DIRS = :hook_dirs

    # Option to load puppet modules from a specific path. Optional and
    # $pwd/modules is used by default, multiple dirs are allowed
    MODULE_DIRS = :module_dirs

    # Kafo has a cache for information parsed from Puppet modules. This
    # determines the location where that information is stored.
    PARSER_CACHE_PATH = :parser_cache_path

    # By default all module parameters must be documented or an error is
    # raised. This can be used to not raise an error when undocumented
    # parameters are found.
    IGNORE_UNDOCUMENTED = :ignore_undocumented

    # Kafo tuning, customization of core functionality

    # An optional mapping of classes
    MAPPING = :mapping
    NO_PREFIX = :no_prefix
    ORDER = :order
    LOW_PRIORITY_MODULES = :low_priority_modules
    HIERA_CONFIG = :hiera_config
    KAFO_MODULES_DIR = :kafo_modules_dir
    CONFIG_HEADER_FILE = :config_header_file
    DONT_SAVE_ANSWERS = :dont_save_answers

    # These options are in DEFAULT but not in kafo.yaml.example

    # Whether the scenario is enabled or not
    ENABLED = :enabled
    STORE_DIR = :store_dir
    INSTALLER_DIR = :installer_dir

    # Puppet modules declare the Puppet version they're compatible with. Kafo
    # implements checks to verify this is correct with the Puppet version
    # that's running. This can be used to bypass the checks
    SKIP_PUPPET_VERSION_CHECK = :skip_puppet_version_check
  end
end
