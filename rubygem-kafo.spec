%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global gem_name kafo

Summary: A gem for making installations based on puppet user friendly
Name: %{?scl_prefix}rubygem-%{gem_name}
Version: 0.6.12
Release: 1%{?dist}
Group: Development/Libraries
License: GPLv3+
URL: https://github.com/theforeman/kafo
Source0: http://rubygems.org/downloads/%{gem_name}-%{version}.gem
%if "%{?scl}" == "ruby193" || (0%{?rhel} == 6 && 0%{!?scl:1})
Requires: %{?scl_prefix}ruby(abi)
%else
Requires: %{?scl_prefix}ruby(release)
%endif
Requires: %{?scl_prefix}puppet < 4.0.0
Requires: %{?scl_prefix}rubygem(logging) < 3.0.0
Requires: %{?scl_prefix}rubygem(clamp) >= 0.6.2
Requires: %{?scl_prefix}rubygem(highline) < 2.0
Requires: %{?scl_prefix}rubygem(kafo_parsers)
Requires: %{?scl_prefix}rubygem(powerbar)
Requires: %{?scl_prefix}rubygems

BuildRequires: %{?scl_prefix}rubygems-devel
%if "%{?scl}" == "ruby193" || (0%{?rhel} == 6 && 0%{!?scl:1})
BuildRequires: %{?scl_prefix}ruby(abi)
%else
BuildRequires: %{?scl_prefix}ruby(release)
%endif
BuildRequires: %{?scl_prefix}rubygems
BuildArch: noarch
Provides: %{?scl_prefix}rubygem(%{gem_name}) = %{version}

%description
If you write puppet modules for installing your software, you can use kafo to create powerful installer

%package doc
BuildArch:  noarch
Requires:   %{?scl_prefix}%{pkg_name} = %{version}-%{release}
Summary:    Documentation for rubygem-%{gem_name}

%description doc
This package contains documentation for rubygem-%{gem_name}.

%prep
%setup -n %{pkg_name}-%{version} -q -c -T
mkdir -p .%{gem_dir}
%{?scl:scl enable %{scl} "}
gem install --local --install-dir .%{gem_dir} \
            --force %{SOURCE0} --no-rdoc --no-ri
%{?scl:"}

%build
sed -i "/add_runtime_dependency.*puppet/d" ./%{gem_spec}
sed -i "/add_dependency.*puppet/d" ./%{gem_spec}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/

%files
%dir %{gem_instdir}
%{gem_instdir}/bin
%{gem_instdir}/config
%{gem_instdir}/lib
%{gem_instdir}/modules
%{gem_dir}/bin/kafo-configure
%{gem_dir}/bin/kafofy
%{gem_dir}/bin/kafo-export-params

%doc %{gem_instdir}/LICENSE.txt

%exclude %{gem_instdir}/README.md
%exclude %{gem_cache}
%exclude %{gem_instdir}/Rakefile
# add once tests are added (maybe spec dir instead)
#%exclude %{gem_instdir}/test
%{gem_cache}
%{gem_spec}

%files doc
%doc %{gem_instdir}/LICENSE.txt
%doc %{gem_instdir}/README.md

%changelog
* Thu Jun 11 2015 Marek Hulan <mhulan@redhat.com> 0.6.11-1
- Treat any return value from stdlib's validate_* functions as success
  (dcleal@redhat.com)
- Add pre_commit hook between param wizard/validation and answer file writing
  (dcleal@redhat.com)
- Document hash as valid parameter type (dcleal@redhat.com)

* Thu May 28 2015 Marek Hulan <mhulan@redhat.com> 0.6.10-1
- Enable progress bar with Puppet 3.8 (kvedulv@kvedulv.de)

* Mon May 18 2015 Marek Hulan <mhulan@redhat.com> 0.6.9-1
- Fixes #10500 - sorting of hooks by name for symbols
  (jkim@jkimdt.usersys.redhat.com)

* Wed May 06 2015 Marek Hulan <mhulan@redhat.com> 0.6.8-2
- Puppet version was pinned

* Wed May 06 2015 Marek Hulan <mhulan@redhat.com> 0.6.8-1
- Pin puppet to < 4.0.0 (martin.bacovsky@gmail.com)
- Fixes #10390 - Hooks within group are executed in right order
  (martin.bacovsky@gmail.com)
- fix spelling mistakes and grammar errors in readme (Manna@Atix.de)

* Mon Apr 06 2015 Marek Hulan <mhulan@redhat.com> 0.6.7-1
- Fixes #9996: Exposes Puppet's --profile as an option for installers.
  (ericdhelms@gmail.com)
- Pin down logging for Ruby 1.8 support (mhulan@redhat.com)

* Wed Mar 18 2015 Marek Hulan <mhulan@redhat.com> 0.6.6-2
- Fixed spec to reflect pinned highline

* Wed Mar 18 2015 Marek Hulan <mhulan@redhat.com> 0.6.6-1
- Fixes 6279 - add skip system checks option (mhulan@redhat.com)
- Fixes #6904 - never duplicate param groups (mhulan@redhat.com)
- Fixes #6911 - unsupported puppet version is reported as warn
  (mhulan@redhat.com)
- Fixes #7529 - Makes order of module configurable (mhulan@redhat.com)
- Fixes #7881 - add logs when default values fetching fails (mhulan@redhat.com)
- Fixes #8403 - report interrupt error code on interrupt (mhulan@redhat.com)
- Fixes #8750 - noop implies not saving answer file (mhulan@redhat.com)
- Fixes #9509 - allow overriding by empty values (mhulan@redhat.com)
- limit highline version to ruby 1.8 compatible one (kvedulv@kvedulv.de)

* Tue Sep 09 2014 Marek Hulan <mhulan@redhat.com> 0.6.5-1
- Pinning test gems (mhulan@redhat.com)
- Enable progress bar with Puppet 3.7 (kvedulv@kvedulv.de)

* Wed Jul 02 2014 Marek Hulan <mhulan@redhat.com> 0.6.4-1
- Fix default values dump for passwords without default values
  (mhulan@redhat.com)

* Wed Jun 11 2014 Marek Hulan <mhulan@redhat.com> 0.6.3-1
- Fix default values issues (mhulan@redhat.com)

* Tue Jun 10 2014 Marek Hulan <mhulan@redhat.com> 0.6.2-1
- Fix default value setting (mhulan@redhat.com)

* Mon Jun 09 2014 Marek Hulan <mhulan@redhat.com> 0.6.1-1
- Add contribute information to README (mhulan@redhat.com)
- Fixes Markdown typo in README.md (owenspencer@gmail.com)
- Improve default values support for puppet 2.7 (mhulan@redhat.com)

* Fri May 30 2014 Marek Hulan <mhulan@redhat.com> 0.6.0-2
- Modernise and update spec file for EL7 (dcleal@redhat.com)

* Fri May 23 2014 Marek Hulan <mhulan@redhat.com> 0.6.0-1
- Enable progress bar with Puppet 3.6 (mhulan@redhat.com)
- Add custom configuration storage (mhulan@redhat.com)
- Fix #4959 and fix #3224 (mhulan@redhat.com)
- Fix #5732 - Refactoring of exit code (mhulan@redhat.com)
- Add new type of hooks (mhulan@redhat.com)

* Tue May 13 2014 Marek Hulan <mhulan@redhat.com> 0.5.5-1
- Fixes #5582 - make the Kafo.exit_code set properly in post hooks
  (inecas@redhat.com)
- s/hooks_dir/hook_dirs/ (inecas@redhat.com)
- Fixes #5452 - Make sure nil is not part of the keys in Puppet resource
  (inecas@redhat.com)

* Wed Apr 23 2014 Marek Hulan <mhulan@redhat.com> 0.5.4-1
- Allow adding custom modules in hooks (mhulan@redhat.com)

* Tue Apr 15 2014 Marek Hulan <mhulan@redhat.com> 0.5.3-1
- Include custom params classes (mhulan@redhat.com)
- Allow custom params_path configuration using mapping (mhulan@redhat.com)
- Load default values of all modules (mhulan@redhat.com)

* Tue Apr 08 2014 Marek Hulan <mhulan@redhat.com> 0.5.2-1
- Fixes #4648 - make sure default password are not exposed (mhulan@redhat.com)
- Fixes #5112: Show actual answers file in '-d' output. (ericdhelms@gmail.com)
- Removed silent code (mhulan@redhat.com)
- Add progressbar support for puppet 3.5 (mhulan@redhat.com)

* Mon Mar 31 2014 Marek Hulan <mhulan@redhat.com> 0.5.0-1
- Improved hooks (mhulan@redhat.com)
- Support classes without param.pp defined (mhulan@redhat.com)

* Tue Mar 11 2014 Marek Hulan <mhulan@redhat.com> 0.4.0-2
- Fixed package dependencies

* Tue Mar 11 2014 Marek Hulan <mhulan@redhat.com> 0.4.0-1
- Version bump to 0.4.0 (mhulan@redhat.com)
- Fix #3053 - Extracted parsers to extra gem (mhulan@redhat.com)
- Refs #4281 - use utf only if supported (mhulan@redhat.com)
- add dynamic path for the default config file (kvedulv@kvedulv.de)
- Refs #4281 - Bright and dark background colors (mhulan@redhat.com)
- Fix #4281 - improve kafo output in interactive mode (mhulan@redhat.com)
- Fix #4177 - Help output is sorted correctly on 1.8 (mhulan@redhat.com)
- Make kafofy more consistent and user friendly (mhulan@redhat.com)
- Improved kafofy usability and out of the box experience (nils@domrose.net)

* Thu Feb 20 2014 Marek Hulan <mhulan@redhat.com> 0.3.16-1
- Fix #4402 - remove definition support (mhulan@redhat.com)

* Tue Feb 18 2014 Marek Hulan <mhulan@redhat.com> 0.3.15-1
- Fix #4367 - current environment compatible with all puppet versions
  (mhulan@redhat.com)

* Mon Feb 17 2014 Marek Hulan <mhulan@redhat.com> 0.3.14-1
- Fix #4347 - validations adapted to latest puppet (mhulan@redhat.com)

* Fri Feb 14 2014 Marek Hulan <mhulan@redhat.com> 0.3.13-1
- Fix #4343 - adds compatibility with latest puppet version (mhulan@redhat.com)

* Thu Jan 30 2014 Marek Hulan <mhulan@redhat.com> 0.3.12-1
- Fix --no-colors issues with older highline (mhulan@redhat.com)

* Wed Jan 29 2014 Marek Hulan <mhulan@redhat.com> 0.3.11-1
- Display fatal errors on STDOUT (mhulan@redhat.com)

* Tue Jan 28 2014 Marek Hulan <mhulan@redhat.com> 0.3.10-1
- Merge pull request #62 from ares/master (ares@igloonet.cz)
- Fix dumping 'false' default values (mhulan@redhat.com)

* Tue Jan 28 2014 Marek Hulan <mhulan@redhat.com> 0.3.9-1
- Fix few smaller issues (mhulan@redhat.com)

* Fri Jan 24 2014 Marek Hulan <mhulan@redhat.com> 0.3.8-1
- Fixes #3990 - Load is_* functions in validator (mhulan@redhat.com)
- Fixes #3887 - Support for deeply nested modules (mhulan@redhat.com)
- Fix issue when manifests can't be parsed (mhulan@redhat.com)

* Tue Jan 14 2014 Marek Hulan <mhulan@redhat.com> 0.3.7-1
- Version bump (mhulan@redhat.com)
- Howto release a new version (mhulan@redhat.com)
- Fix error with nil modules_dir running kafo-export-params (dcleal@redhat.com)

* Sun Jan 12 2014 Marek Hulan <mhulan@redhat.com> 0.3.6-1
- Fixes ignoring of custom modules_dir path (mhulan@redhat.com)
- Mention the --ignore-undocumented option in README (inecas@redhat.com)
- Fix modules_dir config override (dcleal@redhat.com)
- Fix logger require conflict (mhulan@redhat.com)
- Keep exit status on non-PTY.check path (dcleal@redhat.com)
- fixes #3394 - added --trace puppet option as default (lzap+git@redhat.com)

* Tue Dec 10 2013 Marek Hulan <mhulan@redhat.com> 0.3.4-1
- Fixes #3831 - Add support for hash type (mhulan@redhat.com)
- Add docs for new Hash type (mhulan@redhat.com)
- Add Puppet 3.4 to supported list for progress bars (dcleal@redhat.com)
- few help screen typos and improvements (lzap+git@redhat.com)
- A tiny grammar fix (dcleal@redhat.com)

* Tue Dec 03 2013 Marek Hulan <mhulan@redhat.com> 0.3.3-1
- Fix #3789: remove relative parts of the modulepath (shk@redhat.com)
- Use minitest for 1.8 in jenkins (mhulan@redhat.com)
- Fix tests on ruby 1.9 (mhulan@redhat.com)
- Fixes #3702 - Ruby 1.8 compatible fix for arrays (mhulan@redhat.com)
- Fixes #3687 - Tests are compatible with ruby 1.8 (mhulan@redhat.com)
- CI integration modifications (mhulan@redhat.com)

* Tue Nov 19 2013 Marek Hulan <mhulan@redhat.com> 0.3.1-1
- Fixes #3244 - Extend app options parsing (mhulan@redhat.com)
- Fixes #3670 - Ruby 1.8 compatible hooks (mhulan@redhat.com)
- Fixes #3619 - better parsing and escaping values (mhulan@redhat.com)
- Updating asciidoc exporter (lzap+git@redhat.com)
- Remove Fedora 18 koji target (dcleal@redhat.com)

* Fri Nov 08 2013 Marek Hulan <mhulan@redhat.com> 0.3.0-1
- Be more tolerant for manifests (mhulan@redhat.com)
- Fix tests caching (mhulan@redhat.com)
- Fix for Ruby 1.8 (mhulan@redhat.com)
- Namespace refactoring (mhulan@redhat.com)
- Conditions are evaluated and reflected in wizard refs #3337
  (mhulan@redhat.com)
- Wizard respects parameter groups (mhulan@redhat.com)
- Add encoding to new files (mhulan@redhat.com)
- Support for brief and full help (mhulan@redhat.com)
- Store parsed groups and conditions to params (mhulan@redhat.com)
- New parser abilities (mhulan@redhat.com)
- Add hooking support (mhulan@redhat.com)
- Adding ascidoc formatter (lzap+git@redhat.com)
- Fixes #3240 - Respect color settings in wizard (mhulan@redhat.com)

* Fri Nov 08 2013 Marek Hulan <mhulan@redhat.com>
- Be more tolerant for manifests (mhulan@redhat.com)
- Fix tests caching (mhulan@redhat.com)
- Fix for Ruby 1.8 (mhulan@redhat.com)
- Namespace refactoring (mhulan@redhat.com)
- Conditions are evaluated and reflected in wizard refs #3337
  (mhulan@redhat.com)
- Wizard respects parameter groups (mhulan@redhat.com)
- Add encoding to new files (mhulan@redhat.com)
- Support for brief and full help (mhulan@redhat.com)
- Store parsed groups and conditions to params (mhulan@redhat.com)
- New parser abilities (mhulan@redhat.com)
- Add hooking support (mhulan@redhat.com)
- Adding ascidoc formatter (lzap+git@redhat.com)
- Fixes #3240 - Respect color settings in wizard (mhulan@redhat.com)

* Wed Oct 09 2013 Marek Hulan <mhulan@redhat.com> 0.2.1-1
- Fixes #3227 - restore app options names (mhulan@redhat.com)
- Fixes #3217 - Do not output messages to STDOUT (mhulan@redhat.com)
- Fixes #3216 - Print error on STDOUT (mhulan@redhat.com)

* Mon Oct 07 2013 Marek Hulan <mhulan@redhat.com> 0.2.0-1
- Fixes #3062 - Add --no-colors support (mhulan@redhat.com)
- Fixes #3191 - custom verbose log level configuration (mhulan@redhat.com)
- Fixes #3188 - don't prefix symbols with !ruby/sym (mhulan@redhat.com)
- Fixes #3032 - ignore documentation inconsistency option (mhulan@redhat.com)
- Share CLI args with app config (mhulan@redhat.com)
- Merge pull request #21 from domcleal/help-sort (dominic@computerkb.co.uk)
- Sort modules and parameters in --help output (dcleal@redhat.com)
- Fixes #3175 - process exiting is handled more carefully (mhulan@redhat.com)
- Exit with 0 when calling kafo-configure --help (dcleal@redhat.com)
- Print validation errors to console when using progress bar (dcleal@redhat.com)

* Mon Sep 30 2013 Marek Hulan <mhulan@redhat.com> 0.1.0-1
- Progress bar support (mhulan@redhat.com)

* Fri Sep 27 2013 Marek Hulan <mhulan@redhat.com> 0.0.17-1
- Fixes #3161 - don't throw away arguments for validate_re (mhulan@redhat.com)

* Fri Sep 27 2013 Marek Hulan <mhulan@redhat.com>
- Fixes #3161 - don't throw away arguments for validate_re (mhulan@redhat.com)

* Thu Sep 26 2013 Marek Hulan <mhulan@redhat.com> 0.0.16-1
- Version bump

* Mon Sep 16 2013 Tomas Strachota <tstrachota@redhat.com> 0.0.15-1
- Fixes #3084 - PTY.check should never return nil (mhulan@redhat.com)

* Fri Sep 13 2013 Marek Hulan <mhulan@redhat.com> 0.0.14-1
- Fixes #3078 - system checks fix for Ruby 1.8.7 (mhulan@redhat.com)

* Thu Sep 12 2013 Marek Hulan <mhulan@redhat.com> 0.0.13-1
- Fixes packaging (mhulan@redhat.com)
- Revert "Fix for Fedora 19 OS name" (mhulan@redhat.com)
- Fix for dumping undef values in puppet 2.6 (mhulan@redhat.com)
- exit code 1 means parser error (necasik@gmail.com)
- Revert FQDN hostname enforcement (mhulan@redhat.com)
- You can change log filename via configuration (mhulan@redhat.com)
- Scripts for exporting params to md-like and html table (mhulan@redhat.com)
- Fix for Fedora 19 OS name (mhulan@redhat.com)
- Fixed type (mhulan@redhat.com)

* Fri Sep 06 2013 Marek Hulan <mhulan@redhat.com> 0.0.12-1
- Make internal moduels path configurable (mhulan@redhat.com)

* Fri Sep 06 2013 Marek Hulan <mhulan@redhat.com> 0.0.11-1
- Allow custom modules to define own validation functions (mhulan@redhat.com)
- Ensure Facter fqdn matches hostname -f Ensure we have an FQDN and not a
  shortname when done. (gsutclif@redhat.com)
- Support older RDoc (mhulan@redhat.com)
- Fix for short puppet messages (mhulan@redhat.com)
- We support RDoc4 (mhulan@redhat.com)
- Make sure decrypt function is available in templates (necasik@gmail.com)
- Generate random password for blank password param (necasik@gmail.com)

* Fri Sep 06 2013 Marek Hulan <mhulan@redhat.com> 0.0.10-1
- Readme update (mhulan@redhat.com)
- Explicit option to set path to modules directory (mhulan@redhat.com)
- Support puppet 2.7 undefined variables (mhulan@redhat.com)

* Thu Sep 05 2013 Marek Hulan <mhulan@redhat.com> 0.0.9-1
- Fix the name of an error (mhulan@redhat.com)
- Add encoding comment (mhulan@redhat.com)
- Fix exit in configuration (mhulan@redhat.com)
- Make sure that main config has mode 0600 (mhulan@redhat.com)
- Fix color layout on STDOUT (mhulan@redhat.com)

* Wed Sep 04 2013 Marek Hulan <mhulan@redhat.com> 0.0.8-1
- Fixed loading from custom default_values_dir (mhulan@redhat.com)

* Wed Sep 04 2013 Marek Hulan <mhulan@redhat.com> 0.0.7-1
- Support relative paths for installer_dir (mhulan@redhat.com)
- Fixate all paths to installer_dir (mhulan@redhat.com)
- Offer an exit code, but don't actually exit (necasik@gmail.com)
- Make "dont_save_answers" option work properly (mhulan@redhat.com)
- Enable custom config comment template (mhulan@redhat.com)
- Dry up puppet execution (mhulan@redhat.com)
- Added create_resources puppet module (mhulan@redhat.com)
- Configuration cleanup (mhulan@redhat.com)
- Ruby-abi is not build requirement either (mhulan@redhat.com)
- Adds Fedora 19 support to rpm spec (mhulan@redhat.com)
- Fix small typo in example for mapping (inecas@redhat.com)

* Thu Aug 29 2013 Marek Hulan <mhulan@redhat.com> 0.0.6-3
- Ruby-abi is not build requirement either (mhulan@redhat.com)

* Thu Aug 29 2013 Marek Hulan <mhulan@redhat.com> 0.0.6-2
- Adds Fedora 19 support to rpm spec (mhulan@redhat.com)
- Use foreman tags for tito (mhulan@redhat.com)

* Thu Aug 29 2013 Marek Hulan <mhulan@redhat.com> 0.0.6-1
- new package built with tito


