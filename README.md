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
kafofy -n foreman-installer
```

You can see that it created a modules directory where your puppet modules
should live. It also created config and bin directories. If you specify the
argument ```--name``` (or -n for short, foreman-installer in this case) a script in 
the "bin" directory with this name will be created.

It's the script you can use to run the installer. If you did not specify any
arguments you can run your installer by `kafo-configure` which is the default.
All configuration related files are to be found in the config directory.

You can supply custom locations for you configuration- and answer- files using
options:
```
kafofy --help
Usage: kafofy [options]
    -a, --answer_file FILE           location of the answer file
    -c, --config_file FILE           location of the configuration file
    -n, --name        NAME           your installer name
```

The configuration file will be created by a default template. It's the configuration
of your installer (so you can setup the log level, path to puppet modules etc).
On the other hand, the answer file must be created manually. Answer files define
which modules should be used and hold all values for the puppet class parameters.


So for example to install foreman you want to
```bash
cd foreman-installer/modules
git clone https://github.com/theforeman/puppet-foreman/ foreman
```
You must also download any dependant modules.
Then you need to tell kafo it's going to use the foreman module.
```bash
cd ..
echo "foreman: true" > config/answers.yaml
```

Alternatively you can use the librarian-puppet project to manage all dependencies for you.
You just create a Puppetfile and call librarian to install your modules. See
https://github.com/rodjek/librarian-puppet for more details.

When you have your modules in-place, fire the installer with -h as argument
```bash
bin/foreman-installer -h
```

This will show you all the possible arguments you can pass to kafo. Note that underscored
puppet parameters are automatically converted to dashed arguments. You can
also see a documentation extracted from the foreman puppet module and a default
value.

Now run it without the -h argument. It will print you the puppet apply command
to execute. This will be automatized later. Look at config/answers.yaml, it
was populated with default values. To change those options you can use
arguments like this

```bash
bin/foreman-installer --foreman-enc=false --foreman-db-type=sqlite
```

or you can run it in interactive mode

```bash
bin/foreman-installer --interactive
```

Also every change made to the config/answers.yaml persists and becomes the new default
value for the next run.

As you may have noticed there are several ways how to specify arguments. Here's the list:
(the lower the item is in this list the higher precedence it has):
  * default values from puppet modules
  * values from answers.yaml
  * values specified on CLI
  * interactive mode arguments

## How do I report bugs or contribute?

You can find our redmine issue tracker [here](http://projects.theforeman.org/projects/kafo),
you can use your github account for logging in. When reporting new issues please 
don't forget to specify your:
  * puppet version
  * installation options (GEM/RPM/DEB)
  * error trace (if any) or log with debug level
  * reproducing steps

Since Kafo is a side project of Foreman you can use its IRC channels to 
contact us on freenode. #theforeman is the channel for generic discussions
and #theforeman-dev is reserved only for technical topics. Likewise you can use the Foreman
mailing lists on googlegroups. For more information see [this page](http://theforeman.org/support.html)

Patches are always welcome. You can use instructions for Foreman, just
substitute Foreman with Kafo. More details are [here](http://projects.theforeman.org/projects/foreman/wiki/Contribute#New-Way-github)

# Advanced topics

## Testing aka noop etc

Since you'll probably want to tweak your installer before you run it, you may find the
```--noop``` argument handy (-n for short). This will run puppet in
noop so no change will be done to your system. The default value here is set to
false!

Sometimes you may want kafo not to store answers from the current run. You can
disable saving answer by passing a ```--dont-save-answers``` argument (or -d for short).

Note that running ```--noop``` implies ```--dont-save-answers```.

## Parameters prefixes

As a default every module parameter is prefixed by the module name.
If you use just one module it's probably not necessary and you
can disable this behavior in config/kafo.yaml. Just enable the following option
```yaml
:no_prefix: true
```

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
#                           type:boolean
class foreman (
  $foreman_url            = $foreman::params::foreman_url,
  $enc                    = $foreman::params::enc
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

By default all arguments that are parsed from puppet are treated as strings.
If you want to indicate that a parameter has a particular type you can do it
in the puppet manifest documentation like this

```puppet
# $param::        Some documentation for param
                  type:boolean
```

Supported types are: string, boolean, integer, array, password, hash

Note that all arguments that are nil (have no value in answers.yaml or you
set them UNDEF (see below)) are translated to ```undef``` in puppet.

## Password arguments

Kafo supports password arguments. It's adding some level of protection for your
passwords. Usually people generate random strings for passwords. However all
values are stored in config/answers.yaml which may introduce a security risk.

If this is something to consider for you, you can use the password type (see 
Argument types for more info how to define parameter type). It will
generate a secure (random) password with a length of 32 chars and encrypts
it using AES 256 in CBC mode. It uses a passphrase that is stored in
config/kafo.yaml so if anyone gets an access to this file, he can read all
the passwords from the answers.yaml, too. A random password is generated and stored
if there is none in kafo.yaml yet.

When Kafo runs puppet, puppet will read this password from config/kafo.yaml.
It runs under the same user so it should have read access by default. The Kafo
puppet module also provides a function that you can use to decrypt such
parameters. You can use it like this

```erb
password: <%= scope.function_decrypt([scope.lookupvar("::foreman::db_password"))]) -%>
```

Also you can take advantage of already encrypted passwords and store since it is
(encrypted). Your application can decrypt it as long as it knows the
passphrase. The passphrase can be obtained from $kafo_configure::password.

Note that we use a bit extraordinary form of encrypted passwords. All our
encrypted passwords look like "$1$base64encodeddata". As you can see we
use the $1$ as prefix by which we can detect that it is our specially encrypted password.
The form has nothing common with Modular Crypt Format. Also our AES output
is base64 encoded. To get a password from this format you can do something
like this in your application

```ruby
require 'base64'
encrypted = "$1$base64encodeddata"
encrypted = encrypted[3..-1]           # strip $1$ prefix
encrypted = Base64.decode64(encrypted) # decode base64 string
result    = aes_decrypt(encrypted)     # for example how to implement aes_decrypt see lib/kafo/password_manager.rb
```

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
#                            type:boolean
#
# == Database parameters:    condition: $use_db
#
# $database_type::           mysql/sqlite
#
# === MySQL:                 condition: $database_type == 'mysql'
#
# $remote::                  use remote connection
#                            type:boolean
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

If you specify validations of parameters in your init.pp manifest they
will be replaced with your values even before puppet is run. In order to do this
you must follow a few rules however:

* you must use standard validation functions (e.g. validate_array, validate_re, ...)
* you must have stdlib in modules directory

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
mechanism that allows you to run custom code at 6 different occasions.
We currently support the following hooks.

* boot - before kafo is ready to work, useful for adding new installer arguments, but logger won't work yet
* init - just after hooking is initialized and kafo is configured, parameters have no values yet
* pre_values - just before value from CLI is set to parameters (they already have default values)
* pre_validations - just after system checks and before validations are executed (and before interactive wizard is started), at this point all parameter values are already set but not yet stored in answer file
* pre  - just before puppet is executed to converge system
* post  - just after puppet is executed to converge system

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

Note that the hook is evaluated in HookContext object which provides some DSL. We can create a
new installer option using ```app_option```. These option values can be accessed by using
```app_value(:reset_foreman_db)```. You can modify parameters (if they are already defined)
using ```param('module name', 'parameter name')``` accessor. You can register your own module
that is not specified in the answer file using ```add_module```. Custom mapping is also supported.
This is useful if you need to add some module to the existing installer based on kafo but you don't
have control over its source code. You can use a custom config storage which persists among
kafo runs using ```get_custom_config``` and ```store_custom_config```.
Last but not least you have access to logger. For more details, see
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
* :modules_dir: /usr/share/foreman-installer/modules
* :kafo_modules_dir: /usr/share/kafo/modules

Answer file is obvious. The "installer_dir" is the place where your installer is 
located. E.g. system checks will be loaded from here (under checks 
subdirectory). You can optionally change foreman-installer modules dir
using modules_dir option.

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
* '130' user interrupt (^C)

## Running Puppet Profiling

As of Puppet 3.2, performance data can be gathered during a puppet run by adding the `--profile` option. See [Tune Puppet for Performance with Profiler](https://puppetlabs.com/blog/tune-puppet-performance-profiler) for more information from the Puppet team. Users who wish to perform a Kafo run and gather this type of profiling data to analyze can pass the same option to their installer. The profiling data will then be present in the normal Kafo logs.

# License

This project is licensed under the GPLv3+.
