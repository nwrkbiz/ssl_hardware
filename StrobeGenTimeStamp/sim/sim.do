vcom -reportprogress 300 -work work C:/Users/Elias/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs/home/elias/ssl/ssl_hardware/PkgGlobal/pkgGlobal.vhd
vcom -reportprogress 300 -work work C:/Users/Elias/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs/home/elias/ssl/ssl_hardware/StrobeGenTimeStamp/src/StrobeGenAndTimeStamp.vhd
vcom -reportprogress 300 -work work C:/Users/Elias/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs/home/elias/ssl/ssl_hardware/StrobeGenTimeStamp/src/TbStrobeGenAndTimeStamp.vhd


vsim work.tbstrobegenandtimestamp

do wave.do
config wave -signalnamewidth 2

run 1000 us