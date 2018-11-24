vlib work
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/PkgGlobal/pkgGlobal.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/Fifo/src/Fifo.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/Fifo/src/TbFifo.vhd}


vsim work.tbfifo

do wave.do
config wave -signalnamewidth 2

run 1000 us