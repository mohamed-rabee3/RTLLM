module synchronizer (
    input  wire        clk_a,
    input  wire        clk_b,
    input  wire        arstn,
    input  wire        brstn,
    input  wire [3:0]  data_in,
    input  wire        data_en,
    output reg  [3:0]  dataout
);

    // Data register in clock A domain
    reg [3:0] data_reg;
    // Enable data register in clock A domain
    reg       en_data_reg;

    // Synchronizer registers in clock B domain
    reg       en_clap_one;
    reg       en_clap_two;

    ///////////////////////////////////////////////////////////////////////////
    // Clock A domain: register data_in and data_en
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge clk_a or negedge arstn) begin
        if (!arstn) begin
            data_reg    <= 4'd0;
            en_data_reg <= 1'b0;
        end else begin
            data_reg    <= data_in;
            en_data_reg <= data_en;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // Clock B domain: double-synchronize the enable signal
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) begin
            en_clap_one <= 1'b0;
            en_clap_two <= 1'b0;
        end else begin
            en_clap_one <= en_data_reg;
            en_clap_two <= en_clap_one;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // Clock B domain: data output register (MUX-based update)
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) begin
            dataout <= 4'd0;
        end else begin
            if (en_clap_two) begin
                dataout <= data_reg;
            end
            // else dataout retains its previous value
        end
    end

endmodule