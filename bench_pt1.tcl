set power_enable_analysis TRUE

if {$power_enable_timing_analysis == false} { set_app_var power_enable_timing_analysis true } 
set power_analysis_mode averaged
#set power_analysis_mode time_based
#####################################################################
#       link design
#####################################################################
set search_path 	"..home/STUDENTS/pv0164/hht_rtl/new/modified . "
#set link_path 		" * core.db"
set link_library	" * svt_16nm.db"
read_verilog		hht_bench.vg
current_design		control
link_design -verbose
list_designs -only_used
#list_designs -all

#####################################################################
#       read SDC
#####################################################################
read_sdc hht_bench.sdc
#set_disable_timing [get_lib_pins ssc_core_typ/*/G]
#source mac_ptpxmap.tcl

#####################################################################
#       set transition time / annotate parasitics
#####################################################################
read_parasitics		hht_bench.spf


#####################################################################
#       check/update/report timing
#####################################################################
check_timing
update_timing
report_timing

#####################################################################
#       read switching activity file
#####################################################################
#read_saif "mac.saif" -strip_path "tb"
#source hht_ptpxmap.ptpx
#sh vcd2saif -input hht_synth.vcd -output hht_synth.saif
#read_saif "hht_synth.saif" -strip_path "testbench/t1"
read_vcd  "g10.vcd" -strip_path "testbench/t1"
#report_switching_activity -list_annotated

#####################################################################
#       check/update/report power
#####################################################################
check_power
update_power
#set_power_analysis_options -waveform_format fsdb -waveform_output vcd
report_power -verbose -hierarchy > saif/saif_hht1_g10.rpt

#####################################################################
#       read switching activity file
#####################################################################
#read_saif "mac.saif" -strip_path "tb"
#source hht_ptpxmap.ptpx
#sh vcd2saif -input hht_synth.vcd -output hht_synth.saif
#read_saif "hht_synth.saif" -strip_path "testbench/t1"
read_vcd  "pesa.vcd" -strip_path "testbench/t1"
#report_switching_activity -list_annotated

#####################################################################
#       check/update/report power
#####################################################################
check_power
update_power
#set_power_analysis_options -waveform_format fsdb -waveform_output vcd
report_power -verbose -hierarchy > saif/saif_hht1_pesa.rpt

quit