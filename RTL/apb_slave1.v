//Doing Read & Write in 2-reg of 32-bit (Total 64-bit)



module apb_slave_1 #(parameter WAIT_CYCLES = 2)(             //For wait transfer, Pready ne wait karva mate for 2 cycle 
    input             PCLK, PRESETn,
    input             PSEL,PENABLE, PWRITE,     // APB control signals

// APB address and write data
    input      [7:0]  PADDR,
    input      [31:0] PWDATA,

    input             WAIT_ENABLE,               // Project-specific wait control

    // APB response signals
    output reg [31:0] PRDATA,
    output wire       PREADY,
    output wire       PSLVEER
);


    // Two 32-bit registers
    reg [31:0] reg0;
    reg [31:0] reg1;

    reg [7:0] wait_count;	 // Counter to generate wait states

    // Address decoding
    wire reg0_sel;
    wire reg1_sel;
    wire address_valid;

    assign reg0_sel = (PADDR == 8'h00);
    assign reg1_sel = (PADDR == 8'h04);

    assign address_valid = reg0_sel || reg1_sel;

    assign PSLVEER = PRESETn && PSEL && PENABLE && PREADY && ! address_valid;
 
    // Ready immediately when waiting is disabled.
    // Otherwise, ready after WAIT_CYCLES wait cycles.
    assign PREADY = (!WAIT_ENABLE) || (wait_count >= WAIT_CYCLES);

    // Read logic
    always @(*) begin
        PRDATA = 32'b0;

        if (PSEL && PENABLE && !PWRITE && address_valid) 
        begin
            case (PADDR)
                8'h00: PRDATA = reg0;
                8'h04: PRDATA = reg1;
                default: PRDATA = 32'b0;
            endcase
        end
    end

    // Reset, wait counter, and write logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) 
            begin
                reg0       <= 32'b0;
                reg1       <= 32'b0;
                wait_count <= 0;
            end
        else 
            begin

                // Reset counter outside the Access phase
                if (!PSEL || !PENABLE) 
                    begin
                        wait_count <= 0;
                    end

                // Count wait cycles during Access
                else if (WAIT_ENABLE && (wait_count < WAIT_CYCLES)) 
                    begin
                        wait_count <= wait_count + 1'b1;
                    end

                // Write to the selected register when ready
                if (PSEL && PENABLE && PWRITE && PREADY && address_valid) 
                    begin

                        case (PADDR)
                            8'h00: reg0 <= PWDATA;
                            8'h04: reg1 <= PWDATA;
                            default: ;
                        endcase

                    end
            end
    end

endmodule
