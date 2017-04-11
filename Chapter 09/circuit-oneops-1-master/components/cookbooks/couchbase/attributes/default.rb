set["couchbase"]["cbhotfix_220_url"]="http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/couchbase/beam/2.2.0-XDCR/beam-2.2.0-XDCR-HF.tar"
# Default Couchbase download site
default[:couchbase][:src_mirror]     = 'http://packages.couchbase.com/releases/'
default[:couchbase][:cbhotfix_220_url]     = 'http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/couchbase/beam/2.2.0-XDCR/beam-2.2.0-XDCR-HF.tar'

set_unless[:membase][:clustersize]   = 4000
set_unless[:membase][:bucketsize]    = 4000
set_unless[:membase][:adminuser]     = "Administrator"
set_unless[:membase][:adminpassword] = "password"
set_unless[:membase][:ver]           = "1.6.5"
set_unless[:membase][:arch]          = "x86_64"
set_unless[:membase][:download]      = "http://easybibdeployment.s3.amazonaws.com/membase-server-community_x86_64_1.6.5.deb"



