build status of unit tests:

[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-create_resources.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-create_resources)


- License - Apache Version 2.0
- Copyright - Puppetlabs 2011

*NOTE* - this has exists in 2.7.x core, it has been published seperately
so that it can be used with 2.6.x

This module contains a custom function for puppet that can be used to dynamically add resources to the catalog.

I wrote this to use with an external node classifier that consumes YAML.

The yaml specifies classes and passes hashes to those classes as parameters

    classes:
      webserver::instances:
        instances:
          instance1:
            foo: bar
          instance2:
            foo: blah

    Then puppet code can consume the hash parameters and convert then into resources

    class webserver::instances (
      $instances = {}
    ) {
      create_resources('webserver::instance', $instances)
    }

Now I can dynamically determine how webserver instances are deployed to nodes
by updating the YAML files.


