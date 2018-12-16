onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbhdc1000/iClk
add wave -noupdate /tbhdc1000/inRstAsync
add wave -noupdate /tbhdc1000/ioSCL
add wave -noupdate /tbhdc1000/ioSDA
add wave -noupdate /tbhdc1000/iStrobe
add wave -noupdate /tbhdc1000/iTimeStamp
add wave -noupdate -divider FMSD
add wave -noupdate -radix hexadecimal /tbhdc1000/UUT/RegDataFrequency
add wave -noupdate -expand /tbhdc1000/UUT/FSMD/R
add wave -noupdate /tbhdc1000/UUT/FSMD/NxR
add wave -noupdate -divider {i2c core}
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/ioSCL
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/ioSDA
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/R
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/NxR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {434615312 ps} 0}
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
WaveRestoreZoom {0 ps} {3472487644 ps}
