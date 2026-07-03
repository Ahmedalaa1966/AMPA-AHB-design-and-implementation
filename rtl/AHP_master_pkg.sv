// =============================================================================
// ahb_master_pkg
//
// Package holding shared type definitions for the AHB master (and any other
// module that needs to reference its FSM states, e.g. a testbench or a
// scoreboard).
// =============================================================================

package ahb_master_pkg;

    // -------------------------------------------------------------------------
    // Master FSM state encoding
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        IDLE                = 3'b000 ,
        write_address_state = 3'b001 ,
        write_data_state    = 3'b010 ,
        read_address_state  = 3'b011 ,
        read_data_state     = 3'b100 ,
        busy_state          = 3'b101
    } state_t;

endpackage : ahb_master_pkg