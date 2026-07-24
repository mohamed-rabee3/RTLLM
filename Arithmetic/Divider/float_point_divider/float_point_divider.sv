`timescale 1ns / 1ps


module tb_Float_point_divider();

logic [31:0] dut_a;
logic [31:0] dut_b;
logic [31:0] dut_result;

int errors = 0;

fp_divider dut(
    .a(dut_a),
    .b(dut_b),
    .result(dut_result)
);

function automatic logic [31:0] golden_divide
(
    input logic [31:0] a,
    input logic [31:0] b
);

logic sign_a, sign_b, sign_r;
logic [7:0] exp_a, exp_b, exp_r;
logic [23:0] man_a, man_b;
logic [47:0] man_div;
logic [22:0] mantissa;

logic a_zero, b_zero;
logic a_inf, b_inf;
logic a_nan, b_nan;

sign_a = a[31];
sign_b = b[31];

exp_a = a[30:23];
exp_b = b[30:23];

man_a = {1'b1, a[22:0]};
man_b = {1'b1, b[22:0]};

a_zero = (exp_a==0 && a[22:0]==0);
b_zero = (exp_b==0 && b[22:0]==0);

a_inf = (exp_a==255 && a[22:0]==0);
b_inf = (exp_b==255 && b[22:0]==0);

a_nan = (exp_a==255 && a[22:0]!=0);
b_nan = (exp_b==255 && b[22:0]!=0);

///////////////////////////////////////
//    Special cases
///////////////////////////////////////

if(a_nan || b_nan)
    return 32'h7FC00000; // NaN

if(a_inf && b_inf)
    return 32'h7FC00000;

if(a_inf)
    return {sign_a^sign_b,8'hFF,23'b0};

if(b_inf)
    return {sign_a^sign_b,8'h00,23'b0};

if(b_zero)
    return {sign_a^sign_b,8'hFF,23'b0};

if(a_zero)
    return 32'h00000000;

///////////////////////////////////////
//     Normal division
///////////////////////////////////////-

sign_r = sign_a ^ sign_b;

exp_r = exp_a - exp_b + 127;

man_div = (man_a << 23) / man_b;

///////////////////////////////////////
//           Normalization
///////////////////////////////////////

if(man_div[47]) begin
    mantissa = man_div[46:24];
    exp_r = exp_r + 1;
end
else begin
    mantissa = man_div[45:23];
end

return {sign_r,exp_r,mantissa};

endfunction

task check_result(input logic [31:0] a,
                  input logic [31:0] b);

logic [31:0] expected;

dut_a = a;
dut_b = b;

#1;

expected = golden_divide(a,b);

if(dut_result !== expected)
begin
    $display("ERROR:");
    $display("A=%h B=%h",a,b);
    $display("DUT=%h EXPECTED=%h",dut_result,expected);
    errors++;
end

endtask

initial begin

    // Directed tests
    check_result(32'h41200000,32'h40000000); // 10 / 2
    check_result(32'h3F800000,32'h00000000); // divide by zero
    check_result(32'h7F800000,32'h3F800000); // inf / 1
    check_result(32'h00000000,32'h3F800000); // 0 / 1

    // Random tests
    repeat(10)
        check_result($random, $random);

    $display("Errors = %0d",errors);

    if(errors==0)
        $display("TEST PASSED");
    else
        $display("TEST FAILED");

    $finish;

end

endmodule
