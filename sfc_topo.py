from mininet.net import Mininet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import TCLink

# Note: Assumes BMv2 switch is configured externally (e.g., via P4 Behavioral Model)
class BMv2Switch(OVSKernelSwitch):
    def __init__(self, name, **params):
        OVSKernelSwitch.__init__(self, name, **params)
        self.switchPath = 'simple_switch'  # BMv2 switch binary

def sfcTopology():
    net = Mininet(controller=Controller, link=TCLink)

    # Add controller
    c0 = net.addController('c0')

    # Add BMv2 switch (requires external configuration with P4 program)
    s1 = net.addSwitch('s1', cls=OVSKernelSwitch, dpid='1')

    # Add hosts
    h1 = net.addHost('h1', ip='10.0.0.1/24')
    s1_host = net.addHost('s1', ip='10.0.0.2/24')  # Service 1
    s2_host = net.addHost('s2', ip='10.0.0.3/24')  # Service 2
    h2 = net.addHost('h2', ip='10.0.0.4/24')

    # Add links with specific ports
    net.addLink(h1, s1, port1=0, port2=1)
    net.addLink(s1_host, s1, port1=0, port2=2)
    net.addLink(s2_host, s1, port1=0, port2=3)
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
