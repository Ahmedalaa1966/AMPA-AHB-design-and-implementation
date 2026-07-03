import ahb_master_pkg::*;
module ahb_master #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (

    ahb_if.master ahb                    ,

// user defined inputs
    input  logic                    en,             // enable signal for the module
    input  logic [DATA_WIDTH-1:0]   data_top,       // write data from user
    input  logic                    write_top,      // 1 = write operation, 0 = read operation
    input  logic [ADDR_WIDTH-1:0]   address_top,    // initial address of the desired slave
    input  logic                    wrap_en,        // enable signal for wrap burst
    input  logic [4:0]              beat_length,    // number of beats in a burst transfer
    input  logic [2:0]              data_width_top, // size of the data bus in bytes
    input  logic                    write_fifo,     // enable signal for writing in the fifo
    input  logic                    busy_en        // enable signal to assert the busy in the master


);

    // internal signals
    logic [ADDR_WIDTH-1:0]  internal_address      ;
    logic [ADDR_WIDTH-1:0]  internal_address_reg  ;
    logic [4:0]             count                 ;
    logic [4:0]             count_reg             ;
    logic [7:0]             size_bytes            ;
    logic [DATA_WIDTH-1:0]  internal_read_data    ;
    logic [ADDR_WIDTH-1:0]  wrap_base             ;
    logic [ADDR_WIDTH-1:0]  wrap_boundary         ;
    logic [ADDR_WIDTH-1:0]  previous_address      ;
    logic [ADDR_WIDTH-1:0]  haddr_reg             ;
    logic [DATA_WIDTH-1:0]  hwdata_reg            ;
    logic                   hwrite_reg            ;
    logic [2:0]             hsize_reg             ;
    logic [1:0]             htrans_reg            ;
    logic [2:0]             hburst_reg            ;
    // ---------------------------------------------------------------
    // FIX: was_busy is now a REGISTERED signal (moved out of always_comb)
    // ---------------------------------------------------------------
    logic                   was_busy              ;
    logic                   flag                  ;


    // FIFO signals
    logic [4:0]             rd_ptr                ;
    logic [4:0]             wr_ptr                ;
    logic [4:0]             rd_ptr_reg            ;
    logic [4:0]             rd_ptr_r              ;   // read FIFO read pointer (separate)
    logic [DATA_WIDTH-1:0]  w_mem [0:16]          ;   // write FIFO memory
    logic [DATA_WIDTH-1:0]  r_mem [0:16]          ;   // read  FIFO memory
    integer                 i, j                  ;
    logic                   fifo_empty            ;   // asserted when FIFO is empty
    logic                   fifo_full             ;   // asserted when FIFO is full

    assign fifo_empty  = (wr_ptr == rd_ptr) ;
    assign fifo_full   = ((wr_ptr + 1'b1) == rd_ptr) ;

    // Tie off unused master control outputs
    assign hmasterlock = 1'b0 ;
    assign hnonsec     = 1'b0 ;
    assign hexcl       = 1'b0 ;



    state_t cs, ns;

    // -------------------------------------------------------------------------
    // Combinational: size_bytes from hsize
    // -------------------------------------------------------------------------
    always_comb begin
        case (ahb.hsize)
            3'b000:  size_bytes = 8'd1  ;   // 8  bits
            3'b001:  size_bytes = 8'd2  ;   // 16 bits
            3'b010:  size_bytes = 8'd4  ;   // 32 bits
            3'b011:  size_bytes = 8'd8  ;   // 64 bits
            3'b100:  size_bytes = 8'd16 ;   // 128 bits
            3'b101:  size_bytes = 8'd32 ;   // 256 bits
            3'b110:  size_bytes = 8'd64 ;   // 512 bits
            3'b111:  size_bytes = 8'd128;   // 1024 bits
            default: size_bytes = 8'd1  ;   // safe fallback
        endcase
    end

    // -------------------------------------------------------------------------
    // Write FIFO
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : fifo_write
        if (!ahb.hreset_n) begin
            for (i = 0; i < 15; i = i + 1)
                w_mem[i] <= '0;
            wr_ptr <= '0;
        end
        else if (write_fifo && !fifo_full && cs != write_data_state) begin
            w_mem[wr_ptr] <= data_top;
            wr_ptr        <= wr_ptr + 1'b1;
        end
        else
            wr_ptr <= 'b0;
    end

    // -------------------------------------------------------------------------
    // Read FIFO
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : fifo_read
        if (!ahb.hreset_n) begin
            for (j = 0; j < 15; j = j + 1)
                r_mem[j] <= '0;
                rd_ptr_r <= '0;
        end
        else if (cs == read_data_state && ahb.hready) begin
            r_mem[rd_ptr_r] <= ahb.hrdata;
            rd_ptr_r        <= rd_ptr_r + 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // Current state register
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : cs_transition
        if (!ahb.hreset_n)
            cs <= IDLE;
        else
            cs <= ns;
    end

    // -------------------------------------------------------------------------
    // Sequential state elements
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : seq_elements
        if (!ahb.hreset_n) begin
            count                <= 'b0 ;
            rd_ptr               <= 'b0 ;
            internal_address     <= 'b0 ;
            internal_address_reg <= 'b0 ;
            wrap_base            <= 'b0 ;
            wrap_boundary        <= 'b0 ;
            haddr_reg            <= 'b0 ;
            hwdata_reg           <= 'b0 ;
            hwrite_reg           <= 'b0 ;
            hsize_reg            <= 'b0 ;
            htrans_reg           <= 'b0 ;
            hburst_reg           <= 'b0 ;
            flag                 <= 'b0 ;
            // ---------------------------------------------------------------
            // FIX: reset was_busy as a register
            // ---------------------------------------------------------------
            was_busy             <= 'b0 ;
        end

        else begin

            
            if (ns == busy_state) begin
                was_busy <= 1'b1;
            end
            else if (cs == write_data_state && was_busy && flag) begin
                was_busy <= 1'b0;
            end
            else if (cs != busy_state && cs != write_data_state) begin
                was_busy <= 1'b0;
            end
            
            if (ahb.hready && cs != busy_state) begin
                haddr_reg  <= ahb.haddr  ;
                hwdata_reg <= ahb.hwdata ;
                hwrite_reg <= ahb.hwrite ;
                hsize_reg  <= ahb.hsize  ;
                htrans_reg <= ahb.htrans ;
                hburst_reg <= ahb.hburst ;
                count_reg  <= count  ;
                rd_ptr_reg <= rd_ptr ;
            end

           
            case (cs)

                IDLE: begin
                    count            <= 'b0   ;
                    rd_ptr           <= 'b0   ;
                    flag             <= 'b0   ;
                    internal_address <= ahb.haddr ;
                    if (wrap_en) begin
                        wrap_boundary <= size_bytes * beat_length            ;
                        wrap_base     <= internal_address & (~(wrap_boundary - 1)) ;
                    end 
                    else begin
                        wrap_boundary <= 'b0 ;
                        wrap_base     <= 'b0 ;
                    end
                end

                write_address_state: begin
                    count            <= 'b0  ;
                    rd_ptr           <= 'b0  ;
                    flag             <= 'b0  ;
                    internal_address <= address_top + size_bytes;
                    if (wrap_en) begin
                        wrap_boundary <= size_bytes * beat_length                  ;
                        wrap_base     <= internal_address & (~(wrap_boundary - 1)) ;
                    end 
                    else begin
                        wrap_boundary <= 'b0 ;
                        wrap_base     <= 'b0 ;
                    end
                end

                write_data_state: begin
                    // Fixed-length incrementing bursts: INCR4 / INCR8 / INCR16
                    if ((ahb.hburst == 3'b011 || ahb.hburst == 3'b101 || ahb.hburst == 3'b111) && ahb.hwrite) begin
                        if (was_busy && !flag) begin
                            internal_address <= internal_address_reg + size_bytes   ;
                            count  <= count_reg + 1'b1  ;
                            rd_ptr <= rd_ptr_reg + 1'b1 ;
                            flag   <= 1'b1              ;
                        end
                        else if (ahb.hready) begin
                            count  <= count + 1'b1  ;
                            rd_ptr <= rd_ptr + 1'b1 ;
                            flag   <= 1'b0          ;
                            if(ns!= busy_state)
                                internal_address <= internal_address + size_bytes;
                        end
                    end

                    // Wrap bursts: WRAP4 / WRAP8 / WRAP16
                    else if ((ahb.hburst == 3'b010 || ahb.hburst == 3'b100 || ahb.hburst == 3'b110)  && ahb.hwrite) begin
                        if (was_busy && !flag) begin
                            count  <= count_reg + 1'b1  ;
                            rd_ptr <= rd_ptr_reg + 1'b1 ;
                            flag   <= 1'b1       ;
                            if (((internal_address_reg + size_bytes) % wrap_boundary == 0) && (internal_address_reg != 'b0))
                                internal_address <= wrap_base;
                            else
                                internal_address <= internal_address_reg + size_bytes;
                        end  
                        else if (ahb.hready) begin    
                            count  <= count + 1'b1;
                            rd_ptr <= rd_ptr + 1'b1;
                            flag   <= 1'b0;
                            if (ns != busy_state) begin
                                if (((internal_address + size_bytes) % wrap_boundary == 0) && (internal_address != 'b0))
                                    internal_address <= wrap_base;
                                else
                                    internal_address <= internal_address + size_bytes;
                            end
                        end
                    end  
                end

                read_address_state: begin

                    count <= '0;
                    internal_address <= address_top + size_bytes;
                    if (wrap_en) begin
                        wrap_boundary <= size_bytes * beat_length                  ;
                        wrap_base     <= internal_address & (~(wrap_boundary - 1)) ;
                    end 
                    else begin
                        wrap_boundary <= 'b0 ;
                        wrap_base     <= 'b0 ;
                    end

                end

                read_data_state: begin
                    
                    // INC bursts: INC4 / INC8 / INC16
                    if ((ahb.hburst == 3'b011 || ahb.hburst == 3'b101 || ahb.hburst == 3'b111) && !ahb.hwrite ) begin
                        if (was_busy && !flag) begin
                            internal_address <= internal_address_reg + size_bytes   ;
                            count  <= count_reg + 1'b1  ;
                            flag   <= 1'b1              ;
                        end
                        else if (ahb.hready) begin
                            count            <= count + 1'b1                        ;
                            flag             <= 'b0                                 ;
                            if(ns!= busy_state)
                                internal_address <= internal_address + size_bytes   ;
                        end
                        
                    end
                        
                    // Wrap bursts: WRAP4 / WRAP8 / WRAP16 
                    else if ((ahb.hburst == 3'b010 || ahb.hburst == 3'b100 || ahb.hburst == 3'b110)  && !ahb.hwrite ) begin
                        if (was_busy && !flag) begin
                            internal_address <= internal_address_reg + size_bytes   ;
                            count  <= count_reg + 1'b1  ;
                            flag   <= 1'b1       ;
                            if (((internal_address_reg + size_bytes) % wrap_boundary == 0) && (internal_address_reg != 'b0))
                                internal_address <= wrap_base;
                            else
                                internal_address <= internal_address_reg + size_bytes;
                        end 
                        else if (ahb.hready) begin
                            count  <= count + 1'b1                              ; 
                            flag   <= 1'b0                                      ;                           
                        if (ns != busy_state) begin
                                if (((internal_address + size_bytes) % wrap_boundary == 0) && (internal_address != 'b0))
                                    internal_address <= wrap_base;
                                else
                                    internal_address <= internal_address + size_bytes;
                            end
                        end 
                    end
                end

                busy_state: begin
                    // Save count/ptr snapshot so we can restore after busy
                    count_reg            <= count - 1        ;
                    rd_ptr_reg           <= rd_ptr - 1       ;
                    internal_address_reg <= internal_address ;
                end

                default: begin
                    count            <= 'b0 ;
                    rd_ptr           <= 'b0 ;
                    internal_address <= 'b0 ;
                end

            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Next-state logic (combinational)
    // -------------------------------------------------------------------------
    always_comb begin : ns_transition

        case (cs)

            IDLE: begin
                if (en && write_top && ahb.hready)
                    ns = write_address_state;
                else if (en && !write_top && ahb.hready)
                    ns = read_address_state;
                else
                    ns = IDLE;
            end

            write_address_state: begin
                ns = write_data_state;
            end

            write_data_state: begin
                if (busy_en) begin
                    ns = busy_state;
                end
                else if (ahb.hburst == 3'b000 && ahb.hready) begin         // Single transfer done
                    ns = IDLE      ;
                end
                else if (ahb.hready && ahb.hwrite) begin                    // Burst transfer
                    if (count > beat_length - 1 && !was_busy)
                        ns = IDLE  ;
                    else
                        ns = write_data_state ;
                end
                else if (!write_top && ahb.hready) begin                // Direction: read
                    ns = read_address_state   ;
                end
                else begin
                    ns = write_data_state    ;
                end
            end

            read_address_state: begin
                    ns = read_data_state;
            end

            read_data_state: begin
                if (busy_en)  begin 
                   ns = busy_state ; 
                end
                else if (ahb.hburst == 3'b000 && ahb.hready) begin               // Single read done
                    ns = IDLE;
                end
                else if (ahb.hburst != 3'b000 && ahb.hready) begin          // Burst read
                    if (count == beat_length - 1)
                        ns = IDLE;
                    else
                        ns = read_data_state;
                end
                else if (write_top && ahb.hready) begin                 // Direction: write
                    ns = write_address_state;
                end
                else begin
                    ns = read_data_state;
                end
            end

            busy_state: begin
                if (busy_en)
                    ns = busy_state;
                else
                    ns = (ahb.hwrite) ? write_data_state : read_data_state ;
            end

            default: ns = IDLE;

        endcase
    end

    // -------------------------------------------------------------------------
    // Output logic (combinational)
    // NOTE: was_busy is now only READ here — never written
    // -------------------------------------------------------------------------
    always_comb begin : output_logic

        // Default output values (avoid latches)
        ahb.haddr  = address_top  ;
        ahb.hwdata = 'b0          ;
        ahb.hwrite = 1'b0         ;
        ahb.hsize  = data_width_top;
        ahb.htrans = 2'b00        ;   // IDLE

        // hburst decode
        case ({wrap_en, beat_length})
            {1'b0, 5'd0}   : ahb.hburst = 3'b000 ;   // SINGLE
            {1'b0, 5'd1}   : ahb.hburst = 3'b001 ;   // INCR (undefined length)
            {1'b0, 5'd4}   : ahb.hburst = 3'b011 ;   // INCR4
            {1'b0, 5'd8}   : ahb.hburst = 3'b101 ;   // INCR8
            {1'b0, 5'd16}  : ahb.hburst = 3'b111 ;   // INCR16
            {1'b1, 5'd4}   : ahb.hburst = 3'b010 ;   // WRAP4
            {1'b1, 5'd8}   : ahb.hburst = 3'b100 ;   // WRAP8
            {1'b1, 5'd16}  : ahb.hburst = 3'b110 ;   // WRAP16
            default        : ahb.hburst = 3'b000 ;
        endcase

        case (cs)

            IDLE: begin
                ahb.haddr  = address_top  ;
                ahb.hwdata = 'b0          ;
                ahb.hwrite = 1'b0         ;
                ahb.htrans = 2'b00        ;   // IDLE
                ahb.hsize  = data_width_top;
            end

            write_address_state: begin
                ahb.haddr  = ahb.hready ? address_top : haddr_reg ;
                ahb.hwrite = 1'b1         ;
                ahb.htrans = 2'b10        ;   // NONSEQUENTIAL
                ahb.hsize  = data_width_top;
            end

            write_data_state: begin
                ahb.hwrite = 1'b1         ;
                ahb.hsize  = data_width_top;
                if(ns!= IDLE || ahb.hburst == 3'b000 ) begin   
                    if (ahb.hburst == 3'b000) begin                     // Single transfer
                        ahb.hwdata = data_top             ;
                        ahb.haddr  = ahb.hready ? address_top : haddr_reg ;
                        ahb.htrans = 2'b10                ;             // NONSEQUENTIAL
                    end
                    else begin                                      // Burst transfer
                        ahb.hwdata = w_mem[rd_ptr]        ;
                        ahb.haddr  = internal_address     ;
                        ahb.htrans = 2'b11                ;             // SEQUENTIAL
                    end
                end
                else begin
                        ahb.hwdata = 'b0             ;
                        ahb.haddr  = 'b0             ;
                        ahb.htrans = 'b0             ; 
                end

            end

            read_address_state: begin
                ahb.haddr  = ahb.hready ? address_top : haddr_reg ;
                ahb.hwrite = 1'b0                 ;
                ahb.htrans = 2'b10                ;           // NONSEQUENTIAL
                ahb.hsize  = data_width_top       ;
            end

            read_data_state: begin
                ahb.hwrite = 1'b0         ;
                ahb.hsize  = data_width_top;
                if (ahb.hburst == 3'b000) begin       // Single read
                    ahb.haddr  = address_top      ;
                    ahb.htrans = 2'b10            ;   // NONSEQUENTIAL
                end
                else begin                        // Burst read
                    ahb.haddr  = internal_address ;
                    ahb.htrans = 2'b11            ;   // SEQUENTIAL
                end
            end

            busy_state: begin
                ahb.haddr  = haddr_reg      ;
                ahb.hwdata = hwdata_reg     ;
                ahb.hwrite = hwrite_reg     ;
                ahb.hsize  = hsize_reg      ;
                ahb.htrans = 2'b01          ;   // BUSY
                ahb.hburst = hburst_reg     ;
            end

            default: begin
                ahb.haddr  = address_top    ;
                ahb.hwdata = 'b0            ;
                ahb.hwrite = 1'b0           ;
                ahb.hsize  = data_width_top ;
                ahb.htrans = 2'b00          ;
                ahb.hburst = 3'b000         ;
            end

        endcase
    end

endmodule