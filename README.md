# Kafo

A puppet based installer and configurer (not-only) for Foreman and Katello
projects. Kafo is a ruby gem that allows you to create fancy user interfaces for
puppet modules. It's some kind of a nice frontend to a

```bash
echo "include some_modules" | puppet apply
```
## Why should I care?

Suppose you work on software which you want to distribute to a machine in an
infrastructure managed by puppet. You write a puppet module for your app.
But now you also want to be able to distribute your app to a machine outside of
your puppet infrastructure (e.g. install it to your clients) or you want to install
it in order to create a puppet infrastructure itself (e.g. foreman or
foreman-proxy).

With kafo you can reuse your puppet modules for creating an installer.
Even better: After the installation you can easily modify your configuration.
All using the very same puppet modules.

With your installer you can also provide multiple configuration files defining
different installation scenarios.

## What does it do, how does it work?

Kafo reads a config file to find out which modules it should use. Then it
loads parameters from puppet manifests and gives you different ways to customize them.

There are three options how you can set parameters. You can
 * predefine them in the configuration file
 * specify them as CLI arguments
 * you can use the interactive mode which will ask you for all required parameters

Note that your answers (gathered from any mode) are automatically saved for the next run
so you don't have to specify them again. Kafo also supports default values for
parameters so you can set only those you want to change. You can also combine
all modes to create an answer file with default values easily
and then use it for unattended installations.

## How do I use it?

First install the kafo gem.

Using bundler - add kafo gem to your Gemfile and run
```bash
bundle install
```

or without bundler
```bash
gem install kafo
```

Create a directory for your installer. Let's say we want to create a
foreman-installer.

```bash
mkdir foreman-installer
cd foreman-installer
```

Now we run ```kafofy``` script which will prepare the directory structure and
optionally create a bin script according to the first parameter.

```bash
kafofy -n foreman-installer -s foreman
```

You can see that it created a modules directory where your puppet modules
should live. It also created config and bin directories and the default installation
scenario config file. If you specify the argument ```--name``` (or -n for short,
foreman-installer in this case) a script in the "bin" directory with this name will be created.

It's the script you can use to run the installer. If you did not specify any
arguments you can run your installer by `kafo-configure` which is the default.
All configuration related files are to be found in the config directory.

You can supply custom location for your scenario configuration and answer files
and change configuration and answer files names using options:
```console
$ kafofy --help
Usage: kafofy [options]
    -c, --config_dir DIR            location of the scenarios configuration directory [./config/installer-scenarios.d/]
    -s, --scenario SCENARIO          scenario file name (without extension) [default]
    -a, --answer_file ANSWERS        answer file file name (without extension) [default-answers]
    -n, --name NAME                  installer name [kafo-configure]
```

The scenario configuration file will be created by a default template. It's the configuration
of your installer (so you can setup the log level, path to puppet modules etc).
On the other hand, the answer file must be created manually. Answer files define
which modules should be used and hold all values for the puppet class parameters.

To add another installation scenario just run kafofy again:
```bash
kafofy -n foreman-installer -s foreman-proxy
```
it will create new configuration template for you. You can check available scenarios with:
```bash
$ bin/foreman-installer --list-scenarios
Available scenarios
  foreman-proxy (use: --scenario foreman-proxy)
  foreman (use: --scenario foreman)
```

Let's see for example how to install foreman:
```bash
cd foreman-installer/modules
git clone https://github.com/theforeman/puppet-foreman/ foreman
```
You must also download any dependant modules.
Then you need to tell kafo it's going to use the foreman module.
```bash
cd ..
echo "foreman: true" > config/installer-scenarios.d/foreman-answers.yaml
```

Alternatively you can use the librarian-puppet project to manage all dependencies for you.
You just create a Puppetfile and call librarian to install your modules. See
https://github.com/rodjek/librarian-puppet for more details.

When you have your modules in-place, fire the installer with -h as argument
and specify the foreman scenario to let installer find the right modules
```bash
bin/foreman-installer -S foreman -h
```

This will show you all the possible arguments you can pass to kafo. Note that underscored
puppet parameters are automatically converted to dashed arguments. You can
also see a documentation extracted from the foreman puppet module and a default
value.

Now run it without the -h argument. It will print you the puppet apply command
to execute. This will be automatized later. Once the installer is run the scenario
is remembered and it is not necessary to specify it again.
Look at config/answers.yaml, it was populated with default values.
To change those options you can use arguments like this

```bash
bin/foreman-installer --foreman-enc=false --foreman-db-type=sqlite
```

or you can run it in interactive mode

```bash
bin/foreman-installer --interactive
```

Also every change made to the `config/installer-scenarios.d/foreman-answers.yaml` persists
and becomes the new default value for the next run.

As you may have noticed there are several ways how to specify arguments. Here's the list:
(the lower the item is in this list the higher precedence it has):
  * default values from puppet modules
  * values from answers.yaml
  * values specified on CLI
  * interactive mode arguments

## Answer File Schema

The answer file schema can be described using Puppet types as such:

```
Hash[
  String $puppet_class => Hash[
    String $parameter => Enum[true, false, Hash[String, Variant[String, Boolean, Integer, Array, Hash]]]
  ]
]
```

An example of each available option:

```
class_a: true
class_b: false
class_c: {}
class_d:
  key: value
  key2: 'value'
  key3: false
  key4: 1
  key5: ['a', 'b']
```

## Requirements

Kafo is supported with Puppet versions 4.9+, 5 and 6. Puppet may be installed
as a gem (add it to Gemfile) or through a package, including official AIO
packages.

## How do I report bugs or contribute?

You can find our redmine issue tracker [here](https://projects.theforeman.org/projects/kafo),
you can use your github account for logging in. When reporting new issues please
don't forget to specify your:
  * puppet version
  * installation options (GEM/RPM/DEB)
  * error trace (if any) or log with debug level
  * reproducing steps

Since Kafo is a side project of Foreman you can use its IRC channels to
contact us on freenode. #theforeman is the channel for generic discussions
and #theforeman-dev is reserved only for technical topics. Likewise you can use the Foreman
mailing lists on googlegroups. For more information see [this page](https://theforeman.org/support.html)

Patches are always welcome. You can use instructions for Foreman, just
substitute Foreman with Kafo. More details are [here](https://projects.theforeman.org/projects/foreman/wiki/Contribute#New-Way-github)

# Advanced topics

## Testing aka noop etc

Since you'll probably want to tweak your installer before you run it, you may find the
```--noop``` argument handy (-n for short). This will run puppet in
noop so no change will be done to your system. The default value here is set to
false!

Sometimes you may want kafo not to store answers from the current run. You can
disable saving answers by passing a ```--dont-save-answers``` argument.

Note that running ```--noop``` implies ```--dont-save-answers```.

## Executing Puppet with multiple versions

Kafo calls the `puppet` binary during an installer run to both compute default
parameter values and perform the actual installer changes. This relies on
`puppet` being in the PATH environment variable or as fallback, in
`/opt/puppetlabs/bin`.

When using Puppet via a Gemfile, Bundler should set up PATH to point at the
gem version. If using a system/packaged version, it will typically find and
execute /usr/bin/puppet from the regular PATH.

When using an AIO/PC1 packaged version of Puppet, other versions of Puppet from
PATH will be preferred if they exist, so they should either be removed or PATH
set to prefer /opt/puppetlabs/bin, i.e. `export PATH=/opt/puppetlabs/bin:$PATH`.
Debug logs from Kafo should indicate the full path of the binary used.

Note that Kafo parsers supports specific versions of Puppet, and may require
extra modules (such as puppet-strings on Puppet 4+) to parse manifests.

## Parameters prefixes

As a default every module parameter is prefixed by the module name.
If you use just one module it's probably not necessary and you
can disable this behavior in config/kafo.yaml. Just enable the following option
```yaml
:no_prefix: true
```
## Scenarios

With your installer you can provide multiple configuration files aka. scenarios.
Every scenario has its own answer file to store the scenario settings.
The files are kept in `installer-scenarios.d/` directory.

### Using scenarios

To list scenarios available on your system
```bash
foreman-installer --list-scenarios
```

The installer needs to know the configuration even for such a basic operation
as printing help is because it contains basic settings and defines where
to look for module parameters. There are multiple ways how the installer can select the scenario:
  * from a command line argument `-S` or `--scenario`
```bash
  foreman-installer --scenario foreman -h
   ...
```
  * by user selection in interractive mode (`-i` or `--interractive`)
```bash
  foreman-installer -i

  Select installation scenario

  Please select one of the pre-set installation scenarios. You can customize your installtion later during the installtion.

  Available actions:
  1. Foreman: Basic and most generic installation of Foreman
  2. Foreman Proxy: Install Foreman proxy without Foreman
  3. Cancel Installation
  Your choice:
```
  * automatically if there is only one scenario available
  * automatically if installer was ran already with scenario selected

### Re-installing with different scenario

Lets assume you have already completed installation with one scenario (e.g. smart-proxy).
Now you want to reinstall or upgrade with different scenario (e.g. foreman). This is tricky
situation and may end with unpredictable results so you should double check
if the scenario and the puppet modules used in it support such kind of change.

Installer tries to prevent unintentional change of a scenario and interrupts when such situation is detected:
```bash
  foreman-installer -S foreman-installer
  ERROR: You are trying to replace existing installation with different scenario. This may lead to unpredictable states. Use --force to override. You can use --compare-scenarios to see the differences
```

To avoid losing some configuration values installer can detect differences between answer files of the two scenarios.
To display them use either interactive mode (`-i`) or `--compare-scenarios` flag:
```bash
  foreman-installer --compare-scenarios --scenario foreman
  Scenarios are being compared, that may take a while...

  Values from previous installation that will be added by installer:
    foreman_proxy::http_port: 8000 -> 8080

  Values from previous installation that will be lost by scenario change:
    foreman_proxy::plugin::abrt::enabled: true
    ...
```

It may take some time as the installer has to evaluate default values for both scenarios. As a result it prints two lists.
 - __Values from previous installation that will be added by installer:__ - in this list are options present in both scenarios but having different default values.
   The only item from the example says that the default value for the new scenario is '8000' while the value for currently intalled scenario is '8080'.
   When the new scenario is used the installer tries to keep the customized values from current installation and thus will use the `8080` value
 - __Values from previous installation that will be lost by scenario change:__ - this list contains options that are part of current installation
   and are missing from the new scenario. Most of the items are options from puppet modules that are disabled in the new scenario by default but were enabled
   in the old one.

If you are sure you want to proceed use `--force` to run the installation. Installer will replace
the default values with values from the previous installation where possible as was indicated in the `--compare-scenario` output.

### Adding scenario

You can add new scenario using kafofy as it was explained earlier or by creating
config and answer file in the `installer-scenarios.d/` directory.
[Template](https://github.com/theforeman/kafo/blob/master/config/kafo.yaml.example)
provided by Kafo can be used and customized to satisfy your needs
```bash
  cp `gem content kafo|grep "kafo.yaml.example"` <config>/installer-scenarios.d/new-scenario.yaml
  touch <config>/installer-scenarios.d/new-scenario-answers.yaml
```

### Scenario as an installer plugin

Scenarios were designed to make it possible to package them separately as optional installer extension.
Config files are located in separate directory which makes packaging of additional scenarios easy.
Configuration of paths to modules, checks and hooks accepts multiple directories
so it is possible to bundle your scenario with additional modules, hooks and checks.

### Updating scenarios

As your project grows you may need to change your installer modules or add new ones. To make upgrades of existing installations easier
Kafo has support for scenario migrations. Migrations are ruby scripts similar to hooks and are located
in `<config>/installer-scenarios.d/your-scenario.migrations/` so each scenario has its own set of independent migrations.
During its initialization the installer checks for migrations that were not applied yet. It happens exactly between execution of `pre-migrations` and `boot` hooks.
The installer stores names of applied migrations in `<config>/installer-scenarios.d/your-scenario.migrations/.applied` to avoid runnig the migrations multiple times.
It is recommended to prefix the migration names with `date +%y%m%d%H%M%S` to avoid migration ordering issues.

In a migration you can modify the scenario configuration as well as the answer file. The changed configs are stored immediately after all the migrations were applied.
If you just want to apply the migrations you can use `--migrations-only` switch.
Note that `--noop` and `--dont-save-answers` has no effect on migrations.

Sample migration adding new module could look like as follows:

```bash
  cat <<EOF > "/etc/foreman/installer-scenarios.d/foreman-installer.migrations/`date +%y%m%d%H%M%S`-gutterball.rb"
  scenario[:mapping]['katello::plugin::gutterball'] = {
      :dir_name => 'katello',
      :manifest_name => 'plugin/gutterball'
  }
  answers['katello::plugin::gutterball'] = true
  EOF
```

The migration can also call `facts`, which returns a hash of symbol fact names to values (from
Facter), to help determine new parameter values.

```ruby
answers['module']['foo'] = 'bar' if facts[:osfamily] == 'Debian'
```

### Enabling/disabling scenarios

Scenarios that are deprecated or wanted to be hidden on the system can be disabled with:

```bash
  foreman-installer --disable-scenario deprecated-scenario
  Scenario deprecated-scenario was disabled.
```
The disabled scenario is not shown in the scenario list and is prevented from being installed.
It is not deleted from the file system however so the custom values in the answer file are preserved
and e.g. migration to new scenario is still possible.

Disabled scenario can be enabled back again with `foreman-installer --enable-scenario SCENARIO`.

## Store

Kafo features simple key value store that can be used to ship data with the installer.

The data are loaded from yaml files located in `store.d` directory that is either specified in
the scenario config's `store_dir:` or on same directory
level as configuration directory containing the scenarios. The files are loaded in
alphabetical order and the data are merged in that order.

The store is read-only during the run and the content can be influenced only by adding
new files into the `store.d` directory (e.g. from installer plugins)

## Documentation

Every parameter that can be set by kafo *must* be documented. This means that
you must add documentation to your puppet class in init.pp. It's basically a
rdoc formatted documentation that must be above the class definitions. There can
be no space between the doc block and the class definition.

In case of emergency, it's still possible to use
`--ignore-undocumented` option, but in general it's not recommended to override it.

Example:
```puppet
# Manage your foreman server
#
# This class ...
# ... does what it does.
#
# === Parameters:
#
# $foreman_url::            URL on which foreman is going to run
#
# $enc::                    Should foreman act as an external node classifier (manage puppet class
#                           assignments)
#
class foreman (
  String $foreman_url = $foreman::params::foreman_url,
  Boolean $enc        = $foreman::params::enc
) {
  class { 'foreman::install': }
}
```

You can separate your parameters into groups like this.

Example - separating parameters into groups:
```puppet
# Manage your foreman server
#
# === Parameters:
#
# $foreman_url::            URL on which foreman is going to run
#
# === Advanced parameters:
#
# $foreman_port::           Foreman listens on this port
#
# ==== MySQL:
#
# $mysql_host::             MySQL server address
```

When you run the installer with the ```--help``` argument it displays only
parameters specified in the ```=== Parameters:``` group. If you don't specify
any group all parameters will be considered as basic and will be displayed.

If you run the installer with ```--full-help``` you'll receive help for all
parameters divided into groups. Note that only headers that include word
parameters are considered as parameter groups. Other headers are ignored.
Also note that you can nest parameter groups and the child has precedence.
Help output does not take header level into account though.

So in the previous example, each parameter would be printed in one group even
though MySQL is a child of Advanced parameter. All groups in help would be
prefixed with a second level (==). The first level is always a module to which
the particular parameter belongs.

## Argument types

The data type will be read from the parameter list and defaults to Puppet's
[Any](https://docs.puppet.com/puppet/latest/reference/lang_data_abstract.html#any)
data type, which Kafo handles as a basic string with no validation.

If more specific data types, such as `Optional[Array[2]]` or similar are
given in the [parameter list](https://docs.puppet.com/puppet/4.5/reference/lang_data_type.html#usage)
then Kafo will parse and validate parameters values according to the
specification.

```puppet
class example (
  Boolean $param = false
) {
```

Note that all arguments that are nil (have no value in answers.yaml or you
set them UNDEF (see below)) are translated to ```undef``` in puppet.

If your module declares its own types, you can add new corresponding subclasses
of DataType which implement validation and typecasting. This can be added to a
`boot` hook by calling:

    Kafo::DataType.register_type('YourType', Kafo::DataType::YourType)

## Array arguments

Some arguments may be Arrays. If you want to specify array values you can
specify CLI argument multiple times e.g.
```bash
bin/foreman-installer --puppetmaster-environments=development --puppetmaster-environments=production
```

In interactive mode you'll be prompted for another value until you specify
blank line.

## Hash arguments

You can use a Hash value like an Array. It's also a multivalue type but
you have to specify a key:value pair like in the following example.
```bash
bin/foreman-installer --puppet-server-git-branch-map=master:some --puppet-server-git-branch-map=development:another
```

The same applies to the interactive mode, you enter each pair on separate lines
just like with an Array, the only difference is that the line must be formatted
as key:value.

When parsing the value, the first colon divides key and value. All other
colons are ignored.

## Default values

Default values for parameters are read from the class definitions in the
manifests. If values are given inline then these will be stored by Kafo as the
initial value of the parameter (unless set in the answers file or later changed
by the user), e.g.

```puppet
class foreman(
  $foreman_url = 'https://example.com'
) {
```

If the "params" pattern is used, where the default parameter values are defined
in another class then Kafo will attempt to retrieve them by running Puppet,
using `include` on the params class and then getting the variable value. This
will retrieve default values set by conditionals correctly, e.g.

```puppet
class foreman(
  $foreman_url = $::foreman::params::foreman_url,
) inherits foreman::params {
```

```puppet
class foreman::params {
  $foreman_url = 'https://example.com'
}
```

If no inline default is given in the manifest, then Kafo will attempt to look
up a default value using [data stored in the
module](https://docs.puppet.com/puppet/latest/lookup_quick_module.html). This
can be specified with Hiera data files (or even a data function) in the module
under `data/`.

## Resetting an argument

Existing stored parameters can be reset back to their default value from the
command line or interactive mode.  This deletes the stored value in the answers
file and stores the default from the Puppet manifest in its place.

The default value is the value set in, or computed by the Puppet params
manifest. This will _not_ reset to any defaults specified in the answers file
before running the Kafo-based installer, they are not kept.

Using the CLI, a --reset option is available for every parameter, e.g.

```bash
bin/foreman-installer --reset-puppet-server-git-branch-map
```

The parameter can also be reset to the default in interactive mode, via the
reset parameters sub-menu under each module.

## Grouping in interactive mode

If your module has too many parameters you may find the grouping feature useful.
Every block in your documentation (prefixed by header) forms a group. Unlike for
help, all blocks are used in interactive mode. Suppose you have the following
example:

```puppet
# Testing class
#
# == Parameters:
#
# $one::    number one
#
# == Advanced parameters:
#
# $two::    number two
#
# === Advanced A:
#
# $two_a::  2_a
#
# === Advanced 2_b
#
# $two_b::  2_b
#
# == Extra parameters:
#
# $three::  number three
```

When you enter the Testing class module in interactive mode you can see parameters
from the Basic group and options to configure parameters which belong to the rest
of groups on same level, in this case Advanced and Extra parameters.

```
Module foreman configuration
1. Enable/disable foreman module, current value: true
2. Set one, current value: '1'
3. Configure Advanced parameters
4. Configure Extra parameters
5. Back to main menu
```

When you enter Extra parameters, you see only $three and an option to get back
to the parent. In Advanced you can see $two and two more subgroups - Advanced A and
Advanced B. When you enter these subgroups, you can again see their parameters.
Nesting is unlimited. Also there's no naming rule. Just notice that
the main group must be called `Parameters` and it's parameters are always
displayed on first level of the module configuration.

```
Group Extra parameters (of module foreman)
1. Set two_b, current value: '2b'
2. Back to parent menu
```

If there's no primary group a new one is created for you and it does not have
any parameter. This means when a user enters the module configuration he or she will
see only subgroups in the menu (no parameters until a particular subgroup is entered).
If there is no group in the documentation a new primary group is created and it
holds all module parameters (there are no subgroups in the module configuration).

## Conditional parameters in interactive mode

You can also define conditions to parameters and their groups. These conditions
are evaluated in interactive mode and are based on the results which are then displayed
to the user. You can use this for example to hide mysql_* parameters when
$db_type is not set 'mysql'. Let's look at following example

```puppet
# Testing class
#
# == Parameters:
#
# $use_db::                  use database?
#
# == Database parameters:    condition: $use_db
#
# $database_type::           mysql/sqlite
#
# === MySQL:                 condition: $database_type == 'mysql'
#
# $remote::                  use remote connection
# $host                      server to connect to
#                            condition: $remote
# $socket                    server to connect to
#                            condition: !$remote
```

Here you can see we defined several conditions on the group and parameter level.
You can write a condition in ruby. All dollar-prefixed words will be
substituted with the value of the particular puppet parameter.

Note that conditions are combined using ```&&``` when you nest them. So these
are facts based on example:

* $database_type, $remote, $host, $socket are displayed only when $use_db is set to true
* $remote, $host, $socket are displayed only when $database_type is set to 'mysql'
* $host is displayed only if $remote is set to true, $socket is displayed otherwise

Here's explanation how conditions are constructed

```
-----------------------------------------------------------------------------
| parameter name | resulting condition                                      |
-----------------------------------------------------------------------------
| $use_db        | true                                                     |
| $database_type | true && $use_db                                          |
| $remote        | true && $use_db && $database_type == 'mysql'             |
| $host          | true && $use_db && $database_type == 'mysql' && $remote  |
| $socket        | true && $use_db && $database_type == 'mysql' && !$remote |
-----------------------------------------------------------------------------
```
As already said you can use whatever ruby code, so you could leverage e.g.
parentheses, &&, ||, !, and, or

## Custom modules and manifest names

By default Kafo expects a common module structure. For example if you add
```yaml
foreman: true
```
to you answer file, Kafo expects a ```foreman``` subdirectory in ```modules/```. Also
it expects that there will be init.pp which it will instantiate. If you need
to change this behavior you can via ```mapping``` option in ```config/kafo.yaml```.

Suppose we have a puppet module and we want to use a puppet/server.pp as our init
file. Also we want to name our module puppetmaster. To do so we add the following mapping
to kafo.yaml

```yaml
:mapping:
  :puppetmaster:                # a module name, so we'll have puppetmaster: true in answer file
    :dir_name: 'puppet'         # the subdirectory in modules/
    :manifest_name: 'server'    # manifest filename without .pp extension
    :params_path: ...           # params manifest full path, overriding params_name, must be with .pp extension
    :params_name: 'params'      # name of manifest holding the params class without .pp extension
```

Note that if you add a mapping you must enter both the dir_name and manifest_name even
if one of them is already the default. The arguments params_path and params_name are optional.
You can use just "params_name" or override not just the file name but also complete paths using "params_path".
If you use "params_path" for this purpose, "params_name" is ignored.

## Validations

If class parameters are declared with Puppet 4 data types then Kafo will
validate user inputs against Puppet's type validation rules.

## Enabling or disabling module

You can enable or disable a module specified in the answers.yaml file. Every module
automatically adds two options to the foreman-installer script. For the module "foreman"
you have two flag options ```--enable-foreman``` and ```--no-enable-foreman```.

When you disable a module all its answers will be removed and "module" will be
set to false. When you reenable the module you'll end up with the default values.

## Special values for arguments

Sometimes you may want to enforce ```undef``` value for a particular parameter.
You can set this value by specifying an UNDEF string e.g.

```bash
bin/foreman-installer --foreman-db-password=UNDEF
```

It also works in interactive mode.

You may also need to override array parameters with empty array values. For this
purpose you can use `EMPTY_ARRAY` string as a value. Similarly you can use
`EMPTY_HASH` for hash parameters.

## Hooks

You may need to add new features to the installer. Kafo provides a simple hook
mechanism that allows you to run custom code at several different occasions.
We currently support the following hooks.

* pre_migrations - just after kafo reads its configuration - useful for config file updates. Only in this stage it is posible to request config reload (`Kafo.request_config_reload`) to get in our changes
* boot - before kafo is ready to work, useful for adding new installer arguments, but logger won't work yet
* init - just after hooking is initialized and kafo is configured, parameters have no values yet
* pre_values - just before value from CLI is set to parameters (they already have default values)
* pre_validations - just after system checks and before validations are executed (and before interactive wizard is started), at this point all parameter values are already set but not yet stored in answer file
* pre_commit - after validations or interactive wizard have completed, all parameter values are set but not yet stored in the answer file
* pre  - just before puppet is executed to converge system, after parameter values are stored in the answer file
* post  - just after puppet is executed to converge system
* pre_exit - happens during exit handling, before exit is completed

For better understanding when the hooks are executed see the [diagram](doc/kafo_run.png).

Let's assume we want to add the ```--reset-foreman-db``` option to our
foreman-installer. We could add the following lines to the generated
installer script.

```ruby
require 'kafo/hooking'

# first hook that creates new app option --reset-foreman-db
KafoConfigure.hooking.register_boot(:add_reset_option) do
  app_option '--reset-foreman-db',
    :flag, 'Drop foreman database first? You will lose all data!', :default => false
end

# second hook which resets the db if value was set to true
KafoConfigure.hooking.register_pre(:reset_db) do
  if app_value(:reset_foreman_db) && !app_value(:noop)
    `which foreman-rake > /dev/null 2>&1`
    if $?.success?
      logger.info 'Dropping database!'
      output = `foreman-rake db:drop 2>&1`
      logger.debug output.to_s
      unless $?.success?
        logger.warn "Unable to drop DB, ignoring since it's not fatal, output was: '#{output}''"
      end
    else
      logger.warn 'Foreman not installed yet, can not drop database!'
    end
  end
end
```

Note that the hook is evaluated in HookContext object which provides a DSL:

* ```app_option``` creates a new installer option
* ```app_value(:reset_foreman_db)``` accesses values of installer options
* ```param('module name', 'parameter name')``` accessor allows parameters to be modified if already
  defined
* ```add_module``` registers your own module not specified in the answer file (custom mapping is also
  supported), useful if you need to add some module to the existing installer based on kafo but you
  don't have control over its source code
* ```module_enabled?('module_name')``` indicates whether a module is currently enabled
* ```get_custom_config``` and ```store_custom_config``` access custom config storage which persists
  among kafo runs
* ```logger``` is also available for writing log messages

For more details, see
[hook_context.rb](https://github.com/theforeman/kafo/blob/master/lib/kafo/hook_context.rb).

If you don't want to modify your installer script you can place your hooks into the
hooks directory. By default the hooks dir is searched for ruby files in subdirectories
based on hook type. For example pre hooks are searched for in ```$installer_dir/hooks/pre/*.rb```
The hooks from the previous example would look like this. The only change to the code is
that you don't explicitely register hooks, it's done automatically for you.

```ruby
# hooks/boot/10-add_reset_option.rb
app_option '--reset-foreman-db', :flag, 'Drop foreman database first? You will lose all data!', :default => false
```

```ruby
# hooks/pre/10-reset_option_feature.rb
if app_value(:reset_foreman_db) && !app_value(:noop)
  `which foreman-rake > /dev/null 2>&1`
  if $?.success?
    logger.info 'Dropping database!'
    output = `foreman-rake db:drop 2>&1`
    logger.debug output.to_s
    unless $?.success?
      logger.warn "Unable to drop DB, ignoring since it's not fatal, output was: '#{output}''"
    end
  else
    logger.warn 'Foreman not installed yet, can not drop database!'
  end
end
```

Hooks can additionally be defined by combining all related stages into a single file
known as a Multi-stage hook. Multi-stage hooks live in a special directory inside
the hooks directory: ```$installer_dir/hooks/multi```. Taking the previous example:

```ruby
# hooks/multi/10-reset_option_feature.rb
boot do
  app_option '--reset-foreman-db', :flag, 'Drop foreman database first? You will lose all data!', :default => false
end

pre do
  if app_value(:reset_foreman_db) && !app_value(:noop)
    `which foreman-rake > /dev/null 2>&1`
    if $?.success?
      logger.info 'Dropping database!'
      output = `foreman-rake db:drop 2>&1`
      logger.debug output.to_s
      unless $?.success?
        logger.warn "Unable to drop DB, ignoring since it's not fatal, output was: '#{output}''"
      end
    else
      logger.warn 'Foreman not installed yet, can not drop database!'
    end
  end
end
```

If you want to add more directories to be search you can use the "hook_dirs" option
in the installer configuration file.

```yaml
:hook_dirs:
- /opt/hooks
- /my/plugin/hooks
```

You can register as many hooks as you need. The order of execution for a particular hook type
is based on hook file name.

If you want to cancel the installation you can use the ```exit``` method and specify an exit code.

## Colors

Everybody loves colors right? In case you don't you can disable them using the ```--no-colors```
argument or disallow them in the installer config file (search for ```colors:``` key and set
it to false). If you don't touch this setting, kafo will try to detect whether colors
are supported and will enable/disable it accordingly.

Kafo supports two sets of colors, one for terminals with bright and one for dark backround.
You can specify your installer default scheme in installer config file (```color_of_background```
key). Alternatively the user can override this default setting with the ```--color-of-background``` argument.
Possible values are ```dark``` and ```bright```.

You can reuse the kafo color schema in your custom hooks (so you can reuse dark/bright logic).
Look at this example in bin/foreman-installer
```ruby
#!/usr/bin/env ruby

# Run the install
@result = Kafo::KafoConfigure.run
exit 0 if @result.nil? # --help invocation

# Puppet status codes say 0 for unchanged, 2 for changed succesfully
if [0,2].include?(@result.exit_code)
  say "  <%= color('Success!', :good) %>"

  if module_enabled? 'foreman'
    say "  * <%= color('Foreman', :info) %> is running at <%= color('#{get_param('foreman','foreman_url')}', :info) %>"
    say "      Default credentials are '<%= color('admin:changeme', :info) %>'"e
  end
end
```

As you can see you can use HighLine helpers (e.g. say) with colors. Look at kafo/color_schema.rb for
supported color identifiers. We can guarantee that there will always be at least :good, :bad, :info.

Methods like module_enabled? and get_param are just helpers defined in the same file. If you find
them useful, here's the definition

```ruby
def module_enabled?(name)
  mod = @result.module(name)
  return false if mod.nil?
  mod.enabled?
end

def get_param(mod, name)
  @result.param(mod, name).value
end
```

## Custom paths

Usually when you package your installer you want to load files from specific
paths. In order to do that you can use following configuration options:

* :answer_file: /etc/kafo/kafo.yaml
* :installer_dir: /usr/share/kafo/
* :module_dirs: /usr/share/foreman-installer/modules
* :hook_dirs: /user/share/foreman-installer/hooks
* :check_dirs: /user/share/foreman-installer/checks
* :kafo_modules_dir: /usr/share/kafo/modules
* :store_dir: /etc/foreman-installer/store.d

Answer file is obvious. The "installer_dir" is the place where your installer is
located. E.g. system checks will be loaded from here (under checks
subdirectory) if not set elsewhere by `check_dirs`. You can optionally change foreman-installer modules dir
using `module_dirs` option and hooks dir using `hook_dirs` option. `module_dirs`, `hook_dirs` and `check_dirs`
can hold multiple directories where to look for the resources.

On debian systems you may want to specify kafo modules dir
independent on your installer location. If you specify this option kafo's
internal-installer puppet-modules will be loaded from here.

## Order of puppet modules execution

When you have more than one module you may end up in the situation where you need a
specific order of execution. It seems as a puppet antipattern to me however
there may be cases where it's needed. You can set order in config/kafo.yaml
like this

```yaml
order:
  - foreman
  - foreman_proxy
```

If you have other modules in your answer file they will be executed after
those that have explicit order. Their order is not be specified.

## Changing the order of module appearance in interactive mode

We sort our modules alphabetically. Sometimes you may want to reorder
modules, e.g. a display plugin modules as last module.
For this you can use the ```low_priority_modules```
configuration option. It accepts an array of patterns considering the
first to have the lowest priority. So in follwing example

```yaml
low_priority_modules:
  - compute
  - plugin
```

all modules containing a word compute in their name would be listed
at the end. If there are two modules containing compute, their order
is alphabetical on suffix after compute word. If there are some modules
containing word plugin, they will be above compute modules as they
were mentioned later.

## Changing of log directory and user/group

By default kafo logs every run to a separate file in /var/log/kafo.
You probably want to put your installation logs alongside with other logs of
your application. That's why kafo has its own configuration file in which you
can tune details like these.

In order to do that, create a configuration file under config/kafo.yaml. You can
use config/kafo.yaml.example as a template. If config/kafo.yaml does not exist
default values will be used.

As a developer you can appreciate more verbose log. You can set a debug level
in config/kafo.yml. Also you can change a user or group that will own the
log file. This is usefull if your installer requires to be run as root
but you want the logs to be readable by specific users.

## System checks

When you want to make sure that a user has a certain software installed or has the
right version you can write a simple script and put it into the checks directory.
All files found there will be executed and if any of these exits with an non-zero
exit code, kafo won't execute puppet but only print an error message
`Your system does not meet configuration criteria.`

Everything on STDOUT and STDERR is logged in error level.

Example shell script which checks java version

```bash
#!/bin/sh
java -version 2>&1 | grep OpenJDK
exit $?
```

If you want to ignore results of the check scripts, you can use the builtin
parameter `--skip-checks-i-know-better` (or `-s`). This will completely
disable running all system check scripts. Note that this option is
not persisted between runs.

## Parser cache

One or more caches of parsed Puppet modules and manifests can be created to skip the use
of kafo_parsers at runtime. This is useful when kafo_parsers doesn't support the
version of Puppet in use, and may also provide a small performance benefit. When multiple
cache files are used, they are being loaded in order they are specified in the config
file. If their files overlap, the later cache fully replaces the previous cache for each
file/manifest.

Create the cache with `kafo-export-params -f parsercache --no-parser-cache` and
configure it in config/kafo.yaml with:

```yaml
# single cache
:parser_cache_path: ./parser_cache.yaml

# multiple caches
:parser_cache_path:
  - ./parser_cache.yaml
  - ./another_parser_cache.yaml
```

The cache will be skipped if the file modification time of the manifest is
greater than the mtime recorded in the cache. Using `--parser-cache` will force
the use of an outdated cache, but this should be used with caution.

## Facts

Kafo provides a structured fact describing the state. This fact is only present
during the Puppet run. Currently it's the scenario id and name where the id is
the same as passed via --scenario by the user and matches the scenario filename
with an extension. The name is a human readable version.

```yaml
---
kafo:
  scenario:
    id: foreman_proxy
    name: Foreman Proxy
```

## Configuring Hiera

Kafo uses Hiera to include classes and pass parameters to classes using data
binding, but this can be extended so parameters can be set for classes not
being managed by Kafo. Set a custom Hiera config file in Kafo's config with:

```yaml
:hiera_config: /usr/share/kafo/hiera.yaml
```

The contents of this file are as per the
[hiera.yaml docs](https://docs.puppet.com/hiera/latest/configuring.html).
Only Hiera version 5 is supported.

An answers file will be generated containing _all_ default and overriden values
for parameters managed by Kafo. During the run this is available as a
`kafo.scenario.answer_file` fact. This may change in the future to allow a more
complex hierarchy.

The hierarchy must contain the path `%{facts.kafo.scenario.answer_file}`. This
contains all answers in a temporary location.

As an example, a hierarchy could be set up with:

```yaml
hierarchy:
  - name: "Kafo Answers"
    path: "%{facts.kafo.scenario.answer_file}"
  - name: "Other YAML hierarchy levels"
    paths:
      - "family/%{facts.os.family}.yaml"
      - "common.yaml"
```

It is possible to include another file above answers:

```yaml
hierarchy:
  - name: "Custom values"
    datadir: "custom"
    path: "override.yaml"
  - name: "Kafo Answers"
    path: "%{facts.kafo.scenario.answer_file}"
  - name: "Other YAML hierarchy levels"
    datadir: "data"
    paths:
      - "family/%{facts.os.family}.yaml"
      - "common.yaml"
```

This would give precedence to all Kafo-managed parameter values, but for any
others, would check for values per OS family, followed by a `common.yaml` file.

The scenario id is also available as a fact which can be used to provide
scenario specific overrides for unmanaged modules.

```yaml
hierarchy:
  - name: "Kafo Answers"
    path: "%{facts.kafo.scenario.answer_file}"
  - name: "Scenario defaults"
    path: "scenario/%{facts.kafo.scenario.id}.yaml"
```

[Migration from Hiera version 3](https://puppet.com/docs/puppet/4.9/hiera_migrate_v3_yaml.html)
is documented by Puppet.

## Exit code

Kafo can terminate either before or after puppet is run. If it is run with
```--detailed-exitcodes``` Kafo returns the same exit code as puppet does. If
kafo terminates after puppet run exit codes are like the following:
* '1' means there were parser/validation errors
* '2' means there were changes,
* '4' means there were failures during the transaction,
* '6' means there were both changes and failures.

Other exit codes that can be returned:
* '0' means everything went fine no changes were made
* '20' means your system does not meet configuration criteria (system checks failed)
* '21' means your answer file contains invalid values
* '22' means that puppet modules contains some error (e.g. missing documentation)
* '23' means that you have no answer file
* '24' means that your answer file asks for puppet module that you did not provide
* '25' means that kafo could not get default values from puppet
* '26' means that kafo could not find the specified scenario
* '27' means that kafo found found scenario configuration error that prevents installation from continuing
* '28' means that a value is missing for a parameter given on the command line
* '29' means that effective user that ran the installer does not have permission to update the answer file
* '30' means that the version of Puppet is incompatible with a module, according to its [metadata.json](https://docs.puppet.com/puppet/latest/modules_metadata.html)
* '130' user interrupt (^C)

## Running Puppet Profiling

Performance data can be gathered during a Puppet run by adding the `--profile` option. See [Tune Puppet for Performance with Profiler](https://puppet.com/blog/tune-puppet-for-performance-profiler) for more information from the Puppet team. Users who wish to perform a Kafo run and gather this type of profiling data to analyze can pass the same option to their installer. The profiling data will then be present in the normal Kafo logs.

## Issue tracker

Issues are tracked in Redmine, see:

* [Open Kafo issues](https://projects.theforeman.org/projects/kafo/issues/)
* [File new issue](https://projects.theforeman.org/projects/kafo/issues/new)

## Related projects

* [kafo_module_lint](https://github.com/domcleal/kafo_module_lint) will lint Puppet modules to ensure data types are specified correctly etc.
* [kafo_parsers](https://github.com/theforeman/kafo_parsers) parses Puppet manifests for class documentation and parameter data
* [puppet-lint-param-docs](https://github.com/voxpupuli/puppet-lint-param-docs) will lint Puppet modules to ensure all parameters are documented

# License

This project is licensed under the GPLv3+.
