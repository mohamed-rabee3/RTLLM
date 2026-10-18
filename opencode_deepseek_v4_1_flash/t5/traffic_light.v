module traffic_light(
    input rst_n,
    input clk,
    input pass_request,
    output [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    parameter idle      = 2'd0,
              s1_red    = 2'd1,
              s2_yellow = 2'd2,
              s3_green  = 2'd3;

    reg [1:0] state, next_state;
    reg [7:0] cnt;
    reg p_red, p_yellow, p_green;

    // Combinational next state and next output logic
    always @(*) begin
        case (state)
            idle: begin
                next_state = s1_red;
                p_red      = 1'b1;
                p_yellow   = 1'b0;
                p_green    = 1'b0;
            end
            s1_red: begin
                next_state = (cnt == 0) ? s3_green : s1_red;
                p_red      = 1'b1;
                p_yellow   = 1'b0;
                p_green    = 1'b0;
            end
            s2_yellow: begin
                next_state = (cnt == 0) ? s1_red : s2_yellow;
                p_red      = 1'b0;
                p_yellow   = 1'b1;
                p_green    = 1'b0;
            end
            s3_green: begin
                next_state = (cnt == 0) ? s2_yellow : s3_green;
                p_red      = 1'b0;
                p_yellow   = 1'b0;
                p_green    = 1'b1;
            end
            default: begin
                next_state = idle;
                p_red      = 1'b0;
                p_yellow   = 1'b0;
                p_green    = 1'b0;
            end
        endcase
    end

    // State and output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= idle;
            red    <= 1'b0;
            yellow <= 1'b0;
            green  <= 1'b0;
        end else begin
            state  <= next_state;
            red    <= p_red;
            yellow <= p_yellow;
            green  <= p_green;
        end
    end

    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'd10;
        end else if (pass_request && green && (cnt > 8'd10)) begin
            cnt <= 8'd10;
        end else if (!green && p_green) begin
            cnt <= 8'd60;
        end else if (!yellow && p_yellow) begin
            cnt <= 8'd5;
        end else if (!red && p_red) begin
            cnt <= 8'd10;
        end else begin
            cnt <= cnt - 1'b1;
        end
    end

    assign clock = cnt;

endmodule
