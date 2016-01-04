# How do we release and build packages

There are more ways possible but I prefer this one.

## Build new gem version

First we have to bump the version in lib/kafo/version.rb. We should try to 
follow semantic versioning. Then we push this to master branch under 
theforeman. Then we build a gem and upload it to rubygems.org by executing

```sh
rake release
```

You have to be among owners of this gem. Ask on #theforeman-dev on freenode
if you want to become one.

## Build RPM

Now we update rubygem-kafo.spec in [foreman-packaging](https://github.com/theforeman/foreman-packaging/tree/rpm/develop/rubygem-kafo).

Follow the [repository instructions](https://github.com/theforeman/foreman-packaging/tree/rpm/develop#howto-update-a-package)
to update the package by changing the version in the spec and updating
the source file.  Open a pull request against `rpm/develop` to submit
the change and create a test build.

## Build DEB

Create a pull-request on theforeman/foreman-packaging repository against
deb/develop branch.

Follow the [repository instructions](https://github.com/theforeman/foreman-packaging/tree/deb/develop/#howto-update-a-package)
to run a script to bump the version number automatically.  Opening a
pull request will automatically attempt a test build.

## Take a rest

Since that's all.
