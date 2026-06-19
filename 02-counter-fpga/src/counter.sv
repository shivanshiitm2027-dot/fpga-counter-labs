`timescale 1ns / 1ps

module updown_counter(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       load,
    input  logic       up_down,
    input  logic       enable,
    input  logic [3:0] d_in,
    output logic [3:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'h0;
        end
        else if (load) begin
            count <= d_in;
        end
        else if (enable) begin
            if (up_down)
                count <= count + 1'b1;
            else
                count <= count - 1'b1;
        end
    end

endmodule