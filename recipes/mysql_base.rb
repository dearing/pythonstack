# Encoding: utf-8
#
# Cookbook Name:: pythonstack
# Recipe:: default
#
# Copyright 2014, Rackspace UK, Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Include the necessary recipes.
include_recipe 'apt' if node.platform_family?('debian')
include_recipe 'chef-sugar'
include_recipe 'database::mysql'
include_recipe 'platformstack::monitors'

# set passwords dynamically...
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
node.set_unless['pythonstack']['cloud_monitoring']['agent_mysql']['password'] = secure_password
if node['mysql']['server_root_password'] == 'ilikerandompasswords'
  node.set['mysql']['server_root_password'] = secure_password
end

include_recipe 'mysql::server'
include_recipe 'mysql-multi::mysql_base'

connection_info = {
  host: 'localhost',
  username: 'root',
  password: node['mysql']['server_root_password']
}

# add holland user (if holland is enabled)
mysql_database_user 'holland' do
  connection connection_info
  password node['holland']['password']
  host 'localhost'
  privileges [:usage, :select, :'lock tables', :'show view', :reload, :super, :'replication client']
  retries 2
  retry_delay 2
  action [:create, :grant]
  only_if { node.deep_fetch('holland', 'enabled') }
end

mysql_database_user node['pythonstack']['cloud_monitoring']['agent_mysql']['user'] do
  connection connection_info
  password node['pythonstack']['cloud_monitoring']['agent_mysql']['password']
  action 'create'
  only_if { node.deep_fetch('platformstack', 'cloud_monitoring', 'enabled') }
end

template 'mysql-monitor' do
  cookbook 'pythonstack'
  source 'monitoring-agent-mysql.yaml.erb'
  path '/etc/rackspace-monitoring-agent.conf.d/agent-mysql-monitor.yaml'
  owner 'root'
  group 'root'
  mode '00600'
  notifies 'restart', 'service[rackspace-monitoring-agent]', 'delayed'
  action 'create'
  only_if { node.deep_fetch('platformstack', 'cloud_monitoring', 'enabled') }
end

# allow traffic to mysql port for local addresses only
add_iptables_rule('INPUT', "-m tcp -p tcp --dport #{node['mysql']['port']} -j ACCEPT", 9999, 'Open port for mysql')
