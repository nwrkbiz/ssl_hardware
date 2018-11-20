vlib work
vmap work work
vcom -reportprogress 300 -work work {../../PkgGlobal/pkgGlobal.vhd}
vcom -reportprogress 300 -work work {../../HDC1000/src/pkgHDC1000.vhd}
vcom -reportprogress 300 -work work {../../RegFile/src/RegFile.vhd}
vcom -reportprogress 300 -work work {../../Fifo/src/Fifo.vhd}
vcom -reportprogress 300 -work work {../../StrobeGenTimeStamp/src/StrobeGenAndTimeStamp.vhd}
vcom -reportprogress 300 -work work {../../I2cUnit/src/I2C.vhd}
vcom -reportprogress 300 -work work {../../I2cUnit/src/I2cSlaveDebounce.vhd}
vcom -reportprogress 300 -work work {../../I2cUnit/src/I2cSlave.vhd}
vcom -reportprogress 300 -work work {../../HDC1000/src/FSMD.vhd}
vcom -reportprogress 300 -work work {../../Sync/src/Sync.vhd}
vcom -reportprogress 300 -work work {../../HDC1000/src/HDC1000.vhd}
vcom -reportprogress 300 -work work {../../HDC1000/src/TbHDC1000.vhd}

vsim work.tbhdc1000

do wave.do
config wave -signalnamewidth 2

run 1000 us