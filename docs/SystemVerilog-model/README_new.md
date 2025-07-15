This is an environment to launch simulations of a RTL core with VCS using a Spike model or Synthara's self contained UVM model

You can launch a single simulation with

`python run-vcs.py`

Run 

`python run-vcs.py -h`

to display all the possible flags.

The run-vcs script
- builds the Spike directory if it has never been built
- checks out the correct version of the RTL and TB repos
- compiles the SW (support libraries, C, asm)
- launches the `parse.py` script with info coming from the `config.json` file

The script `automate.sh` is used in order to run regressions and compare the result of Spike vs UVM model.

## Simulation time mismatch

VCS simulation time was different between Spike and UVM model. This made impossible to compare the actual simulation times.
To solve the following changes took place

~~1. In `lib/uvm_agents/uvma_obi_memory/src/comps/uvma_obi_memory_drv.sv`~~
~~- line 449 `repeat (0) begin`~~
~~- line 473 `repeat (0) begin`~~
~~- line 303 `int unsigned effective_latency = 0;`~~
~~2. In `cv32e20/env/uvme/uvme_cv32e20_cfg.sv`~~
~~- line 170 `obi_memory_data_cfg.drv_slv_gnt_mode    == UVMA_OBI_MEMORY_DRV_SLV_GNT_MODE_CONSTANT;`~~
~~- line 174 `obi_memory_data_cfg.drv_slv_rvalid_mode == UVMA_OBI_MEMORY_DRV_SLV_RVALID_MODE_CONSTANT;`~~

1. In file `cv32e20/env/uvme/uvme_cv32e20_cfg.sv` comment from line 290 to 294.
2. To the command `run-vcs` pass `+rand_stall_obi_disable` after the flag `-asf` (additional sim flags) 

## COREMARK

To check the commands on OpenHW env

1. Go to `mk/Common.mk` line 316 and write `CFLAGS ?= -Os -g -static -mabi=ilp32 -march=$(RISCV_MARCH) -Wall -pedantic $(RISCV_CFLAGS) -DITERATIONS=1 -DVALIDATION_RUN=1 -DFLAGS_STR="\"-Os -g -static -mabi=ilp32 -Wall -pedantic\""`
2. In file `lib/uvm_components/uvmc_rvfi_reference_model/uvmc_rvfi_reference_model_pkg.sv` comment line 36

go to cv32e20/sim/uvmt and run 
`reset;make test TEST=coremark CV_SIMULATOR=vcs USE_ISS=YES WAVES=1`

It would fail if you run it without ISS

Everything must be then merged with Python script