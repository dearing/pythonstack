# Encoding: utf-8
name 'pythonstack'
maintainer 'Rackspace'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license 'Apache 2.0'
description 'Installs/Configures pythonstack'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

depends 'apache2', '~> 1.10'
depends 'application'
depends 'application_python'
depends 'python'
depends 'chef-sugar'
depends 'git'
