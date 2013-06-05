#Cookbook Name: torque::worker

execute "Configure Torque server" do
  command "echo #{node[:torque][:server_name]} > /var/spool/torque/server_name"
end

execute "Install SSH keys" do
  cwd "/home/torque"
  user "torque"
  group "torque"
  environment('HOME' => "/home/torque")
  command <<-EOH
  mkdir -p /home/torque/.ssh
  chmod 700 /home/torque/.ssh
  echo "StrictHostKeyChecking no" > /home/torque/.ssh/config
  echo -n "#{node[:torque][:ssh_public_key]}" >> /home/torque/.ssh/authorized_keys
  echo -n "#{node[:torque][:ssh_public_key]}" > /home/torque/.ssh/id_rsa.pub
  echo -n "#{node[:torque][:ssh_private_key]}" > /home/torque/.ssh/id_rsa
  chmod 600 /home/torque/.ssh/id_rsa.pub /home/torque/.ssh/id_rsa /home/torque/.ssh/config /home/torque/.ssh/authorized_keys
  EOH
end

execute "Run Torque Worker Daemon" do
  command "/usr/local/sbin/pbs_mom"
  not_if "pgrep pbs_mom"
end
