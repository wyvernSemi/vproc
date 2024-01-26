onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test/clk
add wave -noupdate -radix unsigned /test/Count
add wave -noupdate /test/CS1
add wave -noupdate /test/CS2
add wave -noupdate /test/DEBUG_STOP
add wave -noupdate /test/Interrupt
add wave -noupdate /test/nreset
add wave -noupdate /test/nreset_h
add wave -noupdate /test/reset_irq
add wave -noupdate /test/Seed
add wave -noupdate /test/Update
add wave -noupdate /test/VCD_DUMP
add wave -noupdate /test/VPAddr
add wave -noupdate /test/VPDataIn
add wave -noupdate /test/VPDataOut
add wave -noupdate /test/VPRD
add wave -noupdate /test/VPWE
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ps} {96600 ps}
