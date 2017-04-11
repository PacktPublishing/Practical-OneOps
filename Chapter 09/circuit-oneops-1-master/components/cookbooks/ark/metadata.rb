name              "Ark"
description       "Installs/configures software archives"
version           "0.1"
maintainer        "OneOps"
maintainer_email  "support@oneops.com"
license          "Apache License, Version 2.0"


grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']
