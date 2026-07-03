import ahb_slave_pkg::*;
module ahb_slave_2 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 256,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR = 32'h0000_0400
)(
    ahb_if.slave ahb   ,

    // user inputs to the slave 
    input logic i_wait
);
    
    // State register declaration 
    state_t cs, ns;
    
    
    // Address-phase latch registers
    logic [ADDR_WIDTH-1:0]  addr_lat   ;
    logic                   hwrite_lat ;
    logic [2:0]             hsize_lat  ;
    logic [2:0]             hburst_lat ;
    logic [1:0]             htrans_lat ;

    // Memory
    logic [DATA_WIDTH-1:0]  mem [0:MEM_DEPTH-1];

    // Active transfer: NONSEQ or SEQ, slave selected
    logic active_transfer;
    assign active_transfer = ahb.hsel && (ahb.htrans == 2'b10 || ahb.htrans == 2'b11);

    // -------------------------------------------------------------------------
    // State register
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : state_reg
        if (!ahb.hreset_n)
            cs <= IDLE;
        else
            cs <= ns;
    end


    // -------------------------------------------------------------------------
    // Address-phase latch
    // Latch on every active transfer when hready=1 (bus is free to advance)
    // -------------------------------------------------------------------------
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : addr_latch
        if (!ahb.hreset_n) begin
            addr_lat   <= '0     ;
            hwrite_lat <= 1'b0   ;
            hsize_lat  <= 3'b000 ;
            hburst_lat <= 3'b000 ;
            htrans_lat <= 2'b00  ;
        end
        else if (active_transfer && ahb.hready) begin
            addr_lat   <= (ahb.haddr - BASE_ADDR) >> $clog2(DATA_WIDTH/8) ;
            hwrite_lat <= ahb.hwrite ;
            hsize_lat  <= ahb.hsize  ;
            hburst_lat <= ahb.hburst ;
            htrans_lat <= ahb.htrans ;
        end
    end

    // -------------------------------------------------------------------------
    // Next-state logic
    // -------------------------------------------------------------------------
    always_comb begin : ns_logic
        case (cs)

            IDLE: begin
                if (active_transfer && ahb.hwrite)
                    ns = i_wait ? WRITE_WAIT : WRITE_DATA;
                else if (active_transfer && !ahb.hwrite)
                    ns = i_wait ? READ_WAIT : READ_DATA;
                else
                    ns = IDLE;
            end

            WRITE_DATA: begin
                if (ahb.htrans == 2'b01 )
                    ns = WRITE_WAIT ;
                else if (active_transfer && ahb.hwrite)
                    ns = i_wait ? WRITE_WAIT : WRITE_DATA ;   // back-to-back write
                else if (active_transfer && !ahb.hwrite)
                    ns = i_wait ? READ_WAIT  : READ_DATA  ;    // write → read switch
                else 
                    ns = IDLE;
            end

            WRITE_WAIT: begin
                if (i_wait || ahb.htrans==2'b01 )
                    ns = WRITE_WAIT;
                else
                    ns = WRITE_DATA;
            end

            READ_DATA: begin
                 if (ahb.htrans == 2'b01 )
                    ns = READ_WAIT ;
                else if (active_transfer && !ahb.hwrite)
                    ns = i_wait ? READ_WAIT  : READ_DATA;    // back-to-back read
                else if (active_transfer && ahb.hwrite)
                    ns = i_wait ? WRITE_WAIT : WRITE_DATA;   // read → write switch
                else
                    ns = IDLE;
            end

            READ_WAIT: begin
                if (i_wait || ahb.htrans == 2'b01)
                    ns = READ_WAIT;
                else
                    ns = READ_DATA;
            end

            default: ns = IDLE;

        endcase
    end

   
    // Memory write (data phase)
    // Uses addr_lat — address captured in the PREVIOUS cycle's address phase
    
    always_ff @(posedge ahb.hclk or negedge ahb.hreset_n) begin : mem_write
        if (!ahb.hreset_n) begin
            for (int k = 0; k < MEM_DEPTH; k++)
                mem[k] <= '0;
        end
        else if (cs == WRITE_DATA && hwrite_lat && ns!= IDLE) begin
            mem[addr_lat] <= ahb.hwdata;
        end
    end

   
    // Output logic
    always_comb begin : output_logic

        ahb.hready = 1'b1;
        ahb.hresp  = 1'b0;
        ahb.hrdata = '0  ;

        case (cs)

            IDLE: begin
                ahb.hready = 1'b1;
                ahb.hresp  = 1'b0;
                ahb.hrdata = '0;
            end

            WRITE_DATA: begin
                ahb.hready = 1'b1;
                ahb.hresp  = 1'b0;
                ahb.hrdata = '0;
            end

            WRITE_WAIT: begin
                ahb.hready = 1'b0;              // stall master
                ahb.hresp  = 1'b0;
                ahb.hrdata = '0;
            end

            READ_DATA: begin
                ahb.hready = (active_transfer) ? 1'b1 : 1'b0 ;
                ahb.hresp  = 1'b0                            ;
                ahb.hrdata = mem[addr_lat]                   ;    // drive data using latched address
            end

            READ_WAIT: begin
                ahb.hready = 1'b0 ;                               // stall master while fetching
                ahb.hresp  = 1'b0 ;
                ahb.hrdata = '0   ;
            end

            default: begin
                ahb.hready = 1'b1 ;
                ahb.hresp  = 1'b0 ;
                ahb.hrdata = '0   ;
            end

        endcase
    end

endmodule