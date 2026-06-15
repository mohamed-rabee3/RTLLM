module traffic_light (
    input               rst_n,
    input               clk,
    input               pass_request,
    output      [7:0]   clock,
    output reg          red,
    output reg          yellow,
    output reg          green
);

    // ------------- Parameters (state encodings) -------------
    parameter   idle      = 2'b00,
                s1_red    = 2'b01,
                s2_yellow = 2'b10,
                s3_green  = 2'b11;

    // ------------- Internal registers and wires -------------
    reg [7:0] cnt;              // 8-bit internal counter
    reg [1:0] state;            // current state
    reg [1:0] next_state;       // next state (combinational)
    reg       p_red, p_yellow, p_green; // next values for the light outputs

    // ------------- Combinational next-state logic -------------
    always @(*) begin
        case (state)
            idle:      next_state = s1_red;
            s1_red:    if (cnt == 8'd1) next_state = s3_green; else next_state = s1_red;
            s2_yellow: if (cnt == 8'd1) next_state = s1_red;   else next_state = s2_yellow;
            s3_green:  if (cnt == 8'd1) next_state = s2_yellow; else next_state = s3_green;
            default:   next_state = idle;
        endcase
    end

    // ------------- Sequential state register -------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= idle;
        else
            state <= next_state;
    end

    // ------------- Next light outputs (combinational) -------------
    always @(*) begin
        p_red    = (next_state == s1_red);
        p_yellow = (next_state == s2_yellow);
        p_green  = (next_state == s3_green);
    end

    // ------------- Output register -------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red    <= 1'b0;
            yellow <= 1'b0;
            green  <= 1'b0;
        end else begin
            red    <= p_red;
            yellow <= p_yellow;
            green  <= p_green;
        end
    end

    // ------------- Counter logic -------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'd10;
        end else begin
            if (pass_request && green && (cnt > 8'd10))
                cnt <= 8'd10;
            else if (!green && p_green)
                cnt <= 8'd60;
            else if (!yellow && p_yellow)
                cnt <= 8'd5;
            else if (!red && p_red)
                cnt <= 8'd10;
            else
                cnt <= cnt - 1'b1;
        end
    end

    // ------------- Output assignments -------------
    assign clock = cnt;

endmodule