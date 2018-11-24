onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbstrobegenandtimestamp/iClk
add wave -noupdate /tbstrobegenandtimestamp/inRstAsync
add wave -noupdate /tbstrobegenandtimestamp/oStrobe
add wave -noupdate /tbstrobegenandtimestamp/oTimeStamp
add wave -noupdate -divider Counters
add wave -noupdate /tbstrobegenandtimestamp/UUT/StrobeCount
add wave -noupdate /tbstrobegenandtimestamp/UUT/TimeStamp
add wave -noupdate -divider {Counter MAX}
add wave -noupdate /tbstrobegenandtimestamp/UUT/StrobeCountMax
add wave -noupdate /tbstrobegenandtimestamp/UUT/TimeStampMax
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 285
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {54823296 ps} {57208542 ps}
