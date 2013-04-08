set_unless[:virtualenv][:python] = "python"
set_unless[:virtualenv][:virtualenv] = "virtualenv"
set_unless[:autoscale][:exceptional_api_key] = nil
set_unless[:autoscale][:statsd][:host] = nil
set_unless[:autoscale][:statsd][:port] = nil
set_unless[:autoscale][:opentsdb][:host] = "localhost"
set_unless[:autoscale][:opentsdb][:port] = 4242
