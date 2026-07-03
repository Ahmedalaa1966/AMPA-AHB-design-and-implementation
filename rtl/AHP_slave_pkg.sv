// =============================================================================
// ahb_slave_pkg
//
// Package holding shared type definitions for the AHB slave (and any other
// module that needs to reference its FSM states, e.g. a testbench or a
// scoreboard).
// =============================================================================

package ahb_slave_pkg;

    // -------------------------------------------------------------------------
    // Slave FSM state encoding
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        IDLE        = 3'b000 ,
        WRITE_DATA  = 3'b001 ,           // data phase: perform write
        WRITE_WAIT  = 3'b010 ,           // slave not ready for write
        READ_DATA   = 3'b011 ,           // data phase: drive read data
        READ_WAIT   = 3'b100            // slave not ready for read
    } state_t;

endpackage : ahb_slave_pkg