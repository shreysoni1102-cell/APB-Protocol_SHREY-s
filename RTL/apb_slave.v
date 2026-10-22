 module apb_slave #(parameter WAIT_CYCLES = 0, parameter DEPTH = 4)(
 
    input             PCLK, PRESETn,

    // APB master control signals
    input             PSEL, PENABLE, PWRITE,

    // APB address and write data
    input      [7:0]  PADDR,
    input      [31:0] PWDATA,
    input      [3:0] PSTRB,

    // Project-specific wait control
    input             WAIT_ENABLE,

    // APB response signals
    output reg [31:0] PRDATA,
    output wire       PREADY,
    output wire       PSLVERR
);

    // FSM states
    parameter IDLE   = 2'b00;
    parameter SETUP  = 2'b01;
    parameter ACCESS = 2'b10;

    reg [1:0] state, next_state;

    reg [31:0] data_reg [0:DEPTH-1];    // Register bank: DEPTH registers, 32 bits each

    reg [7:0] wait_count;           // Wait-state counter

    integer i;

    wire address_valid;         // Check whether the address is aligned and within range

    assign address_valid = (PADDR[1:0] == 2'b00) && (PADDR[7:2] < DEPTH);

//IDEAL SETUP, ACCESS, IDLE STATE
    // Next-state logic
    always @(*) begin
        case (state)

            IDLE:
                next_state = PSEL ?
                             (PENABLE ? ACCESS : SETUP) :
                             IDLE;

            SETUP:
                next_state = !PSEL ? IDLE :
                             (PENABLE ? ACCESS : SETUP);

            ACCESS:
                next_state = !PSEL ? IDLE :
                             (!PENABLE ? SETUP : ACCESS);

            default:
                next_state = IDLE;

        endcase
    end

    // Update FSM state
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // PREADY is asserted only during ACCESS,
    // when no wait is required or wait cycles are complete.
    assign PREADY = PRESETn && PSEL && PENABLE &&
                    ((!WAIT_ENABLE) ||                      //agar wait enable nahi hai to ready ho jao
                     (wait_count >= WAIT_CYCLES));          //agar wait enable hai to wait cycles complete hone ke baad ready ho jao

    // Report an error for an invalid address when ACCESS completes
    assign PSLVERR = PRESETn && PSEL && PENABLE &&
                     PREADY && !address_valid;

    // Read logic
    always @(*) begin
        PRDATA = 32'b0;

        if (PSEL && PENABLE && !PWRITE && address_valid)
            PRDATA = data_reg[PADDR[7:2]];
    end

    // Reset, wait counter, and write logic
    always @(posedge PCLK or negedge PRESETn) begin

     //Reset the counter and every register
        if (!PRESETn) 
            begin
                wait_count <= 0;

                // Reset every register
                for (i = 0; i < DEPTH; i = i + 1)
                    data_reg[i] <= 32'b0;
            end
        else 
            begin
                // Clear wait counter outside ACCESS
                if (!PSEL || !PENABLE || !WAIT_ENABLE)
                    wait_count <= 0;

                // Count wait cycles during ACCESS
                else if (wait_count < WAIT_CYCLES)
                    wait_count <= wait_count + 1'b1;

                // Write only when the transfer completes
                if (PSEL && PENABLE && PREADY && PWRITE && address_valid)
		begin
	    		if (PSTRB[0])
        		data_reg[PADDR[7:2]][7:0] <= PWDATA[7:0];

	    		if (PSTRB[1])
        		data_reg[PADDR[7:2]][15:8] <= PWDATA[15:8];

    			if (PSTRB[2])
        		data_reg[PADDR[7:2]][23:16] <= PWDATA[23:16];

    			if (PSTRB[3])
        		data_reg[PADDR[7:2]][31:24] <= PWDATA[31:24];

		end

                //    data_reg[PADDR[7:2]] <= PWDATA;
                    $display("mem : %p , addr : %0d , wdata : %0d , rdata : %h",data_reg,PADDR,PWDATA,PRDATA);

            end
    end

endmodule

