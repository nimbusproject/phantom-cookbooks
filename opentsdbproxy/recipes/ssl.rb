app_dir = node[:opentsdbproxy][:appdir]

if node[:opentsdbproxy][:ssl_cert].nil? and node[:opentsdbproxy][:ssl_key].nil?

  bash "generate SSL Key and Cert" do
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    cwd app_dir
    code <<-EOH
    openssl genrsa -out server.key 1024
    openssl req -new -key server.key -out server.csr -subj "/C=US/CN=#{node[:fqdn]}"
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
    EOH
  end

elsif node[:opentsdbproxy][:ssl_cert].nil? ^ node[:opentsdbproxy][:ssl_key].nil?
  raise "You must either set both an ssl cert and key or neither"
else
  
  file "#{app_dir}/server.key" do
    content node[:opentsdbproxy][:ssl_key]
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    action :create
  end
  
  file "#{app_dir}/server.crt" do
    content node[:opentsdbproxy][:ssl_cert]
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    action :create
  end
end
