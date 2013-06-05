#Cookbook Name: phorque

package "git-core python-setuptools" do
  action :install
end

git "/tmp/phorque" do
  repository "git://github.com/nimbusproject/phorque.git"
  action :sync
end

execute "Install phorque" do
  cwd "/tmp/phorque"
  command "python setup.py install"
end

execute "Generate SSH keys" do
  cwd "/home/torque"
  user "torque"
  group "torque"
  environment('HOME' => "/home/torque")
  command <<-EOH
  if ! [ -f /home/torque/.ssh/id_rsa ]; then
    mkdir -p /home/torque/.ssh
    chmod 700 /home/torque/.ssh
    ssh-keygen -f /home/torque/.ssh/id_rsa -N ''
    chmod 600 /home/torque/.ssh/id_rsa.pub /home/torque/.ssh/id_rsa
  fi
  echo "StrictHostKeyChecking no" > /home/torque/.ssh/config
  cat /home/torque/.ssh/id_rsa.pub >> /home/torque/.ssh/authorized_keys
  chmod 600 /home/torque/.ssh/id_rsa.pub /home/torque/.ssh/id_rsa /home/torque/.ssh/config /home/torque/.ssh/authorized_keys
  EOH
end

template "/home/torque/user_data" do
    source "user_data.erb"
    mode 0644
    owner "torque"
    group "torque"
    variables({
      :server_name => node[:fqdn],
      :ssh_public_key => "/home/torque/.ssh/id_rsa.pub",
      :ssh_private_key => "/home/torque/.ssh/id_rsa"
    })
end

template "/home/torque/phorque.ini" do
    source "phorque.ini.erb"
    mode 0644
    owner "torque"
    group "torque"
    variables({
      :clouds => node[:phorque][:clouds],
      :price_per_hour => node[:phorque][:price_per_hour],
      :user_data_file => "/home/torque/user_data"
    })
end

execute "Run phorque" do
  cwd "/home/torque"
  user "torque"
  group "torque"
  environment('HOME' => "/home/torque")
  command "nohup phorque.py -c /home/torque/phorque.ini -d > /home/torque/phorque.log 2>&1 &"
end
