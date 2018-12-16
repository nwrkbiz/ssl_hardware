vlib work
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/PkgGlobal/pkgGlobal.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2C.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/Sync/src/Sync.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cController.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cSlaveDebounce.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/I2cSlave.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/I2cUnit/src/TbI2cController.vhd}


vsim work.tbi2ccontroller

do wave.do
config wave -signalnamewidth 2

run 1000 us