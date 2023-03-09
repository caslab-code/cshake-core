
#
# This is a Makefle for the program for generating test vectors for checking 
# SHAKE and cSHAKE hardware implementaitons.
# 
# Copyright (C): 2019
# Authors:       Bernhard Jungk <bernhard@projectstarfire.de>
#                Jakub Szefer <jakub.szefer@yale.edu>
# Updated:       2019-06-12
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
#


ifndef NUMTESTS
  ifneq ($(MAKECMDGOALS),clean)
    $(error "Need to specify HDL and NUMTESTS, e.g. 'make NUMTESTS=10 HDL="verilog" TARGET' where TARGET is Shake256, shake128, cshake256, or cshake128, and HDL is "vhdl" or "verilog".")
  endif
endif

ifndef HDL
  ifneq ($(MAKECMDGOALS),clean)
    $(error "Need to specify HDL and NUMTESTS, e.g. 'make NUMTESTS=10 HDL="verilog" TARGET' where TARGET is Shake256, shake128, cshake256, or cshake128, and HDL is "vhdl" or "verilog".")
  endif
endif


all: null

null:
	@echo "Need to specify make shake256, shake128, cshake256, or cshake128."
	@exit 1

shake256: generator.cpp fips202.c fips202.h
ifeq ("$(HDL)","vhdl") 
	g++ -DSHAKE256 -DNUMTESTS=$(NUMTESTS) -DVHDL generator.cpp fips202.c fips202.h -o generator
	./generator > ../vhdl/testvectors.vhd
	@echo "Generated testvenctors in VHDL!" 
else ifeq ("$(HDL)","verilog")
	g++ -DSHAKE256 -DNUMTESTS=$(NUMTESTS) -DVERILOG generator.cpp fips202.c fips202.h -o generator
	./generator > ../verilog/testvectors.v 
	@echo "Generated testvenctors in Verilog!" 
else
	$(error "Need to specify HDL and NUMTESTS, e.g. 'make NUMTESTS=10 HDL="verilog" TARGET' where TARGET is Shake256, shake128, cshake256, or cshake128, and HDL is "vhdl" or "verilog".")
endif


shake128: generator.cpp fips202.c fips202.h
ifeq ("$(HDL)","vhdl") 
	g++ -DSHAKE128 -DNUMTESTS=$(NUMTESTS) -DVHDL generator.cpp fips202.c fips202.h -o generator
	./generator > ../vhdl/testvectors.vhd
	@echo "Generated testvenctors in VHDL!" 
else ifeq ("$(HDL)","verilog")
	g++ -DSHAKE128 -DNUMTESTS=$(NUMTESTS) -DVERILOG generator.cpp fips202.c fips202.h -o generator
	./generator > ../verilog/testvectors.v 
	@echo "Generated testvenctors in Verilog!" 
else
	$(error "Need to specify HDL and NUMTESTS, e.g. 'make NUMTESTS=10 HDL="verilog" TARGET' where TARGET is Shake256, shake128, cshake256, or cshake128, and HDL is "vhdl" or "verilog".")
endif


cshake256: generator.cpp fips202.c fips202.h
ifeq ("$(HDL)","vhdl") 
	g++ -DCSHAKE256 -DNUMTESTS=$(NUMTESTS) -DVHDL generator.cpp fips202.c fips202.h -o generator
	./generator > ../vhdl/testvectors.vhd
	@echo "Generated testvenctors in VHDL!" 
else ifeq ("$(HDL)","verilog")
	g++ -DCSHAKE256 -DNUMTESTS=$(NUMTESTS) -DVERILOG generator.cpp fips202.c fips202.h -o generator
	./generator > ../verilog/testvectors.v 
	@echo "Generated testvenctors in Verilog!" 
else
	$(error "Need to specify HDL and NUMTESTS, e.g. 'make NUMTESTS=10 HDL="verilog" TARGET' where TARGET is Shake256, shake128, cshake256, or cshake128, and HDL is "vhdl" or "verilog".")
endif

cshake128: generator.cpp fips202.c fips202.h
ifeq ("$(HDL)","vhdl") 
	g++ -DCSHAKE128 -DNUMTESTS=$(NUMTESTS) -DVHDL generator.cpp fips202.c fips202.h -o generator
	./generator > ../vhdl/testvectors.vhd
	@echo "Generated testvenctors in VHDL!"
else ifeq ("$(HDL)","verilog")
	g++ -DCSHAKE128 -DNUMTESTS=$(NUMTESTS) -DVERILOG generator.cpp fips202.c fips202.h -o generator
	./generator > ../verilog/testvectors.v 
	@echo "Generated testvenctors in Verilog!" 
else
	$(error "Need to specify HDL and NUMTESTS, e.g. 'make NUMTESTS=10 HDL="verilog" TARGET' where TARGET is Shake256, shake128, cshake256, or cshake128, and HDL is "vhdl" or "verilog".")
endif



clean:
	rm -rf generator generator.exe *.gch
