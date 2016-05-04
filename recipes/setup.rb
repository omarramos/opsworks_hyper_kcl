# Adapted from unicorn::rails: https://github.com/aws/opsworks-cookbooks/blob/master/unicorn/recipes/rails.rb

include_recipe "opsworks_kcl::service"

MAVEN_PACKAGES = [
  # (group id, artifact id, version),
  ['com.amazonaws', 'amazon-kinesis-client', '1.6.2'],
  ['com.amazonaws', 'aws-java-sdk-core', '1.10.61'],
  ['com.amazonaws', 'aws-java-sdk-dynamodb', '1.10.61'],
  ['com.amazonaws', 'aws-java-sdk-kinesis', '1.10.61'],
  ['com.amazonaws', 'aws-java-sdk-cloudwatch', '1.10.61'],
  ['com.google.guava', 'guava', '18.0'],
  ['com.google.protobuf', 'protobuf-java', '2.6.1'],
  ['commons-lang', 'commons-lang', '2.6'],
  ['com.fasterxml.jackson.core', 'jackson-core', '2.7.4'],
  ['org.apache.httpcomponents', 'httpclient', '4.5.2'],
  ['org.apache.httpcomponents', 'httpcore', '4.4.4'],
  ['com.fasterxml.jackson.core', 'jackson-annotations', '2.7.4'],
  ['commons-codec', 'commons-codec', '1.10'],
  ['joda-time', 'joda-time', '2.9.3'],
  ['com.fasterxml.jackson.core', 'jackson-databind', '2.7.4'],
  ['commons-logging', 'commons-logging', '1.2']
]

# setup kcl service per app
node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping opsworks_kcl::setup application #{application} as it is not a Rails app")
    next
  end

  opsworks_deploy_user do
    deploy_data deploy
  end

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  # Allow deploy user to restart workers
  template "/etc/sudoers.d/#{deploy[:user]}" do
    mode 0440
    source "sudoer.erb"
    variables :user => deploy[:user]
  end
  
  template "#{deploy[:deploy_to]}/shared/scripts/kcl.sh" do
    mode 0740
    source "kcl.erb"
    user deploy[:user]
    group deploy[:group]
    variables({
      :deploy => deploy,
      :application => application
    })
  end

  template "#{deploy[:deploy_to]}/shared/scripts/kcl-#{deploy[:rails_env]}.properties" do
    mode 0740
    source "properties.erb"
    user deploy[:user]
    group deploy[:group]
    variables({
      :deploy => deploy,
      :application => application
    })
  end

  template "/etc/monit/conf.d/#{application}_kcl.monitrc" do
    mode 0644
    source "kcl_monitrc.erb"
    variables({
      :deploy => deploy,
      :application => application
    })
    notifies :reload, resources(:service => "monit"), :immediately
  end

  directory "#{deploy[:deploy_to]}/shared/scripts/jars/" do
    mode '0755'
    action :create
    user deploy[:user]
    group deploy[:group]
    not_if { File.exists?("#{deploy[:deploy_to]}/shared/scripts/jars/") }
  end

  def get_maven_jar_info(group_id, artifact_id, version)
    jar_name = "#{artifact_id}-#{version}.jar"
    jar_url = "http://repo1.maven.org/maven2/#{group_id.gsub(/\./, '/')}/#{artifact_id}/#{version}/#{jar_name}"
    [jar_name, jar_url]
  end

  MAVEN_PACKAGES.each do |jar|
    jar_name, jar_url = get_maven_jar_info(*jar)
    remote_file "#{deploy[:deploy_to]}/shared/scripts/jars/#{jar_name}" do
      source jar_url
      mode '0755'
      action :create
    end
  end
end
