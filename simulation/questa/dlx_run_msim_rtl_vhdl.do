transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/TS/Desktop/dlx_processor/regfile.vhd}
vcom -93 -work work {C:/Users/TS/Desktop/dlx_processor/imem.vhd}
vcom -93 -work work {C:/Users/TS/Desktop/dlx_processor/dlx_pkg.vhd}
vcom -93 -work work {C:/Users/TS/Desktop/dlx_processor/fetch.vhd}
vcom -93 -work work {C:/Users/TS/Desktop/dlx_processor/decode.vhd}
vcom -93 -work work {C:/Users/TS/Desktop/dlx_processor/dlx.vhd}

