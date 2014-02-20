# Kafo

A puppet based installer and configurer (not-only) for Foreman and Katello
projects. Kafo is a ruby gem that allows you to create fancy user interfaces for
puppet modules. It's some kind of a nice frontend to a

```bash
echo "include some_modules" | puppet apply
```
## Why should I care?

Suppose you work on software which you want to distribute to a machine in
infrastructure managed by puppet. You write a puppet module for your app.
But you also want to be able to distribute this app to a machine outside of
puppet infrastructure (e.g. install it to your clients) or you want to install
it in order to create a puppet infrastructure itself (e.g. foreman or
foreman-proxy).

With kafo you can reuse your puppet modules for creating an installer. Even
better after the installation you can easily modify you configuration. All
using the very same puppet modules.

## What it does, how does it work?

Kafo reads a config file to find out which modules should it use. Then it
loads parameters from puppet manifests and gives you a way to customize them.

There are three ways how you can set parameters. You can
 * predefine them in configuration file
 * specify them as CLI arguments
 * you can use interactive mode which will ask you for all required parameters

Note that your answers (gathered from any mode) are saved for the next run
so you don't have to specify them again. Kafo also support default values of
parameters so you can set only those you want to change. Also you can combine
akk modes so you can create an answer file with default values easily
and then use it for unattended installs.

## How do I use it?

First install kafo gem.

Using bundler - add kafo gem to your Gemfile and run
```bash
bundle install
```

or without bundler
```bash
gem install kafo
```

Create a directory for your installer. Let's say we want to create
foreman-installer.

```bash
mkdir foreman-installer
cd foreman-installer
```

Now we run ```kafofy``` script which will prepare directory structure and
optionally create a bin script according to first parameter.

```bash
kafofy foreman-installer
```

You can see that it created modules directory where your puppet modules
should live. It also created config and bin directories. If you specified
argument (foreman-installer in this case) a script in bin was created.
You can supply custom locations for you configuration and answers files using
options:

```kafofy --help
Usage: kafofy [options] installer_name
    -c, --config_file FILE           location of the configuration file
    -a, --answers_file FILE          location of the answers file
```

It's the script you can use to run installer. If you did not specify any
you can run your installer by ```kafo-configure``` which is provided by the gem.
All configuration related files are to be found in config directory.

So for example to install foreman you want to
```bash
cd foreman-installer/modules
git clone https://github.com/theforeman/puppet-foreman/ foreman
```
Currently you must also download any dependant modules.
Then you need to tell kafo it's going to use foreman module.
```bash
cd ..
echo "foreman: true" > config/answers.yaml
```
Fire it with -h
```bash
bin/foreman-installer -h
```

You will see all arguments that you can pass to kafo. Note that underscored
puppet parameters are automatically converted to dashed arguments. You can
also see a documentation extracted from foreman puppet module and default
value.

Now run it without -h argument. It will print you the puppet apply command
to execute. This will be automatized later. Look at config/answers.yaml, it
was populated with default values. To change those options you can use
arguments like this

```bash
bin/foreman-installer --foreman-enc=false --foreman-db-type=sqlite
```

or you can run interactive mode

```bash
bin/foreman-installer --interactive
```

Also every change made to config/answers.yaml persists and becomes new default
value for next run.

As you noticed there are several ways how to specify arguments. Here's the list
the lower the item is the higher precedence it has:
  * default values from puppet modules
  * values from answers.yaml
  * values specified on CLI
  * interactive mode arguments

# Advanced topics

## Testing aka noop etc

You'll probably want to tweak your installer before so you may find
```--noop``` argument handy (-n for short). This will run puppet in
noop so no change will be done to your system. Default value is
false!

Sometimes you may want kafo not to store answers from current run. You can
disable saving by passing a ```--dont-save-answers``` argument (or -d for short).

## Parameters prefixes

You probably noticed that every module parameter is prefixed by module name
by default. If you use just one module it's probably unnecessary and you
can disable this behavior in config/kafo.yaml. Just set option like this
```yaml
:no_prefix: true
```

## Documentation

Every parameter that can be set by kafo *must* be documented. This means that
you must add documentation to your puppet class in init.pp. It's basically
rdoc formatted documentation that must be above class definitions. There can
be no space between doc block and class definition.

In case of emergency, it's still possible to use
`--ignore-undocumented` option, but in general it's not recommended to
use it long-term.

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

When you run the installer with ```--help``` argument it displays only
parameters specified in ```=== Parameters:``` group. If you don't specify
any group all parameters will be considered as Basic and will be displayed.

If you run installer with ```--full-help``` you'll receive help of all
parameters divided into groups. Note that only headers that include word
parameters are considered as parameter groups. Other headers are ignored.
Also note that you can nest parameter groups and the child has precedence.
Help output does not take header level into account though.

So in previous example, each parameter would be printed in one group even
though MySQL is a child of Advanced parameter. All groups in help would be
prefixed with second level (==). The first level is always a module to which
particular parameter belongs.

## Argument types

By default all arguments that are parsed from puppet are treated as string.
If you want to indicate that a parameter has a particular type you can do it
in puppet manifest documentation like this

```puppet
# $param::        Some documentation for param
                  type:boolean
```

Supported types are: string, boolean, integer, array, password

Note that all arguments that are nil (have no value in answers.yaml or you
set them UNDEF (see below) are translated to ```undef``` in puppet.

## Password arguments

Kafo support password arguments. It's adding some level of protection for you
passwords. Usually people generate random strings for passwords. However all
values are stored in config/answers.yaml which introduce some security risk.

If this is something to consider for you, you can use password type (see 
Argument types for more info how to define parameter type). It will
generate a secure (random) password of decent length (32 chars) and encrypts
it using AES 256 in CBC mode. It uses a passphrase that is stored in
config/kafo.yaml so if anyone gets an access to this file, he can read all
other passwords from answers.yaml. A random password is generated and stored
if there is none in kafo.yaml yet.

When Kafo runs puppet, puppet will read this password from config/kafo.yaml.
It runs under the same user so it should have read access by default. Kafo
puppet module also provides a function that you can use to decrypt such
parameters. You can use it like this

```erb
password: <%= scope.function_decrypt([scope.lookupvar("::foreman::db_password"))]) -%>
```

Also you can take advantage of already encrypted password and store as it is
(encrypted). Your application can decrypt it as long as it knows the
passphrase. Passphrase can be obtained as $kafo_configure::password.

Note that we use a bit extraordinary form of encrypted passwords. All our
encrypted passwords looks like "$1$base64encodeddata". As you can see we
use $1$ prefix by which we can detect that its encrypted password by us.
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

You can use Hash value not unlike Arrays. It's also multivalue type but
you have to specify a key:value pairs like this.
```bash
bin/foreman-installer --puppet-server-git-branch-map=master:some --puppet-server-git-branch-map=development:another
```

The same applies in interactive mode, you enter each pair on separate line
just like with Array, the only difference is that the line must be formatted
as key:value.

When parsing the value, the first colon divides key and value. All other
colons are ignored.

## Grouping in interactive mode

If your module has too much parameters you may find useful grouping. Every
block in your documentation (prefixed by header) forms a group. Unlike for
help, all block are used in interactive mode. Suppose you have following
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

When you enter Testing class module in interactive mode you see parameters
from Basic group and options to configure parameters which belongs to rest
of groups on same level, in this case Advanced and Extra parameters. 

```
Module foreman configuration
1. Enable/disable foreman module, current value: true
2. Set one, current value: '1'
3. Configure Advanced parameters
4. Configure Extra parameters
5. Back to main menu
```

When you enter Extra paramaters, you see only $three and option to get back 
to parent. In Advanced you see $two and two more subgroups - Advanced A and 
Advanced B. When you enter these subgroups, you see their parameters of 
course. Nesting is unlimited. Also there's no naming rule. Just notice that 
the main group must be called `Parameters` and it's parameters are always 
displayed on first level of module configuration.

```
Group Extra parameters (of module foreman)
1. Set two_b, current value: '2b'
2. Back to parent menu
```

If there's no primary group a new one is created for you and it does not have
any parameter. This mean when user enters module configuration he or she will 
see only subgroups in menu (no parameters until a particular subgroup is entered). 
If there is no group in documentation a new primary group is created and it 
holds all module parameters (there are no subgroups in module configuration).

## Conditional parameters in interactive mode

You can also define conditions to parameter and their groups. These conditions
are evaluated in interactive mode and based on the result they are displayed
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

Here you can see we defined several conditions on group and parameter level.
You can write condition in ruby language. All dollar-prefixed words are be
substituted by value of a particular puppet parameter.

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

Suppose we have puppet module and we want to use puppet/server.pp as our init
file. Also we want to name our module as puppetmaster. We add following mapping
to kafo.yaml

```yaml
:mapping:
  :puppetmaster:                # a module name, so we'll have puppetmaster: true in answer file
    :dir_name: 'puppet'         # the subdirectory in modules/
    :manifest_name: 'server'    # manifest filename without .pp extension
```

Note that if you add mapping you must enter both dir_name and manifest_name even
if one of them is default.

## Validations

If you specify validations of parameters in you init.pp manifest they
will be executed for your values even before puppet is run. In order to do this
you must follow few rules however:

* you must use standard validation functions (e.g. validate_array, validate_re, ...)
* you must have stdlib in modules directory

## Enabling or disabling module

You can enable or disable module specified in answers.yaml file. Every module
automatically adds two options to foreman-installer script. For module foreman
you have two flag options ```--enable-foreman``` and ```--no-enable-foreman```.

When you disable a module all its answers will be removed and module will be
set to false. When you reenable the module you'll end up with default values.

## Special values for arguments

Sometimes you may want to enforce ```undef``` value for a particular parameter.
You can set this value by specifying UNDEF string e.g.

```bash
bin/foreman-installer --foreman-db-password=UNDEF
```

It also works in interactive mode.

## Hooks

You may need to add new features to the installer. Kafo provides simple hook
mechanism that allows you to run custom code just before and after the puppet
is ran. Let's assume we want to add --reset-foreman-db option to our
foreman-installer. We add following lines to generated installer script

```ruby
require 'kafo/hooking'

# functions specific to foreman installer
KafoConfigure.app_option '--reset-foreman-db',
  :flag, 'Drop foreman database first? You will lose all data!', :default => false

KafoConfigure.hooking.register_pre(:reset_db) do |kafo|
  if kafo.config.app[:reset_foreman_db] && !kafo.config.app[:noop]
    `which foreman-rake > /dev/null 2>&1`
    if $?.success?
      KafoConfigure.logger.info 'Dropping database!'
      output = `foreman-rake db:drop 2>&1`
      KafoConfigure.logger.debug output.to_s
      unless $?.success?
        KafoConfigure.logger.warn "Unable to drop DB, ignoring since it's not fatal, output was: '#{output}''"
      end
    else
      KafoConfigure.logger.warn 'Foreman not installed yet, can not drop database!'
    end
  end
end
```

Note that we can access other installer options using ```kafo.config.app```. Since ```kafo``` is
KafoConfigure instance, you can even access puppet params values. Last but not least you have
access to logger.

You can register as many hooks as you need. They are executed in unspecified order. Every hook
must have a unique name. In a very similar way you can register :post hooks that are executed
right after puppet run is over.

## Custom paths

Usually when you package your installer you want to load files from specific
paths. In order to do that you can use following configuration options:

* :answer_file: /etc/kafo/kafo.yaml
* :installer_dir: /usr/share/kafo/
* :modules_dir: /usr/share/foreman-installer/modules
* :kafo_modules_dir: /usr/share/kafo/modules

Answer file is obvious. Installer dir is a place where you installer is 
installed. E.g. system checks will be loaded from here (under checks 
subdirectory). You can optionally change foreman-installer modules dir
using modules_dir option.

On debian systems you may want to specify kafo modules dir
independent on your installer location. If you specify this option kafo
internal installer puppet modules will be loaded from here.

## Order of puppet modules execution

When you have more than one module you may end up in situation where you need
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

## Changing of log directory and user/group

By default kafo logs every run to a separate file in /var/log/kafo.
You probably want to put your installation logs alongside with other logs of
your application. That's why kafo has its own configuration file in which you
can tune details like this.

In order to do that create a configuration file in config/kafo.yaml. You can
use config/kafo.yaml.example as a template. If config/kafo.yaml does not exist
default values will be used.

As a developer you can appreciate more verbose log. You can set debug level
in config/kafo.yml. Also you can change a user or group that will own the
log file. This is usefull if your installer requires to be run under root
but you want the logs to be readable by specific users.

## System checks

When you want to make sure that user has some software installed or has the
right version you can write a simple script and put it into checks directory.
All files found there will be ran and if any has non-zero exit code, kafo
wont execute puppet.

Everything on STDOUT and STDERR is logged in error level.

Example shell script which checks java version

```bash
#!/bin/sh
java -version 2>&1 | grep OpenJDK
exit $?
```

## Exit code

Kafo can terminate either before or after puppet is ran. Puppet is ran with
--detailed-exitcodes and Kafo returns the same exit code as puppet does. If
kafo terminates after puppet run exit codes are:
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


# License

This project is licensed under the GPLv3+.
