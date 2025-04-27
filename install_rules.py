import p4runtime_lib.bmv2
import p4runtime_lib.helper

def writeSfcRules(p4info_helper, sw):
    # Table entry: From h1 to s1
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.sfc_forward",
        match_fields={
            "standard_metadata.ingress_port": 1,
            "hdr.sfc.chain_id": 1,
            "hdr.sfc.index": 0
        },
        action_name="MyIngress.forward",
        action_params={"port": 2}
    )
    sw.WriteTableEntry(table_entry)

    # Table entry: From s1 to s2
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.sfc_forward",
        match_fields={
            "standard_metadata.ingress_port": 2,
            "hdr.sfc.chain_id": 1,
            "hdr.sfc.index": 0
        },
        action_name="MyIngress.set_index_and_forward",
        action_params={"new_index": 1, "port": 3}
    )
    sw.WriteTableEntry(table_entry)

    # Table entry: From s2 to h2
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.sfc_forward",
        match_fields={
            "standard_metadata.ingress_port": 3,
            "hdr.sfc.chain_id": 1,
            "hdr.sfc.index": 1
        },
        action_name="MyIngress.remove_sfc_and_forward",
        action_params={"port": 4}
    )
    sw.WriteTableEntry(table_entry)

def main():
    p4info_file_path = 'sfc.p4info.txt'
    bmv2_file_path = 'sfc.json'
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    sw = p4runtime_lib.bmv2.Bmv2SwitchConnection(
        name='s1',
        address='127.0.0.1:50051',
        device_id=0
    )
    sw.MasterArbitrationUpdate()
    writeSfcRules(p4info_helper, sw)
    sw.shutdown()

if __name__ == '__main__':
    main()
