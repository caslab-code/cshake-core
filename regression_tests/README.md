Use the run_test.sh script to run the regresison tests, the tests check
VHDL and Verilog code, for SHAKE256, cSHAKE256, SHAKE128, cSHAKE128.
The tests also test 'parallel slices' option for hardware
for 1,2,4,8,16,32.  You can specify the number of tests per configuration.

For each test, the domain separator (cSHAKE), input size, input data, and output data
are generated randomly as part of the test vectors.

This script uses scripts in following folders:
* testvectors_generator/ -- to generate test vectors for each configuration
* Vivado/ -- to synthesize the design and run simulation
