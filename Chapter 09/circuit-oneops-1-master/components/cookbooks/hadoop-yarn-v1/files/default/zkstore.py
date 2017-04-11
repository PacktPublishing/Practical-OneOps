#!/usr/bin/env python

from kazoo.client import KazooClient
from argparse import ArgumentParser
import sys

def _put(putnode, putdata):
    """ puts data specified in the node specified """
    # if the node already exists, update it
    if zk.exists(putnode):
        zk.set(putnode, putdata)
    # if the node doesn't exist, create it
    else:
        zk.create(putnode, putdata, makepath=True)

def _get(getnode):
    """ if specified node has children, it will list children.  if node specified has data, it will list data """
    # try to see if we can get the node specified
    try:
        # if the node has children, return list of children
        if zk.get_children(getnode):
            nodedata = [node.encode('ascii') for node in zk.get_children(getnode) ]
        # if the node has data, return data
        else:
            nodedata = zk.get(getnode)[0]
    # if specified node doesn't exist, die
    except:
        _die('ERROR: there is no such node as %s' % getnode)

    return nodedata

def _getclusterinfo(subdomain):
    try:
        _get("/%s" % subdomain)
    except:
        _die('The subdomain %s does not exist on the zookeepers specified' % subdomain)

    """ prints out cluster info """
    activeRM = _get("/%s/yarn/resourcemanager/active" % subdomain)
    standbyRM = _get("/%s/yarn/resourcemanager/standby" % subdomain)
    datanodes = _get("/%s/yarn/datanodes" % subdomain)
    clients = _get("/%s/yarn/clients" % subdomain)

    print "-------------------------------------------------------------------------------"
    print "cluster info for %s" % subdomain
    print "-------------------------------------------------------------------------------"
    print " active resource manager: %s" % activeRM
    print "standby resource manager: %s" % standbyRM
    print "               datanodes: %s" % ', '.join(datanodes)
    print "                 clients: %s" % ', '.join(clients)
    print "        cluster overview: http://%s:50070" % activeRM
    print "             job tracker: http://%s:8088" % activeRM

def _del(delnode):
    """ delete the node recursively """
    zk.delete(delnode, recursive=True)

def _die(error_message=None):
    """nod to perl die"""
    if error_message:
        #print error_message + '\n'
        sys.stderr.write(error_message + '\n')
    #_examples()
    sys.exit(0)

def _getArguments():
    """ reads in arguments passed in, returns options """
    parser = ArgumentParser(description='tool to store/retrieve attributes in zookeeper')
    parser.add_argument('--debug', action='store_true', default=False, dest='debugMode', help='debug mode')
    parser.add_argument('--zks', nargs='*', dest='zks', default=None, help='space separated list of zookeepers in the format of hostname:port')
    parser.add_argument('--putnode', dest='putnode', default=None, help='full path of node (attribute) to create')
    parser.add_argument('--putdata', dest='putdata', default=None, help='data to put into node, enclosed in quotes')
    parser.add_argument('--getnode', dest='getnode', default=None, help='full path of node (attribute) to retrieve')
    parser.add_argument('--delnode', dest='delnode', default=None, help='full path of node (attribute) to delete')
    parser.add_argument('--subdomain', dest='subdomain', default=None, help='subdomain of the environment')
    parser.add_argument('--clusterinfo', action='store_true', default=False, dest='clusterinfo', help='display clusters info')

    if len(sys.argv)==1:
        parser.print_help()
        _die()

    options = parser.parse_args()

    # we need to connect somewhere, right?
    if not options.zks :
        _die('ERROR: zookeeper(s) needs to be specified')

    actions=[options.putnode, options.getnode, options.delnode, options.clusterinfo]
    numberOfActions = len([ action for action in actions if action ])

    if numberOfActions != 1:
        _die('ERROR: one and only one --getnode, --putnode, --delnode, or --clusterinfo needs to be specified')
    # if put is specified, make sure data is included
    elif options.clusterinfo and not options.subdomain :
        _die('ERROR: specify --subdomain for clusterinfo')
    elif options.putnode and not options.putdata :
        _die('ERROR: specify --putdata to put into node')

    return options

def main():
    # get arguments
    options = _getArguments()

    global DEBUG

    if options.debugMode:
        DEBUG = True
    else:
        DEBUG = False

    # zks need to be comma delimited
    zks = ','.join(options.zks)

    global zk

    # create zk object and connect to zks
    zk = KazooClient(hosts=zks)
    zk.start()

    # put data in node specified
    if options.putnode:
        _put(options.putnode, options.putdata)

    # get data in node specified
    if options.getnode:
        print _get(options.getnode)

    # del node specified
    if options.delnode:
        print _del(options.delnode)

    if options.clusterinfo:
        _getclusterinfo(options.subdomain)

    zk.stop()

if __name__ == '__main__':
    main()
