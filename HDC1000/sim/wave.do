onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbhdc1000/iClk
add wave -noupdate /tbhdc1000/inRstAsync
add wave -noupdate /tbhdc1000/ioSCL
add wave -noupdate /tbhdc1000/ioSDA
add wave -noupdate /tbhdc1000/UUT/StrobeTimeStamp/Strobe
add wave -noupdate /tbhdc1000/UUT/StrobeTimeStamp/cStrobeCountMax
add wave -noupdate /tbhdc1000/UUT/StrobeTimeStamp/StrobeCount
add wave -noupdate -expand /tbhdc1000/UUT/RegFile/RegFile
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16417889398 ps} 0}
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
WaveRestoreZoom {0 ps} {17238784500 ps}
