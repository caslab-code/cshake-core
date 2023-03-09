#!/bin/bash

#
# This is script for running regression tests on the VHDL and Verilog
# code for SHAKE / cSHAKE.
#
# Copyright (C): 2019
# Author:        Jakub Szefer <jakub.szefer@yale.edu>
#                Shanquan Tian <shanquan.tian@yale.edu>
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


configs=( "cshake128" "cshake256" )
parallel_slices=( 1 2 4 8 16 32 )
hdls=( "verilog")
num_tests=50
tb_wait_cycles_din=( 0 1 2 )
tb_wait_cycles_dout=( 0 1 2 )

regression_root=$(pwd)

if ! [ -x "$(command -v xelab)" ] || ! [ -x "$(command -v xsim)" ] || ! [ -x "$(command -v vivado)" ]
then
  echo 'Error: ensure xelab, xsim, and vivado are in PATH.' >&2
  echo '       consider doing: export PATH=$PATH:/tools/Xilinx/Vivado/2018.3/bin/' >&2
  exit 1
fi

echo ''
echo 'Running tests, please be patient while output is being generated...'
echo ''
echo -e "HDL\tCONFIG\t\tPARALLEL_SLICES\tNUM_TESTS\tTB_WAIT_CYCLES_DIN\tTB_WAIT_CYCLES_DOUT\tRESULT"

for h in "${hdls[@]}"
do
  for i in "${configs[@]}"
  do
    for j in "${parallel_slices[@]}"
    do
      for k in "${tb_wait_cycles_din[@]}"
      do
        for l in "${tb_wait_cycles_dout[@]}"
        do
          echo -e "$h\t$i\t$j\t\t$num_tests\t\t$k\t\t\t$l\t\t\t(running...)\c"
          # Generate testvectors
          cd $regression_root
          cd ../testvectors_generator/
          make NUMTESTS=$num_tests HDL=$h $i &> /dev/null

          # Edit hardware configuration to match the current test
          # Possible rates are 1344 (128 bit variant) or 1088 (256 bit variant)
          # Possible cSHAKE prefixes are: cshake128 (X"10010001a801") and cshake256 (X"100100018801")
          cd $regression_root
          sed -i "s/^\(\`define PARALLEL_SLICES [ ]*\)\([0-9]*\)/\1$j/" ../verilog/keccak_pkg.v
          sed -i "s/^\([ ]*constant parallel_slices .*:= \)\([0-9]*;\)/\1$j;/" ../vhdl/keccak_pkg.vhd

          if [ "$h" = "vhdl" ]
          then
            sed -i "s/^\([ ]*constant max_wait_counter_din .*:= \)\([0-9]*;\)/\1$k;/" ../vhdl/tb.vhd
            sed -i "s/^\([ ]*constant max_wait_counter_dout .*:= \)\([0-9]*;\)/\1$l;/" ../vhdl/tb.vhd
          fi

          # if [ "$h" = "verilog" ]
          # then
          #   if [ "$i" = "shake256" ] || [ "$i" = "cshake256" ]
          #   then
          #     sed -i "s/^\(\`define RATE [ ]*\)\([0-9]*\)/\11088/" ../verilog/keccak_pkg.v
          #     sed -i "s/^\(\`define PARALLEL_SLICES [ ]*\)\([0-9]*\)/\1$j/" ../verilog/keccak_pkg.v
          #     sed -i "s/10010001a801/100100018801/g" ../verilog/keccak_pkg.v
          #     # FIXME fix switching prefix for verilog code
          #     # FIXME do both vhdl and verilog updates for now
          #     sed -i "s/^\([ ]*constant rate .*:= \)\([0-9]*;\)/\11088;/" ../vhdl/keccak_pkg.vhd
          #     sed -i "s/^\([ ]*constant parallel_slices .*:= \)\([0-9]*;\)/\1$j;/" ../vhdl/keccak_pkg.vhd
          #     sed -i "s/^\([ ]*constant cshake_prefix .*:= X\)\(\"[0-9a-f]*\";\)/\1\"100100018801\";/" ../vhdl/keccak_pkg.vhd
          #   else
          #     sed -i "s/^\(\`define RATE [ ]*\)\([0-9]*\)/\11344/" ../verilog/keccak_pkg.v
          #     sed -i "s/^\(\`define PARALLEL_SLICES [ ]*\)\([0-9]*\)/\1$j/" ../verilog/keccak_pkg.v
          #     sed -i "s/100100018801/10010001a801/g" ../verilog/keccak_pkg.v
          #     # FIXME fix switching prefix for verilog code
          #     # FIXME do both vhdl and verilog updates for now
          #     sed -i "s/^\([ ]*constant rate .*:= \)\([0-9]*;\)/\11344;/" ../vhdl/keccak_pkg.vhd
          #     sed -i "s/^\([ ]*constant parallel_slices .*:= \)\([0-9]*;\)/\1$j;/" ../vhdl/keccak_pkg.vhd
          #     sed -i "s/^\([ ]*constant cshake_prefix .*:= X\)\(\"[0-9a-f]*\";\)/\1\"10010001a801\";/" ../vhdl/keccak_pkg.vhd
          #   fi
          # fi

          #cp ../vhdl/keccak_pkg.vhd ../vhdl/keccak_pkg_$i"_"$j.vhd#What is it for?

          # Run the simulation and check output
          cd $regression_root
          cd ../Vivado
          if [ "$h" = "vhdl" ]
          then
            if $(make simulate_vhdl 2>&1 | grep -q Success)
            then
              echo -e "\r$h\t$i\t$j\t\t$num_tests\t\t$k\t\t\t$l\t\t\tpassed      "
              cd $regression_root
              cd ../
              mkdir -p successful_regression_tests
              cd successful_regression_tests
              savepath="successful-$h-$i-parallel-slices-$j"
              mkdir -p $savepath
              cp ../vhdl/* $savepath
              #cp ../vhdl/keccak_pkg.vhd $savepath
              #cp ../verilog/keccak_pkg.v $savepath
              #cp ../vhdl/testvectors.vhd $savepath
              #cp ../verilog/testvectors.v $savepath
              cd $regression_root
              cd ../Vivado
            else
              echo -e "\r$h\t$i\t$j\t\t$num_tests\t\t$k\t\t\t$l\t\t\tFAILED      "
              make simulate_vhdl
              cd $regression_root
              cd ../
              mkdir -p failed_regression_tests
              cd failed_regression_tests
              savepath="failed-$h-$i-parallel-slices-$j"
              mkdir -p $savepath
              cp ../vhdl/* $savepath
              #cp ../vhdl/keccak_pkg.vhd $savepath
              #cp ../verilog/keccak_pkg.v $savepath
              #cp ../vhdl/testvectors.vhd $savepath
              #cp ../verilog/testvectors.v $savepath
              cd $regression_root
              cd ../Vivado
            fi
          else
            if $(make simulate_verilog 2>&1 | grep -q Success)
            then
              echo -e "\r$h\t$i\t$j\t\t$num_tests\t\t$k\t\t\t$l\t\t\tpassed      "
            else
              echo -e "\r$h\t$i\t$j\t\t$num_tests\t\t$k\t\t\t$l\t\t\tFAILED      "
              cd $regression_root
              cd ../
              mkdir -p failed_regression_tests
              cd failed_regression_tests
              savepath="failed-$h-$i-parallel-slices-$j"
              mkdir -p $savepath
              cp ../vhdl/keccak_pkg.vhd $savepath
              cp ../verilog/keccak_pkg.v $savepath
              cp ../vhdl/testvectors.vhd $savepath
              cp ../verilog/testvectors.v $savepath
              cd $regression_root
              cd ../Vivado
            fi
          fi

          # Done testing one configuration, contine with next for loop and configuration
        done
      done
    done
  done
done

# Make clean in sub-directories
cd $regression_root
cd ../testvectors_generator/
make clean

cd $regression_root
cd ../Vivado
make clean


