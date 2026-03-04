quit -sim
vdel -lib work -all
vlib work
vmap work work

vcom dlx_pkg.vhd
vcom regfile.vhd
vcom imem.vhd
vcom fetch.vhd
vcom decode.vhd
vcom execute.vhd
vcom dmem.vhd
vcom memory.vhd
vcom writeBack.vhd
vcom dlx.vhd
vcom tb_dlx.vhd

vsim -voptargs=+acc work.tb_dlx
do wave.do