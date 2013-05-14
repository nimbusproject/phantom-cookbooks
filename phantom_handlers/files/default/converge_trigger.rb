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

require 'chef/log'
require 'chef/config'
require 'chef/node'


class ConvergeTriggerHandler < Chef::Handler

  # forks off a sub process that polls a databag in the server, for hints
  # that this node should converge again early.
  @@poller_pid = nil

  def report
    # ensure poller is still alive
    if not @@poller_pid.nil?
      begin
        Process.kill(0, @@poller_pid)
      rescue Errno::ESRCH, Errno::EPERM
        @@poller_pid = nil
      end
    end

    if @@poller_pid.nil?
      ConvergeTriggerHandler.spawn(node.name)
    end
  end

  def self.spawn(node_name)
    begin
      # try to read from pidfile first, in case this is a forked process
      pid_file = Chef::Config[:pid_file] or "/tmp/#{@name}.pid"
      chef_client_pid = File.read(pid_file).chomp.to_i
    rescue Errno::ENOENT, Errno::EACCES
      chef_client_pid = Process.pid
    end

    poller = ConvergeTriggerPoller.new(chef_client_pid, node_name)
    Chef::Log.info "Forking converge trigger poller process"
    @@poller_pid = fork do
      poller.run
      exit
    end
  end
end

class ConvergeTriggerPoller
  def initialize(chef_pid, node_name)
    @chef_pid = chef_pid
    @node_name = node_name
  end

  def run
    loop do
      begin
        # poll the Chef process and die when it goes away
        Process.kill(0, @chef_pid)
      rescue Errno::ESRCH, Errno::EPERM
        return
      end

      if node_should_converge
      Chef::Log.info "Triggering converge"
        Process.kill("USR1", @chef_pid)
      end
      sleep 5
    end
  end

  private

  def node_should_converge
    # look for a should_converge flag on the node
    # if found, remove it and trigger the converge
    begin
      node = Chef::Node.load(@node_name)
      if node[:should_converge]
        node.set[:should_converge] = false
        node.save
        return true
      end
      false

    rescue Net::HTTPServerException => e
      false
    end
  end
end