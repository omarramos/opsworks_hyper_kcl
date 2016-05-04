include_attribute 'deploy'

default[:kcl] = {}

node[:deploy].each do |application, deploy|
  default[:kcl][application.intern] = {}
  default[:kcl][application.intern][:restart_command] = "sudo monit restart #{application}_kcl"
  default[:kcl][application.intern][:syslog] = false
end

