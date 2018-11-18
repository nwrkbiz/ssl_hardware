onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbi2cwrapper/iClk
add wave -noupdate /tbi2cwrapper/inRstAsync
add wave -noupdate -divider {I2C IF}
add wave -noupdate /tbi2cwrapper/ioSCL
add wave -noupdate /tbi2cwrapper/ioSDA
add wave -noupdate -divider I2cWrapper
add wave -noupdate /tbi2cwrapper/iStart
add wave -noupdate /tbi2cwrapper/iI2cAddr
add wave -noupdate /tbi2cwrapper/iI2cRegAddr
add wave -noupdate /tbi2cwrapper/iI2cData
add wave -noupdate /tbi2cwrapper/oI2cData
add wave -noupdate /tbi2cwrapper/oDataValid
add wave -noupdate -divider {I2c Slave}
add wave -noupdate /tbi2cwrapper/read_req
add wave -noupdate /tbi2cwrapper/data_to_master
add wave -noupdate /tbi2cwrapper/data_valid
add wave -noupdate /tbi2cwrapper/data_from_master
add wave -noupdate -divider {I2cWrapper Internals}
add wave -noupdate /tbi2cwrapper/UUT/AckIn
add wave -noupdate /tbi2cwrapper/UUT/DataIn
add wave -noupdate /tbi2cwrapper/UUT/CmdAck
add wave -noupdate /tbi2cwrapper/UUT/AckOut
add wave -noupdate /tbi2cwrapper/UUT/DataOut
add wave -noupdate /tbi2cwrapper/UUT/R
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {337 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ps} {732 ps}
