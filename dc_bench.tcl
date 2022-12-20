set search_path {. ../home/STUDENTS/pv0164/hht_rtl/new/twoport} 
#set link_library {* svt_16nm.db}
#set synthetic_library {/home/STUDENTS/pv0164/dw_foundation.sldb}
set target_library {svt_16nm.db}
set synthetic_library {/home/STUDENTS/pv0164/dw_foundation.sldb}
set link_library [list "*" $target_library $synthetic_library]
read_sverilog {hht_bench.sv}
analyze -f sverilog -define SYNTH hht_bench.sv

# elaborate the design with the desired parameter values
# currently, the desired parameter values are the default ones

#elaborate control

# AFTER_ANALYZE_SECTION
current_design control
link
#uniquify

set_max_area 0.0
#current_design hht
saif_map -start
list_designs
create_clock [get_ports clk]  -period 20
#

compile -map_effort medium
#compile
write_sdc ./hht_bench.sdc
write -hierarchy -format verilog -output ./hht_bench.vg
write_parasitics -output ./hht_bench.spf
#sh vcd2saif -input hht_rtl.vcd -output ./rtlvcd.saif
#saif_map -create_map -source_instance testbench/t1 -input ./rtlvcd.saif 
#saif_map -write_map ./hht_ptpxmap.ptpx -type ptpx
report_area -hierarchy    > hht_bench_synth.area
report_cell               > hht_bench_synth.cell
report_hierarchy          > hht_bench_synth.hier
report_net                > hht_bench_synth.net
#report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 3   > hht_bench_synth.tim
report_power              > hht_bench_synth.pow
echo "HHT-bench synthesis complete" [ date ]

#check_timing
check_design
exit

