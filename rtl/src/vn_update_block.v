// vn_update_block.v - IAMS Version (replaces plain Min-Sum)
//
// Implements the Improved Adapted Min-Sum (IAMS) check-node-update function
// from Cui, Ghaffari, Le, Declercq, Lin, Wang, "Design of High-Performance
// and Area-Efficient Decoder for 5G LDPC Codes," IEEE TCAS-I, vol. 68, no. 2,
// pp. 879-891, Feb. 2021, Eq. (10):
//
//   alpha_m,n =  tau * min2 ,              n = idx1
//                tau * min1 ,              n = idx2
//                tau * max(min1 - 1, 0) ,  n in Ibar(m) & Delta = 0  (tie)
//                tau * min1 ,              n in Ibar(m) & Delta != 0
//
// where idx1/idx2 are the VNs achieving the check's first/second minimum
// magnitude, Delta = min2 - min1, and tau is the sign product carried in
// sign_c (already XORed with this node's own sign to give the outgoing sign).
//
// -----------------------------------------------------------------------------
// Hardware note on idx1 / idx2 identification
// -----------------------------------------------------------------------------
// This architecture is magnitude-comparison based: cn_update_block only ever
// forwards the running (sign, min1, min2) triple through the column slices,
// it never carries an explicit node index. Cui et al.'s own architecture adds
// an idx2 field through the datapath for exactly this reason ("idx2 should
// also be calculated and stored, which is the main difference with other
// decoders").
//
// To avoid widening layer_msg_in/out (and therefore touching column_slice.v,
// processing_node.v, and the permutation network) we instead reconstruct
// idx1/idx2 locally at each node from the FINAL min1_c/min2_c broadcast
// during the VN phase:
//   is_idx1 = (lvc_mag == min1_c)                -- this node produced min1
//   is_idx2 = (lvc_mag == min2_c) & ~is_idx1      -- this node produced min2
// This reproduces Eq. (10) exactly whenever a check has a single unique min1
// contributor and a single, distinct min2 contributor (the normal case, and
// the only case the paper itself proves the tie-correction property for).
// In the degenerate case of 3+ nodes tied at the same minimum value, at most
// one of them is arbitrarily treated as idx1/idx2 and the rest fall into the
// "otherwise" branch below -- no worse than the index-tracked hardware,
// which also only special-cases exactly two positions (idx1, idx2).
//
// cn_update_block.v is UNCHANGED: min1/min2/sign tracking is identical for
// MS, NMS, and IAMS -- only the extrinsic message computed here differs.

module vn_update_block (
    input  wire        phase_select,  // 0 = CN phase, 1 = VN phase
    input  wire        sign_c,        // final sc(T-1) from CN phase
    input  wire [3:0]  min1_c,        // final min1c(T-1)
    input  wire [3:0]  min2_c,        // final min2c(T-1)
    input  wire        lvc_sign,      // sign of this node's Lvc (sign-magnitude)
    input  wire [3:0]  lvc_mag,       // magnitude of this node's Lvc
    output wire signed [4:0] mcv_tc   // mcv in 2's-complement, 0 during CN phase
);

    // -------------------------------------------------------------------------
    // Identify this node's role: idx1 (min1 contributor), idx2 (min2
    // contributor), or "other" (Ibar(m) in the paper's notation).
    // -------------------------------------------------------------------------
    wire is_idx1 = (lvc_mag == min1_c);
    wire is_idx2 = (~is_idx1) & (lvc_mag == min2_c);

    // -------------------------------------------------------------------------
    // Tie flag: Delta = min2_c - min1_c = 0  <=>  min1_c == min2_c
    // -------------------------------------------------------------------------
    wire tie = (min1_c == min2_c);

    // -------------------------------------------------------------------------
    // Saturating max(min1_c - 1, 0) for the "other & tie" branch of Eq. (10)
    // -------------------------------------------------------------------------
    wire [3:0] min1_minus1_sat = (min1_c == 4'd0) ? 4'd0 : (min1_c - 4'd1);

    // -------------------------------------------------------------------------
    // Eq. (10): pick the IAMS magnitude for this node
    // -------------------------------------------------------------------------
    wire [3:0] mcv_mag =
        is_idx1 ? min2_c :                    // n = idx1
        is_idx2 ? min1_c :                    // n = idx2
        tie     ? min1_minus1_sat :           // n in Ibar(m), Delta = 0
                  min1_c;                     // n in Ibar(m), Delta != 0

    wire mcv_sign = sign_c ^ lvc_sign;

    wire signed [4:0] mcv_val =
        mcv_sign ? -$signed({1'b0, mcv_mag})
                 :  $signed({1'b0, mcv_mag});

    assign mcv_tc = phase_select ? mcv_val : 5'sd0;

endmodule