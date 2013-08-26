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

Now we run +kafofy+ script which will prepare directory structure and
optionally create a bin script according to first parameter.

```bash
kafofy foreman-installer
```

You can see that it created modules directory where your puppet modules
should live. It also created config and bin directories. If you specified
argument (foreman-installer in this case) a script in bin was created.
It's the script you can use to run installer. If you did not specify any
you can run your installer by +kafo-configure+ which is provided by the gem.
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

or you can run (very early proof of concept) interactive mode

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

Supported types are: string, boolean, integer, array

Note that all arguments that are nil (have no value in answers.yaml or you
set them UNDEF (see below) are translated to ```undef``` in puppet.

## Array arguments

Some arguments may be Arrays. If you want to specify array values you can
specify CLI argument multiple times e.g.
```bash
bin/foreman-installer --puppetmaster-environments=development --puppetmaster-environments=production
```

In interactive mode you'll be prompted for another value until you specify
blank line.

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
