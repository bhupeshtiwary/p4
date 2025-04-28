# Makefile for P4 SFC Implementation
# Assumes Ubuntu 20.04+ with p4c, BMv2, Mininet, P4Runtime, and Scapy installed

# Variables
P4C           = p4c
MININET       = python3 sfc_topo.py
P4_SRC        = sfc.p4
P4_JSON       = sfc.json
P4_P4INFO     = sfc.p4info.txt
TOPO_SCRIPT   = sfc_topo.py
RULES_SCRIPT  = install_rules.py
SEND_SCRIPT   = send_packet.py
ECHO_SCRIPT   = echo_service.py
CAPTURE_FILE  = capture.pcap
PCAP_DIR      = .
MININET_PID   = mininet.pid

# Default target
all: compile run

# Compile P4 program
compile:
	@echo "Compiling P4 program..."
	$(P4C) --std p4-16 -b bmv2 $(P4_SRC) \
	    -o $(P4_JSON) \
	    --p4runtime-files $(P4_P4INFO)

# Run the whole demo
run: start_mininet install_rules run_demo

# Launch Mininet (which in turn starts BMv2 via your BMv2Switch class)
start_mininet:
	@echo "Starting Mininet topology..."
	@sudo $(MININET) & echo $$! > $(MININET_PID)
	@sleep 5

# Push your P4Runtime rules
install_rules:
	@echo "Installing flow rules..."
	@sudo -E python3 $(RULES_SCRIPT)

# Kick off echo servers, tcpdump, send test packet, then clean up
run_demo:
	@echo "Running demonstration..."
	@sudo mkdir -p $(PCAP_DIR)
	@sudo ip netns exec svc1 python3 $(ECHO_SCRIPT) & echo $$! > svc1_echo.pid
	@sudo ip netns exec svc2 python3 $(ECHO_SCRIPT) & echo $$! > svc2_echo.pid
	@sudo ip netns exec h2   tcpdump -i h2-eth0 -w $(PCAP_DIR)/$(CAPTURE_FILE) & echo $$! > tcpdump.pid
	@sleep 2
	@sudo ip netns exec h1 python3 $(SEND_SCRIPT)
	@sleep 2
	@sudo kill $$(cat tcpdump.pid) || true
	@rm -f tcpdump.pid svc1_echo.pid svc2_echo.pid

# Clean up all artifacts and Mininet state
clean:
	@echo "Cleaning up..."
	@sudo killall python3 tcpdump || true
	@sudo rm -f $(P4_JSON) $(P4_P4INFO) $(PCAP_DIR)/$(CAPTURE_FILE) $(MININET_PID)
	@sudo mn -c || true

# Just stop any running pieces
stop:
	@echo "Stopping running processes..."
	@sudo killall python3 tcpdump || true
	@sudo rm -f $(MININET_PID)
	@sudo mn -c || true

.PHONY: all compile run start_mininet install_rules run_demo clean stop
