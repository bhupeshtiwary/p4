# Makefile for P4 SFC Implementation
# Assumes Ubuntu 20.04+ with p4c, BMv2, Mininet, P4Runtime, and Scapy installed

# Variables
P4C = p4c
BMV2_SWITCH = simple_switch
BMV2_LOG = switch.log
MININET = python3 sfc_topo.py
P4_SRC = sfc.p4
P4_JSON = sfc.json
P4_P4INFO = sfc.p4info.txt
TOPO_SCRIPT = sfc_topo.py
RULES_SCRIPT = install_rules.py
SEND_SCRIPT = send_packet.py
ECHO_SCRIPT = echo_service.py
CAPTURE_FILE = capture.pcap
PCAP_DIR = .
BMV2_PID = bmv2.pid
MININET_PID = mininet.pid

# Default target
all: compile run

# Compile P4 program
compile:
    @echo "Compiling P4 program..."
    $(P4C) --std p4-16 -b bmv2 $(P4_SRC) -o $(P4_JSON) --p4runtime-files $(P4_P4INFO)

# Run the entire setup
run: start_bmv2 start_mininet install_rules run_demo

# Start BMv2 switch
start_bmv2:
    @echo "Starting BMv2 switch..."
    $(BMV2_SWITCH) --interface 1@veth1 --interface 2@veth2 --interface 3@veth3 --interface 4@veth4 \
        --grpc-server-addr 127.0.0.1:50051 $(P4_JSON) > $(BMV2_LOG) 2>&1 & echo $$! > $(BMV2_PID)
    @sleep 5  # Wait for BMv2 to initialize

# Start Mininet topology
start_mininet:
    @echo "Starting Mininet topology..."
    @sudo $(MININET) & echo $$! > $(MININET_PID) &
    @sleep 10  # Wait for Mininet to set up

# Install flow rules
install_rules:
    @echo "Installing flow rules..."
    @sudo python3 $(RULES_SCRIPT)

# Run demonstration
run_demo:
    @echo "Running demonstration..."
    @sudo mkdir -p $(PCAP_DIR)
    # Start echo services on s1 and s2
    @sudo ip netns exec s1 python3 $(ECHO_SCRIPT) & echo $$! > s1.pid &
    @sudo ip netns exec s2 python3 $(ECHO_SCRIPT) & echo $$! > s2.pid &
    # Start packet capture on h2
    @sudo ip netns exec h2 tcpdump -i h2-eth0 -w $(PCAP_DIR)/$(CAPTURE_FILE) & echo $$! > tcpdump.pid &
    @sleep 2
    # Send packet from h1
    @sudo ip netns exec h1 python3 $(SEND_SCRIPT)
    @sleep 2
    # Stop packet capture
    @sudo kill $$(cat tcpdump.pid)
    @sudo rm tcpdump.pid

# Clean up
clean:
    @echo "Cleaning up..."
    @sudo killall $(BMV2_SWITCH) mininet python3 tcpdump || true
    @sudo rm -f $(BMV2_LOG) $(BMV2_PID) $(MININET_PID) s1.pid s2.pid tcpdump.pid
    @sudo rm -f $(P4_JSON) $(P4_P4INFO) $(PCAP_DIR)/$(CAPTURE_FILE)
    @sudo mn -c || true  # Clean Mininet state

# Stop running processes
stop:
    @echo "Stopping running processes..."
    @sudo killall $(BMV2_SWITCH) mininet python3 tcpdump || true
    @sudo rm -f $(BMV2_PID) $(MININET_PID) s1.pid s2.pid tcpdump.pid
    @sudo mn -c || true

.PHONY: all compile run start_bmv2 start_mininet install_rules run_demo clean stop
