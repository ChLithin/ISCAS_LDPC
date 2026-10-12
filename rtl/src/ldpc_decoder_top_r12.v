// ldpc_decoder_top_r12.v
// IEEE 802.11ad Rate 1/2  N=672, K=336, NUM_LAYERS=8
// NUM_FRAMES=16, Z=42, MAX_ITER=10, LV_WIDTH=10
// Sub-modules: processing_node, column_slice, decoder_controller,
//              permutation_network, cn_update_block, vn_update_block  - UNCHANGED

module ldpc_decoder_top_r12 #(
    parameter Q           = 42,
    parameter NUM_COLS    = 16,
    parameter NUM_LAYERS  = 8,
    parameter NUM_FRAMES  = 16,
    parameter LV_WIDTH    = 10,
    parameter MSG_W       = 10,
    parameter MAX_ITER    = 10,
    parameter [5:0] BP    = 6'd63
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,

    input  wire                  qv_we,
    input  wire [3:0]            qv_col,
    input  wire [3:0]            qv_frame,
    input  wire [5:0]            qv_node,
    input  wire signed [4:0]     qv_data,

    input  wire [3:0]            rd_frame,
    output wire [NUM_COLS*Q-1:0] C_hat,

    output wire                  decoding,
    output wire                  done
);

    localparam BUS_W = Q * NUM_LAYERS * MSG_W;
    localparam [5:0] BPAS = BP;

    localparam [MSG_W-1:0] SEED_ONE = {1'b0, 1'b0, 4'hF, 4'hF};
    localparam [BUS_W-1:0] SEED_BUS = {(Q*NUM_LAYERS){SEED_ONE}};

    // ============================================================
    // Differential CN shifts  (63 = BYPASS)
    // ============================================================
      localparam [5:0] DSH_c0_l0=6'd40;  localparam [5:0] DSH_c0_l1=6'd34;  localparam [5:0] DSH_c0_l2=BP;  localparam [5:0] DSH_c0_l3=BP;  localparam [5:0] DSH_c0_l4=6'd35;  localparam [5:0] DSH_c0_l5=6'd29;  localparam [5:0] DSH_c0_l6=BP;  localparam [5:0] DSH_c0_l7=BP;
      localparam [5:0] DSH_c1_l0=BP;  localparam [5:0] DSH_c1_l1=BP;  localparam [5:0] DSH_c1_l2=6'd36;  localparam [5:0] DSH_c1_l3=6'd27;  localparam [5:0] DSH_c1_l4=BP;  localparam [5:0] DSH_c1_l5=BP;  localparam [5:0] DSH_c1_l6=6'd31;  localparam [5:0] DSH_c1_l7=6'd22;
      localparam [5:0] DSH_c2_l0=6'd40;  localparam [5:0] DSH_c2_l1=6'd1;  localparam [5:0] DSH_c2_l2=6'd37;  localparam [5:0] DSH_c2_l3=BP;  localparam [5:0] DSH_c2_l4=6'd6;  localparam [5:0] DSH_c2_l5=6'd13;  localparam [5:0] DSH_c2_l6=6'd34;  localparam [5:0] DSH_c2_l7=BP;
      localparam [5:0] DSH_c3_l0=BP;  localparam [5:0] DSH_c3_l1=BP;  localparam [5:0] DSH_c3_l2=BP;  localparam [5:0] DSH_c3_l3=6'd33;  localparam [5:0] DSH_c3_l4=BP;  localparam [5:0] DSH_c3_l5=BP;  localparam [5:0] DSH_c3_l6=BP;  localparam [5:0] DSH_c3_l7=6'd12;
      localparam [5:0] DSH_c4_l0=6'd17;  localparam [5:0] DSH_c4_l1=6'd34;  localparam [5:0] DSH_c4_l2=6'd18;  localparam [5:0] DSH_c4_l3=BP;  localparam [5:0] DSH_c4_l4=6'd41;  localparam [5:0] DSH_c4_l5=6'd22;  localparam [5:0] DSH_c4_l6=6'd27;  localparam [5:0] DSH_c4_l7=6'd39;
      localparam [5:0] DSH_c5_l0=BP;  localparam [5:0] DSH_c5_l1=BP;  localparam [5:0] DSH_c5_l2=BP;  localparam [5:0] DSH_c5_l3=6'd36;  localparam [5:0] DSH_c5_l4=BP;  localparam [5:0] DSH_c5_l5=BP;  localparam [5:0] DSH_c5_l6=6'd13;  localparam [5:0] DSH_c5_l7=BP;
      localparam [5:0] DSH_c6_l0=6'd34;  localparam [5:0] DSH_c6_l1=BP;  localparam [5:0] DSH_c6_l2=BP;  localparam [5:0] DSH_c6_l3=6'd8;  localparam [5:0] DSH_c6_l4=6'd41;  localparam [5:0] DSH_c6_l5=6'd24;  localparam [5:0] DSH_c6_l6=6'd41;  localparam [5:0] DSH_c6_l7=BP;
      localparam [5:0] DSH_c7_l0=BP;  localparam [5:0] DSH_c7_l1=BP;  localparam [5:0] DSH_c7_l2=BP;  localparam [5:0] DSH_c7_l3=BP;  localparam [5:0] DSH_c7_l4=BP;  localparam [5:0] DSH_c7_l5=BP;  localparam [5:0] DSH_c7_l6=BP;  localparam [5:0] DSH_c7_l7=6'd25;
      localparam [5:0] DSH_c8_l0=6'd13;  localparam [5:0] DSH_c8_l1=6'd3;  localparam [5:0] DSH_c8_l2=6'd27;  localparam [5:0] DSH_c8_l3=BP;  localparam [5:0] DSH_c8_l4=6'd31;  localparam [5:0] DSH_c8_l5=6'd24;  localparam [5:0] DSH_c8_l6=BP;  localparam [5:0] DSH_c8_l7=6'd32;
      localparam [5:0] DSH_c9_l0=BP;  localparam [5:0] DSH_c9_l1=6'd14;  localparam [5:0] DSH_c9_l2=6'd18;  localparam [5:0] DSH_c9_l3=BP;  localparam [5:0] DSH_c9_l4=BP;  localparam [5:0] DSH_c9_l5=6'd40;  localparam [5:0] DSH_c9_l6=6'd34;  localparam [5:0] DSH_c9_l7=BP;
      localparam [5:0] DSH_c10_l0=BP;  localparam [5:0] DSH_c10_l1=6'd41;  localparam [5:0] DSH_c10_l2=6'd31;  localparam [5:0] DSH_c10_l3=6'd37;  localparam [5:0] DSH_c10_l4=BP;  localparam [5:0] DSH_c10_l5=6'd24;  localparam [5:0] DSH_c10_l6=BP;  localparam [5:0] DSH_c10_l7=BP;
      localparam [5:0] DSH_c11_l0=BP;  localparam [5:0] DSH_c11_l1=BP;  localparam [5:0] DSH_c11_l2=BP;  localparam [5:0] DSH_c11_l3=6'd33;  localparam [5:0] DSH_c11_l4=6'd17;  localparam [5:0] DSH_c11_l5=6'd19;  localparam [5:0] DSH_c11_l6=BP;  localparam [5:0] DSH_c11_l7=6'd14;
      localparam [5:0] DSH_c12_l0=BP;  localparam [5:0] DSH_c12_l1=BP;  localparam [5:0] DSH_c12_l2=BP;  localparam [5:0] DSH_c12_l3=BP;  localparam [5:0] DSH_c12_l4=6'd25;  localparam [5:0] DSH_c12_l5=BP;  localparam [5:0] DSH_c12_l6=6'd30;  localparam [5:0] DSH_c12_l7=6'd37;
      localparam [5:0] DSH_c13_l0=BP;  localparam [5:0] DSH_c13_l1=BP;  localparam [5:0] DSH_c13_l2=BP;  localparam [5:0] DSH_c13_l3=BP;  localparam [5:0] DSH_c13_l4=BP;  localparam [5:0] DSH_c13_l5=6'd23;  localparam [5:0] DSH_c13_l6=BP;  localparam [5:0] DSH_c13_l7=6'd9;
      localparam [5:0] DSH_c14_l0=BP;  localparam [5:0] DSH_c14_l1=BP;  localparam [5:0] DSH_c14_l2=BP;  localparam [5:0] DSH_c14_l3=BP;  localparam [5:0] DSH_c14_l4=BP;  localparam [5:0] DSH_c14_l5=6'd15;  localparam [5:0] DSH_c14_l6=6'd13;  localparam [5:0] DSH_c14_l7=6'd0;
      localparam [5:0] DSH_c15_l0=BP;  localparam [5:0] DSH_c15_l1=BP;  localparam [5:0] DSH_c15_l2=BP;  localparam [5:0] DSH_c15_l3=BP;  localparam [5:0] DSH_c15_l4=BP;  localparam [5:0] DSH_c15_l5=BP;  localparam [5:0] DSH_c15_l6=BP;  localparam [5:0] DSH_c15_l7=6'd2;

    // ============================================================
    // VN wraparound shifts  ( base[l][0] - base[l][last_active] + 42 ) % 42
    // ============================================================
      // VN_WRAP_l2/l3/l6/l7 corrected: those layers' first active column is
      // column 1, not column 0 (column 0 is bypassed for them). The old
      // values used (base[l,first_act]-base[l,last_act])%Z, but dsh()
      // already re-applies +base[l,first_act] when the broadcast path
      // re-enters that column on the same physical PERM wire -- so vwrap
      // must only cancel base[l,last_act], or that term is subtracted twice.
      localparam [5:0] VN_WRAP_l0=6'd22;  localparam [5:0] VN_WRAP_l1=6'd33;  localparam [5:0] VN_WRAP_l2=6'd1;  localparam [5:0] VN_WRAP_l3=6'd36;  localparam [5:0] VN_WRAP_l4=6'd7;  localparam [5:0] VN_WRAP_l5=6'd6;  localparam [5:0] VN_WRAP_l6=6'd29;  localparam [5:0] VN_WRAP_l7=6'd18;

    // ============================================================
    // LAYER_ACTIVE per column  (bit l = 1 means layer l active)
    // ============================================================
    localparam [7:0] LA_00110011 = 8'b00110011;
    localparam [7:0] LA_11001100 = 8'b11001100;
    localparam [7:0] LA_01110111 = 8'b01110111;
    localparam [7:0] LA_10001000 = 8'b10001000;
    localparam [7:0] LA_11110111 = 8'b11110111;
    localparam [7:0] LA_01001000 = 8'b01001000;
    localparam [7:0] LA_01111001 = 8'b01111001;
    localparam [7:0] LA_10000000 = 8'b10000000;
    localparam [7:0] LA_10110111 = 8'b10110111;
    localparam [7:0] LA_01100110 = 8'b01100110;
    localparam [7:0] LA_00101110 = 8'b00101110;
    localparam [7:0] LA_10111000 = 8'b10111000;
    localparam [7:0] LA_11010000 = 8'b11010000;
    localparam [7:0] LA_10100000 = 8'b10100000;
    localparam [7:0] LA_11100000 = 8'b11100000;

    // ============================================================
    // Controller
    // ============================================================
    wire [3:0] ctrl_frame;
    wire       ctrl_phase, ctrl_first;
    wire       ctrl_issue_en;
    wire       all_term_w;
    wire       decoding_w, done_w;

    decoder_controller #(
        .NUM_COLS(NUM_COLS), .NUM_FRAMES(NUM_FRAMES), .MAX_ITER(MAX_ITER)
    ) CTRL (
        .clk(clk), .rst(rst), .start(start), .all_term(all_term_w),
        .frame_id(ctrl_frame), .phase_select(ctrl_phase), .first_iter(ctrl_first),
        .issue_en(ctrl_issue_en),
        .decoding(decoding_w), .done(done_w)
    );
    assign decoding = decoding_w;
    assign done     = done_w;

    // ============================================================
    // 16-stage pipeline control shift registers
    // ============================================================
    reg [3:0] frame_sr [1:NUM_COLS-1];
    reg       phase_sr [1:NUM_COLS-1];
    reg       first_sr [1:NUM_COLS-1];
    reg       dec_sr   [1:NUM_COLS-1];

    integer pi;
    always @(posedge clk or posedge rst) begin : PIPE_SR
        if (rst) begin
            for (pi = 1; pi < NUM_COLS; pi = pi+1) begin
                frame_sr[pi] <= 4'd0; phase_sr[pi] <= 1'b0;
                first_sr[pi] <= 1'b0; dec_sr  [pi] <= 1'b0;
            end
        end else begin
            frame_sr[1] <= ctrl_frame; phase_sr[1] <= ctrl_phase;
            first_sr[1] <= ctrl_first; dec_sr  [1] <= ctrl_issue_en;
            for (pi = 2; pi < NUM_COLS; pi = pi+1) begin
                frame_sr[pi] <= frame_sr[pi-1]; phase_sr[pi] <= phase_sr[pi-1];
                first_sr[pi] <= first_sr[pi-1]; dec_sr  [pi] <= dec_sr  [pi-1];
            end
        end
    end

    wire [3:0] stg_frame [0:NUM_COLS-1];
    wire       stg_phase [0:NUM_COLS-1];
    wire       stg_first [0:NUM_COLS-1];
    wire       stg_en    [0:NUM_COLS-1];

    assign stg_frame[0] = ctrl_frame; assign stg_phase[0] = ctrl_phase;
    assign stg_first[0] = ctrl_first; assign stg_en   [0] = ctrl_issue_en;

    genvar sk;
    generate
        for (sk = 1; sk < NUM_COLS; sk = sk+1) begin : GEN_STG
            assign stg_frame[sk] = frame_sr[sk]; assign stg_phase[sk] = phase_sr[sk];
            assign stg_first[sk] = first_sr[sk]; assign stg_en   [sk] = dec_sr  [sk];
        end
    endgenerate

    // ============================================================
    // Data path wires
    // ============================================================
    wire [BUS_W-1:0] perm_out    [0:NUM_COLS-1];
    wire [BUS_W-1:0] perm_out_vn;
    wire [BUS_W-1:0] col_out     [0:NUM_COLS-1];

    // ============================================================
    // Col 0 input MUX (CN seed path vs VN wraparound path)
    // ============================================================
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c0_l0), .SHIFT_1(DSH_c0_l1), .SHIFT_2(DSH_c0_l2), .SHIFT_3(DSH_c0_l3), .SHIFT_4(DSH_c0_l4), .SHIFT_5(DSH_c0_l5), .SHIFT_6(DSH_c0_l6), .SHIFT_7(DSH_c0_l7))
        PERM_0(.msg_in(SEED_BUS),.msg_out(perm_out[0]));

    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(VN_WRAP_l0), .SHIFT_1(VN_WRAP_l1), .SHIFT_2(VN_WRAP_l2), .SHIFT_3(VN_WRAP_l3), .SHIFT_4(VN_WRAP_l4), .SHIFT_5(VN_WRAP_l5), .SHIFT_6(VN_WRAP_l6), .SHIFT_7(VN_WRAP_l7))
        PERM_0_VN(.msg_in(col_out[15]),.msg_out(perm_out_vn));

    wire [BUS_W-1:0] col0_msg_in;
    assign col0_msg_in = stg_phase[0] ? perm_out_vn : perm_out[0];

    // ============================================================
    // Early Termination (paper Sec. III-H)
    //
    // Tap col_out[15]'s pc bits at the end of each VN pass.
    // pc[node][layer] = XOR-accumulated parity over all connected
    // columns for that check. Zero across all nodes/active-layers
    // means the frame's syndrome is satisfied -> terminate that frame.
    //
    // Fix: syndrome_check_now fires at the SAME posedge that writes
    // col_out[15] (NBA), so it reads the stale pre-write value.
    // We register the check flag and frame_id, then evaluate
    // syndrome_nonzero (combinational from col_out[15]) one cycle
    // later when col_out[15] holds the settled post-write value.
    // ============================================================
    wire [Q*NUM_LAYERS-1:0] col15_pc_bits;
    genvar pcn, pcl;
    generate
        for (pcn = 0; pcn < Q; pcn = pcn+1) begin : GEN_PC_N
            for (pcl = 0; pcl < NUM_LAYERS; pcl = pcl+1) begin : GEN_PC_L
                assign col15_pc_bits[pcn*NUM_LAYERS+pcl] =
                    col_out[15][(pcn*NUM_LAYERS+pcl)*MSG_W + 9];
            end
        end
    endgenerate

    wire syndrome_nonzero = |col15_pc_bits;
    wire syndrome_check_now = stg_en[15] & stg_phase[15] & ~stg_first[15];

    reg        syndrome_check_d;
    reg [3:0]  syndrome_frame_d;

    always @(posedge clk or posedge rst) begin : SYNDROME_DELAY
        if (rst) begin
            syndrome_check_d <= 1'b0;
            syndrome_frame_d <= 4'd0;
        end else begin
            syndrome_check_d <= syndrome_check_now;
            syndrome_frame_d <= stg_frame[15];
        end
    end

    reg [NUM_FRAMES-1:0] term_reg;

    always @(posedge clk or posedge rst) begin : TERM_SET
        if (rst) begin
            term_reg <= {NUM_FRAMES{1'b0}};
        end else if (start) begin
            term_reg <= {NUM_FRAMES{1'b0}};
        end else if (syndrome_check_d && !syndrome_nonzero) begin
            term_reg[syndrome_frame_d] <= 1'b1;
        end
    end

    assign all_term_w = decoding_w && (&term_reg);

    wire [NUM_COLS-1:0] stg_term;
    genvar tk;
    generate
        for (tk = 0; tk < NUM_COLS; tk = tk+1) begin : GEN_TERM_GATE
            assign stg_term[tk] = term_reg[stg_frame[tk]];
        end
    endgenerate

    // Column 0
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_00110011)) CS_0 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[0] & ~stg_term[0]),.phase_select(stg_phase[0]),
        .first_iter(stg_first[0]),.frame_id(stg_frame[0]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd0)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(col0_msg_in),.layer_msg_out(col_out[0]),.C_hat(C_hat[0*Q+:Q]));

    // Column 1
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c1_l0), .SHIFT_1(DSH_c1_l1), .SHIFT_2(DSH_c1_l2), .SHIFT_3(DSH_c1_l3), .SHIFT_4(DSH_c1_l4), .SHIFT_5(DSH_c1_l5), .SHIFT_6(DSH_c1_l6), .SHIFT_7(DSH_c1_l7))
        PERM_1(.msg_in(col_out[0]),.msg_out(perm_out[1]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_11001100)) CS_1 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[1] & ~stg_term[1]),.phase_select(stg_phase[1]),
        .first_iter(stg_first[1]),.frame_id(stg_frame[1]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd1)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[1]),.layer_msg_out(col_out[1]),.C_hat(C_hat[1*Q+:Q]));

    // Column 2
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c2_l0), .SHIFT_1(DSH_c2_l1), .SHIFT_2(DSH_c2_l2), .SHIFT_3(DSH_c2_l3), .SHIFT_4(DSH_c2_l4), .SHIFT_5(DSH_c2_l5), .SHIFT_6(DSH_c2_l6), .SHIFT_7(DSH_c2_l7))
        PERM_2(.msg_in(col_out[1]),.msg_out(perm_out[2]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_01110111)) CS_2 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[2] & ~stg_term[2]),.phase_select(stg_phase[2]),
        .first_iter(stg_first[2]),.frame_id(stg_frame[2]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd2)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[2]),.layer_msg_out(col_out[2]),.C_hat(C_hat[2*Q+:Q]));

    // Column 3
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c3_l0), .SHIFT_1(DSH_c3_l1), .SHIFT_2(DSH_c3_l2), .SHIFT_3(DSH_c3_l3), .SHIFT_4(DSH_c3_l4), .SHIFT_5(DSH_c3_l5), .SHIFT_6(DSH_c3_l6), .SHIFT_7(DSH_c3_l7))
        PERM_3(.msg_in(col_out[2]),.msg_out(perm_out[3]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_10001000)) CS_3 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[3] & ~stg_term[3]),.phase_select(stg_phase[3]),
        .first_iter(stg_first[3]),.frame_id(stg_frame[3]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd3)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[3]),.layer_msg_out(col_out[3]),.C_hat(C_hat[3*Q+:Q]));

    // Column 4
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c4_l0), .SHIFT_1(DSH_c4_l1), .SHIFT_2(DSH_c4_l2), .SHIFT_3(DSH_c4_l3), .SHIFT_4(DSH_c4_l4), .SHIFT_5(DSH_c4_l5), .SHIFT_6(DSH_c4_l6), .SHIFT_7(DSH_c4_l7))
        PERM_4(.msg_in(col_out[3]),.msg_out(perm_out[4]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_11110111)) CS_4 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[4] & ~stg_term[4]),.phase_select(stg_phase[4]),
        .first_iter(stg_first[4]),.frame_id(stg_frame[4]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd4)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[4]),.layer_msg_out(col_out[4]),.C_hat(C_hat[4*Q+:Q]));

    // Column 5
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c5_l0), .SHIFT_1(DSH_c5_l1), .SHIFT_2(DSH_c5_l2), .SHIFT_3(DSH_c5_l3), .SHIFT_4(DSH_c5_l4), .SHIFT_5(DSH_c5_l5), .SHIFT_6(DSH_c5_l6), .SHIFT_7(DSH_c5_l7))
        PERM_5(.msg_in(col_out[4]),.msg_out(perm_out[5]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_01001000)) CS_5 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[5] & ~stg_term[5]),.phase_select(stg_phase[5]),
        .first_iter(stg_first[5]),.frame_id(stg_frame[5]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd5)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[5]),.layer_msg_out(col_out[5]),.C_hat(C_hat[5*Q+:Q]));

    // Column 6
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c6_l0), .SHIFT_1(DSH_c6_l1), .SHIFT_2(DSH_c6_l2), .SHIFT_3(DSH_c6_l3), .SHIFT_4(DSH_c6_l4), .SHIFT_5(DSH_c6_l5), .SHIFT_6(DSH_c6_l6), .SHIFT_7(DSH_c6_l7))
        PERM_6(.msg_in(col_out[5]),.msg_out(perm_out[6]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_01111001)) CS_6 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[6] & ~stg_term[6]),.phase_select(stg_phase[6]),
        .first_iter(stg_first[6]),.frame_id(stg_frame[6]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd6)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[6]),.layer_msg_out(col_out[6]),.C_hat(C_hat[6*Q+:Q]));

    // Column 7
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c7_l0), .SHIFT_1(DSH_c7_l1), .SHIFT_2(DSH_c7_l2), .SHIFT_3(DSH_c7_l3), .SHIFT_4(DSH_c7_l4), .SHIFT_5(DSH_c7_l5), .SHIFT_6(DSH_c7_l6), .SHIFT_7(DSH_c7_l7))
        PERM_7(.msg_in(col_out[6]),.msg_out(perm_out[7]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_10000000)) CS_7 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[7] & ~stg_term[7]),.phase_select(stg_phase[7]),
        .first_iter(stg_first[7]),.frame_id(stg_frame[7]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd7)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[7]),.layer_msg_out(col_out[7]),.C_hat(C_hat[7*Q+:Q]));

    // Column 8
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c8_l0), .SHIFT_1(DSH_c8_l1), .SHIFT_2(DSH_c8_l2), .SHIFT_3(DSH_c8_l3), .SHIFT_4(DSH_c8_l4), .SHIFT_5(DSH_c8_l5), .SHIFT_6(DSH_c8_l6), .SHIFT_7(DSH_c8_l7))
        PERM_8(.msg_in(col_out[7]),.msg_out(perm_out[8]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_10110111)) CS_8 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[8] & ~stg_term[8]),.phase_select(stg_phase[8]),
        .first_iter(stg_first[8]),.frame_id(stg_frame[8]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd8)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[8]),.layer_msg_out(col_out[8]),.C_hat(C_hat[8*Q+:Q]));

    // Column 9
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c9_l0), .SHIFT_1(DSH_c9_l1), .SHIFT_2(DSH_c9_l2), .SHIFT_3(DSH_c9_l3), .SHIFT_4(DSH_c9_l4), .SHIFT_5(DSH_c9_l5), .SHIFT_6(DSH_c9_l6), .SHIFT_7(DSH_c9_l7))
        PERM_9(.msg_in(col_out[8]),.msg_out(perm_out[9]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_01100110)) CS_9 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[9] & ~stg_term[9]),.phase_select(stg_phase[9]),
        .first_iter(stg_first[9]),.frame_id(stg_frame[9]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd9)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[9]),.layer_msg_out(col_out[9]),.C_hat(C_hat[9*Q+:Q]));

    // Column 10
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c10_l0), .SHIFT_1(DSH_c10_l1), .SHIFT_2(DSH_c10_l2), .SHIFT_3(DSH_c10_l3), .SHIFT_4(DSH_c10_l4), .SHIFT_5(DSH_c10_l5), .SHIFT_6(DSH_c10_l6), .SHIFT_7(DSH_c10_l7))
        PERM_10(.msg_in(col_out[9]),.msg_out(perm_out[10]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_00101110)) CS_10 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[10] & ~stg_term[10]),.phase_select(stg_phase[10]),
        .first_iter(stg_first[10]),.frame_id(stg_frame[10]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd10)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[10]),.layer_msg_out(col_out[10]),.C_hat(C_hat[10*Q+:Q]));

    // Column 11
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c11_l0), .SHIFT_1(DSH_c11_l1), .SHIFT_2(DSH_c11_l2), .SHIFT_3(DSH_c11_l3), .SHIFT_4(DSH_c11_l4), .SHIFT_5(DSH_c11_l5), .SHIFT_6(DSH_c11_l6), .SHIFT_7(DSH_c11_l7))
        PERM_11(.msg_in(col_out[10]),.msg_out(perm_out[11]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_10111000)) CS_11 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[11] & ~stg_term[11]),.phase_select(stg_phase[11]),
        .first_iter(stg_first[11]),.frame_id(stg_frame[11]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd11)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[11]),.layer_msg_out(col_out[11]),.C_hat(C_hat[11*Q+:Q]));

    // Column 12
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c12_l0), .SHIFT_1(DSH_c12_l1), .SHIFT_2(DSH_c12_l2), .SHIFT_3(DSH_c12_l3), .SHIFT_4(DSH_c12_l4), .SHIFT_5(DSH_c12_l5), .SHIFT_6(DSH_c12_l6), .SHIFT_7(DSH_c12_l7))
        PERM_12(.msg_in(col_out[11]),.msg_out(perm_out[12]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_11010000)) CS_12 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[12] & ~stg_term[12]),.phase_select(stg_phase[12]),
        .first_iter(stg_first[12]),.frame_id(stg_frame[12]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd12)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[12]),.layer_msg_out(col_out[12]),.C_hat(C_hat[12*Q+:Q]));

    // Column 13
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c13_l0), .SHIFT_1(DSH_c13_l1), .SHIFT_2(DSH_c13_l2), .SHIFT_3(DSH_c13_l3), .SHIFT_4(DSH_c13_l4), .SHIFT_5(DSH_c13_l5), .SHIFT_6(DSH_c13_l6), .SHIFT_7(DSH_c13_l7))
        PERM_13(.msg_in(col_out[12]),.msg_out(perm_out[13]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_10100000)) CS_13 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[13] & ~stg_term[13]),.phase_select(stg_phase[13]),
        .first_iter(stg_first[13]),.frame_id(stg_frame[13]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd13)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[13]),.layer_msg_out(col_out[13]),.C_hat(C_hat[13*Q+:Q]));

    // Column 14
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c14_l0), .SHIFT_1(DSH_c14_l1), .SHIFT_2(DSH_c14_l2), .SHIFT_3(DSH_c14_l3), .SHIFT_4(DSH_c14_l4), .SHIFT_5(DSH_c14_l5), .SHIFT_6(DSH_c14_l6), .SHIFT_7(DSH_c14_l7))
        PERM_14(.msg_in(col_out[13]),.msg_out(perm_out[14]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_11100000)) CS_14 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[14] & ~stg_term[14]),.phase_select(stg_phase[14]),
        .first_iter(stg_first[14]),.frame_id(stg_frame[14]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd14)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[14]),.layer_msg_out(col_out[14]),.C_hat(C_hat[14*Q+:Q]));

    // Column 15
    permutation_network #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.MSG_W(MSG_W),.BYPASS_SENTINEL(BPAS),
        .SHIFT_0(DSH_c15_l0), .SHIFT_1(DSH_c15_l1), .SHIFT_2(DSH_c15_l2), .SHIFT_3(DSH_c15_l3), .SHIFT_4(DSH_c15_l4), .SHIFT_5(DSH_c15_l5), .SHIFT_6(DSH_c15_l6), .SHIFT_7(DSH_c15_l7))
        PERM_15(.msg_in(col_out[14]),.msg_out(perm_out[15]));
    column_slice #(.Q(Q),.NUM_LAYERS(NUM_LAYERS),.NUM_FRAMES(NUM_FRAMES),
                   .LV_WIDTH(LV_WIDTH),.MSG_W(MSG_W),.LAYER_ACTIVE(LA_10000000)) CS_15 (
        .clk(clk),.rst(rst),
        .node_en(stg_en[15] & ~stg_term[15]),.phase_select(stg_phase[15]),
        .first_iter(stg_first[15]),.frame_id(stg_frame[15]),.rd_frame_id(rd_frame),
        .qv_we(qv_we&&(qv_col==4'd15)),.qv_wframe(qv_frame),
        .qv_waddr(qv_node),.qv_wdata(qv_data),
        .layer_msg_in(perm_out[15]),.layer_msg_out(col_out[15]),.C_hat(C_hat[15*Q+:Q]));

endmodule