#
# Cookbook Name:: phantom_handlers
# Recipe:: default
#
# Copyright 2013, University of Chicago
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

include_recipe "chef_handler"

lastrun_handler_file = ::File.join(node['chef_handler']['handler_path'], "lastrun_update.rb")
converge_handler_file = ::File.join(node['chef_handler']['handler_path'], "converge_trigger.rb")

cookbook_file lastrun_handler_file do
  source "lastrun_update.rb"
  mode "0600"
  owner "root"
  group "root"
end.run_action(:create)

cookbook_file converge_handler_file do
  source "converge_trigger.rb"
  mode "0600"
  owner "root"
  group "root"
end.run_action(:create)

chef_handler "LastRunUpdateHandler" do
  source lastrun_handler_file
  action :nothing
end.run_action(:enable)

chef_handler "ConvergeTriggerHandler" do
  source converge_handler_file
  action :enable
  notifies :create, "ruby_block[converge_trigger_installed]", :immediately
  not_if { node.attribute?("converge_trigger_installed") }
end

# ensure handler is only installed the first time
ruby_block "converge_trigger_installed" do
  block do
    node.set['converge_trigger_installed'] = true
    node.save
  end
  action :nothing
end