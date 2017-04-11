name             "Image"
description      "Image for Containers"
version          "0.1"
maintainer       "OneOps, Inc."
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

depends 'artifact'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'account', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]


# Image

attribute 'image_type',
  :description => "Image Type",
  :required => "required",
  :default => "registry",
  :format => {
    :category => '1.Image',
    :important => true,
    :help => 'Select image type',
    :order => 1,
    :form => {
      'field' => 'select',
      'options_for_select' => [
        ['Use image from registry','registry'],
        ['Build image using Dockerfile from a URL context','url'],
        ['Build image by specifying custom Dockerfile','dockerfile']
      ]
    }
  }

# registry
attribute 'image',
  :description => "Image Name",
  :default => "alpine",
  :format => {
    :help => 'Reference to an image name in the registry',
    :category => '1.Image',
    :important => true,
    :order => 2,
    :filter => {:all => {:visible => 'image_type:eq:registry'}}
  }

# application source
attribute 'url',
  :description => 'Application Package URL',
  :default => '',
  :format => {
    :help => 'URL to Dockefile, source code repository or application package',
    :important => true,
    :category => '1.Image',
    :order => 3,
    :filter => {:all => {:visible => 'image_type:ne:registry'}}
  }

attribute 'tag',
  :description => "Version Tag",
  :default => 'latest',
  :format => {
    :help => 'Version for the image tag',
    :important => true,
    :category => '1.Image',
    :order => 4,
    :filter => {:all => {:visible => 'image_type:ne:registry'}}
  }

attribute 'cache',
  :description => "Cache",
  :default => 'true',
  :format => {
    :help => 'Use cache when building the image',
    :category => '1.Image',
    :form => { 'field' => 'checkbox' },
    :order => 5,
    :filter => {:all => {:visible => 'image_type:ne:registry'}}
  }

# dockerfile
attribute 'dockerfile',
  :description => 'Dockerfile Content',
  :data_type => "text",
  :default => '',
  :format => {
    :help => 'Insert Dockerfile content needed to create the image',
    :category => '1.Image',
    :order => 6,
    :tip => 'Leave empty to use Dockerfile from application package',
    :filter => {:all => {:visible => 'image_type:eq:dockerfile'}}
  }


# bom only
attribute 'image_url',
  :description => "Image URL",
  :grouping => 'bom',
  :format => {
    :help => 'Full Image URL repository/image-name:tag',
    :category => '2.Repository',
    :order => 1
  }

recipe "repair", "Repair"
