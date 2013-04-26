include_recipe "git"

execute "Remove OpenTSDB source" do
  command "rm -rf /opt/opentsdb"
end

# Git resource seems broken?
script "Extract OpenTSDB" do
  interpreter "bash"
  code <<-EOH
  git clone #{node[:opentsdb][:git_url]} opentsdb
  EOH
  cwd "/opt"
end

case node[:platform]
when "debian","ubuntu"
  %w{ autoconf gnuplot }.each do |pkg|
    package pkg
  end
end

execute "Build OpenTSDB" do
  command "./build.sh"
  cwd "/opt/opentsdb"
end

execute "Install OpenTSDB" do
  command "make install"
  cwd "/opt/opentsdb/build/"
end

execute "Create HBase Tables" do
  command "JAVA_HOME=$(readlink -f /usr/bin/java | sed \"s:bin/java::\") ./src/create_table.sh"
  cwd "/opt/opentsdb"
  environment ({'COMPRESSION' => 'none', 'HBASE_HOME' => node[:hbase][:location]})
end

directory node[:opentsdb][:cachedir]
  action :create
end

cron "clear_tsd_cache" do
  action :create
  minute "*/15"
  command %Q{
      cd #{node[:opentsdb][:cachedir]} &&
      find . -name "*" -print0 | xargs -0 rm
  }
end

bash "Start TSD" do
  code <<-EOH
  tsdb tsd --port=#{node[:opentsdb][:port]} --staticroot=/usr/local/share/opentsdb/static --cachedir=#{node[:opentsdb][:cachedir] --auto-metric &
  EOH
end
