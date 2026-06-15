.PHONY: vcs sim clean compile

TEST_DESIGN = ROM
SNAPSHOT = rtllm_snap

# vcs target kept for RTLLM script compatibility (now uses Vivado XSim)
vcs: compile

compile:
		xvlog -log compile.log $(TEST_DESIGN).v testbench.v

sim:
		xelab -debug typical -top testbench -snapshot $(SNAPSHOT) -log elab.log
		xsim $(SNAPSHOT) -R -log run.log

clean:
		rm -rf xsim.dir *.log *.jou *.pb .Xil *.wdb *.str
