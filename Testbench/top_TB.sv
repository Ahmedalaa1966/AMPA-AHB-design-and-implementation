`timescale 1ns/1ps

module ahb_top_tb;

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter MEM_DEPTH  = 256;

    // =========================================================================
    // DUT Signals (these are the ONLY signals ahb_top exposes)
    // =========================================================================
    logic hclk;
    logic hreset_n;

    logic                    en;
    logic [DATA_WIDTH-1:0]   data_top;
    logic                    write_top;
    logic [ADDR_WIDTH-1:0]   address_top;
    logic                    wrap_en;
    logic [4:0]              beat_length;
    logic [2:0]              data_width_top;
    logic                    write_fifo;
    logic                    busy_en;

    logic i_wait_1;
    logic i_wait_2;
    logic i_wait_3;
    logic i_wait_4;

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    ahb_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .MEM_DEPTH  (MEM_DEPTH)
    ) dut (
        .hclk           (hclk),
        .hreset_n       (hreset_n),

        .en             (en),
        .data_top       (data_top),
        .write_top      (write_top),
        .address_top    (address_top),
        .wrap_en        (wrap_en),
        .beat_length    (beat_length),
        .data_width_top (data_width_top),
        .write_fifo     (write_fifo),
        .busy_en        (busy_en),

        .i_wait_1       (i_wait_1),
        .i_wait_2       (i_wait_2),
        .i_wait_3       (i_wait_3),
        .i_wait_4       (i_wait_4)
    );

    // =========================================================================
    // Clock Generation
    // =========================================================================
    initial hclk = 0;
    always #5 hclk = ~hclk;   // 100 MHz

    // =========================================================================
    // Tasks
    // =========================================================================

    // ---- Apply reset --------------------------------------------------------
    task apply_reset();
        hreset_n       = 0;

        en             = 0;
        write_top      = 0;
        write_fifo     = 0;
        busy_en        = 0;
        wrap_en        = 0;
        beat_length    = 5'd0;
        data_width_top = 3'b010;   // 32-bit, matches DATA_WIDTH default

        data_top       = '0;
        address_top    = '0;

        i_wait_1 = 0;
        i_wait_2 = 0;
        i_wait_3 = 0;
        i_wait_4 = 0;

        repeat(4) @(posedge hclk);
        hreset_n = 1;
        @(posedge hclk);
        $display("[%0t] Reset released", $time);
    endtask

    // ---- Single write ---------------------------------------------------
    task single_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        $display("[%0t] SINGLE WRITE  addr=0x%08h  data=0x%08h", $time, addr, data);
        @(posedge hclk);
        en          = 1;
        write_top   = 1;
        @(posedge hclk);
        address_top = addr;
        data_top    = data;
        beat_length = 5'd0;   // SINGLE
        wrap_en     = 0;
        @(posedge hclk);
        en        = 0;
        write_top = 0;
        $display("[%0t] SINGLE WRITE  done", $time);
    endtask

    // ---- Single read ------------------------------------------------------
    // Reads master_if.hrdata hierarchically since ahb_top does not expose
    // hrdata as a top-level port.
    task single_read(
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] expected
        );
        $display("[%0t] SINGLE READ addr=0x%08h", $time, addr);
        @(posedge hclk);
        en          = 1;
        write_top   = 0;      // READ
        @(posedge hclk);
        address_top = addr;
        beat_length = 5'd0;
        wrap_en     = 0;

        // Wait for data phase
        @(posedge hclk);
        @(posedge hclk);

        if (dut.master_if.hrdata === expected)
            $display("[%0t] PASS READ addr=0x%08h data=0x%08h",
                      $time, addr, dut.master_if.hrdata);
        else
            $display("[%0t] FAIL READ addr=0x%08h data=0x%08h expected=0x%08h",
                      $time, addr, dut.master_if.hrdata, expected);

        en = 0;
    endtask

    // ---- Memory check -------------------------------------------------------
    // NOTE: matches the slave RTL fix — each slave now latches addr_lat as
    // (haddr - BASE_ADDR) >> $clog2(DATA_WIDTH/8), i.e. a relative word index.
    // So this task must subtract the same per-slave BASE_ADDR before shifting,
    // or it will check the wrong (and possibly out-of-range) mem[] location.
    task check_mem(input string slave_inst, input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] expected);
        int word_idx;
        logic [ADDR_WIDTH-1:0] base_addr;
        case (slave_inst)
            "slave1": base_addr = 32'h0000_0000;
            "slave2": base_addr = 32'h0000_0400;
            "slave3": base_addr = 32'h0000_0800;
            "slave4": base_addr = 32'h0000_0C00;
            default:  base_addr = 32'h0000_0000;
        endcase
        word_idx = (addr - base_addr) >> 2;
        case (slave_inst)
            "slave1": begin
                if (dut.slave1.mem[word_idx] === expected)
                    $display("[%0t] PASS  %s mem[%0d] (addr 0x%08h) = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave1.mem[word_idx]);
                else
                    $display("[%0t] FAIL  %s mem[%0d] (addr 0x%08h) = 0x%08h  expected = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave1.mem[word_idx], expected);
            end
            "slave2": begin
                if (dut.slave2.mem[word_idx] === expected)
                    $display("[%0t] PASS  %s mem[%0d] (addr 0x%08h) = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave2.mem[word_idx]);
                else
                    $display("[%0t] FAIL  %s mem[%0d] (addr 0x%08h) = 0x%08h  expected = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave2.mem[word_idx], expected);
            end
            "slave3": begin
                if (dut.slave3.mem[word_idx] === expected)
                    $display("[%0t] PASS  %s mem[%0d] (addr 0x%08h) = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave3.mem[word_idx]);
                else
                    $display("[%0t] FAIL  %s mem[%0d] (addr 0x%08h) = 0x%08h  expected = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave3.mem[word_idx], expected);
            end
            "slave4": begin
                if (dut.slave4.mem[word_idx] === expected)
                    $display("[%0t] PASS  %s mem[%0d] (addr 0x%08h) = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave4.mem[word_idx]);
                else
                    $display("[%0t] FAIL  %s mem[%0d] (addr 0x%08h) = 0x%08h  expected = 0x%08h",
                              $time, slave_inst, word_idx, addr, dut.slave4.mem[word_idx], expected);
            end
            default: $display("[%0t] check_mem: unknown slave_inst %s", $time, slave_inst);
        endcase
    endtask

    // ---- Burst write (INCR4) -------------------------------------------------
    // Same style as the reference master+slave TB: pre-load 4 beats into the
    // write FIFO, then kick off the burst.
    task burst_write_incr4(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] data0,
        input [DATA_WIDTH-1:0] data1,
        input [DATA_WIDTH-1:0] data2,
        input [DATA_WIDTH-1:0] data3
        );

        $display("[%0t] INCR4 WRITE   start_addr=0x%08h", $time, start_addr);

        @(posedge hclk); en = 0; write_fifo = 1; data_top = data0; repeat(1) @(posedge hclk);
                                                 data_top = data1; repeat(1) @(posedge hclk);
                                                 data_top = data2; repeat(1) @(posedge hclk);
                                                 data_top = data3; repeat(1) @(posedge hclk);
        write_fifo = 0;

        @(posedge hclk);
        en          = 1;
        write_top   = 1;
        address_top = start_addr;
        beat_length = 5'd4;
        wrap_en     = 0;

        wait(dut.master_if.htrans == 2'b00 && dut.master_if.hready);
        @(posedge hclk);
        en        = 0;
        write_top = 0;
        $display("[%0t] INCR4 WRITE   done", $time);
    endtask

    // ---- Burst read (INCR4) ---------------------------------------------------
    task burst_read_incr4(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] exp0,
        input [DATA_WIDTH-1:0] exp1,
        input [DATA_WIDTH-1:0] exp2,
        input [DATA_WIDTH-1:0] exp3
        );

        logic [DATA_WIDTH-1:0] read_data [0:3];

        $display("[%0t] INCR4 READ start_addr=0x%08h", $time, start_addr);

        @(posedge hclk);
        en          = 1;
        write_top   = 0;      // READ
        address_top = start_addr;
        beat_length = 5'd4;
        wrap_en     = 0;

        repeat(2) @(posedge hclk);
        for (int i = 0; i < 4; i++) begin
            @(posedge hclk);
            if (dut.master_if.hready)
                read_data[i] = dut.master_if.hrdata;
        end

        en = 0;

        if (read_data[0] === exp0 && read_data[1] === exp1 &&
            read_data[2] === exp2 && read_data[3] === exp3)
            $display("[%0t] TEST PASSED  INCR4 READ start_addr=0x%08h", $time, start_addr);
        else
            $display("[%0t] TEST FAILED  INCR4 READ start_addr=0x%08h  got=%h %h %h %h  expected=%h %h %h %h",
                      $time, start_addr,
                      read_data[0], read_data[1], read_data[2], read_data[3],
                      exp0, exp1, exp2, exp3);
    endtask

    // ---- Burst write (WRAP4) --------------------------------------------------
    task burst_write_wrap4(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] data0,
        input [DATA_WIDTH-1:0] data1,
        input [DATA_WIDTH-1:0] data2,
        input [DATA_WIDTH-1:0] data3
        );

        $display("[%0t] WRAP4 WRITE   start_addr=0x%08h", $time, start_addr);

        @(posedge hclk); en = 0; write_fifo = 1; data_top = data0; repeat(1) @(posedge hclk);
                                                 data_top = data1; repeat(1) @(posedge hclk);
                                                 data_top = data2; repeat(1) @(posedge hclk);
                                                 data_top = data3; repeat(1) @(posedge hclk);
        write_fifo = 0;

        @(posedge hclk);
        en          = 1;
        write_top   = 1;
        address_top = start_addr;
        beat_length = 5'd4;
        wrap_en     = 1;        // WRAP enabled

        wait(dut.master_if.htrans == 2'b00 && dut.master_if.hready);
        @(posedge hclk);
        en        = 0;
        write_top = 0;
        $display("[%0t] WRAP4 WRITE   done", $time);
    endtask

    // ---- Burst read (WRAP4) ----------------------------------------------------
    // Expected values must be supplied in the actual wrapped return order
    // (i.e. exp0 is the first beat returned, not necessarily the lowest address).
    task burst_read_wrap4(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] exp0,
        input [DATA_WIDTH-1:0] exp1,
        input [DATA_WIDTH-1:0] exp2,
        input [DATA_WIDTH-1:0] exp3
        );

        logic [DATA_WIDTH-1:0] read_data [0:3];

        $display("[%0t] WRAP4 READ start_addr=0x%08h", $time, start_addr);

        @(posedge hclk);
        en          = 1;
        write_top   = 0;      // READ
        address_top = start_addr;
        beat_length = 5'd4;
        wrap_en     = 1;       // WRAP enabled

        repeat(2) @(posedge hclk);
        for (int i = 0; i < 4; i++) begin
            @(posedge hclk);
            if (dut.master_if.hready)
                read_data[i] = dut.master_if.hrdata;
        end

        en = 0;

        if (read_data[0] === exp0 && read_data[1] === exp1 &&
            read_data[2] === exp2 && read_data[3] === exp3)
            $display("[%0t] TEST PASSED  WRAP4 READ start_addr=0x%08h", $time, start_addr);
        else
            $display("[%0t] TEST FAILED  WRAP4 READ start_addr=0x%08h  got=%h %h %h %h  expected=%h %h %h %h",
                      $time, start_addr,
                      read_data[0], read_data[1], read_data[2], read_data[3],
                      exp0, exp1, exp2, exp3);
    endtask

    // ---- Burst write (WRAP8) --------------------------------------------------
    task burst_write_wrap8(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] data0, data1, data2, data3,
        input [DATA_WIDTH-1:0] data4, data5, data6, data7
        );

        $display("[%0t] WRAP8 WRITE   start_addr=0x%08h", $time, start_addr);

        @(posedge hclk); en = 0; write_fifo = 1; data_top = data0; repeat(1) @(posedge hclk);
                                                 data_top = data1; repeat(1) @(posedge hclk);
                                                 data_top = data2; repeat(1) @(posedge hclk);
                                                 data_top = data3; repeat(1) @(posedge hclk);
                                                 data_top = data4; repeat(1) @(posedge hclk);
                                                 data_top = data5; repeat(1) @(posedge hclk);
                                                 data_top = data6; repeat(1) @(posedge hclk);
                                                 data_top = data7; repeat(1) @(posedge hclk);
        write_fifo = 0;

        @(posedge hclk);
        en          = 1;
        write_top   = 1;
        address_top = start_addr;
        beat_length = 5'd8;
        wrap_en     = 1;        // WRAP enabled

        wait(dut.master_if.htrans == 2'b00 && dut.master_if.hready);
        @(posedge hclk);
        en        = 0;
        write_top = 0;
        $display("[%0t] WRAP8 WRITE   done", $time);
    endtask

    // ---- Burst read (WRAP8) ----------------------------------------------------
    // Expected values must be supplied in the actual wrapped return order.
    task burst_read_wrap8(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] exp0, exp1, exp2, exp3,
        input [DATA_WIDTH-1:0] exp4, exp5, exp6, exp7
        );

        logic [DATA_WIDTH-1:0] read_data [0:7];

        $display("[%0t] WRAP8 READ start_addr=0x%08h", $time, start_addr);

        @(posedge hclk);
        en          = 1;
        write_top   = 0;      // READ
        address_top = start_addr;
        beat_length = 5'd8;
        wrap_en     = 1;       // WRAP enabled

        repeat(2) @(posedge hclk);
        for (int i = 0; i < 8; i++) begin
            @(posedge hclk);
            if (dut.master_if.hready)
                read_data[i] = dut.master_if.hrdata;
        end

        en = 0;

        if (read_data[0] === exp0 && read_data[1] === exp1 &&
            read_data[2] === exp2 && read_data[3] === exp3 &&
            read_data[4] === exp4 && read_data[5] === exp5 &&
            read_data[6] === exp6 && read_data[7] === exp7)
            $display("[%0t] TEST PASSED  WRAP8 READ start_addr=0x%08h", $time, start_addr);
        else
            $display("[%0t] TEST FAILED  WRAP8 READ start_addr=0x%08h  got=%h %h %h %h %h %h %h %h",
                      $time, start_addr,
                      read_data[0], read_data[1], read_data[2], read_data[3],
                      read_data[4], read_data[5], read_data[6], read_data[7]);
    endtask

    // ---- Burst write (WRAP16) ---------------------------------------------------
    task burst_write_wrap16(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] data0,  data1,  data2,  data3,
        input [DATA_WIDTH-1:0] data4,  data5,  data6,  data7,
        input [DATA_WIDTH-1:0] data8,  data9,  data10, data11,
        input [DATA_WIDTH-1:0] data12, data13, data14, data15
        );

        $display("[%0t] WRAP16 WRITE   start_addr=0x%08h", $time, start_addr);

        @(posedge hclk); en = 0; write_fifo = 1; data_top = data0;  repeat(1) @(posedge hclk);
                                                 data_top = data1;  repeat(1) @(posedge hclk);
                                                 data_top = data2;  repeat(1) @(posedge hclk);
                                                 data_top = data3;  repeat(1) @(posedge hclk);
                                                 data_top = data4;  repeat(1) @(posedge hclk);
                                                 data_top = data5;  repeat(1) @(posedge hclk);
                                                 data_top = data6;  repeat(1) @(posedge hclk);
                                                 data_top = data7;  repeat(1) @(posedge hclk);
                                                 data_top = data8;  repeat(1) @(posedge hclk);
                                                 data_top = data9;  repeat(1) @(posedge hclk);
                                                 data_top = data10; repeat(1) @(posedge hclk);
                                                 data_top = data11; repeat(1) @(posedge hclk);
                                                 data_top = data12; repeat(1) @(posedge hclk);
                                                 data_top = data13; repeat(1) @(posedge hclk);
                                                 data_top = data14; repeat(1) @(posedge hclk);
                                                 data_top = data15; repeat(1) @(posedge hclk);
        write_fifo = 0;

        @(posedge hclk);
        en          = 1;
        write_top   = 1;
        address_top = start_addr;
        beat_length = 5'd16;
        wrap_en     = 1;        // WRAP enabled

        wait(dut.master_if.htrans == 2'b00 && dut.master_if.hready);
        @(posedge hclk);
        en        = 0;
        write_top = 0;
        $display("[%0t] WRAP16 WRITE   done", $time);
    endtask

    // ---- Burst read (WRAP16) -----------------------------------------------------
    // Expected values must be supplied in the actual wrapped return order.
    task burst_read_wrap16(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] exp0,  exp1,  exp2,  exp3,
        input [DATA_WIDTH-1:0] exp4,  exp5,  exp6,  exp7,
        input [DATA_WIDTH-1:0] exp8,  exp9,  exp10, exp11,
        input [DATA_WIDTH-1:0] exp12, exp13, exp14, exp15
        );

        logic [DATA_WIDTH-1:0] read_data [0:15];

        $display("[%0t] WRAP16 READ start_addr=0x%08h", $time, start_addr);

        @(posedge hclk);
        en          = 1;
        write_top   = 0;      // READ
        address_top = start_addr;
        beat_length = 5'd16;
        wrap_en     = 1;       // WRAP enabled

        repeat(2) @(posedge hclk);
        for (int i = 0; i < 16; i++) begin
            @(posedge hclk);
            if (dut.master_if.hready)
                read_data[i] = dut.master_if.hrdata;
        end

        en = 0;

        if (read_data[0]  === exp0  && read_data[1]  === exp1  &&
            read_data[2]  === exp2  && read_data[3]  === exp3  &&
            read_data[4]  === exp4  && read_data[5]  === exp5  &&
            read_data[6]  === exp6  && read_data[7]  === exp7  &&
            read_data[8]  === exp8  && read_data[9]  === exp9  &&
            read_data[10] === exp10 && read_data[11] === exp11 &&
            read_data[12] === exp12 && read_data[13] === exp13 &&
            read_data[14] === exp14 && read_data[15] === exp15)
            $display("[%0t] TEST PASSED  WRAP16 READ start_addr=0x%08h", $time, start_addr);
        else
            $display("[%0t] TEST FAILED  WRAP16 READ start_addr=0x%08h", $time, start_addr);
    endtask

    // ---- Burst write (INCR8) --------------------------------------------------
    task burst_write_incr8(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] data0, data1, data2, data3,
        input [DATA_WIDTH-1:0] data4, data5, data6, data7
        );

        $display("[%0t] INCR8 WRITE   start_addr=0x%08h", $time, start_addr);

        @(posedge hclk); en = 0; write_fifo = 1; data_top = data0; repeat(1) @(posedge hclk);
                                                 data_top = data1; repeat(1) @(posedge hclk);
                                                 data_top = data2; repeat(1) @(posedge hclk);
                                                 data_top = data3; repeat(1) @(posedge hclk);
                                                 data_top = data4; repeat(1) @(posedge hclk);
                                                 data_top = data5; repeat(1) @(posedge hclk);
                                                 data_top = data6; repeat(1) @(posedge hclk);
                                                 data_top = data7; repeat(1) @(posedge hclk);
        write_fifo = 0;

        @(posedge hclk);
        en          = 1;
        write_top   = 1;
        address_top = start_addr;
        beat_length = 5'd8;
        wrap_en     = 0;

        wait(dut.master_if.htrans == 2'b00 && dut.master_if.hready);
        @(posedge hclk);
        en        = 0;
        write_top = 0;
        $display("[%0t] INCR8 WRITE   done", $time);
    endtask

    // ---- Burst read (INCR8) ----------------------------------------------------
    task burst_read_incr8(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] exp0, exp1, exp2, exp3,
        input [DATA_WIDTH-1:0] exp4, exp5, exp6, exp7
        );

        logic [DATA_WIDTH-1:0] read_data [0:7];

        $display("[%0t] INCR8 READ start_addr=0x%08h", $time, start_addr);

        @(posedge hclk);
        en          = 1;
        write_top   = 0;      // READ
        address_top = start_addr;
        beat_length = 5'd8;
        wrap_en     = 0;

        repeat(2) @(posedge hclk);
        for (int i = 0; i < 8; i++) begin
            @(posedge hclk);
            if (dut.master_if.hready)
                read_data[i] = dut.master_if.hrdata;
        end

        en = 0;

        if (read_data[0] === exp0 && read_data[1] === exp1 &&
            read_data[2] === exp2 && read_data[3] === exp3 &&
            read_data[4] === exp4 && read_data[5] === exp5 &&
            read_data[6] === exp6 && read_data[7] === exp7)
            $display("[%0t] TEST PASSED  INCR8 READ start_addr=0x%08h", $time, start_addr);
        else
            $display("[%0t] TEST FAILED  INCR8 READ start_addr=0x%08h  got=%h %h %h %h %h %h %h %h",
                      $time, start_addr,
                      read_data[0], read_data[1], read_data[2], read_data[3],
                      read_data[4], read_data[5], read_data[6], read_data[7]);
    endtask

    // ---- Burst write (INCR16) ---------------------------------------------------
    task burst_write_incr16(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] data0,  data1,  data2,  data3,
        input [DATA_WIDTH-1:0] data4,  data5,  data6,  data7,
        input [DATA_WIDTH-1:0] data8,  data9,  data10, data11,
        input [DATA_WIDTH-1:0] data12, data13, data14, data15
        );

        $display("[%0t] INCR16 WRITE   start_addr=0x%08h", $time, start_addr);

        @(posedge hclk); en = 0; write_fifo = 1; data_top = data0;  repeat(1) @(posedge hclk);
                                                 data_top = data1;  repeat(1) @(posedge hclk);
                                                 data_top = data2;  repeat(1) @(posedge hclk);
                                                 data_top = data3;  repeat(1) @(posedge hclk);
                                                 data_top = data4;  repeat(1) @(posedge hclk);
                                                 data_top = data5;  repeat(1) @(posedge hclk);
                                                 data_top = data6;  repeat(1) @(posedge hclk);
                                                 data_top = data7;  repeat(1) @(posedge hclk);
                                                 data_top = data8;  repeat(1) @(posedge hclk);
                                                 data_top = data9;  repeat(1) @(posedge hclk);
                                                 data_top = data10; repeat(1) @(posedge hclk);
                                                 data_top = data11; repeat(1) @(posedge hclk);
                                                 data_top = data12; repeat(1) @(posedge hclk);
                                                 data_top = data13; repeat(1) @(posedge hclk);
                                                 data_top = data14; repeat(1) @(posedge hclk);
                                                 data_top = data15; repeat(1) @(posedge hclk);
        write_fifo = 0;

        @(posedge hclk);
        en          = 1;
        write_top   = 1;
        address_top = start_addr;
        beat_length = 5'd16;
        wrap_en     = 0;

        wait(dut.master_if.htrans == 2'b00 && dut.master_if.hready);
        @(posedge hclk);
        en        = 0;
        write_top = 0;
        $display("[%0t] INCR16 WRITE   done", $time);
    endtask

    // ---- Burst read (INCR16) -----------------------------------------------------
    task burst_read_incr16(
        input [ADDR_WIDTH-1:0] start_addr,
        input [DATA_WIDTH-1:0] exp0,  exp1,  exp2,  exp3,
        input [DATA_WIDTH-1:0] exp4,  exp5,  exp6,  exp7,
        input [DATA_WIDTH-1:0] exp8,  exp9,  exp10, exp11,
        input [DATA_WIDTH-1:0] exp12, exp13, exp14, exp15
        );

        logic [DATA_WIDTH-1:0] read_data [0:15];

        $display("[%0t] INCR16 READ start_addr=0x%08h", $time, start_addr);

        @(posedge hclk);
        en          = 1;
        write_top   = 0;      // READ
        address_top = start_addr;
        beat_length = 5'd16;
        wrap_en     = 0;

        repeat(2) @(posedge hclk);
        for (int i = 0; i < 16; i++) begin
            @(posedge hclk);
            if (dut.master_if.hready)
                read_data[i] = dut.master_if.hrdata;
        end

        en = 0;

        if (read_data[0]  === exp0  && read_data[1]  === exp1  &&
            read_data[2]  === exp2  && read_data[3]  === exp3  &&
            read_data[4]  === exp4  && read_data[5]  === exp5  &&
            read_data[6]  === exp6  && read_data[7]  === exp7  &&
            read_data[8]  === exp8  && read_data[9]  === exp9  &&
            read_data[10] === exp10 && read_data[11] === exp11 &&
            read_data[12] === exp12 && read_data[13] === exp13 &&
            read_data[14] === exp14 && read_data[15] === exp15)
            $display("[%0t] TEST PASSED  INCR16 READ start_addr=0x%08h", $time, start_addr);
        else
            $display("[%0t] TEST FAILED  INCR16 READ start_addr=0x%08h", $time, start_addr);
    endtask

    // =========================================================================
    // Test Sequence
    // =========================================================================
    initial begin
        $dumpfile("ahb_top_tb.vcd");
        $dumpvars(0, ahb_top_tb);

        apply_reset();

        //--------------------------------------------------------------------
        // Test 1: Single write + read-back to Slave 1
        // (decoder maps haddr[11:10]==2'b00 -> slave 1, so 0x0000_0000 lands there)
        //--------------------------------------------------------------------
        $display("\n===== Test 1 : Write/Read Slave 1 =====");
        single_write(32'h0000_0000, 32'h1234_5678);
        repeat(3) @(posedge hclk);
        check_mem("slave1", 32'h0000_0000, 32'h1234_5678);
        single_read(32'h0000_0000, 32'h1234_5678);
        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 2: Single write + read-back to Slave 4 with a wait state
        // (haddr[11:10]==2'b11 -> slave 4; 0x0000_0C00 lands there)
        //--------------------------------------------------------------------
        $display("\n===== Test 2 : Write/Read Slave 4 with wait state =====");
        single_write(32'h0000_0C00, 32'hCAFE_BABE);
        repeat(3) @(posedge hclk);
        check_mem("slave4", 32'h0000_0C00, 32'hCAFE_BABE);

        @(posedge hclk);
        i_wait_4 = 1;
        repeat(2) @(posedge hclk);
        i_wait_4 = 0;

        single_read(32'h0000_0C00, 32'hCAFE_BABE);
        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 3: INCR4 write + read-back to Slave 1 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 3 : INCR4 Write/Read Slave 1 =====");
        burst_write_incr4(32'h0000_0010,
                           32'hAAAA_0001,
                           32'hBBBB_0002,
                           32'hCCCC_0003,
                           32'hDDDD_0004);
        repeat(6) @(posedge hclk);
        check_mem("slave1", 32'h0000_0010, 32'hAAAA_0001);
        check_mem("slave1", 32'h0000_0014, 32'hBBBB_0002);
        check_mem("slave1", 32'h0000_0018, 32'hCCCC_0003);
        check_mem("slave1", 32'h0000_001C, 32'hDDDD_0004);

        burst_read_incr4(32'h0000_0010,
                          32'hAAAA_0001,
                          32'hBBBB_0002,
                          32'hCCCC_0003,
                          32'hDDDD_0004);
        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 4: INCR4 write + read-back to Slave 2 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 4 : INCR4 Write/Read Slave 2 =====");
        burst_write_incr4(32'h0000_0410,
                           32'h1111_0001,
                           32'h2222_0002,
                           32'h3333_0003,
                           32'h4444_0004);
        repeat(6) @(posedge hclk);
        check_mem("slave2", 32'h0000_0410, 32'h1111_0001);
        check_mem("slave2", 32'h0000_0414, 32'h2222_0002);
        check_mem("slave2", 32'h0000_0418, 32'h3333_0003);
        check_mem("slave2", 32'h0000_041C, 32'h4444_0004);

        burst_read_incr4(32'h0000_0410,
                          32'h1111_0001,
                          32'h2222_0002,
                          32'h3333_0003,
                          32'h4444_0004);
        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 5: INCR4 write + read-back to Slave 3 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 5 : INCR4 Write/Read Slave 3 =====");
        burst_write_incr4(32'h0000_0810,
                           32'h5555_0001,
                           32'h6666_0002,
                           32'h7777_0003,
                           32'h8888_0004);
        repeat(6) @(posedge hclk);
        check_mem("slave3", 32'h0000_0810, 32'h5555_0001);
        check_mem("slave3", 32'h0000_0814, 32'h6666_0002);
        check_mem("slave3", 32'h0000_0818, 32'h7777_0003);
        check_mem("slave3", 32'h0000_081C, 32'h8888_0004);

        burst_read_incr4(32'h0000_0810,
                          32'h5555_0001,
                          32'h6666_0002,
                          32'h7777_0003,
                          32'h8888_0004);
        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 6: INCR4 write + read-back to Slave 4 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 6 : INCR4 Write/Read Slave 4 =====");
        burst_write_incr4(32'h0000_0C10,
                           32'h9999_0001,
                           32'hAAAA_0002,
                           32'hBBBB_0003,
                           32'hCCCC_0004);
        repeat(6) @(posedge hclk);
        check_mem("slave4", 32'h0000_0C10, 32'h9999_0001);
        check_mem("slave4", 32'h0000_0C14, 32'hAAAA_0002);
        check_mem("slave4", 32'h0000_0C18, 32'hBBBB_0003);
        check_mem("slave4", 32'h0000_0C1C, 32'hCCCC_0004);

        burst_read_incr4(32'h0000_0C10,
                          32'h9999_0001,
                          32'hAAAA_0002,
                          32'hBBBB_0003,
                          32'hCCCC_0004);
        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 7: WRAP4 write + read-back, Slave 1, unaligned start address
        // wrap window = size(4B) * beat_length(4) = 16 bytes -> window is
        // 0x0000_0000-0x0000_000C. Starting at 0x04, the sequence goes
        // 0x04 -> 0x08 -> 0x0C -> wraps back to 0x00.
        //--------------------------------------------------------------------
        $display("\n===== Test 7 : WRAP4 Write/Read Slave 1 (unaligned, wraps) =====");
        burst_write_wrap4(32'h0000_0004,
                           32'h1111_0001,   // -> 0x04
                           32'h2222_0002,   // -> 0x08
                           32'h3333_0003,   // -> 0x0C
                           32'h4444_0004);  // -> wraps to 0x00
        repeat(6) @(posedge hclk);
        check_mem("slave1", 32'h0000_0004, 32'h1111_0001);
        check_mem("slave1", 32'h0000_0008, 32'h2222_0002);
        check_mem("slave1", 32'h0000_000C, 32'h3333_0003);
        check_mem("slave1", 32'h0000_0000, 32'h4444_0004);

        burst_read_wrap4(32'h0000_0004,
                          32'h1111_0001,   // 0x04
                          32'h2222_0002,   // 0x08
                          32'h3333_0003,   // 0x0C
                          32'h4444_0004);  // wraps to 0x00

        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 8: WRAP8 write + read-back, Slave 2, unaligned start address
        // wrap window = size(4B) * beat_length(8) = 32 bytes -> window is
        // 0x0000_0400-0x0000_041C. Starting at 0x410 (word offset 4 within
        // the window), sequence: 0x410->0x414->0x418->0x41C->wraps to
        // 0x400->0x404->0x408->0x40C.
        //--------------------------------------------------------------------
        $display("\n===== Test 8 : WRAP8 Write/Read Slave 2 (unaligned, wraps) =====");
        burst_write_wrap8(32'h0000_0410,
                           32'hA001_0001,   // -> 0x410
                           32'hA002_0002,   // -> 0x414
                           32'hA003_0003,   // -> 0x418
                           32'hA004_0004,   // -> 0x41C
                           32'hA005_0005,   // -> wraps to 0x400
                           32'hA006_0006,   // -> 0x404
                           32'hA007_0007,   // -> 0x408
                           32'hA008_0008);  // -> 0x40C
        repeat(12) @(posedge hclk);
        check_mem("slave2", 32'h0000_0410, 32'hA001_0001);
        check_mem("slave2", 32'h0000_0414, 32'hA002_0002);
        check_mem("slave2", 32'h0000_0418, 32'hA003_0003);
        check_mem("slave2", 32'h0000_041C, 32'hA004_0004);
        check_mem("slave2", 32'h0000_0400, 32'hA005_0005);
        check_mem("slave2", 32'h0000_0404, 32'hA006_0006);
        check_mem("slave2", 32'h0000_0408, 32'hA007_0007);
        check_mem("slave2", 32'h0000_040C, 32'hA008_0008);

        burst_read_wrap8(32'h0000_0410,
                          32'hA001_0001,   // 0x410
                          32'hA002_0002,   // 0x414
                          32'hA003_0003,   // 0x418
                          32'hA004_0004,   // 0x41C
                          32'hA005_0005,   // wraps to 0x400
                          32'hA006_0006,   // 0x404
                          32'hA007_0007,   // 0x408
                          32'hA008_0008);  // 0x40C

        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 9: WRAP16 write + read-back, Slave 3, unaligned start address
        // wrap window = size(4B) * beat_length(16) = 64 bytes -> window is
        // 0x0000_0800-0x0000_083C. Starting at 0x818 (word offset 6), the
        // sequence walks up to 0x83C then wraps back to 0x800.
        //--------------------------------------------------------------------
        $display("\n===== Test 9 : WRAP16 Write/Read Slave 3 (unaligned, wraps) =====");
        burst_write_wrap16(32'h0000_0818,
                            32'hB001_0001, 32'hB002_0002, 32'hB003_0003, 32'hB004_0004, // 0x818,0x81C,0x820,0x824
                            32'hB005_0005, 32'hB006_0006, 32'hB007_0007, 32'hB008_0008, // 0x828,0x82C,0x830,0x834
                            32'hB009_0009, 32'hB010_0010, 32'hB011_0011, 32'hB012_0012, // 0x838,0x83C,wrap->0x800,0x804
                            32'hB013_0013, 32'hB014_0014, 32'hB015_0015, 32'hB016_0016);// 0x808,0x80C,0x810,0x814
        repeat(20) @(posedge hclk);
        check_mem("slave3", 32'h0000_0818, 32'hB001_0001);
        check_mem("slave3", 32'h0000_081C, 32'hB002_0002);
        check_mem("slave3", 32'h0000_0820, 32'hB003_0003);
        check_mem("slave3", 32'h0000_0824, 32'hB004_0004);
        check_mem("slave3", 32'h0000_0828, 32'hB005_0005);
        check_mem("slave3", 32'h0000_082C, 32'hB006_0006);
        check_mem("slave3", 32'h0000_0830, 32'hB007_0007);
        check_mem("slave3", 32'h0000_0834, 32'hB008_0008);
        check_mem("slave3", 32'h0000_0838, 32'hB009_0009);
        check_mem("slave3", 32'h0000_083C, 32'hB010_0010);
        check_mem("slave3", 32'h0000_0800, 32'hB011_0011);
        check_mem("slave3", 32'h0000_0804, 32'hB012_0012);
        check_mem("slave3", 32'h0000_0808, 32'hB013_0013);
        check_mem("slave3", 32'h0000_080C, 32'hB014_0014);
        check_mem("slave3", 32'h0000_0810, 32'hB015_0015);
        check_mem("slave3", 32'h0000_0814, 32'hB016_0016);

        burst_read_wrap16(32'h0000_0818,
                           32'hB001_0001, 32'hB002_0002, 32'hB003_0003, 32'hB004_0004,
                           32'hB005_0005, 32'hB006_0006, 32'hB007_0007, 32'hB008_0008,
                           32'hB009_0009, 32'hB010_0010, 32'hB011_0011, 32'hB012_0012,
                           32'hB013_0013, 32'hB014_0014, 32'hB015_0015, 32'hB016_0016);

        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 10: WRAP16 write + read-back, Slave 4, unaligned start address
        // wrap window = 64 bytes -> window is 0x0000_0C00-0x0000_0C3C.
        // Starting at 0xC28 (word offset 10), sequence walks up to 0xC3C
        // then wraps back to 0xC00.
        //--------------------------------------------------------------------
        $display("\n===== Test 10 : WRAP16 Write/Read Slave 4 (unaligned, wraps) =====");
        burst_write_wrap16(32'h0000_0C28,
                            32'hC001_0001, 32'hC002_0002, 32'hC003_0003, 32'hC004_0004, // 0xC28,0xC2C,0xC30,0xC34
                            32'hC005_0005, 32'hC006_0006, 32'hC007_0007, 32'hC008_0008, // 0xC38,0xC3C,wrap->0xC00,0xC04
                            32'hC009_0009, 32'hC010_0010, 32'hC011_0011, 32'hC012_0012, // 0xC08,0xC0C,0xC10,0xC14
                            32'hC013_0013, 32'hC014_0014, 32'hC015_0015, 32'hC016_0016);// 0xC18,0xC1C,0xC20,0xC24
        repeat(20) @(posedge hclk);
        check_mem("slave4", 32'h0000_0C28, 32'hC001_0001);
        check_mem("slave4", 32'h0000_0C2C, 32'hC002_0002);
        check_mem("slave4", 32'h0000_0C30, 32'hC003_0003);
        check_mem("slave4", 32'h0000_0C34, 32'hC004_0004);
        check_mem("slave4", 32'h0000_0C38, 32'hC005_0005);
        check_mem("slave4", 32'h0000_0C3C, 32'hC006_0006);
        check_mem("slave4", 32'h0000_0C00, 32'hC007_0007);
        check_mem("slave4", 32'h0000_0C04, 32'hC008_0008);
        check_mem("slave4", 32'h0000_0C08, 32'hC009_0009);
        check_mem("slave4", 32'h0000_0C0C, 32'hC010_0010);
        check_mem("slave4", 32'h0000_0C10, 32'hC011_0011);
        check_mem("slave4", 32'h0000_0C14, 32'hC012_0012);
        check_mem("slave4", 32'h0000_0C18, 32'hC013_0013);
        check_mem("slave4", 32'h0000_0C1C, 32'hC014_0014);
        check_mem("slave4", 32'h0000_0C20, 32'hC015_0015);
        check_mem("slave4", 32'h0000_0C24, 32'hC016_0016);

        burst_read_wrap16(32'h0000_0C28,
                           32'hC001_0001, 32'hC002_0002, 32'hC003_0003, 32'hC004_0004,
                           32'hC005_0005, 32'hC006_0006, 32'hC007_0007, 32'hC008_0008,
                           32'hC009_0009, 32'hC010_0010, 32'hC011_0011, 32'hC012_0012,
                           32'hC013_0013, 32'hC014_0014, 32'hC015_0015, 32'hC016_0016);

        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 11: INCR8 write + read-back, Slave 2 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 11 : INCR8 Write/Read Slave 2 =====");
        burst_write_incr8(32'h0000_0440,
                           32'hD001_0001, 32'hD002_0002, 32'hD003_0003, 32'hD004_0004,
                           32'hD005_0005, 32'hD006_0006, 32'hD007_0007, 32'hD008_0008);
        repeat(12) @(posedge hclk);
        check_mem("slave2", 32'h0000_0440, 32'hD001_0001);
        check_mem("slave2", 32'h0000_0444, 32'hD002_0002);
        check_mem("slave2", 32'h0000_0448, 32'hD003_0003);
        check_mem("slave2", 32'h0000_044C, 32'hD004_0004);
        check_mem("slave2", 32'h0000_0450, 32'hD005_0005);
        check_mem("slave2", 32'h0000_0454, 32'hD006_0006);
        check_mem("slave2", 32'h0000_0458, 32'hD007_0007);
        check_mem("slave2", 32'h0000_045C, 32'hD008_0008);

        burst_read_incr8(32'h0000_0440,
                          32'hD001_0001, 32'hD002_0002, 32'hD003_0003, 32'hD004_0004,
                          32'hD005_0005, 32'hD006_0006, 32'hD007_0007, 32'hD008_0008);

        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 12: INCR8 write + read-back, Slave 3 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 12 : INCR8 Write/Read Slave 3 =====");
        burst_write_incr8(32'h0000_0850,
                           32'hE001_0001, 32'hE002_0002, 32'hE003_0003, 32'hE004_0004,
                           32'hE005_0005, 32'hE006_0006, 32'hE007_0007, 32'hE008_0008);
        repeat(12) @(posedge hclk);
        check_mem("slave3", 32'h0000_0850, 32'hE001_0001);
        check_mem("slave3", 32'h0000_0854, 32'hE002_0002);
        check_mem("slave3", 32'h0000_0858, 32'hE003_0003);
        check_mem("slave3", 32'h0000_085C, 32'hE004_0004);
        check_mem("slave3", 32'h0000_0860, 32'hE005_0005);
        check_mem("slave3", 32'h0000_0864, 32'hE006_0006);
        check_mem("slave3", 32'h0000_0868, 32'hE007_0007);
        check_mem("slave3", 32'h0000_086C, 32'hE008_0008);

        burst_read_incr8(32'h0000_0850,
                          32'hE001_0001, 32'hE002_0002, 32'hE003_0003, 32'hE004_0004,
                          32'hE005_0005, 32'hE006_0006, 32'hE007_0007, 32'hE008_0008);

        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 13: INCR16 write + read-back, Slave 2 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 13 : INCR16 Write/Read Slave 2 =====");
        burst_write_incr16(32'h0000_0480,
                            32'hF001_0001, 32'hF002_0002, 32'hF003_0003, 32'hF004_0004,
                            32'hF005_0005, 32'hF006_0006, 32'hF007_0007, 32'hF008_0008,
                            32'hF009_0009, 32'hF010_0010, 32'hF011_0011, 32'hF012_0012,
                            32'hF013_0013, 32'hF014_0014, 32'hF015_0015, 32'hF016_0016);
        repeat(20) @(posedge hclk);
        check_mem("slave2", 32'h0000_0480, 32'hF001_0001);
        check_mem("slave2", 32'h0000_0484, 32'hF002_0002);
        check_mem("slave2", 32'h0000_0488, 32'hF003_0003);
        check_mem("slave2", 32'h0000_048C, 32'hF004_0004);
        check_mem("slave2", 32'h0000_0490, 32'hF005_0005);
        check_mem("slave2", 32'h0000_0494, 32'hF006_0006);
        check_mem("slave2", 32'h0000_0498, 32'hF007_0007);
        check_mem("slave2", 32'h0000_049C, 32'hF008_0008);
        check_mem("slave2", 32'h0000_04A0, 32'hF009_0009);
        check_mem("slave2", 32'h0000_04A4, 32'hF010_0010);
        check_mem("slave2", 32'h0000_04A8, 32'hF011_0011);
        check_mem("slave2", 32'h0000_04AC, 32'hF012_0012);
        check_mem("slave2", 32'h0000_04B0, 32'hF013_0013);
        check_mem("slave2", 32'h0000_04B4, 32'hF014_0014);
        check_mem("slave2", 32'h0000_04B8, 32'hF015_0015);
        check_mem("slave2", 32'h0000_04BC, 32'hF016_0016);

        burst_read_incr16(32'h0000_0480,
                           32'hF001_0001, 32'hF002_0002, 32'hF003_0003, 32'hF004_0004,
                           32'hF005_0005, 32'hF006_0006, 32'hF007_0007, 32'hF008_0008,
                           32'hF009_0009, 32'hF010_0010, 32'hF011_0011, 32'hF012_0012,
                           32'hF013_0013, 32'hF014_0014, 32'hF015_0015, 32'hF016_0016);

        repeat(3) @(posedge hclk);

        //--------------------------------------------------------------------
        // Test 14: INCR16 write + read-back, Slave 3 (no wait/busy states)
        //--------------------------------------------------------------------
        $display("\n===== Test 14 : INCR16 Write/Read Slave 3 =====");
        burst_write_incr16(32'h0000_0880,
                            32'h1A01_0001, 32'h1A02_0002, 32'h1A03_0003, 32'h1A04_0004,
                            32'h1A05_0005, 32'h1A06_0006, 32'h1A07_0007, 32'h1A08_0008,
                            32'h1A09_0009, 32'h1A10_0010, 32'h1A11_0011, 32'h1A12_0012,
                            32'h1A13_0013, 32'h1A14_0014, 32'h1A15_0015, 32'h1A16_0016);
        repeat(20) @(posedge hclk);
        check_mem("slave3", 32'h0000_0880, 32'h1A01_0001);
        check_mem("slave3", 32'h0000_0884, 32'h1A02_0002);
        check_mem("slave3", 32'h0000_0888, 32'h1A03_0003);
        check_mem("slave3", 32'h0000_088C, 32'h1A04_0004);
        check_mem("slave3", 32'h0000_0890, 32'h1A05_0005);
        check_mem("slave3", 32'h0000_0894, 32'h1A06_0006);
        check_mem("slave3", 32'h0000_0898, 32'h1A07_0007);
        check_mem("slave3", 32'h0000_089C, 32'h1A08_0008);
        check_mem("slave3", 32'h0000_08A0, 32'h1A09_0009);
        check_mem("slave3", 32'h0000_08A4, 32'h1A10_0010);
        check_mem("slave3", 32'h0000_08A8, 32'h1A11_0011);
        check_mem("slave3", 32'h0000_08AC, 32'h1A12_0012);
        check_mem("slave3", 32'h0000_08B0, 32'h1A13_0013);
        check_mem("slave3", 32'h0000_08B4, 32'h1A14_0014);
        check_mem("slave3", 32'h0000_08B8, 32'h1A15_0015);
        check_mem("slave3", 32'h0000_08BC, 32'h1A16_0016);

        burst_read_incr16(32'h0000_0880,
                           32'h1A01_0001, 32'h1A02_0002, 32'h1A03_0003, 32'h1A04_0004,
                           32'h1A05_0005, 32'h1A06_0006, 32'h1A07_0007, 32'h1A08_0008,
                           32'h1A09_0009, 32'h1A10_0010, 32'h1A11_0011, 32'h1A12_0012,
                           32'h1A13_0013, 32'h1A14_0014, 32'h1A15_0015, 32'h1A16_0016);

        // test 15 : INC4 write with slave1 delay 
        $display("\n===== Test 15 : INCR4 Write/Read Slave 1 with a delay =====");
        burst_write_incr4(32'h0000_0010,
                           32'hAAAA_0011,
                           32'hBBBB_0022,
                           32'hCCCC_0033,
                           32'hDDDD_0044);
        repeat(2) @(posedge hclk);
        i_wait_1 = 1 ;
        @(posedge hclk);
        i_wait_1 = 0 ;
        repeat(3) @(posedge hclk);

        burst_read_incr4(32'h0000_0010,
                          32'hAAAA_0011,
                          32'hBBBB_0022,
                          32'hCCCC_0033,
                          32'hDDDD_0044);

        // test 16: INC8 write with slave2 delay 
         $display("\n===== Test 16 : INCR8 Write/Read Slave 3 with a delay =====");
        burst_write_incr8(32'h0000_0850,
                           32'hE001_0001, 32'hE002_0002, 32'hE003_0003, 32'hE004_0004,
                           32'hE005_0005, 32'hE006_0006, 32'hE007_0007, 32'hE008_0008);
        repeat(3) @(posedge hclk);
        i_wait_3 = 1 ;
        repeat(2)@(posedge hclk);
        i_wait_3 = 0 ;
        repeat(10) @(posedge hclk);

        burst_read_incr8(32'h0000_0850,
                          32'hE001_0001, 32'hE002_0002, 32'hE003_0003, 32'hE004_0004,
                          32'hE005_0005, 32'hE006_0006, 32'hE007_0007, 32'hE008_0008);

        // test 17 INC16 write with delay 
        $display("\n===== Test 17 : INCR16 Write/Read Slave 3 with delay=====");
        burst_write_incr16(32'h0000_0880,
                            32'h1A01_0001, 32'h1A02_0002, 32'h1A03_0003, 32'h1A04_0004,
                            32'h1A05_0005, 32'h1A06_0006, 32'h1A07_0007, 32'h1A08_0008,
                            32'h1A09_0009, 32'h1A10_0010, 32'h1A11_0011, 32'h1A12_0012,
                            32'h1A13_0013, 32'h1A14_0014, 32'h1A15_0015, 32'h1A16_0016);
        repeat(3) @(posedge hclk);
        i_wait_3 = 1 ;
        repeat(2)@(posedge hclk);
        i_wait_3 = 0 ;
        @(posedge hclk) ;
        i_wait_3 = 1 ;
        @(posedge hclk);
        i_wait_3 = 0 ;

        repeat(16) @(posedge hclk);
        
        burst_read_incr16(32'h0000_0880,
                           32'h1A01_0001, 32'h1A02_0002, 32'h1A03_0003, 32'h1A04_0004,
                           32'h1A05_0005, 32'h1A06_0006, 32'h1A07_0007, 32'h1A08_0008,
                           32'h1A09_0009, 32'h1A10_0010, 32'h1A11_0011, 32'h1A12_0012,
                           32'h1A13_0013, 32'h1A14_0014, 32'h1A15_0015, 32'h1A16_0016);

        // TEST 18 WRAP4 with a delay 
        $display("\n===== Test 18 : WRAP4 Write/Read Slave 1 with a delay  =====");
        burst_write_wrap4(32'h0000_0004,
                           32'h1111_0001,   // -> 0x04
                           32'h2222_0002,   // -> 0x08
                           32'h3333_0003,   // -> 0x0C
                           32'h4444_0004);  // -> wraps to 0x00
         repeat(2) @(posedge hclk);
        i_wait_1 = 1 ;
        @(posedge hclk);
        i_wait_1 = 0 ;
        repeat(3) @(posedge hclk);
        
       

        burst_read_wrap4(32'h0000_0004,
                          32'h1111_0001,   // 0x04
                          32'h2222_0002,   // 0x08
                          32'h3333_0003,   // 0x0C
                          32'h4444_0004);  // wraps to 0x00


        // TEST 19 WRAP8 Write with a delay 
        $display("\n===== Test 19 : WRAP8 Write/Read Slave 2 with delay  =====");
        burst_write_wrap8(32'h0000_0410,
                           32'hA001_0001,   // -> 0x410
                           32'hA002_0002,   // -> 0x414
                           32'hA003_0003,   // -> 0x418
                           32'hA004_0004,   // -> 0x41C
                           32'hA005_0005,   // -> wraps to 0x400
                           32'hA006_0006,   // -> 0x404
                           32'hA007_0007,   // -> 0x408
                           32'hA008_0008);  // -> 0x40C
        repeat(2) @(posedge hclk);
        i_wait_2 = 1 ;
        repeat(2)@(posedge hclk);
        i_wait_2 = 0 ;
        repeat(10) @(posedge hclk);


        burst_read_wrap8(32'h0000_0410,
                          32'hA001_0001,   // 0x410
                          32'hA002_0002,   // 0x414
                          32'hA003_0003,   // 0x418
                          32'hA004_0004,   // 0x41C
                          32'hA005_0005,   // wraps to 0x400
                          32'hA006_0006,   // 0x404
                          32'hA007_0007,   // 0x408
                          32'hA008_0008);  // 0x40C

        repeat(10) @(posedge hclk);
        $display("[%0t] All tests complete", $time);
        $stop;
    end

endmodule