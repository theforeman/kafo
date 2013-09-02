# Kafo

A puppet based installer and configurer (not-only) for Foreman and Katello
projects. Kafo is a ruby gem that allows you to create fancy user interfaces for
puppet modules. It's some kind of a nice frontend to a

```bash
echo "include some_modules" | puppet apply
```
## Why should I care?

Suppose you work on a software which you want to distribute to a machine in
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

If this is something to concern for you, you can use password type. It will
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

Everything on STDOUT is logged in debug level, everything on STDERR is logged
in error level.

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
