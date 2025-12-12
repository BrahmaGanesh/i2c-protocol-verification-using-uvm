module i2c_slave #(
    parameter ADDR = 7'h42
)(
    input  logic clk,
    input  logic resetn,
    input  logic SDA_in,
    output logic SDA_out_en,
    input  logic SCL
);

    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;
    logic rw;
    logic [7:0] mem;
    logic scl_d;
    logic stretch;

    typedef enum logic [2:0] {
        IDLE,
        ADDR_SHIFT,
        ADDR_ACK,
        DATA_SHIFT,
        DATA_ACK,
        READ_SEND
    } state_t;
    state_t state, next_state;

    wire start_cond = (SDA_in == 0 && SCL == 1);
    wire stop_cond  = (SDA_in == 1 && SCL == 1);
    wire scl_rising  = (SCL && !scl_d);
    wire scl_falling = (!SCL && scl_d);

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE;
            scl_d <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            SDA_out_en <= 1;
            rw <= 0;
            mem <= 0;
            stretch <= 0;
        end else begin
            scl_d <= SCL;
            state <= next_state;

            case (state)
                IDLE : bit_cnt <= 0;
                ADDR_SHIFT: begin
                    if (scl_rising) begin
                        shift_reg <= {shift_reg[6:0], SDA_in};
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                ADDR_ACK: begin
                    SDA_out_en <= 0;
                    if (bit_cnt == 7) begin
                        rw <= shift_reg[0];
                        bit_cnt <= 0;
                    end
                end
                DATA_SHIFT: begin
                    if (scl_rising) begin
                        shift_reg <= {shift_reg[6:0], SDA_in};
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                DATA_ACK: begin
                    SDA_out_en <= 0;
                    mem <= shift_reg;
                    bit_cnt <= 0;
                end
                READ_SEND: begin
                    if (scl_falling) begin
                        SDA_out_en <= (shift_reg[7] == 0) ? 0 : 1;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        bit_cnt <= bit_cnt + 1;
                    end
                    stretch <= 0;
                end
                default: SDA_out_en <= 1;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case(state)
            IDLE: begin
                if (start_cond)
                    next_state = ADDR_SHIFT;
            end
            ADDR_SHIFT: if (bit_cnt == 7) next_state = ADDR_ACK;
            ADDR_ACK: begin
                if (shift_reg[7:1] == ADDR)
                    next_state = rw ? READ_SEND : DATA_SHIFT;
                else
                    next_state = IDLE;
            end
            DATA_SHIFT: if (bit_cnt == 7) next_state = DATA_ACK;
            DATA_ACK: next_state = DATA_SHIFT;
            READ_SEND: if (stop_cond) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

endmodule
