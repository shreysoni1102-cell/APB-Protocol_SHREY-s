module apb_slave #(parameter WAIT_CYCLES = 2)(
    input             PCLK, PRESETn,

    // APB control signals
    input             PSEL, PENABLE, PWRITE,

    // APB address and write data
    input      [7:0]  PADDR,
    input      [31:0] PWDATA,

    // Project-specific wait control
    input             WAIT_ENABLE,

    // APB response signals
    output reg [31:0] PRDATA,
    output wire       PREADY,
    output wire       PSLVERR
);

    reg [31:0] data_reg;    // Single 32-bit register

    reg [7:0] wait_count;   // Wait-state counter

    // Only address 0x00 is valid
    wire address_valid;
    assign address_valid = (PADDR == 8'h00);

    // Ready immediately or after configured wait cycles
    assign PREADY = PRESETn && ((!WAIT_ENABLE) || (wait_count >= WAIT_CYCLES));

    // Error when an invalid-address transfer completes
    assign PSLVERR = PRESETn && PSEL && PENABLE && PREADY && !address_valid;

    // Read logic
    always @(*) begin
        PRDATA = 32'b0;

        if (PSEL && PENABLE && !PWRITE && address_valid) 
            begin
                PRDATA = data_reg;
            end
    end

    // Reset, wait counter, and write logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) 
            begin
                data_reg   <= 32'b0;
                wait_count <= 0;
            end
        else 
            begin

                // Reset the counter outside the Access phase
                if (!PSEL || !PENABLE)
                    begin
                        wait_count <= 0;
                    end

                // Count wait cycles during Access
                else if (WAIT_ENABLE && (wait_count < WAIT_CYCLES))
                    begin
                        wait_count <= wait_count + 1'b1;
                    end

                // Write data when the transfer completes
                if (PSEL && PENABLE && PWRITE && PREADY && address_valid) 
                    begin
                        data_reg <= PWDATA;
                    end
            end
    end

endmodule

