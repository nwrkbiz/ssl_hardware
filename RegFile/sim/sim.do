vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/PkgGlobal/pkgGlobal.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/HDC1000/src/pkgHDC1000.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/RegFile/src/RegFile.vhd}
vcom -reportprogress 300 -work work {C:/Users/Elias/Desktop/ESD FH/SSL_repo/ssl_hardware/RegFile/src/TbRegFile.vhd}

vsim work.tbregfile

do wave.do
config wave -signalnamewidth 2

run 1000 us