%{?scl:%scl_package rubygem-%{gem_name}}
%{!?scl:%global pkg_name %{name}}

%global gem_name kafo

%define rubyabi 1.9.1

Summary: A gem for making installations based on puppet user friendly
Name: %{?scl_prefix}rubygem-%{gem_name}
Version: 0.0.5
Release: 1%{?dist}
Group: Development/Libraries
License: GPLv3+
URL: https://github.com/theforeman/kafo
Source0: http://rubygems.org/downloads/%{gem_name}-%{version}.gem
Requires: %{?scl_prefix}ruby(abi) >= %{rubyabi}
Requires: %{?scl_prefix}rubygem(puppet)
Requires: %{?scl_prefix}rubygem(logging)
Requires: %{?scl_prefix}rubygem(clamp)
Requires: %{?scl_prefix}rubygem(highline)
Requires: %{?scl_prefix}rubygem(rdoc)
Requires: %{?scl_prefix}rubygems
BuildRequires: %{?scl_prefix}rubygems-devel
BuildRequires: %{?scl_prefix}ruby(abi) >= %{rubyabi}
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
%exclude %{gem_dir}/cache/%{gem_name}-%{version}.gem

%files doc
%doc %{gem_instdir}/LICENSE.txt
%doc %{gem_instdir}/README.md
%{gem_spec}

%changelog
