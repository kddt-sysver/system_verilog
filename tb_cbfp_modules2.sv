`timescale 1ns/1ps
`default_nettype none

module tb_cbfp_streaming_safe;
    // Parameters
    parameter int IN_W = 16;
    parameter int OUT_W = 13;
    parameter int SHIFT_W = 5;
    parameter int REF_SUM = 23;
    parameter int FINAL_REF = 9;
    
    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // Input signals (16 samples per cycle)
    logic valid_in;
    logic signed [IN_W-1:0] data_re_in [0:15];
    logic signed [IN_W-1:0] data_im_in [0:15];
    logic [SHIFT_W-1:0]     index1_re_in [0:15];
    logic [SHIFT_W-1:0]     index1_im_in [0:15];
    logic [SHIFT_W-1:0]     index2_re_in [0:15];
    logic [SHIFT_W-1:0]     index2_im_in [0:15];
    
    // Output signals (16 samples per cycle)
    logic signed [OUT_W-1:0] data_re_out [0:15];
    logic signed [OUT_W-1:0] data_im_out [0:15];
    logic valid_out;
    
    // Test variables
    int input_cycle;
    int output_cycle;
    int sample_idx;
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz clock
    
    // DUT instantiation
    cbfp_streaming_module #(
        .IN_W(IN_W),
        .OUT_W(OUT_W),
        .SHIFT_W(SHIFT_W),
        .REF_SUM(REF_SUM),
        .FINAL_REF(FINAL_REF)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_re_in(data_re_in),
        .data_im_in(data_im_in),
        .index1_re_in(index1_re_in),
        .index1_im_in(index1_im_in),
        .index2_re_in(index2_re_in),
        .index2_im_in(index2_im_in),
        .data_re_out(data_re_out),
        .data_im_out(data_im_out),
        .valid_out(valid_out)
    );
    
    // Initialize input arrays
    initial begin
        for (int k = 0; k < 16; k++) begin
            data_re_in[k] = 0;
            data_im_in[k] = 0;
            index1_re_in[k] = 0;
            index1_im_in[k] = 0;
            index2_re_in[k] = 0;
            index2_im_in[k] = 0;
        end
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        valid_in = 0;
        input_cycle = 0;
        output_cycle = 0;
        
        $display("=== Starting VCS-Safe Streaming Test ===");
        
        // Reset sequence
        #20 rst_n = 1;
        #10;
        
        // Stream 512 samples (32 cycles × 16 samples)
        $display("Streaming 512 input samples...");
        for (input_cycle = 0; input_cycle < 32; input_cycle++) begin
            @(posedge clk);
            valid_in = 1;
            
            // Generate 16 samples for this cycle
            for (int k = 0; k < 16; k++) begin
                sample_idx = input_cycle * 16 + k;
                data_re_in[k] = sample_idx + 100;  // Simple test pattern
                data_im_in[k] = sample_idx + 200;
                index1_re_in[k] = sample_idx % 8;
                index1_im_in[k] = sample_idx % 8;
                index2_re_in[k] = 7 - (sample_idx % 8);
                index2_im_in[k] = 7 - (sample_idx % 8);
            end
            
            if (input_cycle % 10 == 0) $display("  Input cycle %0d", input_cycle);
        end
        
        @(posedge clk);
        valid_in = 0;
        $display("Input streaming completed");
        
        // Wait for and collect outputs
        $display("Waiting for outputs...");
        output_cycle = 0;
        
        while (output_cycle < 32) begin
            @(posedge clk);
            if (valid_out) begin
                if (output_cycle < 3) begin  // Show first 3 cycles
                    $display("Output cycle %0d:", output_cycle);
                    for (int k = 0; k < 4; k++) begin  // Show first 4 samples
                        $display("  [%0d] RE=%0d IM=%0d", k, data_re_out[k], data_im_out[k]);
                    end
                end
                output_cycle++;
            end
        end
        
        $display("Collected %0d output cycles", output_cycle);
        
        #100;
        $display("=== Test Completed Successfully ===");
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (valid_in && dut.write_ptr == 0) begin
            $display("@%0t: Starting new frame input", $time);
        end
        if (valid_out && dut.read_ptr == 0) begin
            $display("@%0t: Starting frame output", $time);
        end
    end

endmodule

`default_nettype wire
