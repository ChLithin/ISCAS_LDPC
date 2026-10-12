// permutation_network.v — Generic (up to 8 layers)
// Supports NUM_LAYERS = 3 (rate 13/16), 4 (rate 3/4),
//                       6 (rate 5/8),   8 (rate 1/2)
// Unused SHIFT_x parameters default to BYPASS_SENTINEL (identity).

module permutation_network #(
    parameter       Q                = 42,
    parameter       NUM_LAYERS       = 3,
    parameter       MSG_W            = 10,
    parameter [5:0] BYPASS_SENTINEL  = 6'd63,
    parameter [5:0] SHIFT_0          = 6'd63,
    parameter [5:0] SHIFT_1          = 6'd63,
    parameter [5:0] SHIFT_2          = 6'd63,
    parameter [5:0] SHIFT_3          = 6'd63,
    parameter [5:0] SHIFT_4          = 6'd63,
    parameter [5:0] SHIFT_5          = 6'd63,
    parameter [5:0] SHIFT_6          = 6'd63,
    parameter [5:0] SHIFT_7          = 6'd63
)(
    input  wire [(Q * NUM_LAYERS * MSG_W)-1:0] msg_in,
    output wire [(Q * NUM_LAYERS * MSG_W)-1:0] msg_out
);

    genvar l, n;
    generate
        for (l = 0; l < NUM_LAYERS; l = l + 1) begin : GEN_L

            wire [5:0] shift_l;
            assign shift_l = (l == 0) ? SHIFT_0 :
                             (l == 1) ? SHIFT_1 :
                             (l == 2) ? SHIFT_2 :
                             (l == 3) ? SHIFT_3 :
                             (l == 4) ? SHIFT_4 :
                             (l == 5) ? SHIFT_5 :
                             (l == 6) ? SHIFT_6 :
                                        SHIFT_7;

            wire active_l;
            assign active_l = (shift_l != BYPASS_SENTINEL);

            for (n = 0; n < Q; n = n + 1) begin : GEN_N
                localparam [5:0] N_VAL = n;

                wire [5:0] src;
                assign src = active_l
                           ? ( (N_VAL >= shift_l)
                               ? (N_VAL - shift_l)
                               : (N_VAL + 6'd42 - shift_l) )
                           : N_VAL;

                assign msg_out[(n   * NUM_LAYERS + l) * MSG_W +: MSG_W]
                     = msg_in [(src * NUM_LAYERS + l) * MSG_W +: MSG_W];
            end
        end
    endgenerate

endmodule
