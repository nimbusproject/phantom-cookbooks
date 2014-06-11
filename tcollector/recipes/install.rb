tcollector_path = "/usr/local/tcollector"

git "Get tcollector source" do
  repository node[:tcollector][:git_repository]
  revision "master"
  destination tcollector_path
  action :sync
end

if node[:tcollector][:use_ssl]
    use_ssl = "--use-ssl"
else
    use_ssl = ""
end

bash "Start tcollector" do
  code <<-EOH
  if [ -f /var/run/tcollector.pid ]; then
    kill `cat /var/run/tcollector.pid`
    sleep 10
  fi
  cp #{tcollector_path}/startstop /etc/init.d/tcollector
  service tcollector start
  EOH
end

bash "Set tcollector to start on boot" do
  case node[:platform]
  when "debian", "ubuntu"
    code "update-rc.d tcollector defaults"
  when "redhat", "centos", "fedora"
    code "/sbin/chkconfig --add tcollector"
  end
end
