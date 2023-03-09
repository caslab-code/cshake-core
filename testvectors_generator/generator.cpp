
/*
 * This is a program for generating test vectors for checking SHAKE and cSHAKE
 * hardware implementaitons.
 * 
 * Copyright (C): 2019
 * Authors:       Bernhard Jungk <bernhard@projectstarfire.de>
 *                Jakub Szefer <jakub.szefer@yale.edu>
 *                Shanquan Tian <shanquan.tian@yale.edu>
 * Updated:       2019-06-18
 *          
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
*/

#include <iostream>
#include <iomanip>
#include <vector>
#include <cstdlib>
#include <stdint.h>
#include <string>
#include <sstream>

#include <cassert>

#include "fips202.h"

// Select SHAKE or cSHAKE and 256 or 128 bit variants
#ifdef SHAKE256
  #define CSHAKE 0
  #define RATE 1088
  #define RATE_BYTE 136
#elif SHAKE128
  #define CSHAKE 0
  #define RATE 1344
  #define RATE_BYTE 168
#elif CSHAKE256
  #define CSHAKE 1
  #define RATE 1088
  #define RATE_BYTE 136
#else // CSHAKE128
  #define CSHAKE 1
  #define RATE 1344
  #define RATE_BYTE 168
#endif

// Select number of test to run
#ifdef NUMTESTS
  #define TEST_COUNTS NUMTESTS
#else
  #define TEST_COUNTS 10
#endif



int main() {
  uint16_t cstm;

  std::vector<uint8_t> input;
  std::vector<uint8_t> output;

  std::vector<uint32_t> inputs;
  std::vector<uint32_t> outputs;
  std::vector<uint32_t> wait_cycles;

  for (int tv_count = 0; tv_count < TEST_COUNTS; ++tv_count) {
    // select randomly between shake and cshake
    // bool cshake = std::rand() % 2; //FIXME: I replaced this line with below
    
#ifdef SHAKE256 
    bool cshake = 0;
#elif SHAKE128
    bool cshake = 0;
#elif CSHAKE256
    bool cshake = 1;
#else // CSHAKE128
    bool cshake = 1;
#endif

#ifdef SHAKE256
    uint32_t mask256 = 0x40000000;
#elif CSHAKE256
    uint32_t mask256 = 0x40000000;
#else
    uint32_t mask256 = 0x00000000;
#endif

    // if cshake is selected, generate 16-bit random cstm
    if (cshake) {
      cstm = std::rand() & 0xFFFF;
    }

    // generate input random length in bytes
    // uint32_t input_length = (std::rand() & 0xFFC) % ((tv_count+1) * 32);
    uint32_t input_length = (std::rand() & 0xFFC);
    // uint32_t input_length = 32;// for debugging
    if (input_length == 0) {
      input_length = 32;
    }

    assert(input_length > 0);

    // generate input
    input = std::vector<uint8_t>(input_length);
    for (int i = 0; i < input_length; ++i) {
      input[i] = std::rand() & 0xFF;
    }

    // generate output random length in bytes 
    // uint32_t output_length = (std::rand() & 0xFFC) % ((tv_count + 1) * 32);
    uint32_t output_length = (std::rand() & 0xFFC);
    // uint32_t output_length = 136;// for debugging
    if (output_length == 0) {
      output_length = 32;
    }
    output = std::vector<uint8_t>(output_length);
    
    assert(output_length > 0);

    if (cshake) {
#if defined (CSHAKE256) 
      cshake256_simple(output.data(), output.size(), cstm, input.data(), input.size());
#else
      cshake128_simple(output.data(), output.size(), cstm, input.data(), input.size());
#endif
    }
    else {
#if defined (SHAKE256)
      shake256(output.data(), output.size(), input.data(), input.size());
#else
      shake128(output.data(), output.size(), input.data(), input.size());
#endif
    }

     
    if (cshake) {
      uint32_t block = 0x80000000 | mask256 | (output_length << 3); // length in bytes
      inputs.push_back(block);
    } else {
      uint32_t block = 0x00000000 | mask256 | (output_length << 3);
      inputs.push_back(block);
    }

    if (cshake) {
      uint32_t block = cstm;
      inputs.push_back(block);
    }

    for (int i = 0; i < input.size(); i += 4) {
      if(i % RATE_BYTE == 0 && (input.size() - i) > RATE_BYTE) {
        uint32_t block = RATE; 
        inputs.push_back(block);
      } else if (i % RATE_BYTE == 0 && (input.size() - i) <= RATE_BYTE) { 
        uint32_t block = 0x80000000 | ((input.size() - i) << 3);
        inputs.push_back(block);
      }

      uint32_t block = input[i + 0] <<  0 |
                       input[i + 1] <<  8 |
                       input[i + 2] << 16 |
                       input[i + 3] << 24;
      inputs.push_back(block);
    }     

    for (int i = 0; i < output.size(); i += 4) {
      uint32_t block = output[i + 0] <<  0 |
                       output[i + 1] <<  8 |
                       output[i + 2] << 16 |
                       output[i + 3] << 24;
      outputs.push_back(block);
    }
  }

//#if HDL==0//vhdl
#ifdef VHDL//vhdl
    std::cout << "library ieee;\n" ;
    std::cout << "use ieee.std_logic_1164.all;\n";
    std::cout << "use ieee.numeric_std.all;\n\n";
    std::cout << "--\n";
  #ifdef SHAKE256
    std::cout << "-- Testvectors for: SHAKE256\n";
    std::cout << "-- Number of tests: " << TEST_COUNTS << "\n";
  #elif SHAKE128
    std::cout << "-- Testvectors for: SHAKE128\n";
    std::cout << "-- Number of tests: " << TEST_COUNTS << "\n";
  #elif CSHAKE256
    std::cout << "-- Testvectors for: cSHAKE256\n";
    std::cout << "-- Number of tests: " << TEST_COUNTS << "\n";
  #else // CSHAKE128
    std::cout << "-- Testvectors for: cSHAKE128\n";
    std::cout << "-- Number of tests: " << TEST_COUNTS << "\n";
  #endif
    std::cout << "--\n\n";


    std::cout << "package testvectors is\n";
    std::cout << "  constant testvector_input_size        : natural := " << std::dec << inputs.size() << ";\n";
    std::cout << "  type t_test_vector is array(natural range <>) of std_logic_vector(31 downto 0);\n";
    
    std::cout << "  constant testvector_input : t_test_vector(0 to " << inputs.size()-1 << ") :=\n    (\n";
//#elif HDL==1//verilog
#elif VERILOG
    std::cout << "//\n";
  #ifdef SHAKE256
    std::cout << "// Testvectors for: SHAKE256\n";
    std::cout << "// Number of tests: " << TEST_COUNTS << "\n";
  #elif SHAKE128
    std::cout << "// Testvectors for: SHAKE128\n";
    std::cout << "// Number of tests: " << TEST_COUNTS << "\n";
  #elif CSHAKE256
    std::cout << "// Testvectors for: cSHAKE256\n";
    std::cout << "// Number of tests: " << TEST_COUNTS << "\n";
  #else // CSHAKE128
    std::cout << "// Testvectors for: cSHAKE128\n";
    std::cout << "// Number of tests: " << TEST_COUNTS << "\n";
  #endif
    std::cout << "//\n\n";
    std::cout << "`ifndef TESTVECTOR\n`define TESTVECTOR\n";
    std::cout << "localparam TESTVECTOR_INPUT_SIZE = " << std::dec << inputs.size() << ";\n";
    std::cout << "localparam [0:"<< std::dec << (inputs.size()*32-1)  <<"] TESTVECTOR_INPUT = { \n";
#endif

  for (int i = 0; i < inputs.size(); ++i) {
    std::cout << "    ";
    #ifdef VHDL//vhdl 
      std::cout << "x\"" << std::hex << std::setfill('0') << std::setw(8) << std::setprecision(8) << inputs[i];
    #elif VERILOG //verilog
      std::cout << "32'h" << std::hex << std::setfill('0') << std::setw(8) << std::setprecision(8) << inputs[i];
    #endif

    if (i + 1 < inputs.size()) {
      #ifdef VHDL//vhdl
        std::cout << "\",\n";
      #elif VERILOG //verilog
        std::cout << " ,\n";
      #endif
    }
    else {
      #ifdef VHDL//vhdl
        std::cout << "\"\n  );\n\n";
      #elif VERILOG //verilog
        std::cout << "\n};\n\n";
      #endif
    }
  }
#ifdef VHDL//vhdl
  std::cout << "  constant testvector_output_size        : natural := " << std::dec << outputs.size() << ";\n";
  std::cout << "  constant testvector_output : t_test_vector(0 to " << std::dec << outputs.size()-1 << ") :=\n    (\n";
#elif VERILOG //verilog
  std::cout << "localparam TESTVECTOR_OUTPUT_SIZE = " << std::dec << outputs.size() << ";\n";
  std::cout << "localparam [0:"<< std::dec << (outputs.size()*32-1)  <<"] TESTVECTOR_OUTPUT = {\n";
#endif


  for (int i = 0; i < outputs.size(); ++i) {
    std::cout << "    ";
    #ifdef VHDL//vhdl
      std::cout << "x\"" << std::hex << std::setfill('0') << std::setw(8) << std::setprecision(8) << outputs[i];
    #elif VERILOG //verilog
      std::cout << "32'h" << std::hex << std::setfill('0') << std::setw(8) << std::setprecision(8) << outputs[i];
    #endif

    if (i + 1 < outputs.size()) {
      #ifdef VHDL//vhdl
        std::cout << "\",\n";
      #elif VERILOG //verilog
        std::cout << " ,\n";
      #endif
    }
    else {
      #ifdef VHDL//vhdl
        std::cout << "\"\n  );\n\n";
      #elif VERILOG //verilog
        std::cout << "\n};\n\n";
      #endif
    }
  }
  #ifdef VHDL//vhdl
    std::cout << "end package;\n";
    std::cout << "package body testvectors is\n";
    std::cout << "end package body;"; 
  #elif VERILOG //verilog
    std::cout << "\n`endif\n";
  #endif
}

