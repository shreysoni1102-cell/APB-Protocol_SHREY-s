//============================================================
// DESIGN 1 : SIMPLE APB SLAVE
//  - 4 registers (32 bit), address = PADDR[3:2]
//  - PREADY is always 1  (zero wait state, "right now" ready)
//  - full 32-bit write, no strobe, no error
//============================================================
module apb_slave_simple (                         // Defines the simple four-register APB slave.
    input             PCLK,                       // 1-bit clock input.
    input             PRESETn,                    // 1-bit active-low reset input.
    input             PSEL,                       // 1-bit slave-select input from the APB master.
    input             PENABLE,                    // 1-bit signal that marks the APB access phase.
    input             PWRITE,                     // 1-bit direction: 1 means write, 0 means read.
    input      [7:0]  PADDR,                      // 8-bit byte address input.
    input      [31:0] PWDATA,                     // 32-bit write-data input.
    output     [31:0] PRDATA,                     // 32-bit read-data output.
    output            PREADY                      // 1-bit ready output; always 1 in this design.
);                                                  // Ends the module's port list.
    reg [31:0] mem [0:3];                         // Four 32-bit storage words; indexes 0 through 3.
    integer i;                                      // Integer loop counter used to reset the four words.

    assign PREADY = 1'b1;                         // Tell the master that this slave is always ready.
    assign PRDATA = mem[PADDR[3:2]];              // Select a word using address bits 3 and 2.

    always @(posedge PCLK or negedge PRESETn) begin // Run on clock rising edge or reset falling edge.
        if (!PRESETn) begin                         // If reset is active (low)...
            for (i = 0; i < 4; i = i + 1) begin    // Loop over all four memory entries...
                mem[i] <= 32'd0;                    // ...and clear each 32-bit entry.
            end                                     // End the reset loop.
        end else if (PSEL && PENABLE && PWRITE) begin // Otherwise, accept an access-phase write.
            mem[PADDR[3:2]] <= PWDATA;              // Store the 32-bit data in the addressed word.
        end                                         // End the reset/write decision.
    end                                             // End the clocked process.
endmodule                                           // End the simple slave module.






//============================================================
// DESIGN 1.3: ONE 32-BIT REGISTER WITHOUT PSLVERR
// Address 0x00 selects the register; invalid accesses return zero and do not write.
//============================================================
module apb_slave_simple_no_error (                     // Declares a one-register design without an error output.
    input             PCLK,                             // 1-bit clock input.
    input             PRESETn,                          // 1-bit active-low reset input.
    input             PSEL,                             // 1-bit signal selecting this slave.
    input             PENABLE,                          // 1-bit signal marking the APB access phase.
    input             PWRITE,                           // 1-bit direction: 1 means write, 0 means read.
    input      [7:0]  PADDR,                            // 8-bit byte address input.
    input      [31:0] PWDATA,                           // 32-bit write-data input.
    output     [31:0] PRDATA,                           // 32-bit read-data output.
    output            PREADY                            // 1-bit ready output; always 1 in this design.
);                                                       // Ends the module port list.
    reg [31:0] data_reg;                                 // The design's only storage register; it is 32 bits wide.
    
    wire address_valid;                                  // 1-bit signal that is 1 only for address 0x00.

    assign address_valid = (PADDR == 8'h00);             // Only address 0x00 selects this register.
    
    assign PREADY = 1'b1;                                // This slave completes transfers without wait states.

//  assign PREADY = ready_reg;              //(no-wait state)   it is also possible to use a register to hold the ready signal, but this design is always ready.

    // Return data only for an APB read access to address 0x00 otherwise return zero.
    assign PRDATA = (PSEL && PENABLE && !PWRITE && address_valid) ? data_reg : 32'b0;

    always @(posedge PCLK or negedge PRESETn)       // Run on rising clock edge or falling reset edge.
    begin
        if (!PRESETn) begin                              // If active-low reset is asserted clear the single 32-bit register
            data_reg <= 32'b0;.
        end 
        else if (PSEL && PENABLE && PWRITE &&        // Otherwise, accept a selected write in the access phase only when address 0x00 is selected.
                     address_valid) begin
            data_reg <= PWDATA;                          // Store the full 32-bit write-data value.
        end                                              // End the reset/write decision.
    end                                                  // End the sequential process.
endmodule                                                // End Design 1.3.



//============================================================
// DESIGN 1.1: FOUR REGISTERS WITH PSLVERR
// PADDR is 8 bits, PWDATA and PRDATA are 32 bits, and each register is 32 bits.
// Only addresses 0x00, 0x04, 0x08, and 0x0C are accepted.
//============================================================
module apb_slave_simple_error (                         // Declares a new APB slave module.
    input             PCLK,                             // 1-bit clock; sequential logic uses its rising edge.
    input             PRESETn,                          // 1-bit active-low reset; 0 resets the registers.
    input             PSEL,                             // 1-bit signal; 1 selects this slave.
    input             PENABLE,                          // 1-bit signal; 1 marks the APB access phase.
    input             PWRITE,                           // 1-bit direction; 1 writes and 0 reads.
    input      [7:0]  PADDR,                            // 8-bit byte address from the APB master.
    input      [31:0] PWDATA,                           // 32-bit data from the master during writes.
    output     [31:0] PRDATA,                           // 32-bit data returned to the master during reads.
    output            PREADY,                           // 1-bit ready response; this design is always ready.
    output            PSLVERR                            // 1-bit error response; 1 means an invalid access.
);                                                       // Ends the port list.
    reg [31:0] mem [0:3];                               // Four entries, each 32 bits wide: 4 x 32-bit storage.
    integer i;                                           // Integer loop variable used to reset all four entries.
    wire address_valid;                                  // 1-bit wire indicating whether PADDR is supported.

    assign address_valid =                              // Continuously calculate whether the address is valid.
        (PADDR[7:4] == 4'b0000) &&                       // Require the upper four address bits to be zero.
        (PADDR[1:0] == 2'b00);                           // Require word alignment; addresses end in two zero bits.
    assign PREADY = 1'b1;                                // Tell the master every access can finish immediately.
    assign PSLVERR = (PSEL && PENABLE && !address_valid);// Report an error only for an invalid APB access.
    assign PRDATA = (PSEL && PENABLE && !PWRITE &&       // Return data only during a selected read access...
                     address_valid) ?                   // ...and only when its address is supported...
                     mem[PADDR[3:2]] : 32'b0;            // ...otherwise return zero; bits [3:2] select entry 0-3.

    always @(posedge PCLK or negedge PRESETn) begin      // Run on the rising clock edge or falling reset edge.
        if (!PRESETn) begin                              // If active-low reset is asserted...
            for (i = 0; i < 4; i = i + 1) begin         // Visit all four memory entries...
                mem[i] <= 32'b0;                         // ...and clear each 32-bit register.
            end                                          // Finish the reset loop.
        end else if (PSEL && PENABLE && PWRITE &&        // Otherwise, during an APB write access...
                     address_valid) begin               // ...write only when the address is supported.
            mem[PADDR[3:2]] <= PWDATA;                   // Store all 32 write-data bits in the selected register.
        end                                              // Finish the reset/write decision.
    end                                                  // Finish the clocked process.
endmodule                                                // Finish Design 1.1.






//============================================================
// DESIGN 1.2: ONE 32-BIT REGISTER WITH PSLVERR
// Only address 0x00 is accepted; all other addresses report an error.
//============================================================
module apb_slave_one_register (                          // Declares a separate one-register APB slave.
    input             PCLK,                             // 1-bit clock; sequential logic uses its rising edge.
    input             PRESETn,                          // 1-bit active-low reset; 0 resets the register.
    input             PSEL,                             // 1-bit signal; 1 selects this slave.
    input             PENABLE,                          // 1-bit signal; 1 marks the APB access phase.
    input             PWRITE,                           // 1-bit direction; 1 writes and 0 reads.
    input      [7:0]  PADDR,                            // 8-bit byte address from the APB master.
    input      [31:0] PWDATA,                           // 32-bit data from the master during writes.
    output     [31:0] PRDATA,                           // 32-bit data returned to the master during reads.
    output            PREADY,                           // 1-bit ready response; this design is always ready.
    output            PSLVERR                            // 1-bit error response; 1 means an invalid access.
);                                                       // Ends the port list.
    reg [31:0] data_reg;                                 // One storage register, exactly 32 bits wide.
    wire address_valid;                                  // 1-bit wire indicating whether address 0x00 was selected.

    assign address_valid = (PADDR == 8'h00);             // Address 0x00 selects this register; other addresses are invalid.
    assign PREADY = 1'b1;                                // Tell the master every access can finish immediately.
    assign PSLVERR = (PSEL && PENABLE && !address_valid);// Report an error only for an invalid APB access.
    assign PRDATA = (PSEL && PENABLE && !PWRITE &&       // Return data only during a selected read access...
                     address_valid) ?                   // ...and only when address 0x00 is selected...
                     data_reg : 32'b0;                   // ...otherwise return zero.

    always @(posedge PCLK or negedge PRESETn) begin      // Run on the rising clock edge or falling reset edge.
        if (!PRESETn) begin                              // If active-low reset is asserted...
            data_reg <= 32'b0;                           // ...clear the one 32-bit register.
        end else if (PSEL && PENABLE && PWRITE &&        // Otherwise, during an APB write access...
                     address_valid) begin               // ...write only when address 0x00 is selected.
            data_reg <= PWDATA;                          // Store all 32 write-data bits in the register.
        end                                              // Finish the reset/write decision.
    end                                                  // Finish the clocked process.
endmodule                                                // Finish the one-register design.






/*
//============================================================
// DESIGN 2 : APB SLAVE with PSTRB + PREADY wait + PSLVERR
//  - PSTRB[n] = 1 -> byte n of the register is written
//  - WAIT = number of wait states (0 = ready immediately)
//  - PSLVERR = 1 if address is outside the 4 registers
//============================================================
module apb_slave_full #(parameter WAIT = 1) (    // Defines Design 2; WAIT sets the number of wait cycles.
    input             PCLK,                      // 1-bit clock input.
    input             PRESETn,                   // 1-bit active-low reset input.
    input             PSEL,                      // 1-bit slave-select input.
    input             PENABLE,                   // 1-bit APB access-phase input.
    input             PWRITE,                    // 1-bit direction: 1 means write, 0 means read.
    input      [7:0]  PADDR,                     // 8-bit byte address input.
    input      [3:0]  PSTRB,                     // 4 byte enables, one for each byte of PWDATA.
    input      [31:0] PWDATA,                    // 32-bit write-data input.
    output     [31:0] PRDATA,                    // 32-bit read-data output.
    output            PREADY,                    // 1-bit ready response from the slave.
    output            PSLVERR                    // 1-bit error response from the slave.
);                                                 // Ends the module's port list.
    reg [31:0] mem [0:3];                        // Four words of storage, each 32 bits wide.
    reg [2:0]  cnt;                              // 3-bit counter for counting wait cycles.
    integer i;                                     // Integer loop counter used during reset.

    wire access   = PSEL & PENABLE;              // True only when the slave is selected in the access phase.
    wire bad_addr = (PADDR[7:2] > 6'd3);         // True when the word address is outside entries 0 through 3.

    // Ready is asserted in access after the selected number of wait cycles.
    assign PREADY  = access & (cnt == WAIT);     // PREADY is 1 only during access when cnt equals WAIT.
    // Error is reported when the transfer is ready to finish and the address is invalid.
    assign PSLVERR = PREADY & bad_addr;          // PSLVERR is 1 for a ready transfer to an invalid address.
    // Return selected memory data only for a valid read; otherwise return zero.
    assign PRDATA  = (PREADY & ~PWRITE & ~bad_addr) ? mem[PADDR[3:2]] : 32'd0; // Conditional read-data output.

    // Count wait cycles while a transfer is selected and not yet ready.
    always @(posedge PCLK or negedge PRESETn) begin // Update the wait counter on clock or reset.
        if (!PRESETn)                 cnt <= 0;      // Reset the counter to zero.
        else if (access && !PREADY)   cnt <= cnt + 1; // Count another cycle while the slave is not ready.
        else                          cnt <= 0;      // Clear the count outside the waiting period.
    end                                               // End the counter process.

    // Write only enabled bytes when a valid write transfer is ready to complete.
    always @(posedge PCLK or negedge PRESETn) begin // Update memory on clock or reset.
        if (!PRESETn) begin                         // If reset is active...
            for (i = 0; i < 4; i = i + 1) begin    // Visit all four entries...
                mem[i] <= 32'd0;                    // ...and clear each word.
            end                                     // End the reset loop.
        end else if (PREADY && PWRITE && !bad_addr) begin // Accept a ready, valid write.
            if (PSTRB[0]) mem[PADDR[3:2]][7:0]   <= PWDATA[7:0];   // Write byte 0 when strobe bit 0 is set.
            if (PSTRB[1]) mem[PADDR[3:2]][15:8]  <= PWDATA[15:8];  // Write byte 1 when strobe bit 1 is set.
            if (PSTRB[2]) mem[PADDR[3:2]][23:16] <= PWDATA[23:16]; // Write byte 2 when strobe bit 2 is set.
            if (PSTRB[3]) mem[PADDR[3:2]][31:24] <= PWDATA[31:24]; // Write byte 3 when strobe bit 3 is set.
        end                                         // End the reset/write decision.
    end                                             // End the memory process.
endmodule                                           // End Design 2.
*/      






//============================================================
// TESTBENCH (acts as the APB master)
//============================================================
`timescale 1ns/1ps                              // Set simulation time unit to 1 ns and precision to 1 ps.
module tb;                                       // Defines the testbench; it has no external ports.
    reg         PCLK = 0, PRESETn = 0;           // Testbench-driven 1-bit clock and active-low reset.
    reg         PSEL = 0, PENABLE = 0, PWRITE = 0; // Testbench-driven 1-bit APB control signals.
    reg  [7:0]  PADDR = 0;                       // Testbench-driven 8-bit address.
    reg  [3:0]  PSTRB = 0;                       // Testbench-driven 4-bit byte-enable input.
    reg  [31:0] PWDATA = 0;                      // Testbench-driven 32-bit write data.
    wire [31:0] PRDATA;                          // 32-bit read data observed from the slave.
    wire        PREADY, PSLVERR;                  // 1-bit ready and error responses observed from the slave.

    apb_slave_full #(.WAIT(1)) dut (.*);         // Instantiate Design 2 with one wait cycle; .* matches port names.

    always #5 PCLK = ~PCLK;                      // Toggle the clock every 5 ns for a 10 ns period.

    reg [31:0] rd;                                // Holds read data captured by the testbench.

    task apb_write(input [7:0] a, input [31:0] d, input [3:0] s); // Reusable task: address, data, and byte strobes.
    begin                                         // Start the write task body.
        @(posedge PCLK); #1;                      // Wait for a clock edge, then enter setup after 1 ns.
        PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = a; PWDATA = d; PSTRB = s; // Drive setup signals for a write.
        @(posedge PCLK); #1;                      // Wait through setup and move just after the next clock edge.
        PENABLE = 1;                              // Assert PENABLE to begin the access phase.
        @(posedge PCLK);                          // Wait for a clock edge in the access phase.
        while (!PREADY) @(posedge PCLK);          // Keep waiting at clock edges until the slave is ready.
        $display("%0t WRITE addr=%h data=%h strb=%b err=%b", $time, a, d, s, PSLVERR); // Print write result.
        #1; PSEL = 0; PENABLE = 0; PWRITE = 0; PSTRB = 0; // Return bus controls to idle after 1 ns.
    end                                           // End the write task body.
    end task                                       // End the reusable write task.

    task apb_read(input [7:0] a);                 // Reusable task: takes one 8-bit address to read.
    begin                                         // Start the read task body.
        @(posedge PCLK); #1;                      // Wait for a clock edge, then prepare setup signals.
        PSEL = 1; PENABLE = 0; PWRITE = 0; PADDR = a; PSTRB = 0; // Select a read and drive its address.
        @(posedge PCLK); #1;                      // Wait through setup and move just after the next clock edge.
        PENABLE = 1;                              // Assert PENABLE to begin the access phase.
        @(posedge PCLK);                          // Wait for a clock edge in the access phase.
        while (!PREADY) @(posedge PCLK);          // Keep waiting at clock edges until the slave is ready.
        rd = PRDATA;                              // Capture the slave's read-data output.
        $display("%0t READ  addr=%h data=%h err=%b", $time, a, rd, PSLVERR); // Print read result and error.
        #1; PSEL = 0; PENABLE = 0;                // Return select and enable to idle after 1 ns.
    end                                           // End the read task body.
    end task                                       // End the reusable read task.

    initial begin                                 // Start the test sequence once at simulation time zero.
        #22 PRESETn = 1;                           // Hold reset low initially, then release it at 22 ns.
        apb_write(8'h00, 32'hAABBCCDD, 4'b1111);  // Write all four bytes to register address 0x00.
        apb_read (8'h00);                         // Read address 0x00; expected data is AABBCCDD.
        apb_write(8'h00, 32'h11223344, 4'b0001);  // Replace only byte 0 at address 0x00.
        apb_read (8'h00);                         // Read address 0x00; expected data is AABBCC44.
        apb_write(8'h04, 32'h12345678, 4'b1100);  // Write only bytes 3 and 2 at address 0x04.
        apb_read (8'h04);                         // Read address 0x04; expected data is 12340000.
        apb_write(8'h40, 32'hDEADBEEF, 4'b1111);  // Try an invalid address; the slave should report an error.
        apb_read (8'h40);                         // Read an invalid address; the slave should report an error.
        #20 $finish;                               // Wait 20 ns, then stop the simulation.
    end                                           // End the initial test sequence.
endmodule                                         // End the testbench module.





// ===========================================================================================================


// ===========================================================================================================

module apb_slave_simple_no_error (
    input             PCLK,
    input             PRESETn,
    input             PSEL,
    input             PENABLE,
    input             PWRITE,
    input      [7:0]  PADDR, 
    input      [31:0] PWDATA,
    output     [31:0] PRDATA,
    output            PREADY
);
    reg [31:0] data_reg;
    
    wire address_valid;

    assign address_valid = (PADDR == 8'h00);    //AGAR ADDRES VALID HAI TOH HI DATA REG MEIN STORE HOGA
    
    assign PREADY = 1'b1;

//  assign PREADY = ready_reg;              //(no-wait state)   it is also possible to use a register to hold the ready signal, but this design is always ready.

    assign PRDATA = (PSEL && PENABLE && !PWRITE && address_valid) ? data_reg : 32'b0;

    always @(posedge PCLK or negedge PRESETn)
     begin
        if (!PRESETn) 
        begin
            data_reg <= 32'b0;
        end 
        else if (PSEL && PENABLE && PWRITE && address_valid) 
        begin
            data_reg <= PWDATA;
        end
    end
    endmodule










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



