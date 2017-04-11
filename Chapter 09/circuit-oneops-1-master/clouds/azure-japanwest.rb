name "azure-japanwest"
description "Microsoft Azure"
auth "3ACFA66E-1DA4-4A04-B3C1-48A1A4761C89"

image_map = '{
      "centos-7.0":"OpenLogic:CentOS:7.0:latest",
      "ubuntu-14.04":"canonical:ubuntuserver:14.04.3-LTS:14.04.201508050",
      "windows_2012_r2":"Microsoftwindowsserver:windowsserver:2012-R2-Datacenter:4.0.20161109"
    }'

repo_map = '{
      "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
      "ubuntu-14.04":"",
      "windows_2012_r2":""
}'

env_vars = '{ "rubygems":"https://rubygems.org/"}'

service "azure-japanwest",
  :cookbook => 'azure',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :offerings => {
      "xsmall" => {
          "description" => "Average Extra Small Azure Standard A0 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.021",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='XS'",
          "specification" => "{}"
      },
      "small" => {
          "description" => "Average Small Azure Standard A1 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.073",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='S'",
          "specification" => "{}"
      },
      "medium" => {
          "description" => "Average medium Azure Standard A2 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.146",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='M'",
          "specification" => "{}"
      },
      "large" => {
          "description" => "Average large Azure Standard A3 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.292",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='L'",
          "specification" => "{}"
      },
      "xlarge" => {
          "description" => "Average xlarge Azure Standard A4 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.584",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='XL'",
          "specification" => "{}"
      },
      "xxlarge" => {
          "description" => "Average xxlarge Azure Standard A5 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.258",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='XXL'",
          "specification" => "{}"
      },
      "xxxlarge" => {
          "description" => "Average 3xlarge Azure Standard A6 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.516",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='3XL'",
          "specification" => "{}"
      },
      "xxxxlarge" => {
          "description" => "Average 4xlarge Azure Standard A7 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "1.032",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='4XL'",
          "specification" => "{}"
      },
      "smallCPU" => {
          "description" => "Average Small Azure Standard D1 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.096",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='S-CPU'",
          "specification" => "{}"
      },
      "mediumCPU" => {
          "description" => "Average medium Azure Standard D2 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.192",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='M-CPU'",
          "specification" => "{}"
      },
      "largeCPU" => {
          "description" => "Average large Azure Standard D3 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.384",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='L-CPU'",
          "specification" => "{}"
      },
      "xlargeCPU" => {
          "description" => "Average xlarge Azure Standard D4 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.768",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='XL-CPU'",
          "specification" => "{}"
      },
      "8xlargeCPU" => {
          "description" => "Average 8xlarge Azure Standard D11 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.21",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='8XL-CPU'",
          "specification" => "{}"
      },
      "9xlargeCPU" => {
          "description" => "Average 9xlarge Azure Standard D12 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.42",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='9XL-CPU'",
          "specification" => "{}"
      },
      "10xlargeCPU" => {
          "description" => "Average 10xlarge Azure Standard D13 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.84",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='10XL-CPU'",
          "specification" => "{}"
      },
      "11xlargeCPU" => {
          "description" => "Average 11xlarge Azure Standard D14 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "1.68",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='11XL-CPU'",
          "specification" => "{}"
      },
      "smallMEM" => {
          "description" => "Average small Azure Standard DS1 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.096",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='M-MEM'",
          "specification" => "{}"
      },
      "mediumMEM" => {
          "description" => "Average medium Azure Standard DS2 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.192",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='M-MEM'",
          "specification" => "{}"
      },
      "largeMEM" => {
          "description" => "Average large Azure Standard DS3 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.384",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='L-MEM'",
          "specification" => "{}"
      },
      "xlargeMEM" => {
          "description" => "Average xlarge Azure Standard DS4 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.768",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='XL-MEM'",
          "specification" => "{}"
      },
      "8xlargeMEM" => {
          "description" => "Average 8xlarge Azure Standard DS11 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.21",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='8XL-MEM'",
          "specification" => "{}"
      },
      "9xlargeMEM" => {
          "description" => "Average 9xlarge Azure Standard DS12 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.42",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='9XL-MEM'",
          "specification" => "{}"
      },
      "10xlargeMEM" => {
          "description" => "Average 10xlarge Azure Standard DS13 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "0.84",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='10XL-MEM'",
          "specification" => "{}"
      },
      "11xlargeMEM" => {
          "description" => "Average 11xlarge Azure Standard DS14 cost per Hour",
          "cost_unit" => "USD",
          "cost_rate" => "1.68",
          "criteria"=> "(ciClassName matches 'bom.[a-zA-Z0-9.]*.Compute' OR ciClassName=='bom.Compute') AND ciAttributes['size']=='11XL-MEM'",
          "specification" => "{}"
      },
  },
  :attributes => {
    :location => 'japanwest',
    :ostype => '["CentOS-7","Windows"]',
    :imagemap => image_map,
    :repo_map => repo_map,
    :env_vars => env_vars
  }
