import logging
import argparse
import subprocess



DEF_CONFIG="/home/prom/Projects/ont-data-storage/scripts/basecall_and_rsync/dna_r10.4.1_e8.2_400bps_modbases_5hmc_5mc_cg_sup_prom.cfg"

def main():
    ap = argparse.ArgumentParser()
    
    # subprocess.run(
    #     [
    #         "ont_basecall_client",
    #         "--input_path", "reads",
    #         "--save_path", "output_folder/basecall",
    #         "--config", DEF_CONFIG,
    #         "-p", 5555 
    #     ],
    #     check=True
    # )
if __name__ == "__main__":
    raise SystemExit(main())
