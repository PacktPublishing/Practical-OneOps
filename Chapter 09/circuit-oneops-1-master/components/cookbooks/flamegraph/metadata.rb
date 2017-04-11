name               'Flamegraph'
description        'FlameGraph Installation For Java Apps'
long_description   IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version            "1.0"
maintainer         "OneOps"
maintainer_email   "support@oneops.com"
license            "Apache License, Version 2.0"

grouping 'default',
         :access => "global",
	 :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom'],
	 :namespace => true

attribute 'perf_record_seconds',
	:description => "Perf Recording Timings",
	:default => "100",
	:required => "required",
	:format => {
		:important => true,
		:category => '1.Perf_Map_Agent',
		:help => 'Perf Recording Timings',
		:order => 1
	}

attribute 'perf_record_freq',
	:description => "Perf Frequency",
	:default => "99",
	:required => "required",
	:format => {
		:important => true,
		:category => '1.Perf_Map_Agent',
		:help => 'Perf Frequency',
		:order => 2
	}

attribute 'perf_java_tmp',
	:description => "Perf Temp Folder",
	:default => "/tmp",
	:required => "required",
	:format => {
		:important => true,
		:category => '1.Perf_Map_Agent',
		:help => 'Perf Temp Folder',
		:order => 3
	}

attribute 'perf_data_file',
	:description => "Perf Data File",
	:default => "perf-out",
	:required => "required",
	:format => {
		:important => true,
		:category => '1.Perf_Map_Agent',
		:help => 'Perf Data File',
		:order => 4
	}

attribute 'perf_flame_output',
	:description => "Perf Flame Output",
	:default => "flamegraph-`date '+%Y-%m-%d-%H-%M'`.svg",
	:required => "required",
	:format => {
		:important => true,
		:category => '1.Perf_Map_Agent',
		:help => 'Perf Flame Output',
		:order => 5
	}

attribute 'flamegraph_dir',
	:description => "FlameGraph Dir",
	:default => "/tmp/flamegraph_src",
	:required => "required",
	:format => {
		:important => true,
		:category => '2.Flame_Graph',
		:help => 'Perf Flame Output',
		:order => 1
	}


attribute 'app_user',
	:description => "App User to run Commands",
	:required => 'required',
	:default => 'app',
	:format => {
		:help => 'App User',
		:category => '3.AppUser',
		:order => 1
	}

recipe 'create_graphs', 'Create Graphs'
