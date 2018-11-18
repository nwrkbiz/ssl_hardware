vmap work work
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/PkgGlobal/pkgGlobal.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/HDC1000/src/pkgHDC1000.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/RegFile/src/RegFile.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/Fifo/src/Fifo.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/StrobeGenTimeStamp/src/StrobeGenAndTimeStamp.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2C.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cSlaveDebounce.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cSlave.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/HDC1000/src/FSMD.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/HDC1000/src/TbFSMD.vhd}

vsim work.tbfsmd

do wave.do
config wave -signalnamewidth 2

run 100 us