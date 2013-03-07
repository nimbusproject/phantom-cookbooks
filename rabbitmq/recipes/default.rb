case node[:platform]
when "debian"
  bash "enable rabbit apt repo" do
    user "root"
    code <<-EOH
    echo '#{node[:rabbitmq][:apt_repo]}' >> /etc/apt/sources.list.d/rabbit.list
    wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
    apt-key add rabbitmq-signing-key-public.asc
    EOH
    not_if "grep '#{node[:rabbitmq][:apt_repo]}' /etc/apt/sources.list.d/rabbit.list"
  end

  execute "force update apt" do
      command "apt-get update"
      action :run
  end

end

package "rabbitmq-server" do
  action :install
end

template "/etc/rabbitmq/rabbitmq-env.conf" do
  source "rabbitmq-env.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/rabbitmq/rabbitmq.config" do
  source "rabbitmq.config.erb"
  owner "root"
  group "root"
  mode 0644
  #notifies :restart, "service[rabbitmq-server]"
end

service "rabbitmq-server" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

if node[:rabbitmq].include? :vhosts
  node[:rabbitmq][:vhosts].each do |vhost|
    execute "Add vhost #{vhost}" do
      returns [0,2] # ok if vhost already exists
      command "rabbitmqctl -q add_vhost #{vhost}"
    end
  end
end

if node[:rabbitmq].include? :users and not node[:rabbitmq][:users].empty?

  execute "Remove default guest user" do
    returns [0,2] # if the guest user doesn't exist, that's ok
    command "rabbitmqctl -q delete_user guest"
  end

  node[:rabbitmq][:users].each do |username, spec|
    execute "Add user #{username}" do
      returns [0,2] # if the user already exists, that's ok
      command "rabbitmqctl -q add_user #{username} #{spec[:password]}"
    end
    
    if spec.include? :permissions
      spec[:permissions].each do |vhost, perms|
        execute "Set permissions for user=#{username} vhost=#{vhost}" do
          command "rabbitmqctl -q set_permissions -p #{vhost} #{username} "+
            "'#{perms[:conf]}' '#{perms[:write]}' '#{perms[:read]}'"
        end
      end
    end
  end
end
