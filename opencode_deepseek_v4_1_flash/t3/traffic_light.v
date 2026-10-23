module traffic_light(
    input rst_n,
    input clk,
    input pass_request,
    output [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    parameter idle = 2'b00;
    parameter s1_red = 2'b01;
    parameter s2_yellow = 2'b10;
    parameter s3_green = 2'b11;

    reg [7:0] cnt;
    reg [1:0] state;
    reg p_red, p_yellow, p_green;

    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= idle;
            p_red <= 0;
            p_yellow <= 0;
            p_green <= 0;
        end else begin
            case (state)
                idle: begin
                    p_red <= 0;
                    p_yellow <= 0;
                    p_green <= 0;
                    state <= s1_red;
                end
                s1_red: begin
                    if (cnt == 1) begin
                        p_red <= 0;
                        p_yellow <= 0;
                        p_green <= 1;
                        state <= s3_green;
                    end else begin
                        p_red <= 1;
                        p_yellow <= 0;
                        p_green <= 0;
                        state <= s1_red;
                    end
                end
                s2_yellow: begin
                    if (cnt == 1) begin
                        p_red <= 1;
                        p_yellow <= 0;
                        p_green <= 0;
                        state <= s1_red;
                    end else begin
                        p_red <= 0;
                        p_yellow <= 1;
                        p_green <= 0;
                        state <= s2_yellow;
                    end
                end
                s3_green: begin
                    if (cnt == 1) begin
                        p_red <= 0;
                        p_yellow <= 1;
                        p_green <= 0;
                        state <= s2_yellow;
                    end else begin
                        p_red <= 0;
                        p_yellow <= 0;
                        p_green <= 1;
                        state <= s3_green;
                    end
                end
                default: begin
                    state <= idle;
                    p_red <= 0;
                    p_yellow <= 0;
                    p_green <= 0;
                end
            endcase
        end
    end

    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 10;
        end else if (pass_request && green && cnt > 10) begin
            cnt <= 10;
        end else if (!green && p_green) begin
            cnt <= 60;
        end else if (!yellow && p_yellow) begin
            cnt <= 5;
        end else if (!red && p_red) begin
            cnt <= 10;
        end else begin
            cnt <= cnt - 1;
        end
    end

    assign clock = cnt;

    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red <= 0;
            yellow <= 0;
            green <= 0;
        end else begin
            red <= p_red;
            yellow <= p_yellow;
            green <= p_green;
        end
    end

endmodule
