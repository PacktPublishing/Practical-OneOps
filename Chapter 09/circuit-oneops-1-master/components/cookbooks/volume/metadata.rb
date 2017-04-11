name             "Volume"
description      "Volume"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"
depends 'azuredatadisk'
depends 'os'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'size',
  :description => "Size",
  :required => "required",
  :default => "100%FREE",
  :format => {
    :important => true,
    :help => 'Volume size as percent of storage or in byte units (Examples: 100%FREE, 60%VG or 1G)',
    :category => '1.Global',
    :order => 1
  }

attribute 'device',
  :description => "Device",
  :format => {
    :help => 'Device to use for the volume (Note: if blank it will automatically use the device map from the related storage component, if nfs use server://nfsshare)',
    :category => '1.Global',
    :order => 2
  }

attribute 'mode',
  :description => "Mode",
  :required => "optional",
  :default => "no-raid",
  :format => {
    :help => 'Select this option to enable external raid functionality',
    :category => '1.Global',
    :form => { 'field' => 'select', 'options_for_select' => [
      ["RAID0", "raid0"],
      ["RAID1", "raid1"],
      ["RAID5", "raid5"],
      ["RAID10", "raid10"],
      ["NO-RAID", "no-raid"]] },
    :filter => {"all" => {"visible" => "mode:eq:invisible"}},
    :order => 3
  }

attribute 'fstype',
  :description => "Filesystem Type",
  :default => 'ext3',
  :format => {
    :important => true,
    :help => 'Select the type of filesystem that this volume should be formatted with',
    :category => '2.Filesystem',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['ext3','ext3'],['ext4','ext4'],['xfs','xfs'],['ocfs2','ocfs2'],['nfs','nfs'],['tmpfs','tmpfs']] }
  }

attribute 'mount_point',
  :description => "Mount Point. (For Windows specify the the drive letter)",
  :required => 'required',
  :default => '/volume',
  :format => {
    :important => true,
    :help => 'Directory path where the volume should be mounted',
    :category => '2.Filesystem',
    :order => 2
  }

attribute 'options',
  :description => "Mount Options",
  :format => {
    :help => 'Specify mount options such as ro,async,noatime etc.',
    :category => '2.Filesystem',
    :order => 3
  }

recipe "repair", "Repair Volume"

recipe "log-grep",
 :description => 'Grep-Search a File',
        :args => {
  "path" => {
    "name" => "Files",
    "description" => "Files space separated",
    "defaultValue" => "",
    "required" => true,
    "dataType" => "string"
  },
  "searchpattern" => {
    "name" => "SearchRegexPattern",
    "description" => "Search Regex",
    "defaultValue" => "",
    "required" => true,
    "dataType" => "string"
  },
  "StartLine" => {
    "name" => "StartAtLine",
    "description" => "Start Line # (Optional)",
    "defaultValue" => "0",
    "required" => false,
    "dataType" => "string"
  },
  "EndLine" => {
    "name" => "EndAtLine",
    "description" => "End Line # (Optional)",
    "defaultValue" => "",
    "required" => false,
    "dataType" => "string"
  }
}
recipe "log-grep-count",
 :description => 'Grep-Count matches in a File ',
        :args => {
  "path" => {
    "name" => "Files",
    "description" => "Files space separated",
    "defaultValue" => "",
    "required" => true,
    "dataType" => "string"
  },
  "searchpattern" => {
    "name" => "SearchRegexPattern",
    "description" => "Search Regex",
    "defaultValue" => "",
    "required" => true,
    "dataType" => "string"
  },
  "StartLine" => {
    "name" => "StartAtLine",
    "description" => "Start Line # (Optional)",
    "defaultValue" => "0",
    "required" => false,
    "dataType" => "string"
  },
  "EndLine" => {
    "name" => "EndAtLine",
    "description" => "End Line # (Optional)",
    "defaultValue" => "",
    "required" => false,
    "dataType" => "string"
  }
}
