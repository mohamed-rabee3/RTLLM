module traffic_light(
    input rst_n,
    input clk,
    input pass_request,
    output [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    parameter idle      = 2'b00;
    parameter s1_red    = 2'b01;
    parameter s2_yellow = 2'b10;
    parameter s3_green  = 2'b11;

    reg [7:0] cnt;
    reg [1:0] state;
    reg p_red;
    reg p_yellow;
    reg p_green;

    assign clock = cnt;

    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= idle;
        end else begin
            case (state)
                idle: begin
                    state <= s1_red;
                end
                s1_red: begin
                    if (cnt == 8'd0)
                        state <= s3_green;
                    else
                        state <= s1_red;
                end
                s2_yellow: begin
                    if (cnt == 8'd0)
                        state <= s1_red;
                    else
                        state <= s2_yellow;
                end
                s3_green: begin
                    if (cnt == 8'd0)
                        state <= s2_yellow;
                    else
                        state <= s3_green;
                end
                default: begin
                    state <= idle;
                end
            endcase
        end
    end

    // Internal counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 8'd10;
        else if (pass_request && green)
            cnt <= 8'd10;
        else if (!green && p_green)
            cnt <= 8'd60;
        else if (!yellow && p_yellow)
            cnt <= 8'd5;
        else if (!red && p_red)
            cnt <= 8'd10;
        else
            cnt <= cnt - 8'd1;
    end

    // Next-state light value registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_red    <= 1'b0;
            p_yellow <= 1'b0;
            p_green  <= 1'b0;
        end else begin
            p_red    <= (state == s1_red)    ? 1'b1 : 1'b0;
            p_yellow <= (state == s2_yellow) ? 1'b1 : 1'b0;
            p_green  <= (state == s3_green)  ? 1'b1 : 1'b0;
        end
    end

    // Output light registers
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

endmodule
