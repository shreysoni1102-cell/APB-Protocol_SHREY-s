 module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter WAIT_CYCLES = 0,
    parameter DEPTH       = 4
)(
    input             PCLK, PRESETn,

    // APB master control signals
    input             PSEL, PENABLE, PWRITE,

    // APB address and write data
    input  [ADDR_WIDTH-1:0] PADDR,
    input  [DATA_WIDTH-1:0] PWDATA,
    input  [DATA_WIDTH/8-1:0] PSTRB,

    // Project-specific wait control
    input             WAIT_ENABLE,

    // APB response signals
    output reg [DATA_WIDTH-1:0] PRDATA,
    output reg          PREADY,
    output reg       PSLVERR
);

    // FSM states
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg [1:0] state, next_state;

    reg [DATA_WIDTH-1:0] data_reg [0:DEPTH-1];    // Register bank: DEPTH registers, DATA_WIDTH bits each

    reg [7:0] wait_count;           // Wait-state counter

    integer i;
    integer j;

    reg address_valid;         // Check whether the address is aligned and within range

    // ALWAYS BLOCK 1:
    // FSM next-state logic + APB output logic
    always @(*) begin

        // Check whether the APB address is valid
        address_valid = (PADDR[1:0] == 2'b00) && (PADDR[7:2] < DEPTH);


        // Default values prevent unintended latches
        next_state = IDLE;
        PREADY     = 1'b0;
        PSLVERR    = 1'b0;
        PRDATA = {DATA_WIDTH{1'b0}};

        // FSM next-state logic
        case (state)

            IDLE: begin
                next_state = (PSEL) ? SETUP : IDLE;            
            end

            SETUP: begin
                next_state = !PSEL ? IDLE : PENABLE ? ACCESS : SETUP;
            end

            ACCESS: begin
                next_state = !PSEL ? IDLE : !PENABLE ? SETUP : ACCESS;
            end

            default: begin
                next_state = IDLE;
            end

        endcase

        // PREADY: completes immediately when wait is disabled,
        // or after the configured wait cycles when enabled.
        PREADY = PRESETn && PSEL && PENABLE &&
                 ((!WAIT_ENABLE) ||
                  (wait_count >= WAIT_CYCLES));

        // PSLVERR: asserted for an invalid address
        // when the APB access transfer is ready to complete.
        PSLVERR = PRESETn && PSEL && PENABLE &&
                  PREADY && !address_valid;

        // Read data
        if (PRESETn && PSEL && PENABLE && !PWRITE && address_valid) begin
            PRDATA = data_reg[PADDR[7:2]];
        end

    end


    // ALWAYS BLOCK 2:
    // FSM state update
    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;

    end


    // ALWAYS BLOCK 3:
    // Reset + wait counter + register write logic
        always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            wait_count <= 0;

            for (i = 0; i < DEPTH; i = i + 1)
                data_reg[i] <= {DATA_WIDTH{1'b0}};

        end
        else begin

            // Wait counter logic
            if (!PSEL || !PENABLE || !WAIT_ENABLE)
                wait_count <= 0;

            else if (wait_count < WAIT_CYCLES)
                wait_count <= wait_count + 1'b1;


           // Write data when the access transfer completes
		if (PSEL && PENABLE && PREADY &&
    			PWRITE && address_valid) begin

    	//		$display("WRITE HIT: addr=%h data=%h strobe=%b",PADDR, PWDATA, PSTRB);
	
		for (j = 0; j < DATA_WIDTH/8; j = j + 1) begin
        		if (PSTRB[j]) begin
            		data_reg[PADDR[ADDR_WIDTH-1:2]][j*8 +: 8]
                	<= PWDATA[j*8 +: 8];

         //   		$display("BYTE %0d: writing %h",j, PWDATA[j*8 +: 8]);
        	      end
    	       end
	end

           // Debug message
            $display(
                "mem: %p, addr: %0d, wdata: %0d, rdata: %h",
                data_reg, PADDR, PWDATA, PRDATA
            );

        end

    end

endmodule
