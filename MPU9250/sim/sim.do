vlib work
vmap work work
vcom -reportprogress 300 -work work {../../PkgGlobal/pkgGlobal.vhd}
vcom -reportprogress 300 -work work {../../APDS9301/src/pkgAPDS9301.vhd}
vcom -reportprogress 300 -work work {../../APDS9301/src/RegFile.vhd}
vcom -reportprogress 300 -work work {../../Fifo/src/Fifo.vhd}
vcom -reportprogress 300 -work work {../../StrobeGenTimeStamp/src/StrobeGenAndTimeStamp.vhd}
vcom -reportprogress 300 -work work {../../I2cUnit/src/I2C.vhd}
vcom -reportprogress 300 -work work {../../I2cUnit/src/I2cSlaveDebounce.vhd}
vcom -reportprogress 300 -work work {../../I2cUnit/src/I2cSlave.vhd}
vcom -reportprogress 300 -work work {../../APDS9301/src/FSMD.vhd}
vcom -reportprogress 300 -work work {../../Sync/src/Sync.vhd}
vcom -reportprogress 300 -work work {../../APDS9301/src/APDS9301.vhd}
vcom -reportprogress 300 -work work {../../APDS9301/src/TbAPDS9301.vhd}

vsim work.tbapds9301

do wave.do
config wave -signalnamewidth 2

run 1000 us