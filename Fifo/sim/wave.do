onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbfifo/iClk
add wave -noupdate /tbfifo/inRstAsync
add wave -noupdate -divider Data
add wave -noupdate -radix hexadecimal /tbfifo/iFifoData
add wave -noupdate -radix hexadecimal /tbfifo/oFifoData
add wave -noupdate -divider controls
add wave -noupdate /tbfifo/iFifoShift
add wave -noupdate /tbfifo/iFifoWrite
add wave -noupdate -divider internals
add wave -noupdate /tbfifo/UUT/Read
add wave -noupdate /tbfifo/UUT/Write
add wave -noupdate -radix hexadecimal -childformat {{/tbfifo/UUT/Fifo(0) -radix hexadecimal} {/tbfifo/UUT/Fifo(1) -radix hexadecimal} {/tbfifo/UUT/Fifo(2) -radix hexadecimal} {/tbfifo/UUT/Fifo(3) -radix hexadecimal}} -expand -subitemconfig {/tbfifo/UUT/Fifo(0) {-radix hexadecimal} /tbfifo/UUT/Fifo(1) {-radix hexadecimal} /tbfifo/UUT/Fifo(2) {-radix hexadecimal} /tbfifo/UUT/Fifo(3) {-radix hexadecimal}} /tbfifo/UUT/Fifo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {73492 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ps} {324250 ps}
