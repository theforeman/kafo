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

Now we update rubygem-kafo.spec. Find the line starting with Version and update
it for desired version. Then tag it using tito

```sh
tito tag --keep-version
```

and edit changelog. I usually remove-merge only commits from changelog. You
have to push tags to theforeman repository.

Then you should build scratch rpms and test them. If they work you can build 
rpms in koji. I am building it with this command

```sh
tito release koji
```

After sucessfull build packages will be moved to repositories automatically.

(you need to have your koji client configured and you must have access to 
koji.katello.org)

## Build DEB

Create a pull-request on theforeman/foreman-packaging repository against
deb/development branch. To bump a version you must edit dependencies/*/kafo/changelog.
After you create new changelog entry (similar to RPM). When you have
your PR ready you can build scratches in ci.theforeman.org. Search for
packaging_build_deb_dependency task under Packaging tab. Again you need to 
have access. Put link to scratches into PR message and wait until someone
merges it.


## Take a rest

Since that's all.
