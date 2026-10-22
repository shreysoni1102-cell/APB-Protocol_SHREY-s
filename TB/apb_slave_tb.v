    module apb_slave_tb;


        // Inputs Signal's given to the APB slave
        reg PCLK, PRESETn;
        reg PSEL, PENABLE, PWRITE;
        reg [7:0] PADDR;
        reg [31:0] PWDATA;
	reg [3:0]  PSTRB;
        reg WAIT_ENABLE;

        // Outputs received from the APB slave
        wire [31:0] PRDATA;
        wire PREADY, PSLVERR;

        // Connect the testbench signals to our actual APB design
        apb_slave DUT (
            .PCLK(PCLK),
            .PRESETn(PRESETn),
            .PSEL(PSEL),
            .PENABLE(PENABLE),
            .PWRITE(PWRITE),
            .PADDR(PADDR),
            .PWDATA(PWDATA),
	    .PSTRB(PSTRB),
            .WAIT_ENABLE(WAIT_ENABLE),
            .PRDATA(PRDATA),
            .PREADY(PREADY),
            .PSLVERR(PSLVERR)
        );
        

        // Generate a clock that changes every 5 ns
        // One complete clock period is 10 ns.
        always #5 PCLK = ~PCLK;

        initial begin
        
            // Initialize the clock and all input signals
            PCLK = 0;
            PRESETn = 0;       // Assert reset (active-low reset)
            PSEL = 0;          // No APB transfer selected
            PENABLE = 0;       // Access phase is inactive
            PWRITE = 0;        // Select read operation
            PADDR = 0;         // Select register address 0x00
            PWDATA = 0;        // Initial write data is zero
            WAIT_ENABLE = 0;   // Disable wait states



// ====================== TEST 1: Check reset at startup ==================

            #2;	

            if (!PREADY && PRDATA == 0 && !PSLVERR)
                $display("PASS: Startup reset");
            // PASS if PREADY=0, PRDATA=0 and PSLVERR=0.
            
	
	    else
                $display("FAIL: Startup reset");
           
            // Release reset after two falling clock edges
            repeat (2) @(negedge PCLK);
            PRESETn = 1; 		// The APB slave can now operate



// ======================== TEST 2: Reset during active ACCES =======

	@(negedge PCLK);
	PSEL      = 1;
	PENABLE   = 0;          // SETUP phase
	PWRITE    = 1;          // Write operation
	PADDR     = 8'h00;
	PWDATA    = 32'h12345678;
	WAIT_ENABLE = 1;        // Enable wait states

	@(negedge PCLK);
	PENABLE = 1;            // ACCESS phase

	// Allow ACCESS to become active
	@(negedge PCLK);

	PRESETn = 0;		// Assert reset while ACCESS is active


	#1;
	if (!PREADY && PRDATA == 0 && !PSLVERR)
	    $display("PASS: Reset outputs");
	else
	    $display("FAIL: Reset outputs");

	// End the master-side transfer
	PSEL = 0;
	PENABLE = 0;
	PWRITE = 0;

	// Release reset
	repeat (2) @(negedge PCLK);
	PRESETn = 1;
	WAIT_ENABLE = 0;

// ================= TEST 3: Start a new write after reset =================

            @(negedge PCLK);
            PSEL = 1;             // Select the slave
            PENABLE = 0;          // SETUP phase
            PWRITE = 1;           // Write operation
            PADDR = 8'h0C;        // Valid register address
            PWDATA = 32'hAABBCCDD; // New data to write


           // Move from SETUP to ACCESS
            @(negedge PCLK);
            PENABLE = 1;

            @(posedge PCLK);		// Wait for a rising clock edge for the write
            
	    #1; 			// Allow nonblocking assignments to update

            // End the APB transfer
            @(negedge PCLK);
            PSEL = 0;
            PENABLE = 0;
            PWRITE = 1;		//=============================== AI YA THI ==================


// =========================== TEST-4 FOR READ,last we write at particular data =====================================================

	 // Assert reset while ACCESS is active
            @(negedge PCLK);
         // PRESETn = 0; 		// Reset the slave
            PSEL = 0;    		// Master ends the transfer
            PENABLE = 0; 		// Master leaves ACCESS phase


	 #1; 				// Allow reset outputs to settle

        // Check reset response outputs and master control signals
      	   if (!PREADY && PRDATA == 0 && !PSLVERR && !PSEL && !PENABLE)

               $display("PASS: Reset during ACCESS");

            else

               $display("FAIL: Reset during ACCESS");
  

	   @(negedge PCLK);
           PSEL = 1;             	// Salve select
           PENABLE = 0;          	// SETUP
           PWRITE = 0;           	// Read 
           PADDR = 8'h0C;        	// Valid register address
        // PWDATA = 32'hAABBCCDD;	// New data to write
      
 	// Move from SETUP to ACCESS
            @(negedge PCLK);
            PENABLE = 1;		// ACCESS

        // Wait for a rising clock edge for the write
            @(posedge PCLK);
            #1; 			// Allow nonblocking assignments to update
    
//===============================================================================================
	// Read address 0x00 after reset

	 @(negedge PCLK);
 	   PSEL = 1;
	   PENABLE = 0;             // SETUP
	   PWRITE = 0;              // READ
	   PADDR = 8'h00;

	 @(negedge PCLK);
	   PENABLE = 1;              // ACCESS

	// Wait until transfer completes

	while (PREADY !== 1'b1)
		@(posedge PCLK);
	#1;
	if (PRDATA === 32'b0)
	    $display("PASS: Register cleared by reset");
	else
	    $display("FAIL: Register not cleared. PRDATA=%h", PRDATA);

	@(negedge PCLK);
	PSEL = 0;
	PENABLE = 0;


          //  $display("Reset test completed");
	#1000;
            $finish; // Stop the simulation

        end

    endmodule
