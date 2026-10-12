// decoder_controller.v — Frame-Interleaved Pipeline Controller (FIXED)
//
// Architecture: 16 column-slice stages, 1 pipeline register per column
// boundary (16-stage variant), 16 interleaved frames, frame_id cycles
// 0..NUM_FRAMES-1 once per CN pass and once per VN pass.
//
// T_cnt drives stage-0 scheduling combinationally while ISSUE is active:
//   frame_id     = T_cnt[3:0]
//   phase_select = T_cnt[4]
//   first_iter   = (T_cnt < 2*NUM_COLS)   true during iteration 1 only
//
// Fix vs prior version: ISSUE and DRAIN are explicit, non-overlapping
// phases. Stage-0 stops issuing new (frame,phase) pairs the instant the
// last iteration's last VN cycle has been issued; 'done' only asserts
// after an additional (NUM_COLS-1)-cycle drain so the last-issued frame's
// result has propagated through every pipeline stage to column NUM_COLS-1.
// No partial/extra pass is ever issued.
//
// Early termination (Sec. III-H of paper): per-frame coarse-grained
// gating. This controller does NOT decide termination itself (that
// requires the live pc-bit syndrome check, done at the top level where
// column-0/column-(NUM_COLS-1) wiring is visible). Instead it accepts
// 'all_term' — a level flag from the top level meaning "every frame's
// sticky termination bit is set" — and uses it to cut the run short
// (stop issuing new passes, then drain and finish), exactly like hitting
// T_cnt's natural end early. Per-frame gating of node_en/memories is done
// in the top module using the per-frame termination vector, not here.

module decoder_controller #(
    parameter NUM_COLS   = 16,
    parameter NUM_FRAMES = 16,
    parameter MAX_ITER   = 10
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        all_term,    // level: 1 once every frame has terminated

    output wire [3:0]  frame_id,
    output wire        phase_select,
    output wire        first_iter,
    output wire        issue_en,    // 1 only while a NEW (frame,phase) is being
                                     // issued into pipeline stage 0 this cycle
    output reg         decoding,
    output reg         done
);

    // Total stage-0 issue cycles for one full run = MAX_ITER * 2 * NUM_COLS
    // (2 passes per iteration: CN then VN, NUM_COLS frame_id values each).
    localparam [9:0] ISSUE_CYCLES = MAX_ITER * 2 * NUM_COLS;
    localparam [9:0] T_ISSUE_LAST = ISSUE_CYCLES - 10'd1;     // last cycle index that issues work
    localparam [9:0] DRAIN_CYCLES = NUM_COLS - 1;             // cycles needed after last issue
                                                                // for it to reach the final stage

    reg [9:0] T_cnt;          // increments only while issuing
    reg [9:0] drain_cnt;

    localparam S_IDLE=2'd0, S_ISSUE=2'd1, S_DRAIN=2'd2, S_DONE=2'd3;
    reg [1:0] state;

    assign frame_id     = T_cnt[3:0];
    assign phase_select = T_cnt[4];
    assign first_iter   = (T_cnt < (NUM_COLS * 2));
    assign issue_en     = (state == S_ISSUE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= S_IDLE;
            T_cnt      <= 10'd0;
            drain_cnt  <= 10'd0;
            decoding   <= 1'b0;
            done       <= 1'b0;
        end else begin
            case (state)

                S_IDLE: begin
                    decoding  <= 1'b0;
                    done      <= 1'b0;
                    T_cnt     <= 10'd0;
                    drain_cnt <= 10'd0;
                    if (start) begin
                        state    <= S_ISSUE;
                        decoding <= 1'b1;
                        T_cnt    <= 10'd0;
                    end
                end

                // Issue (frame_id, phase_select) pairs to pipeline stage 0,
                // one per cycle, until either the scheduled run completes
                // or every frame has terminated early.
                S_ISSUE: begin
                    decoding <= 1'b1;
                    if ((T_cnt == T_ISSUE_LAST) || all_term) begin
                        state     <= S_DRAIN;
                        drain_cnt <= 10'd0;
                    end else begin
                        T_cnt <= T_cnt + 10'd1;
                    end
                end

                // No new work is issued; wait for the last-issued frame's
                // result to propagate through the remaining pipeline
                // stages before declaring done.
                S_DRAIN: begin
                    decoding <= 1'b1;
                    if (drain_cnt == DRAIN_CYCLES) begin
                        state    <= S_DONE;
                        done     <= 1'b1;
                        decoding <= 1'b0;
                    end else begin
                        drain_cnt <= drain_cnt + 10'd1;
                    end
                end

                S_DONE: begin  // 'done' is a level signal until restart
                    decoding <= 1'b0;
                    if (start) begin
                        state     <= S_ISSUE;
                        decoding  <= 1'b1;
                        done      <= 1'b0;
                        T_cnt     <= 10'd0;
                        drain_cnt <= 10'd0;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
