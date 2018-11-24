vlib work
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/PkgGlobal/pkgGlobal.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2C.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cWrapper.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cSlaveDebounce.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cSlave.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/TbI2cWrapper.vhd}


vsim work.tbi2cwrapper

do wave.do
config wave -signalnamewidth 2

run 1000 us