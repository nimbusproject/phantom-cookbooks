tcollector_path = "/usr/local/tcollector"

git "Get tcollector source" do
  repository node[:tcollector][:git_repository]
  revision "master"
  destination tcollector_path
  action :sync
end

bash "Start tcollector" do
  code <<-EOH
  if [ -f /var/run/tcollector.pid ]; then
    kill `cat /var/run/tcollector.pid`
    sleep 10
  fi
  #{tcollector_path}/tcollector.py --host #{node[:tcollector][:tsd_host]} --port #{node[:tcollector][:tsd_port]} --logfile #{node[:tcollector][:logfile]} -D
  EOH
end
