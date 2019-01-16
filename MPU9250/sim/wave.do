onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbapds9301/iClk
add wave -noupdate /tbapds9301/inRstAsync
add wave -noupdate -divider FMSD
add wave -noupdate /tbapds9301/UUT/FSMD/R
add wave -noupdate -divider {i2c core}
add wave -noupdate /tbapds9301/UUT/ioSCL
add wave -noupdate /tbapds9301/UUT/ioSDA
add wave -noupdate -divider Fifo
add wave -noupdate /tbapds9301/UUT/Fifo/Fifo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {25344828 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 206
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {700750 ns} {1015750 ns}
