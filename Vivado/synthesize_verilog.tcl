set fileName [lindex $argv 0]

catch {set fptr [open $fileName r]} ;
set contents [read -nonewline $fptr] ;
close $fptr ;

set splitCont [split $contents "\n"] ;
foreach f $splitCont {
  puts $f
  read_verilog $f
}

#set module "main"
set module [lindex $argv 1]

#set partname "xc7a35ticsg324-1L"
#set partname "xc7a100tcsg324-1"
#Arty-A7 (biggest)
#set partname "xc7a200tfbg484-1"

#Virtex-7 (biggest)
#set partname "xc7v2000tflg1925-1"

set partname [lindex $argv 2]

#set brd_part "digilentinc.com:arty-a7-35:part0:1.0"

set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]

#synth_design -part $partname -top $module -mode out_of_context
synth_design -part $partname -top $module

  report_utilization
  report_utilization -hierarchical -hierarchical_depth 2

#read_xdc Arty-A7-35-Master.xdc
read_xdc timing.xdc

opt_design

  report_utilization
  report_utilization -hierarchical -hierarchical_depth 2

place_design

  report_utilization
  report_utilization -hierarchical -hierarchical_depth 2

route_design

  report_utilization
  report_utilization -hierarchical -hierarchical_depth 2
  report_timing
  #report_timing_summary
#Added by Shanquan, generating timing summary.
  #report_timing_summary -file timingSummary.rpt 

#write_verilog -force synth_system.v
#write_bitstream -force synth_system.bit

