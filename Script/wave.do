vsim -voptargs="+acc" work.ahb_top_tb
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Test /ahb_top_tb/hclk
add wave -noupdate -group Test /ahb_top_tb/hreset_n
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/haddr
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/hwdata
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/hrdata
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/hwrite
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/hsize
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/hburst
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/htrans
add wave -noupdate -group Test /ahb_top_tb/dut/master_if/hready
add wave -noupdate -group Top /ahb_top_tb/hclk
add wave -noupdate -group Top /ahb_top_tb/hreset_n
add wave -noupdate -group Top /ahb_top_tb/en
add wave -noupdate -group Top /ahb_top_tb/data_top
add wave -noupdate -group Top /ahb_top_tb/write_top
add wave -noupdate -group Top /ahb_top_tb/address_top
add wave -noupdate -group Top /ahb_top_tb/wrap_en
add wave -noupdate -group Top /ahb_top_tb/beat_length
add wave -noupdate -group Top /ahb_top_tb/data_width_top
add wave -noupdate -group Top /ahb_top_tb/write_fifo
add wave -noupdate -group Top /ahb_top_tb/busy_en
add wave -noupdate -group Top /ahb_top_tb/i_wait_1
add wave -noupdate -group Top /ahb_top_tb/i_wait_2
add wave -noupdate -group Top /ahb_top_tb/i_wait_3
add wave -noupdate -group Top /ahb_top_tb/i_wait_4
add wave -noupdate -group Master /ahb_top_tb/dut/master/en
add wave -noupdate -group Master /ahb_top_tb/dut/master/data_top
add wave -noupdate -group Master /ahb_top_tb/dut/master/write_top
add wave -noupdate -group Master /ahb_top_tb/dut/master/address_top
add wave -noupdate -group Master /ahb_top_tb/dut/master/wrap_en
add wave -noupdate -group Master /ahb_top_tb/dut/master/beat_length
add wave -noupdate -group Master /ahb_top_tb/dut/master/data_width_top
add wave -noupdate -group Master /ahb_top_tb/dut/master/write_fifo
add wave -noupdate -group Master /ahb_top_tb/dut/master/busy_en
add wave -noupdate -group Master /ahb_top_tb/dut/master/internal_address
add wave -noupdate -group Master /ahb_top_tb/dut/master/internal_address_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/count
add wave -noupdate -group Master /ahb_top_tb/dut/master/count_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/size_bytes
add wave -noupdate -group Master /ahb_top_tb/dut/master/internal_read_data
add wave -noupdate -group Master /ahb_top_tb/dut/master/wrap_base
add wave -noupdate -group Master /ahb_top_tb/dut/master/wrap_boundary
add wave -noupdate -group Master /ahb_top_tb/dut/master/previous_address
add wave -noupdate -group Master /ahb_top_tb/dut/master/haddr_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/hwdata_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/hwrite_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/hsize_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/htrans_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/hburst_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/was_busy
add wave -noupdate -group Master /ahb_top_tb/dut/master/flag
add wave -noupdate -group Master /ahb_top_tb/dut/master/rd_ptr
add wave -noupdate -group Master /ahb_top_tb/dut/master/wr_ptr
add wave -noupdate -group Master /ahb_top_tb/dut/master/rd_ptr_reg
add wave -noupdate -group Master /ahb_top_tb/dut/master/rd_ptr_r
add wave -noupdate -group Master /ahb_top_tb/dut/master/i
add wave -noupdate -group Master /ahb_top_tb/dut/master/j
add wave -noupdate -group Master /ahb_top_tb/dut/master/fifo_empty
add wave -noupdate -group Master /ahb_top_tb/dut/master/fifo_full
add wave -noupdate -group Master /ahb_top_tb/dut/master/hmasterlock
add wave -noupdate -group Master /ahb_top_tb/dut/master/hnonsec
add wave -noupdate -group Master /ahb_top_tb/dut/master/hexcl
add wave -noupdate -group Master /ahb_top_tb/dut/master/cs
add wave -noupdate -group Master /ahb_top_tb/dut/master/ns
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hclk
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hreset_n
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/haddr
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hwrite
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hsize
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hburst
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/htrans
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hmastlock
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hprot
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hsel
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hwdata
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hrdata
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hready
add wave -noupdate -group Master /ahb_top_tb/dut/master_if/hresp
add wave -noupdate -group Decoder /ahb_top_tb/dut/decoder/hsel_1
add wave -noupdate -group Decoder /ahb_top_tb/dut/decoder/hsel_2
add wave -noupdate -group Decoder /ahb_top_tb/dut/decoder/hsel_3
add wave -noupdate -group Decoder /ahb_top_tb/dut/decoder/hsel_4
add wave -noupdate -group Decoder /ahb_top_tb/dut/decoder/mux_select
add wave -noupdate -group Decoder /ahb_top_tb/dut/decoder/transfer_valid
add wave -noupdate -group Decoder /ahb_top_tb/dut/decoder/slave_index
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/i_wait
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/cs
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/ns
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/addr_lat
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/hwrite_lat
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/hsize_lat
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/hburst_lat
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/htrans_lat
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/active_transfer
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hclk
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hreset_n
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/haddr
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hwrite
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hsize
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hburst
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/htrans
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hmastlock
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hprot
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hsel
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hwdata
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hrdata
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hready
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1_if/hresp
add wave -noupdate -group {Slave 1} /ahb_top_tb/dut/slave1/mem
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/i_wait
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/cs
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/ns
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/addr_lat
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/hwrite_lat
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/hsize_lat
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/hburst_lat
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/htrans_lat
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/active_transfer
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hclk
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hreset_n
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/haddr
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hwrite
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hsize
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hburst
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/htrans
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hmastlock
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hprot
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hsel
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hwdata
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hrdata
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hready
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2_if/hresp
add wave -noupdate -group {Slave 2} /ahb_top_tb/dut/slave2/mem
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/i_wait
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/cs
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/ns
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/addr_lat
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/hwrite_lat
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/hsize_lat
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/hburst_lat
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/htrans_lat
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/active_transfer
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hclk
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hreset_n
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/haddr
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hwrite
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hsize
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hburst
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/htrans
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hmastlock
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hprot
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hsel
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hwdata
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hrdata
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hready
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3_if/hresp
add wave -noupdate -group {Slave 3} /ahb_top_tb/dut/slave3/mem
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/hsel
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/i_wait
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/cs
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/ns
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/addr_lat
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/hwrite_lat
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/hsize_lat
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/hburst_lat
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/htrans_lat
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/active_transfer
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hclk
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hreset_n
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/haddr
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hwrite
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hsize
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hburst
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/htrans
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hmastlock
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hprot
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hsel
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hwdata
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hrdata
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hready
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4_if/hresp
add wave -noupdate -group {Slave 4} /ahb_top_tb/dut/slave4/mem
add wave -noupdate -group MUX /ahb_top_tb/dut/hrdata_mux/mux_select
add wave -noupdate -group MUX /ahb_top_tb/dut/hrdata_mux/hrdata_1
add wave -noupdate -group MUX /ahb_top_tb/dut/hrdata_mux/hrdata_2
add wave -noupdate -group MUX /ahb_top_tb/dut/hrdata_mux/hrdata_3
add wave -noupdate -group MUX /ahb_top_tb/dut/hrdata_mux/hrdata_4
add wave -noupdate -group MUX /ahb_top_tb/dut/hrdata_mux/hrdata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {152859 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {4537582 ps} {4832481 ps}
