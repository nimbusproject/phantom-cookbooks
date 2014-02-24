# hitting this bug when using java recipe from opscode:
# http://tickets.opscode.com/browse/OHAI-234
# using our own package list for now

#include_recipe "java"

case node[:platform]
when "debian"
  include_recipe "apt"

  execute "force update apt" do
      command "apt-get update"
      action :run
  end

  %w{ ant sqlite3 sun-java6-jdk uuid-runtime }.each do |pkg|
    package pkg
  end

  java_home = ""

when "ubuntu"
  include_recipe "apt"

  %w{ ant sqlite3 openjdk-7-jdk uuid-runtime }.each do |pkg|
    package pkg
  end

  java_home = "/usr/lib/jvm/java-7-openjdk-amd64/jre"

when "redhat","centos"
  %w{ java-1.6.0-openjdk ant sqlite }.each do |pkg|
    package pkg
  end
  java_home = "/usr/lib/jvm/java-1.6.0"
end

remote_file "/tmp/hbase-0.95-SNAPSHOT.tar.gz" do
  source node[:hbase][:source]
  checksum "34a74454cffe2a0e0cee71432a041e79f119c9c1ab4ead88f4a20f49c8f09bd2"
end

script "Extract HBase" do
  interpreter "bash"
  code <<-EOH
  tar xzf /tmp/hbase-0.95-SNAPSHOT.tar.gz
  mv hbase* hbase
  EOH
  cwd "/opt"
  creates "/opt/hbase"
end

template "/opt/hbase/conf/hbase-site.xml" do
  source "hbase-site.xml.erb"
end

script "Start HBase" do
  interpreter "bash"
  environment ({"JAVA_HOME" => java_home})
  code <<-EOH
  if ps axww | grep "org.apache.hadoop.hbase.master.HMaster start" | grep -v grep; then
    ./bin/stop-hbase.sh
    sleep 10
  fi
  ./bin/start-hbase.sh
  sleep 10
  ps axww | grep "org.apache.hadoop.hbase.master.HMaster start" | grep -v grep
  EOH
  cwd "/opt/hbase/"
end
