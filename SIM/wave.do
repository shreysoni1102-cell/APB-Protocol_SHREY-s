onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /reset_case_tb/DUT/PCLK
add wave -noupdate -color White /reset_case_tb/DUT/PRESETn
add wave -noupdate -color Gold /reset_case_tb/DUT/PSEL
add wave -noupdate /reset_case_tb/DUT/PENABLE
add wave -noupdate /reset_case_tb/DUT/PREADY
add wave -noupdate /reset_case_tb/DUT/PWRITE
add wave -noupdate /reset_case_tb/DUT/PADDR
add wave -noupdate /reset_case_tb/DUT/PWDATA
add wave -noupdate /reset_case_tb/DUT/PSTRB
add wave -noupdate /reset_case_tb/DUT/WAIT_ENABLE
add wave -noupdate /reset_case_tb/DUT/PRDATA
add wave -noupdate /reset_case_tb/DUT/PSLVERR
add wave -noupdate /reset_case_tb/DUT/state
add wave -noupdate /reset_case_tb/DUT/next_state
add wave -noupdate /reset_case_tb/DUT/wait_count
add wave -noupdate /reset_case_tb/DUT/i
add wave -noupdate /reset_case_tb/DUT/address_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {137 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {168 ns}
