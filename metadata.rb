maintainer       "Omar Ramos"
license          "MIT"
description      "Configure and deploy KCL on opsworks."

name   'opsworks_kcl'
recipe 'opsworks_kcl::setup',     'Set up kcl.'
recipe 'opsworks_kcl::configure', 'Configure kcl.'
recipe 'opsworks_kcl::deploy',    'Deploy kcl.'
recipe 'opsworks_kcl::undeploy',  'Undeploy kcl.'
recipe 'opsworks_kcl::stop',      'Stop kcl.'
