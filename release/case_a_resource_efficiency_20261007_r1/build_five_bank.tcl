if {[catch {
    import_device eagle_s20.db -package EG4S20BG256
    open_project {C:/Users/27348/.codex_tmp/resource_efficiency_20261007_r5_tags/src/td_project/HDMI1.4b_Transmitter_v1.0.al} -single_run
    elaborate -top top
    read_adc {../user_source/constraints_source/pin.adc}
    read_sdc {../user_source/constraints_source/timing.sdc}
    optimize_rtl
    report_area -file five_bank_rtl.area
    optimize_gate -packarea five_bank_gate.area
    legalize_phy_inst
    update_timing
    report_timing_summary -file five_bank_gate.timing
    place
    update_timing -mode manhattan
    report_timing_summary -file five_bank_place.timing
    route
    update_timing -mode final
    report_area -io_info -file five_bank_phy.area
    report_timing_status -file five_bank_phy.ts
    report_timing_summary -file five_bank_pr.timing
    export_db five_bank_pr.db
    bitgen -bit case_a_5bank.bit
} reason]} {
    puts stderr $reason
    exit 1
}
puts {FIVE_BANK_TD_BUILD_COMPLETE}
exit
