create_clock -name clk -period 8.500 [get_ports clk]
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { rst }];


set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { din_valid  }]; 
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { din_ready  }]; 
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { din[0]  }]; 
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { din[1]  }]; 
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { din[2]  }]; 
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { din[3]  }]; 
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { din[4]  }]; 
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { din[5]  }]; 
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { din[6]  }]; 
set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { din[7]  }]; 
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { din[8]  }]; 
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { din[9]  }]; 
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { din[10] }]; 
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { din[11] }]; 
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { din[12] }]; 
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { din[13] }]; 
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { din[14] }]; 
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports { din[15] }]; 	
set_property -dict { PACKAGE_PIN R11   IOSTANDARD LVCMOS33 } [get_ports { din[16] }]; 
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { din[17] }]; 
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { din[18] }]; 
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { din[19] }]; 
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { din[20] }]; 
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { din[21] }]; 
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { din[22] }]; 
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { din[23] }]; 
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { din[24] }]; 
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { din[25] }]; 
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { din[26] }]; 
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { din[27] }]; 
set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { din[28] }]; 
set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { din[29] }]; 
set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { din[30] }]; 
set_property -dict { PACKAGE_PIN A6    IOSTANDARD LVCMOS33 } [get_ports { din[31] }]; 



set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { dout_valid  }]; 
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { dout_ready  }]; 
set_property -dict { PACKAGE_PIN A1    IOSTANDARD LVCMOS33 } [get_ports { dout[0]  }]; 


set_property -dict { PACKAGE_PIN B1    IOSTANDARD LVCMOS33 } [get_ports { dout[1]  }];
set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33 } [get_ports { dout[2]  }];
set_property -dict { PACKAGE_PIN B3    IOSTANDARD LVCMOS33 } [get_ports { dout[3]  }]; 
set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33 } [get_ports { dout[4]  }]; 
set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { dout[5]  }]; 
set_property -dict { PACKAGE_PIN F5    IOSTANDARD LVCMOS33 } [get_ports { dout[6] }]; 
set_property -dict { PACKAGE_PIN D8    IOSTANDARD LVCMOS33 } [get_ports { dout[7] }]; 
set_property -dict { PACKAGE_PIN C7    IOSTANDARD LVCMOS33 } [get_ports { dout[8] }]; 
set_property -dict { PACKAGE_PIN E7    IOSTANDARD LVCMOS33 } [get_ports { dout[9] }]; 
set_property -dict { PACKAGE_PIN D7    IOSTANDARD LVCMOS33 } [get_ports { dout[10] }]; 
set_property -dict { PACKAGE_PIN D5    IOSTANDARD LVCMOS33 } [get_ports { dout[11] }]; 
set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { dout[12] }]; 
set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { dout[13] }]; 
set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVCMOS33 } [get_ports { dout[14] }]; 
set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { dout[15] }]; 
set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { dout[16] }]; 
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { dout[17] }]; 
set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { dout[18] }]; 
set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { dout[19] }]; 
set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVCMOS33 } [get_ports { dout[20] }]; 
set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { dout[21] }]; 
set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { dout[22] }]; 
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { dout[23] }]; 
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { dout[24] }]; 
set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33 } [get_ports { dout[25] }]; 
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { dout[26] }]; 
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { dout[27] }]; 
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports { dout[28] }]; 
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { dout[29] }]; 
set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { dout[30] }]; 
set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports { dout[31] }]; 




