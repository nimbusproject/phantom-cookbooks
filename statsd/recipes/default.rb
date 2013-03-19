#
# Cookbook Name:: statsd
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

user node[:statsd][:username] do
  comment "Dynamically created user."
  gid "#{node[:statsd][:groupname]}"
  home "/home/#{node[:statsd][:username]}"
  shell "/bin/bash"
  supports :manage_home => true
end

template "/home/#{node[:statsd][:username]}/config.js" do
  source "config.js.erb"
  owner node[:statsd][:username]
  group node[:statsd][:groupname]
  mode 0600
  variables(
    :librato_email => node[:statsd][:librato_email],
    :librato_token => node[:statsd][:librato_token]
  )
end

execute "Run statsd" do
  user node[:statsd][:username]
  group node[:statsd][:groupname]
  cwd "/home/#{node[:statsd][:username]}"
  environment({
    'HOME' => "/home/#{node[:statsd][:username]}"
  })
  command <<-EOH
  PID=`ps aux | grep -v grep | grep node | grep statsd | awk '{ print $2 }'`
  if ! [ "x$PID" == "x" ]; then
    kill $PID
  fi
  nohup node /usr/local/lib/node_modules/statsd/stats.js $HOME/config.js >> $HOME/statsd.log 2>&1 &
  EOH
end
