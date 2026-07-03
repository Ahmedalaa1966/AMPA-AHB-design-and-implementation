// ahb_hrdata_mux
//
// Selects the read-data bus (hrdata) returned to the AHB master from one of
// four slaves, based on mux_select. This is the standard AHB "output mux"
// that sits between the slaves and the master on the read-data path.
// =============================================================================

module ahb_hrdata_mux #(
    parameter DATA_WIDTH = 32
) (
    input  logic [1:0]            mux_select,

    input  logic [DATA_WIDTH-1:0] hrdata_1,
    input  logic [DATA_WIDTH-1:0] hrdata_2,
    input  logic [DATA_WIDTH-1:0] hrdata_3,
    input  logic [DATA_WIDTH-1:0] hrdata_4,

    output logic [DATA_WIDTH-1:0] hrdata
);

    always_comb begin
        case (mux_select)
            2'b00   : hrdata = hrdata_1;
            2'b01   : hrdata = hrdata_2;
            2'b10   : hrdata = hrdata_3;
            2'b11   : hrdata = hrdata_4;
            default : hrdata = '0;
        endcase
    end

endmodule