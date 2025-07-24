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

    // Stimulus
    initial begin
        rst_n = 0;
        valid_in = 0;
        #20 rst_n = 1;

        // Apply input pattern
        #10;
        valid_in = 1;
        for (int i = 0; i < 512; i++) begin
            data_re_in[i] = $random % (1 << (IN_W-1));
            data_im_in[i] = $random % (1 << (IN_W-1));
            index1_re_in[i] = i % 16;
            index1_im_in[i] = i % 16;
            index2_re_in[i] = (15 - i % 16);
            index2_im_in[i] = (15 - i % 16);
        end
        #10 valid_in = 0;

        // Wait for output
        wait (valid_out);
        #10;

        // Check output
        for (int i = 0; i < 16; i++) begin
            $display("[%0d] RE: %0d, IM: %0d", i, data_re_out[i], data_im_out[i]);
        end

        #100;
        $finish;
    end
endmodule

`default_nettype wire
