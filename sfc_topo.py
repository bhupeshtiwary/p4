#!/usr/bin/env python3
import os, sys

# Ensure Python can find your p4runtime_lib under ~/p4tutorials/utils
sys.path.insert(0, os.path.expanduser('~/p4tutorials/utils'))

from mininet.net import Mininet
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import TCLink
from p4runtime_lib.bmv2 import Bmv2Switch




# Note: Assumes BMv2 switch is configured externally (e.g., via P4 Behavioral Model)
class BMv2Switch(OVSKernelSwitch):
    def __init__(self, name, **params):
        OVSKernelSwitch.__init__(self, name, **params)
        self.switchPath = 'simple_switch'  # BMv2 switch binary

def sfcTopology():
    net = Mininet(controller=None, link=TCLink)

    # Add controller
    #c0 = net.addController('c0')

    # Add BMv2 switch (requires external configuration with P4 program)
    #s1 = net.addSwitch('s1', cls=BMv2Switch, dpid='1')

    
    s1 = net.addSwitch(
        's1',
        cls=BMv2Switch,
        dpid='1',
        sw_path='simple_switch_grpc',
        json_path='sfc.json',
        grpc_port=50051,
        device_id=0
    )


    # Add hosts
    h1 = net.addHost('h1', ip='10.0.0.1/24')
    svc1 = net.addHost('svc1', ip='10.0.0.2/24')  # Service 1
    svc2 = net.addHost('svc2', ip='10.0.0.3/24')  # Service 2
    h2 = net.addHost('h2', ip='10.0.0.4/24')

    # Add links with specific ports
    net.addLink(h1, s1, port1=0, port2=1)
    net.addLink(svc1, s1, port1=0, port2=2)
    net.addLink(svc2, s1, port1=0, port2=3)
    net.addLink(h2, s1, port1=0, port2=4)

    # Start the network
    net.start()
    info("*** Network started\n")

    # Open CLI for interaction
    CLI(net)

    # Stop the network
    net.stop()

if __name__ == '__main__':
    setLogLevel('info')
    sfcTopology()
