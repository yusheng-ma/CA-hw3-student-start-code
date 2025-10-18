IVERILOG = iverilog
VVP      = vvp
VFLAGS   = -g2012

.PHONY: all basic unroll clean

all: basic unroll

basic: dot_product_basic.v testbench_basic.v
	$(IVERILOG) $(VFLAGS) -o sim_basic testbench_basic.v dot_product_basic.v
	$(VVP) sim_basic

unroll: dot_product_unroll.v testbench_unroll.v
	$(IVERILOG) $(VFLAGS) -o sim_unroll testbench_unroll.v dot_product_unroll.v
	$(VVP) sim_unroll

clean:
	rm -f sim_basic sim_unroll