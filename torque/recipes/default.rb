#Cookbook Name: torque

package "build-essential" do
  action :install
end

group "torque" do
end

user "torque" do
  gid "torque"
  home "/home/torque"
  shell "/bin/bash"
end

directory "/home/torque" do
  owner "torque"
  group "torque"
  mode 0755
end

torque_tarball = "#{Chef::Config[:file_cache_path]}/torque-3.0.6.tar.gz"
torque_dir = "/tmp/torque-3.0.6"

remote_file torque_tarball do
  source "http://www.adaptivecomputing.com/index.php?wpfb_dl=190"
  checksum "f76736d780fc0f8ac73c54d586b4d15704e37cf191649b748b07f660186642b3"
end

execute "Extract Torque" do
  cwd "/tmp"
  command "tar xzf #{torque_tarball}"
  not_if { File.exists?(torque_dir) }
end

execute "Build and install Torque" do
  cwd torque_dir
  command "./configure && make install"
  not_if { File.exists?('/usr/local/sbin/pbs_server') }
end
