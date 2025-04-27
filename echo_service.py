from scapy.all import *

def echo_packet(pkt):
    # Send the packet back unchanged
    sendp(pkt, iface="svc1-eth0", verbose=True)

sniff(iface="svc1-eth0", prn=echo_packet)
