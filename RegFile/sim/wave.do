onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbregfile/iClk
add wave -noupdate /tbregfile/inRstAsync
add wave -noupdate -divider AvalonMM
add wave -noupdate -radix unsigned /tbregfile/iAvalonAddr
add wave -noupdate /tbregfile/iAvalonRead
add wave -noupdate -radix hexadecimal /tbregfile/oAvalonReadData
add wave -noupdate /tbregfile/iAvalonWrite
add wave -noupdate -radix hexadecimal /tbregfile/iAvalonWriteData
add wave -noupdate -divider FIFO
add wave -noupdate /tbregfile/iFifoData
add wave -noupdate /tbregfile/oFifoShift
add wave -noupdate /tbregfile/UUT/FifoRead
add wave -noupdate -divider {FSM IF}
add wave -noupdate /tbregfile/oRegDataFrequency
add wave -noupdate /tbregfile/oRegDataConfig
add wave -noupdate /tbregfile/oWriteConfigReg
add wave -noupdate -divider Registers
add wave -noupdate -radix hexadecimal -childformat {{/tbregfile/UUT/RegFile(0) -radix hexadecimal} {/tbregfile/UUT/RegFile(1) -radix hexadecimal} {/tbregfile/UUT/RegFile(2) -radix hexadecimal} {/tbregfile/UUT/RegFile(3) -radix hexadecimal} {/tbregfile/UUT/RegFile(4) -radix hexadecimal} {/tbregfile/UUT/RegFile(5) -radix hexadecimal} {/tbregfile/UUT/RegFile(6) -radix hexadecimal} {/tbregfile/UUT/RegFile(7) -radix hexadecimal} {/tbregfile/UUT/RegFile(8) -radix hexadecimal} {/tbregfile/UUT/RegFile(9) -radix hexadecimal} {/tbregfile/UUT/RegFile(10) -radix hexadecimal} {/tbregfile/UUT/RegFile(11) -radix hexadecimal}} -expand -subitemconfig {/tbregfile/UUT/RegFile(0) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(1) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(2) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(3) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(4) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(5) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(6) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(7) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(8) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(9) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(10) {-height 15 -radix hexadecimal} /tbregfile/UUT/RegFile(11) {-height 15 -radix hexadecimal}} /tbregfile/UUT/RegFile
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1307053 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 293
configure wave -valuecolwidth 69
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
WaveRestoreZoom {0 ps} {2161818 ps}
