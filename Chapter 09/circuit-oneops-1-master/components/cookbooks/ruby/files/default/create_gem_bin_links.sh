#!/bin/bash

cd /var/lib/gems/1.8/bin
for gem_bin in `ls -1 *`
do
	if [ ! -L /usr/bin/$gem_bin ]; then
		echo "Linking /usr/bin/$gem_bin to /var/lib/gems/1.8/bin/$gem_bin"
		ln -s /var/lib/gems/1.8/bin/$gem_bin /usr/bin/$gem_bin
	fi
done
