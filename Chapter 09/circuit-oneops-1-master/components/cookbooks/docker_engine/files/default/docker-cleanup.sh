#!/bin/bash -x
docker rm -v $(docker ps -a -q -f status=exited)
docker rmi $(docker images -f "dangling=true" -q)
# ok for above to fail/not have any cleanup
exit 0