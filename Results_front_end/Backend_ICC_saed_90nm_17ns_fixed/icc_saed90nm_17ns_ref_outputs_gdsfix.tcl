set TOP riscv_core_synth
set PROJECT_DIR /home/vdevaraj/Projects/RISC_v_single_cycle

set PHYS_DIR     $PROJECT_DIR/lib/saed90_phys/ref
set LIB_DIR      $PHYS_DIR/models
set NETLIST_DIR  $PROJECT_DIR/Results_front_end/Design_best_freq_saed_90nm
set REPORT_DIR   $PROJECT_DIR/backend/icc90/reports_ref
set OUTPUT_DIR   $PROJECT_DIR/backend/icc90/outputs_ref
set MW_DIR       $PROJECT_DIR/backend/icc90/mw

set TECH_FILE    $PHYS_DIR/techfiles/saed90nm_icc_1p9m.tf
set MW_REF_LIB   "$PHYS_DIR/saed90nm_fr $PHYS_DIR/saed90nm_dv"
set MAX_TLU      $PHYS_DIR/tluplus/saed90nm_1p9m_1t_Cmax.tluplus
set MIN_TLU      $PHYS_DIR/tluplus/saed90nm_1p9m_1t_Cmin.tluplus
set MAP_FILE     $PHYS_DIR/tluplus/tech2itf.map

set search_path "$LIB_DIR $NETLIST_DIR"
set target_library "saed90nm_typ_ht.db"
set link_library "* saed90nm_typ_ht.db"

file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR
file mkdir $MW_DIR

set MW_LIB $MW_DIR/riscv_core_synth_90nm_mw_ref

if {[file exists $MW_LIB]} {
    sh rm -rf $MW_LIB
}

create_mw_lib $MW_LIB \
    -technology $TECH_FILE \
    -mw_reference_library $MW_REF_LIB \
    -open

set_tlu_plus_files \
    -max_tluplus $MAX_TLU \
    -min_tluplus $MIN_TLU \
    -tech2itf_map $MAP_FILE

read_ddc $NETLIST_DIR/riscv_core_synth_saed90nm_17ns.ddc

current_design $TOP
link

read_sdc $NETLIST_DIR/riscv_core_synth_saed90nm_17ns.sdc

# Ignore async reset pins
set_false_path -to [get_pins -hierarchical */RSTB]

derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection -power_net VDD -ground_net VSS -tie

check_timing > $REPORT_DIR/check_timing_before_place.rpt
report_timing -max_paths 10 > $REPORT_DIR/timing_before_place.rpt
report_area > $REPORT_DIR/area_before_place.rpt
report_qor > $REPORT_DIR/qor_before_place.rpt

create_floorplan \
    -control_type aspect_ratio \
    -core_aspect_ratio 1.0 \
    -core_utilization 0.70 \
    -left_io2core 10 \
    -bottom_io2core 10 \
    -right_io2core 10 \
    -top_io2core 10

create_fp_placement

place_opt -power -continue_on_missing_scandef

clock_opt -only_cts -continue_on_missing_scandef
clock_opt -only_psyn -continue_on_missing_scandef

route_opt

report_timing -max_paths 10 > $REPORT_DIR/timing_post_route.rpt
report_area > $REPORT_DIR/area_post_route.rpt
report_power > $REPORT_DIR/power_post_route.rpt
report_constraint -all_violators > $REPORT_DIR/constraints_post_route.rpt
report_qor > $REPORT_DIR/qor_post_route.rpt

write_verilog -no_physical_only_cells $OUTPUT_DIR/riscv_core_synth_saed90nm_postroute.v
write_sdc $OUTPUT_DIR/riscv_core_synth_saed90nm_postroute.sdc
write_sdf $OUTPUT_DIR/riscv_core_synth_saed90nm_postroute.sdf

extract_rc
write_parasitics -format SPEF -output $OUTPUT_DIR/riscv_core_synth_saed90nm_postroute.spef

save_mw_cel -as ${TOP}_postroute

set_write_stream_options \
    -map_layer $PHYS_DIR/saed90nm.gdsout.map \
    -output_filling fill \
    -child_depth 20 \
    -output_outdated_fill \
    -output_pin {text geometry}

write_stream -cells ${TOP}_postroute $OUTPUT_DIR/riscv_core_synth_saed90nm_postroute.gds

close_mw_lib

puts "ICC SAED90nm layout with extracted ref completed."
exit
