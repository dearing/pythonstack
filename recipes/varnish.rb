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

include_recipe 'chef-sugar'
if platform_family?('debian')
  include_recipe 'apt'
end

if rhel?
  include_recipe 'yum-epel'
end

add_iptables_rule('INPUT', "-p tcp --dport #{node['varnish']['listen_port']} -j ACCEPT", 9997, 'allow web browsers to connect')

# set the default port to send things on to something that might be useful
node.default['varnish']['backend_port'] = node[node['pythonstack']['webserver']]['listen_ports'].first

# pull a list of backend hosts to populate the template
# node.default['pythonstack']['varnish']['backend_hosts'] = Hash.new
backend_hosts = {}
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
  backend_nodes = nil
else
  backend_nodes = search('node', "tags:python_app_node AND chef_environment:#{node.chef_environment}")
end

backend_nodes.each do |backend_node|
  if backend_node.deep_fetch(node['pythonstack']['webserver'], 'sites').nil?
    errmsg = 'Did not find sites, default.vcl not configured'
    Chef::Log.warn(errmsg)
  else
    backend_node[node['pythonstack']['webserver']]['sites'].each do |site_name|
      site_name = site_name[0]
      site = backend_node[node['pythonstack']['webserver']]['sites'][site_name]
      backend_hosts.merge!(
        best_ip_for(backend_node) => {
          site['port'] => {
            site_name => site_name
          }
        }
      )
    end
  end
end

node.default['pythonstack']['varnish']['backends'] = backend_hosts

# only set if we have backends to populate (aka not on first run with an all in one node)
if backend_nodes.first.nil?
  # if our backends go away we needs this
  node.default['varnish']['vcl_cookbook'] = 'varnish'
  node.default['varnish']['vcl_source'] = 'default.vcl.erb'
else
  # let us set up a more complicated vcl config if needed
  node.default['varnish']['vcl_cookbook'] = 'pythonstack' if node['pythonstack']['varnish']['multi']
  node.default['varnish']['vcl_source'] = 'varnish-default-vcl.erb' if node['pythonstack']['varnish']['multi']
end
include_recipe 'varnish::default'
