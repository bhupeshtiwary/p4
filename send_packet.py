from scapy.all import *

class SFC(Packet):
    name = "SFC"
    fields_desc = [ShortField("chain_id", 0),
                   ByteField("index", 0)]

bind_layers(IP, SFC, proto=0xFD)

packet = Ether(dst="ff:ff:ff:ff:ff:ff") / IP(dst="10.0.0.4", proto=0xFD) / SFC(chain_id=1, index=0) / Raw(load="Hello SFC")
sendp(packet, iface="h1-eth0", verbose=True)
