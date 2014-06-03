#Cookbook Name: packer

package "bzr golang mercurial" do
  action :install
end

execute "Set up source" do
  user node[:packer][:username]
  group node[:packer][:groupname]
  environment({
     "HOME" => "/home/#{node[:packer][:username]}",
     "GOPATH" => "/home/#{node[:packer][:username]}/go"
  })
  cwd "/home/#{node[:packer][:username]}"
  command "go get -u github.com/mitchellh/gox"
end

git "/home/#{node[:packer][:username]}/go/src/github.com/mitchellh/packer" do
  repository node[:packer][:git_repo]
  reference node[:packer][:git_branch]
  action :sync
  user node[:packer][:username]
  group node[:packer][:groupname]
end

cookbook_file "servers.go" do
  path "/home/#{node[:packer][:username]}/go/src/github.com/rackspace/gophercloud/servers.go"
  action :create
end

execute "Compile packer" do
  cwd "/home/#{node[:packer][:username]}/go/src/github.com/mitchellh/packer"
  user node[:packer][:username]
  group node[:packer][:groupname]
  environment({
     "HOME" => "/home/#{node[:packer][:username]}",
     "GOPATH" => "/home/#{node[:packer][:username]}/go"
  })
  command <<-EOH
  export PATH="$GOPATH/bin:$PATH"
  make
  EOH
end

execute "Install Nimbus cloud client" do
  cwd "/home/#{node[:packer][:username]}"
  user node[:packer][:username]
  group node[:packer][:groupname]
  environment({
    "HOME" => "/home/#{node[:packer][:username]}"
  })
  command <<-EOH
  wget http://www.nimbusproject.org/downloads/#{node[:packer][:nimbus_cloud_client]}.tar.gz
  tar xzf #{node[:packer][:nimbus_cloud_client]}.tar.gz
  EOH
  not_if { File.exist?("/home/#{node[:packer][:username]}/#{node[:packer][:nimbus_cloud_client]}") }
end
