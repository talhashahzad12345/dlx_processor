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
vcom fifo.vhd
vcom div.vhd
vcom print_engine.vhd
vcom pll.vhd
vcom uart_rx.vhd
vcom uart_tx.vhd
vcom UART.vhd
vcom dlx.vhd
vcom tb_dlx.vhd

vsim -t ps -voptargs=+acc work.tb_dlx
do wave.do
