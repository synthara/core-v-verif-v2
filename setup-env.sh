#!/bin/bash
export CV_SIMULATOR="vcs"
export PATH="/mnt/rhea_hdd_raid5/opt_non_storage/backend/toolchains/risc/rv32imc/bin:$PATH"
export VERILATOR_ROOT="/opt/verilator/v5.004/"
export CV_SW_TOOLCHAIN="/mnt/rhea_hdd_raid5/opt_non_storage/backend/toolchains/risc/rv32imc"
export CV_SW_PREFIX="riscv32-unknown-elf-"
export PATH=$PATH:/opt/eda/riscv/tools/isa-sim/bin
export PATH=$PATH:/opt/eda/riscv/tools/isa-sim/riscv32-unknown-elf/bin
export PATH=$PATH:/opt/eda/synopsys/tools/vcs/latest/bin/
export PATH=$PATH:/opt/eda/synopsys/tools/verdi/latest/bin/
export VCS_UVMHOME_ARG=/opt/eda/synopsys/tools/vcs/latest/etc/uvm
export VERDI_HOME="/opt/eda/synopsys/tools/verdi/latest"
export CV_TOOL_PREFIX="/opt/eda/synopsys/tools/verdi/latest/bin"
cd cv32e20/sim/uvmt 
make corev-dv CV_CORE=cv32e20 SIMULATOR=vcs
make comp CV_CORE=cv32e20 SIMULATOR=vcs