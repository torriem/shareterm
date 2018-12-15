#!/usr/bin/env python2
# Copyright (C) 2010 Michael Torrie (torriem@gmail.com)
#
# Licensed under the GNU General Public License Version 2
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# version 1.0

import optparse
import sys
import os

DEFAULT_PORT = 5555
DEFAULT_CERT = '/etc/openvpn/isengard.crt'
DEFAULT_KEY = '/etc/openvpn/isengard.key'

def help():
    print "This program listens for an SSL connection on a port and"
    print "displays to the terminal anything that is received.  The"
    print "intended purpose of this is to allow someone to send a"
    print "terminal session (usually via tmux) that both the receiver"
    print "and the sender can interact with."


if __name__ == "__main__":
    usage = "usage: %prog [options]"
    parser = optparse.OptionParser(usage=usage)

    port = 5555
    cert = DEFAULT_CERT
    key = DEFAULT_KEY

    parser.add_option('-p', '--port',
                      help = "TCP/IP port to listen on.  Defaults to %d." % port,
                      dest = 'PORT')

    parser.add_option('-c', '--cert',
                      help = "Certificate file to use for SSL.",
                      dest = 'CERT', )

    parser.add_option('-k', '--key',
                      help = "Key to use for SSL.",
                      dest = 'KEY', )

    (options, args) = parser.parse_args()

    if options.PORT:
        port = int(options.PORT)
    if options.CERT:
        cert = options.CERT
    if options.KEY:
        key = options.KEY

    if not cert:
        print "Please provide a Certificate file for use with SSL."
        print
        sys.exit(1)

    if not key:
        print "Please provide a private key file for use with SSL."
        print
        sys.exit(1)

    sslopts='certificate=%s,key=%s' % ( cert,
                                        key,)

    print sslopts


    os.execvp('socat', ['socat', 
                        'openssl-listen:%d,verify=0,keepalive=1,%s' % (port,sslopts), 
                        'stdio,raw,echo=0'])
