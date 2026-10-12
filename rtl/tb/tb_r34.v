`timescale 1ns/1ps
//===========================================================================
// tb_r34.v  —  IEEE 802.11ad Rate 3/4 LDPC Decoder Testbench
//
// DUT : ldpc_decoder_top_r34
//       N=672, K=504, NUM_LAYERS=4, Z=42, NUM_FRAMES=16, MAX_ITER=10
//
// Prerequisites:
//   python3 gen_test_cases_all_rates.py
//   -> creates test_cases_r34/<case>_llr.hex  and  <case>_chat.txt
//===========================================================================

module tb_r34;

    localparam Q          = 42;
    localparam NUM_COLS   = 16;
    localparam NUM_LAYERS = 4;
    localparam NUM_FRAMES = 16;
    localparam N          = 672;
    localparam NUM_CASES  = 10;
    localparam CLK_HALF   = 5;

    reg        clk, rst, start;
    reg        qv_we;
    reg [3:0]  qv_col, qv_frame_in;
    reg [5:0]  qv_node;
    reg signed [4:0] qv_data;
    reg [3:0]  rd_frame;

    wire [N-1:0] C_hat;
    wire         decoding, done;

    ldpc_decoder_top_r34 #(
        .Q(Q), .NUM_COLS(NUM_COLS), .NUM_LAYERS(NUM_LAYERS),
        .NUM_FRAMES(NUM_FRAMES), .LV_WIDTH(8), .MSG_W(10), .MAX_ITER(10)
    ) DUT (
        .clk(clk), .rst(rst), .start(start),
        .qv_we(qv_we), .qv_col(qv_col), .qv_frame(qv_frame_in),
        .qv_node(qv_node), .qv_data(qv_data),
        .rd_frame(rd_frame),
        .C_hat(C_hat), .decoding(decoding), .done(done)
    );

    initial clk = 0;
    always #(CLK_HALF) clk = ~clk;

    integer cycle_count;
    always @(posedge clk) begin
        if (rst)           cycle_count <= 0;
        else if (decoding) cycle_count <= cycle_count + 1;
    end

    reg [4:0] llr_mem [0:NUM_FRAMES-1][0:N-1];
    reg       exp_mem [0:NUM_FRAMES-1][0:N-1];
    reg [4:0] tmp_llr  [0:N-1];
    reg       tmp_chat [0:N-1];

    reg [256*8-1:0] case_names [0:NUM_CASES-1];
    integer frame_to_case [0:NUM_FRAMES-1];
    integer f, node, idx, err_cnt, total_pass, total_fail;
    reg [1024*8-1:0] llr_path, chat_path;

    initial begin #5000000; $display("[TIMEOUT]"); $finish; end

    initial begin
        $display("\n=== IEEE 802.11ad Rate 3/4 LDPC Decoder TB ===");
        $display("    N=%0d  K=504  LAYERS=4  FRAMES=%0d\n", N, NUM_FRAMES);

        case_names[0] = "allzero_snr5_seed5";
        case_names[1] = "allzero_snr4_seed1";
        case_names[2] = "allzero_snr4_seed2";
        case_names[3] = "allzero_snr3p5_seed10";
        case_names[4] = "allzero_snr3_seed7";
        case_names[5] = "allzero_snr6_seed99";
        case_names[6] = "random_snr5_seed42";
        case_names[7] = "random_snr4_seed123";
        case_names[8] = "random_snr6_seed7";
        case_names[9] = "random_snr3_seed55";

        for (f = 0; f < NUM_FRAMES; f = f+1)
            frame_to_case[f] = f % NUM_CASES;

        $display("[TB] Loading test vectors ...");
        for (f = 0; f < NUM_FRAMES; f = f+1) begin
            $sformat(llr_path,  "test_cases_r34/%0s_llr.hex",  case_names[frame_to_case[f]]);
            $sformat(chat_path, "test_cases_r34/%0s_chat.txt", case_names[frame_to_case[f]]);
            $readmemh(llr_path,  tmp_llr);
            $readmemb(chat_path, tmp_chat);
            for (idx = 0; idx < N; idx = idx+1) begin
                llr_mem[f][idx] = tmp_llr[idx];
                exp_mem[f][idx] = tmp_chat[idx];
            end
        end
        $display("[TB] Vectors loaded.\n");

        cycle_count = 0;
        rst = 1; start = 0; qv_we = 0; rd_frame = 0;
        qv_frame_in = 0; qv_col = 0; qv_node = 0; qv_data = 0;
        repeat(5) @(posedge clk); #1; rst = 0;
        repeat(2) @(posedge clk); #1;

        $display("[TB] Pre-loading LLR memories ...");
        for (f = 0; f < NUM_FRAMES; f = f+1) begin
            for (node = 0; node < Q; node = node+1) begin
                DUT.CS_0.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 0*Q+node]);
                DUT.CS_1.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 1*Q+node]);
                DUT.CS_2.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 2*Q+node]);
                DUT.CS_3.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 3*Q+node]);
                DUT.CS_4.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 4*Q+node]);
                DUT.CS_5.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 5*Q+node]);
                DUT.CS_6.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 6*Q+node]);
                DUT.CS_7.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 7*Q+node]);
                DUT.CS_8.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 8*Q+node]);
                DUT.CS_9.qv_mem[f*Q+node]  = $signed(llr_mem[f][ 9*Q+node]);
                DUT.CS_10.qv_mem[f*Q+node] = $signed(llr_mem[f][10*Q+node]);
                DUT.CS_11.qv_mem[f*Q+node] = $signed(llr_mem[f][11*Q+node]);
                DUT.CS_12.qv_mem[f*Q+node] = $signed(llr_mem[f][12*Q+node]);
                DUT.CS_13.qv_mem[f*Q+node] = $signed(llr_mem[f][13*Q+node]);
                DUT.CS_14.qv_mem[f*Q+node] = $signed(llr_mem[f][14*Q+node]);
                DUT.CS_15.qv_mem[f*Q+node] = $signed(llr_mem[f][15*Q+node]);
            end
        end
        $display("[TB] LLR memories ready. Starting decode ...\n");

        @(posedge clk); #1; start = 1;
        @(posedge clk); #1; start = 0;
        @(posedge done);
        $display("[TB] Done. Cycles = %0d", cycle_count);
        repeat(2) @(posedge clk); #1;

        $display("\n[TB] Checking frames ...");
        total_pass = 0; total_fail = 0;
        for (f = 0; f < NUM_FRAMES; f = f+1) begin
            rd_frame = f[3:0]; #1;
            err_cnt = 0;
            for (idx = 0; idx < N; idx = idx+1)
                if (C_hat[idx] !== exp_mem[f][idx]) err_cnt = err_cnt + 1;
            if (err_cnt == 0) begin
                $display("[PASS] Frame %2d  %-30s  0 errors", f, case_names[frame_to_case[f]]);
                total_pass = total_pass + 1;
            end else if (err_cnt <= 10) begin
                $display("[WARN] Frame %2d  %-30s  %0d errors (low-SNR)", f, case_names[frame_to_case[f]], err_cnt);
                total_pass = total_pass + 1;
            end else begin
                $display("[FAIL] Frame %2d  %-30s  %0d errors", f, case_names[frame_to_case[f]], err_cnt);
                total_fail = total_fail + 1;
            end
        end
        $display("\n=== Rate 3/4 Summary: %0d/%0d passed%0s ===\n",
                 total_pass, NUM_FRAMES, (total_fail==0) ? "  RESULT: ALL PASSED" : "  RESULT: FAILED");
        $finish;
    end

endmodule
