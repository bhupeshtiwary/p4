#include <core.p4>
#include <v1model.p4>

// Header Definitions
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header sfc_t {
    bit<16> chain_id; // Identifies the service chain
    bit<8>  index;    // Indicates the current position in the chain
}

struct metadata {
    /* Empty for this example */
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    sfc_t      sfc;
}

// Parser
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            0xFD: parse_sfc; // Custom protocol number for SFC
            default: accept;
        }
    }
    state parse_sfc {
        packet.extract(hdr.sfc);
        transition accept;
    }
}

// Checksum Verification (Placeholder)
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

// Ingress Control
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action forward(bit<9> port) {
        standard_metadata.egress_spec = port;
    }

    action set_index_and_forward(bit<8> new_index, bit<9> port) {
        hdr.sfc.index = new_index;
        standard_metadata.egress_spec = port;
    }

    action remove_sfc_and_forward(bit<9> port) {
        hdr.sfc.setInvalid();
        standard_metadata.egress_spec = port;
    }

    table sfc_forward {
        key = {
            standard_metadata.ingress_port: exact;
            hdr.sfc.chain_id: exact;
            hdr.sfc.index: exact;
        }
        actions = {
            forward;
            set_index_and_forward;
            remove_sfc_and_forward;
            drop;
        }
        size = 1024;
        default_action = drop;
    }

    apply {
        if (hdr.sfc.isValid()) {
            sfc_forward.apply();
        } else {
            drop(); // Drop packets without SFC header
        }
    }
}

// Egress Control (Placeholder)
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

// Checksum Computation (Placeholder)
control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

// Deparser
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        if (hdr.ipv4.isValid()) {
            packet.emit(hdr.ipv4);
            if (hdr.sfc.isValid()) {
                packet.emit(hdr.sfc);
            }
        }
    }
}

// V1Switch Architecture
V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
