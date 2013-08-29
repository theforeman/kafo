%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global gem_name kafo


%define rubyabi 1.8

Summary: A gem for making installations based on puppet user friendly
Name: %{?scl_prefix}rubygem-%{gem_name}
Version: 0.0.6
Release: 3%{?dist}
Group: Development/Libraries
License: GPLv3+
URL: https://github.com/theforeman/kafo
Source0: http://rubygems.org/downloads/%{gem_name}-%{version}.gem
%if 0%{?rhel} == 6 || 0%{?fedora} < 19
Requires: %{?scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires: %{?scl_prefix}puppet
Requires: %{?scl_prefix}rubygem(logging)
Requires: %{?scl_prefix}rubygem(clamp)
Requires: %{?scl_prefix}rubygem(highline)
Requires: %{?scl_prefix}rubygem(rdoc)
Requires: %{?scl_prefix}rubygems

%if 0%{?rhel} == 6 && 0%{?scl_prefix:0} || 0%{?fedora} > 17
BuildRequires: %{?scl_prefix}rubygems-devel
%else
%global gem_dir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gem_docdir %{gem_dir}/doc/%{gem_name}-%{version}
%global gem_cache %{gem_dir}/cache/%{gem_name}-%{version}.gem
%global gem_spec %{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%global gem_instdir %{gem_dir}/gems/%{gem_name}-%{version}
%global gem_libdir %{gem_dir}/gems/%{gem_name}-%{version}/lib
%endif

%if 0%{?rhel} == 6 || 0%{?fedora} < 19
BuildRequires: %{?scl_prefix}ruby(abi) >= %{rubyabi}
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
* Thu Aug 29 2013 Marek Hulan <mhulan@redhat.com> 0.0.6-3
- Ruby-abi is not build requirement either (mhulan@redhat.com)

* Thu Aug 29 2013 Marek Hulan <mhulan@redhat.com> 0.0.6-2
- Adds Fedora 19 support to rpm spec (mhulan@redhat.com)
- Use foreman tags for tito (mhulan@redhat.com)

* Thu Aug 29 2013 Marek Hulan <mhulan@redhat.com> 0.0.6-1
- new package built with tito


