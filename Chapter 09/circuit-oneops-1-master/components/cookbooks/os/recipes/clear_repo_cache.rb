#!/usr/bin/env ruby
`wget -r --header="Pragma:no-cache" --header="Cache-Control:no-cache" --no-parent http://$OO_CLOUD{satproxy}/epel/6/repodata/`