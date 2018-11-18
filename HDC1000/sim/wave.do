onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbfsmd/iClk
add wave -noupdate /tbfsmd/inRstAsync
add wave -noupdate -divider {I2C IF}
add wave -noupdate -radix unsigned /tbfsmd/FSMD/I2cController/clk_cnt
add wave -noupdate /tbfsmd/ioSCL
add wave -noupdate /tbfsmd/ioSDA
add wave -noupdate -divider StrobeTime
add wave -noupdate /tbfsmd/iStrobe
add wave -noupdate -radix unsigned /tbfsmd/iTimeStamp
add wave -noupdate /tbfsmd/StrobeTimeStamp/StrobeCount
add wave -noupdate /tbfsmd/StrobeTimeStamp/cStrobeCountMax
add wave -noupdate -radix hexadecimal /tbfsmd/StrobeTimeStamp/TimeStamp
add wave -noupdate /tbfsmd/StrobeTimeStamp/cTimeStampMax
add wave -noupdate -divider FIFO
add wave -noupdate /tbfsmd/oFifoWrite
add wave -noupdate -radix hexadecimal /tbfsmd/oDataToFifo
add wave -noupdate -radix hexadecimal /tbfsmd/oDataFromFifo
add wave -noupdate /tbfsmd/oFifoShift
add wave -noupdate -divider FSMD
add wave -noupdate -childformat {{/tbfsmd/FSMD/R.FifoData -radix hexadecimal}} -expand -subitemconfig {/tbfsmd/FSMD/R.FifoData {-height 15 -radix hexadecimal}} /tbfsmd/FSMD/R
add wave -noupdate /tbfsmd/FSMD/NxR
add wave -noupdate /tbfsmd/FSMD/I2cCmdAck
add wave -noupdate /tbfsmd/FSMD/I2cAckOut
add wave -noupdate -divider {I2c core}
add wave -noupdate /tbfsmd/FSMD/I2cController/clk_cnt
add wave -noupdate /tbfsmd/FSMD/I2cController/start
add wave -noupdate /tbfsmd/FSMD/I2cController/stop
add wave -noupdate /tbfsmd/FSMD/I2cController/read
add wave -noupdate /tbfsmd/FSMD/I2cController/write
add wave -noupdate /tbfsmd/FSMD/I2cController/ack_in
add wave -noupdate /tbfsmd/FSMD/I2cController/Din
add wave -noupdate /tbfsmd/FSMD/I2cController/cmd_ack
add wave -noupdate /tbfsmd/FSMD/I2cController/ack_out
add wave -noupdate /tbfsmd/FSMD/I2cController/Dout
add wave -noupdate /tbfsmd/FSMD/I2cController/SCL
add wave -noupdate /tbfsmd/FSMD/I2cController/SDA
add wave -noupdate /tbfsmd/FSMD/I2cController/core_cmd
add wave -noupdate /tbfsmd/FSMD/I2cController/core_ack
add wave -noupdate /tbfsmd/FSMD/I2cController/core_busy
add wave -noupdate /tbfsmd/FSMD/I2cController/core_txd
add wave -noupdate /tbfsmd/FSMD/I2cController/core_rxd
add wave -noupdate /tbfsmd/FSMD/I2cController/sr
add wave -noupdate /tbfsmd/FSMD/I2cController/shift
add wave -noupdate /tbfsmd/FSMD/I2cController/ld
add wave -noupdate /tbfsmd/FSMD/I2cController/go
add wave -noupdate /tbfsmd/FSMD/I2cController/host_ack
add wave -noupdate /tbfsmd/FSMD/I2cController/CMD_NOP
add wave -noupdate /tbfsmd/FSMD/I2cController/CMD_START
add wave -noupdate /tbfsmd/FSMD/I2cController/CMD_STOP
add wave -noupdate /tbfsmd/FSMD/I2cController/CMD_READ
add wave -noupdate /tbfsmd/FSMD/I2cController/CMD_WRITE
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {95200170 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 201
configure wave -valuecolwidth 188
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
WaveRestoreZoom {90155854 ps} {104398647 ps}
