app_dir = node[:opentsdbproxy][:appdir]
sup_conf = File.join(app_dir, "supervisor.conf")
sup_sock = File.join(app_dir, "supervisor.sock")

template sup_conf do
    source "supervisor.conf.erb"
    mode 0400
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
end

bash "Start supervisord or restart services" do
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    cwd app_dir
    environment({
        "HOME" => "/home/#{node[:opentsdbproxy][:username]}"
    })
    code <<-EOH
         if [ -e #{sup_sock} ]; then
    #{node[:opentsdbproxy][:supervisorctl_path]} -c #{sup_conf} restart all
         else
    #{node[:opentsdbproxy][:supervisord_path]} -c #{sup_conf}
         fi
    EOH
end
