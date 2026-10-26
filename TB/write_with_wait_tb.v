
// `timescale 1ns/1ps

module write_with_wait_tb;

    //==================================================
    // PARAMETERS
    //==================================================
    parameter WAIT_CYCLES = 2;
    parameter DEPTH = 4;

    //==================================================
    // INPUT SIGNALS: DRIVEN BY TESTBENCH
    //==================================================
    reg PCLK, PRESETn;
    reg PSEL, PENABLE, PWRITE;
    reg [7:0] PADDR;
    reg [31:0] PWDATA;
    reg [3:0] PSTRB;
    reg WAIT_ENABLE;

    //==================================================
    // OUTPUT SIGNALS: FROM DUT
    //==================================================
    wire [31:0] PRDATA;
    wire PREADY;
    wire PSLVERR;

    integer errors;

    //==================================================
    // DUT INSTANTIATION
    // Uses your corrected APB slave design.
    //==================================================
    apb_slave #(
    .ADDR_WIDTH(8),
    .DATA_WIDTH(32),
    .WAIT_CYCLES(WAIT_CYCLES),
    .DEPTH(4)
    ) DUT (
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

    //==================================================
    // CLOCK GENERATOR
    //==================================================
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    //==================================================
    // FUNCTION 1: ADDRESS VALIDATION
    // Checks alignment and register-bank range.
    //==================================================
    function address_is_valid;
        input [7:0] address;
        begin
            address_is_valid =
                (address[1:0] == 2'b00) &&
                (address[7:2] < DEPTH);
        end
    endfunction

    //==================================================
    // FUNCTION 2: EXPECTED DATA AFTER BYTE WRITE
    // Calculates the result without changing DUT memory.
    //==================================================
    function [31:0] merge_bytes;
        input [31:0] old_data;
        input [31:0] new_data;
        input [3:0] strobe;
        integer b;
        begin
            merge_bytes = old_data;
            for (b = 0; b < 4; b = b + 1) begin
                if (strobe[b])
                    merge_bytes[b*8 +: 8] =
                        new_data[b*8 +: 8];
            end
        end
    endfunction

    //==================================================
    // TASK 1: COMMON CHECKER
    //==================================================
    task check;
        input condition;
        input [8*100-1:0] message;
        begin
            if (condition === 1'b1)
                $display("[PASS] %0s", message);
            else begin
                $display("[FAIL] %0s", message);
                errors = errors + 1;
            end
        end
    endtask

    //==================================================
    // TASK 2: RESET
    //==================================================
    task apply_reset;
        begin
            @(negedge PCLK);
            PRESETn = 0;
            PSEL = 0;
            PENABLE = 0;
            PWRITE = 0;
            PADDR = 0;
            PWDATA = 0;
            PSTRB = 0;
            WAIT_ENABLE = 0;

            repeat (2) @(negedge PCLK);
            #1;

            check(PREADY === 0, "PREADY low during reset");
            check(PSLVERR === 0, "PSLVERR low during reset");

            PRESETn = 1;
            @(negedge PCLK);
        end
    endtask

    //==================================================
    // TASK 3: DRIVE APB SETUP PHASE
    //==================================================
    task start_setup;
        input write_mode;
        input [7:0] address;
        input [31:0] write_data;
        input [3:0] strobe;
        begin
            @(negedge PCLK);
            PSEL = 1;
            PENABLE = 0;
            PWRITE = write_mode;
            PADDR = address;
            PWDATA = write_data;
            PSTRB = strobe;
        end
    endtask

    //==================================================
    // TASK 4: PERFORM AN APB TRANSFER
    // Supports reads/writes, waits, and invalid addresses.
    //==================================================
    task transfer;
        input write_mode;
        input [7:0] address;
        input [31:0] write_data;
        input [3:0] strobe;
        input use_wait;
        input expect_error;

        integer timeout;
        reg finished;
        begin
            WAIT_ENABLE = use_wait;

            start_setup(write_mode, address, write_data, strobe);

            // Move from SETUP to ACCESS.
            @(negedge PCLK);
            PENABLE = 1;

            timeout = 0;
            finished = 0;

            // Wait for PREADY, allowing a bounded timeout.
            while (!finished && timeout < WAIT_CYCLES + 10) begin
                @(posedge PCLK);

// this one last chnage                //#1;

                if (PREADY === 1'b1) begin
                    finished = 1;

                    if (expect_error)
                        check(PSLVERR === 1'b1,
                              "Invalid address raises PSLVERR");
                    else
                        check(PSLVERR === 1'b0,
                              "Valid address has no PSLVERR");
                end
                else begin
                    timeout = timeout + 1;
                end
            end

            check(finished, "Transfer completes before timeout");

            // Release bus after ACCESS completes.
            @(negedge PCLK);
            PSEL = 0;
            PENABLE = 0;
            PSTRB = 0;
            WAIT_ENABLE = 0;
        end
    endtask

    //==================================================
    // TASK 5: READ AND COMPARE DATA
    //==================================================
    task read_check;
        input [7:0] address;
        input [31:0] expected_data;
        input use_wait;

        integer timeout;
        reg finished;
        reg [31:0] actual_data;
        begin
            WAIT_ENABLE = use_wait;

            start_setup(0, address, 0, 4'b0000);

            @(negedge PCLK);
            PENABLE = 1;

            timeout = 0;
            finished = 0;
            actual_data = 0;

            while (!finished && timeout < WAIT_CYCLES + 10) begin
                @(posedge PCLK);

// this one last chnage                //#1;

                if (PREADY === 1'b1) begin
                    finished = 1;
                    actual_data = PRDATA;
                end
                else begin
                    timeout = timeout + 1;
                end
            end

            check(finished, "Read transfer completes");

            if (finished)
                check(actual_data === expected_data,
                      "Read data matches expected value");

            @(negedge PCLK);
            PSEL = 0;
            PENABLE = 0;
            WAIT_ENABLE = 0;
        end
    endtask

 // TEST: write_with_wait
    task write_with_wait;
        begin
            $display("\n--- write_with_wait ---");
            transfer(1, 8'h00, 32'h55AA55AA,
                     4'b1111, 1, 0);
            read_check(8'h00, 32'h55AA55AA, 0);
        end
    endtask
/*
- The transfer can remain in ACCESS while PREADY is low.
- The write completes when the slave indicates readiness.
- The correct data is stored despite the delay.
*/

    //==================================================
    // MAIN TEST SEQUENCE
    //==================================================
    initial begin
        errors = 0;

        PRESETn = 0;
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 0;
        PWDATA = 0;
        PSTRB = 0;
        WAIT_ENABLE = 0;

        apply_reset();

        write_with_wait();
        
        $display("\n==================================");
        $display("APB TESTBENCH COMPLETED");
        $display("Total check failures = %0d", errors);
        $display("==================================");

        if (errors == 0)
            $display("RESULT: ALL CHECKS PASSED");
        else
            $display("RESULT: SOME CHECKS FAILED");

        $finish;
  
end

endmodule
