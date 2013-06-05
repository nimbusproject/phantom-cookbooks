#Cookbook Name: torque::server

include_recipe "torque::default"

torque_dir = "/tmp/torque-3.0.6"

execute "Configure Torque" do
  cwd torque_dir
  command <<-EOH
  echo localhost > /var/spool/torque/server_name
  yes | ./torque.setup torque
  echo localhost > /var/spool/torque/server_priv/nodes
  qterm; /usr/local/sbin/pbs_server

  qmgr -c "set server scheduling=true"
  qmgr -c "set server mom_job_sync=true"
  qmgr -c "set server query_other_jobs=true"
  qmgr -c "set server tcp_timeout=20"
  qmgr -c "create queue default queue_type=execution"
  qmgr -c "set queue default started=true"
  qmgr -c "set queue default enabled=true"
  qmgr -c "set queue default resources_default.nodes=1"
  qmgr -c "set queue default resources_default.walltime=3600"
  qmgr -c "set server default_queue=default"
  qmgr -c "set server scheduler_iteration=10"
  qmgr -c 'set server managers += torque@#{node[:fqdn]}'
  EOH
end

execute "Run Torque scheduler" do
  command "/usr/local/sbin/pbs_sched"
  not_if "pgrep pbs_sched"
end
