

# Copyright (C): 2023
# Authors:       Shanquan Tian <shanquan.tian@yale.edu>
# Updated:       2023-02-02
#          
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA



TOPLEVEL=keccak_top
SIM_TOP=cshake_tb

PARTNAME=xc7a200tfbg676-3

SOURCES_VERILOG=sources_verilog.txt
SOURCES_LIST_VERILOG=$(shell cat $(SOURCES_VERILOG) | grep -v "\#" | sed -e "s/\"//g" )

REPORT_VERILOG=report-Verilog-$(PARTNAME).txt

EXECUTABLES=xelab xsim vivado
TEST_FOR_EXECUTABLES=$(foreach exec,$(EXECUTABLES), $(if $(shell which $(exec)),,$(error 'No $(exec) in PATH, consider doing: export PATH=$$PATH:/tools/Xilinx/Vivado/2018.3/bin/')))

all: synth_system.bit

synth_system.bit: $(SOURCES_LIST_VERILOG)
	$(TEST_FOR_EXECUTABLES)
	echo $(TOPLEVEL) $(PARTNAME) > $(REPORT_VERILOG) 
	vivado -nojournal -log log.log -mode batch -source synthesize_verilog.tcl -tclargs $(SOURCES_VERILOG) $(TOPLEVEL) $(PARTNAME) | tee -a $(REPORT_VERILOG)
	mv report-* ./reports/

simulate:
	$(TEST_FOR_EXECUTABLES)
	xelab -prj cshake_tb_verilog.prj --relax -debug typical $(SIM_TOP) -s cshake_sim
	xsim cshake_sim -t simulate.tcl 

waveform: cshake_save.wcfg
	xsim cshake_sim -view $< -gui

program_verilog: synth_system.bit
	$(TEST_FOR_EXECUTABLES)
	vivado -nojournal -log log.log -mode batch -source program.tcl -tclargs xc7a200t synth_system.bit

clean:
	rm -rf .Xil synth_system.bit usage_statistics_webtalk.html usage_statistics_webtalk.xml vivado.jou fsm_encoding.os
	rm -rf xsim.dir *.pb *.jou *.wdb *.wcfg *.log

clean_rpt:
	rm -rf report*.txt  *.rpt

