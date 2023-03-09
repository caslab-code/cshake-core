# cSHAKE Core

This folder holds the Verilog code for the cSHAKE, a **c**ustomizable variant of the **S**ecure **H**ash **A**lgorithm and **KE**CCAK.

## Authorship and License

The source code is developed by Bernhard Jungk <jungk@hs-albsig.de> in VHDL,
and translated to Verilog HDL by
Shanquan Tian <shanquan.tian@yale.edu>, Xiayuan Wen <xiayuan.wen@yale.edu>, Jakub Szefer <jakub.szefer@yale.edu>.
The [performance evaluation](#performance) results are collected by Sanjay Deshpande <sanjay.deshpande@yale.edu>.



This program is free software under GNU General Public License v3.
You can redistribute it and/or modify it under the terms of the GNU General Public License v3 as published by the Free Software Foundation.
The license contents can be found at [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.en.html), or the file [LICENSE](LICENSE).

## Code Organization

- [verilog](verilog/) contains Verilog source code.
- [testvectors_generator](testvectors_generator/) contains the software script for generating the inputs for hardware and the theoretical software outputs.
- [Vivado](Vivado/) contains Makefile and TCL scripts for synthesis and simulation. Check [Makefile](Vivado/Makefile) for the options.
- [regression_tests](regression_tests/) contains the code for regression tests.

## Basic Usage

### How to run the simulation

#### Step 1: Generate test inputs and software output

```sh
$ cd testvectors_generator
$ make clean
$ make NUMTESTS=10 HDL="verilog" cshake256
```

The correct output is stored in [testvectors.v](verilog/testvectors.v). The hardware simulation code uses `TESTVECTOR_INPUT` as input.
The hardware output should match the values in `TESTVECTOR_OUTPUT`.



#### STEP 2: Run simulation automatically

Try to execute the commands below. The output should state whether the simulation ends in success.

```sh
$ cd Vivado
$ make clean
$ make simulate
```

The simulation script should return with success message.
If the simulation script returns with errors or failures, proceed to STEP 3 and debug the code according to the waveform.

#### STEP 3: Debug the code using Vivado Waveform

To view the waveform for debugging the code, please run

```sh
$ cd Vivado
$ make waveform
```

### Different Parallel Parameters

This implementation supports different parallel units. Users can specify the value of `PARALLEL_SLICES` in the file
[keccak_pkg.v](verilog/keccak_pkg.v) to pick any parallel unit number from `1,2,4,8,16,32`.

## Performance

Following results are post-implementation results targeting Xilinx Artix-7 FPGA {Device: xc7a200t-3}.



| PARALLEL_SLICES |      Area       |       Area       |  Area   |  Area  |   Area   | Frequency |   Clock    | Time  | Time x Area |
| :-------------: | :-------------: | :--------------: | :-----: | :----: | :------: | :-------: | :--------: | :---: | :---------: |
|                 | **LUT (Logic)** | **LUT (Memory)** | **DSP** | **FF** | **BRAM** |   (MHz)   | **Cycles** | (us)  |   (x10^3)   |
|        1        |       773       |        25        |    0    |  483   |   0.5    |    163    |   5,010    | 30.74 |    24.53    |
|        2        |       875       |        50        |    0    |  451   |   0.5    |    167    |   2,306    | 13.81 |    12.77    |
|        4        |       896       |       100        |    0    |  360   |    0     |    157    |   1,086    | 6.92  |    6.89     |
|        8        |      1,183      |       200        |    0    |  270   |    0     |    158    |    542     | 3.43  |    4.74     |
|       16        |      1,818      |       400        |    0    |  226   |    0     |    164    |    270     | 1.65  |    3.65     |
|       32        |      3,863      |       800        |    0    |  181   |    0     |    166    |    101     | 0.61  |    2.84     |

