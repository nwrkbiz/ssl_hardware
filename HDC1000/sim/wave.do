onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbhdc1000/iClk
add wave -noupdate /tbhdc1000/inRstAsync
add wave -noupdate /tbhdc1000/ioSCL
add wave -noupdate /tbhdc1000/ioSDA
add wave -noupdate /tbhdc1000/iStrobe
add wave -noupdate /tbhdc1000/iTimeStamp
add wave -noupdate -radix unsigned -childformat {{/tbhdc1000/UUT/RegFile/RegFile(0) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(1) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(2) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(3) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(4) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(5) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(6) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(7) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(8) -radix hexadecimal} {/tbhdc1000/UUT/RegFile/RegFile(9) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(10) -radix unsigned} {/tbhdc1000/UUT/RegFile/RegFile(11) -radix unsigned}} -expand -subitemconfig {/tbhdc1000/UUT/RegFile/RegFile(0) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(1) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(2) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(3) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(4) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(5) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(6) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(7) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(8) {-radix hexadecimal} /tbhdc1000/UUT/RegFile/RegFile(9) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(10) {-radix unsigned} /tbhdc1000/UUT/RegFile/RegFile(11) {-radix unsigned}} /tbhdc1000/UUT/RegFile/RegFile
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/ack_in
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/ack_out
add wave -noupdate -divider FMSD
add wave -noupdate -radix hexadecimal /tbhdc1000/UUT/RegDataFrequency
add wave -noupdate -expand /tbhdc1000/UUT/FSMD/R
add wave -noupdate /tbhdc1000/UUT/FSMD/NxR
add wave -noupdate -divider {i2c core}
add wave -noupdate -radix unsigned /tbhdc1000/UUT/FSMD/I2cController/clk_cnt
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cCmdAck
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cAckOut
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/core_cmd
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/Din
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/Dout
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/statemachine/state
add wave -noupdate /tbhdc1000/UUT/FSMD/I2cController/u1/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12278571197 ps} 0}
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
WaveRestoreZoom {11961036498 ps} {13025831656 ps}
