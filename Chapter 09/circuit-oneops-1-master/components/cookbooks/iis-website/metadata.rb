name             'Iis-website'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook creates/configures iis website'
version          '0.1.0'

supports 'windows'
depends 'iis'

grouping 'default',
  :access   => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'physical_path',
  :description => 'Web Site Physical Path',
  :required    => 'required',
  :format      => {
    :help      => 'The physical path on disk this Web Site will point to, Default value is set to e:\apps',
    :category  => '1.IIS Web site',
    :order     => 1
  }

attribute 'log_file_directory',
  :description => 'Log file directory',
  :required    => 'required',
  :format      => {
    :help      => 'Set central w3c and central binary log file directory',
    :category  => '1.IIS Web site',
    :order     => 2
  }

attribute 'static_mime_types',
  :description => 'Mime type(s)',
  :data_type   => 'hash',
  :default     => '{}',
  :format      => {
    :help      => 'Adds MIME type(s) to the collection of static content types. Eg: .tab = application/xml',
    :category  => '1.IIS Web site',
    :order     => 3
  }

attribute 'binding_type',
  :description => 'Binding Type',
  :default     => 'http',
  :required    => 'required',
  :format      => {
    :help      => 'Select HTTP/HTTPS bindings that should be added to the IIS Web Site',
    :category  => '1.IIS Web site',
    :order     => 4,
    :form      => { 'field' => 'select',
                    'options_for_select' => [
                      ['http', 'http'],
                      ['https', 'https']
                    ]
                  }
  }

attribute 'binding_port',
  :description => 'Binding Port',
  :default     => '80',
  :required    => 'required',
  :format      => {
    :help      => 'IIS binding port',
    :category  => '1.IIS Web site',
    :order     => 5
  }

attribute 'windows_authentication',
  :description => 'Windows authentication',
  :default     => 'false',
  :format      => {
    :help      => 'Enable windows authentication',
    :category  => '1.IIS Web site',
    :form     => {'field' => 'checkbox'},
    :order     => 6
  }

attribute 'anonymous_authentication',
  :description => 'Anonymous authentication',
  :default     => 'true',
  :format      => {
    :help      => 'Enable anonymous authentication',
    :category  => '1.IIS Web site',
    :form     => {'field' => 'checkbox'},
    :order     => 7
  }

attribute 'runtime_version',
:description => '.Net CLR version',
:required    => 'required',
:default     => 'v4.0',
:format      => {
  :help      => 'The version of .Net CLR runtime that the application pool will use',
  :category  => '2.IIS Application Pool',
  :order     => 1,
  :form      => { 'field' => 'select',
                  'options_for_select' => [['v2.0', 'v2.0'], ['v4.0', 'v4.0']]
                }
}

attribute 'identity_type',
  :description => 'Identity type',
  :required    => 'required',
  :default     => 'ApplicationPoolIdentity',
  :format      => {
  :help        => 'Select the built-in account which application pool will use',
    :category  => '2.IIS Application Pool',
    :order     => 2,
    :form      => { 'field' => 'select',
                    'options_for_select' => [
                      ['Application Pool Identity', 'ApplicationPoolIdentity'],
                      ['Network Service', 'NetworkService'],
                      ['Local Service', 'LocalService'],
                      ['Specific User', 'SpecificUser']
                    ]
                  }
  }

attribute 'process_model_user_name',
  :description => 'Username',
  :default     => '',
  :format      => {
  :help        => 'The user name of the account which application pool will use',
    :category  => '2.IIS Application Pool',
    :order     => 3,
    :filter    => {'all' => {'visible' => 'identity_type:eq:SpecificUser'}}
  }

attribute 'process_model_password',
  :description => 'Password',
  :encrypted   => true,
  :default     => '',
  :format      => {
  :help        => 'Password for the user account',
    :category  => '2.IIS Application Pool',
    :order     => 4,
    :filter    => {'all' => {'visible' => 'identity_type:eq:SpecificUser'}}
  }


attribute 'enable_static_compression',
  :description => 'Enable static compression',
  :default     => 'true',
  :format      => {
    :help      => 'Specifies whether static compression is enabled for URLs.',
    :category  => '3.IIS Static Compression',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'sc_level',
  :description => 'Compression level',
  :default     => '7',
  :required    => 'required',
  :format      => {
    :help      => 'Compression level - from 0 (none) to 10 (maximum)',
    :category  => '3.IIS Static Compression',
    :order     => 2,
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [['0', '0'], ['1', '1'], ['2', '2'],
                                             ['3', '3'], ['4', '4'], ['5', '5'],
                                             ['6', '6'], ['7', '7'], ['8', '8'],
                                             ['9', '9'], ['10', '10']]
                  }
  }

attribute 'sc_mime_types',
  :description => 'Mime type(s)',
  :default     => '{
    "text/*":"true",
    "message/*":"true",
    "application/x-javascript":"true",
    "application/atom+xml":"true",
    "application/json":"true",
    "application/xml":"true",
    "*/*":"false"
  }',
  :data_type   => 'hash',
  :format      => {
    :help      => 'Which mime-types will be / will not be compressed',
    :category  => '3.IIS Static Compression',
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :order     => 3
  }

attribute 'sc_cpu_usage_to_disable',
  :description => 'CPU usage disable',
  :default     => '90',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) above which compression is disabled',
      :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
      :category  => '3.IIS Static Compression',
      :order     => 4
  }

attribute 'sc_cpu_usage_to_reenable',
  :description => 'CPU usage re-enable',
  :default     => '50',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) below which compression is re-enabled after disable due to excess usage',
      :category  => '3.IIS Static Compression',
      :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
      :order     => 5
  }

attribute 'compression_max_disk_usage',
  :description => 'Maximum disk usage',
  :default     => '100',
  :required    => 'required',
  :format      => {
    :help      => 'Disk space limit (in megabytes), that compressed files can occupy',
    :category  => '3.IIS Static Compression',
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :order     => 5
  }

attribute 'compresion_min_file_size',
  :description => 'Minimum file size to compression',
  :required    => 'required',
  :default     => '2400',
  :format      => {
    :help      => 'The minimum file size (in bytes) for a file to be compressed',
    :category  => '3.IIS Static Compression',
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :order     => 5
  }

attribute 'sc_file_directory',
  :description => 'Compression file directory',
  :required    => 'required',
    :format      => {
      :help      => 'Location of the directory to store compressed files',
      :category  => '3.IIS Static Compression',
      :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
      :order     => 6
    }

attribute 'enable_dynamic_compression',
  :description => 'Enable dynamic compression',
  :default     => 'true',
  :format      => {
    :help      => 'Specifies whether dynamic compression is enabled for URLs',
    :category  => '4.IIS Dynamic Compression',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'dc_level',
  :description => 'Compression level',
  :default     => '0',
  :required    => 'required',
  :format      => {
    :help      => 'Compression level - from 0 (none) to 10 (maximum)',
    :category  => '4.IIS Dynamic Compression',
    :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
    :order     => 2,
    :form      => { 'field' => 'select',
                    'options_for_select' => [['0', '0'], ['1', '1'], ['2', '2'],
                                             ['3', '3'], ['4', '4'], ['5', '5'],
                                             ['6', '6'], ['7', '7'], ['8', '8'],
                                             ['9', '9'], ['10', '10']]
                  }
  }

attribute 'dc_mime_types',
  :description => 'Mime type(s)',
  :default     => '{
    "text/*":"true",
    "message/*":"true",
    "application/x-javascript":"true",
    "application/xml":"true",
    "*/*":"false"
  }',
  :data_type   => 'hash',
  :format      => {
    :help      => 'Which mime-types will be / will not be compressed',
    :category  => '4.IIS Dynamic Compression',
    :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
    :order     => 3
  }

attribute 'dc_cpu_usage_to_disable',
  :description => 'CPU usage disable',
  :default     => '90',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) above which compression is disabled',
      :category  => '4.IIS Dynamic Compression',
      :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
      :order     => 4
    }

attribute 'dc_cpu_usage_to_reenable',
  :description => 'CPU usage re-enable',
  :default     => '50',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) below which compression is re-enabled after disable due to excess usage',
      :category  => '4.IIS Dynamic Compression',
      :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
      :order     => 5
    }

attribute 'url_compression_dc_before_cache',
  :description => 'Dynamic compression before cache',
  :default     => 'false',
  :format      => {
    :help      => 'Specifies whether the currently available response is dynamically compressed before it is put into the output cache.',
    :category  => '4.IIS Dynamic Compression',
    :form      => {'field' => 'checkbox'},
    :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
    :order     => 6
  }

attribute 'dc_file_directory',
  :description => 'Compression file directory',
  :required    => 'required',
    :format      => {
      :help      => 'Location of the directory to store compressed files',
      :category  => '4.IIS Dynamic Compression',
      :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
      :order     => 7
    }

attribute 'session_state_cookieless',
  :description => 'Cookieless',
  :default     => 'UseCookies',
  :format      => {
    :help      => 'Specifies how cookies are used for a Web application.',
    :category  => '5.Session State',
    :form        => { 'field' => 'select',
                    'options_for_select' => [['Use URI', 'UseURI'], ['Use Cookies', 'UseCookies'],
                                             ['Auto Detect', 'AutoDetect'], ['Use Device Profile', 'UseDeviceProfile']]
                    },
    :order     => 1
  }

attribute 'session_state_cookie_name',
  :description => 'Cookie name',
  :default     => 'ASP.NET_SessionId',
  :format      => {
    :help      => 'Specifies the name of the cookie that stores the session identifier.',
    :category  => '5.Session State',
    :order     => 2
  }

attribute 'session_time_out',
  :description => 'Time out',
  :default     => '20',
  :format      => {
    :help      => 'Specifies the number of minutes a session can be idle before it is abandoned.',
    :category  => '5.Session State',
    :order     => 3
  }

attribute 'requestfiltering_allow_double_escaping',
  :description => 'Allow double escaping',
  :default     => 'false',
  :format      => {
    :help      => 'If set to false, request filtering will deny the request if characters that have been escaped twice are present in URLs.',
    :category  => '6.Request filtering',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'requestfiltering_allow_high_bit_characters',
  :description => 'Allow high bit characters',
  :default     => 'true',
  :format      => {
    :help      => 'If set to true, request filtering will allow non-ASCII characters in URLs.',
    :category  => '6.Request filtering',
    :form      => {'field' => 'checkbox'},
    :order     => 2
  }

attribute 'requestfiltering_verbs',
  :description => 'Verbs',
  :default     => '{ "TRACE": "false" }',
  :data_type   => 'hash',
  :format      => {
    :help      => 'Specifies which HTTP verbs are allowed or denied to limit types of requests sent to the Web server.',
    :category  => '6.Request filtering',
    :order     => 3
  }

attribute 'requestfiltering_max_allowed_content_length',
  :description => 'Maximum allowed content length',
  :default     => '30000000',
  :format      => {
    :help      => 'Specifies the maximum length of content in a request, in bytes.',
    :category  => '6.Request filtering',
    :order     => 4
  }

attribute 'requestfiltering_max_url',
  :description => 'Maximum url length',
  :default     => '4096',
  :format      => {
    :help      => 'Specifies the maximum length of the URL, in bytes.',
    :category  => '6.Request filtering',
    :order     => 5
  }

attribute 'requestfiltering_max_query_string',
  :description => 'Maximum query string length',
  :default     => '2048',
  :format      => {
    :help      => 'Specifies the maximum length of the query string, in bytes.',
    :category  => '6.Request filtering',
    :order     => 6
  }

attribute 'requestfiltering_file_extension_allow_unlisted',
  :description => 'File extension allow unlisted',
  :default     => 'true',
  :format      => {
    :help      => 'Specifies whether the Web server should process files that have unlisted file name extensions.',
    :category  => '6.Request filtering',
    :form      => {'field' => 'checkbox'},
    :order     => 7
  }

recipe 'app_pool_recycle', 'Recycle application pool'
recipe 'iis_reset', 'Restart IIS'
