onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbi2ccontroller/iClk
add wave -noupdate /tbi2ccontroller/inRstAsync
add wave -noupdate -divider {I2C IF}
add wave -noupdate /tbi2ccontroller/ioSCL
add wave -noupdate /tbi2ccontroller/ioSDA
add wave -noupdate -divider I2cWrapper
add wave -noupdate /tbi2ccontroller/UUT/sda_tri_i
add wave -noupdate /tbi2ccontroller/UUT/sda_tri_o
add wave -noupdate /tbi2ccontroller/UUT/sda_tri_t
add wave -noupdate /tbi2ccontroller/UUT/sda_async
add wave -noupdate /tbi2ccontroller/UUT/scl_tri_i
add wave -noupdate /tbi2ccontroller/UUT/scl_tri_o
add wave -noupdate /tbi2ccontroller/UUT/scl_tri_t
add wave -noupdate -divider {I2c Slave}
add wave -noupdate -divider {I2cWrapper Internals}
add wave -noupdate /tbi2ccontroller/UUT/iI2cAddr
add wave -noupdate /tbi2ccontroller/UUT/iI2cRegAddr
add wave -noupdate /tbi2ccontroller/UUT/iI2cData
add wave -noupdate /tbi2ccontroller/UUT/oI2cData
add wave -noupdate /tbi2ccontroller/UUT/iI2cBurstCount
add wave -noupdate /tbi2ccontroller/UUT/iI2cRead
add wave -noupdate /tbi2ccontroller/UUT/iI2cWrite
add wave -noupdate /tbi2ccontroller/UUT/oTransferDone
add wave -noupdate -expand /tbi2ccontroller/UUT/R
add wave -noupdate /tbi2ccontroller/UUT/NxR
add wave -noupdate /tbi2ccontroller/UUT/CmdAck
add wave -noupdate /tbi2ccontroller/UUT/AckOut
add wave -noupdate /tbi2ccontroller/UUT/i2c_core/u1/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {490484 ps} 0}
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
WaveRestoreZoom {3227687091 ps} {3228316940 ps}
