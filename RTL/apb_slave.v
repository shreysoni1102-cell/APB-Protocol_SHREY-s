//Doing Read & Write in 1-reg of 32-bit



module apb_slave #(parameter WAIT_CYCLES = 2)(                   //For wait transfer, Pready ne wait karva mate
    input             PCLK, PRESETn,
    input             PSEL,PENABLE, PWRITE,     // APB control signals

    // APB address and write data
    input      [7:0]  PADDR,
    input      [31:0] PWDATA,

   input             WAIT_ENABLE,               // Project-specific wait control

    // APB response signals
    output reg [31:0] PRDATA,
    output wire       PREADY
);


    reg [31:0] data_reg;     // Single 32-bit register

    reg [7:0] wait_count;    // Wait-state counter


    wire address_valid;      // Only address 0x00 is valid

    assign address_valid = (PADDR == 8'h00);


    assign PREADY = (!WAIT_ENABLE) || (wait_count >= WAIT_CYCLES);     // Ready immediately or after the configured wait cycles


    // Read logic
    always @(*) begin
        PRDATA = 32'b0;

        if (PSEL && PENABLE && !PWRITE && address_valid) 
	begin
            PRDATA = data_reg;
        end
    end

    // Reset, wait counter, and write logic
    always @(posedge PCLK or negedge PRESETn) 
    begin
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


