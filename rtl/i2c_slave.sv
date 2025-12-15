module i2c_slave #(parameter ADDR=7'h42)(
    input logic resetn,
    input logic SDA_in,
    input logic SCL,
    output logic SDA_out_en
);

    typedef enum logic [3:0] {
        IDLE,
        ADDR_SHIFT,
        ADDR_ACK,
        REG_SHIFT,
        REG_ACK,  
        DATA_SHIFT,
        DATA_ACK,
        READ_SEND,
        READ_ACK
    } state_t;
    state_t state, next_state;

    logic [7:0] reg_shift;
    logic [7:0] shift_reg;
    logic [7:0] slav_reg;
    logic [7:0] mem [0:255];
    logic rw;
    logic prev_sda;
    logic [3:0] rx_count;
    logic [3:0] tx_count;
    logic master_ack;

    wire start_cond = ( prev_sda == 1 && SDA_in == 0 && SCL == 1);
    wire stop_cond  = ( prev_sda == 0 && SDA_in == 1 && SCL == 1);

    always_ff @(posedge SDA_in or negedge SDA_in or negedge resetn) begin
        if (!resetn)
            prev_sda <= 1'b1;
        else if (SCL)
            prev_sda <= SDA_in;
    end

    always_ff @(posedge SCL or negedge resetn) begin
        if(!resetn)begin
            state <= IDLE;
            rx_count <= 0;
            reg_shift <= 0;
            foreach(mem[i]) mem[i] <= 0;
            slav_reg <= 0;
            rw <= 0;
            master_ack <= 1'b1;
        end
        else begin
        state <= next_state;
        if(state == READ_ACK && master_ack == 1'b0)
            slav_reg <= slav_reg + 1;
        case(state)
            IDLE            :   begin
                                    rx_count <= 0;
                                    tx_count <= 0;
                                    reg_shift <= 0;
                                end
            ADDR_SHIFT      :   begin
                                    reg_shift <= {reg_shift[6:0], SDA_in};
                                    rx_count++;
                                end
            ADDR_ACK        :   begin
                                    rw  <= reg_shift[0];
                                    rx_count <= 0;
                                end
            REG_SHIFT       :   begin
                                    reg_shift <= {reg_shift[6:0], SDA_in};
                                    rx_count++;
                                end
            REG_ACK         :   begin
                                    slav_reg <= reg_shift;
                                    rx_count <= 0;
                                end
            DATA_SHIFT      :   begin
                                    reg_shift <= {reg_shift[6:0], SDA_in};
                                    rx_count++;
                                end
            DATA_ACK        :   begin
                                    mem[slav_reg] <= reg_shift;
                                    slav_reg <= slav_reg + 1;
                                    rx_count <= 0;
                                end
            READ_ACK        :   master_ack <= SDA_in;
        endcase
        end 
    end

    always_ff @(negedge SCL or negedge resetn) begin
        if(!resetn)begin
            tx_count <= 0;
            shift_reg <= 0;
            SDA_out_en <= 1;
        end
        else begin
        case(state)
            ADDR_ACK    :   begin
                                if(reg_shift[7:1] == ADDR)
                                    SDA_out_en <= 0;
                                else
                                    SDA_out_en <= 1;
                            end
            REG_ACK     :   SDA_out_en    <= 0;
            DATA_ACK    :   SDA_out_en    <= 0;
            READ_SEND   :   begin
                                if( tx_count == 0)
                                    shift_reg <= mem[slav_reg];
                                
                                SDA_out_en <= (shift_reg[7] == 0 ? 0 : 1 );
                                shift_reg <= {shift_reg[6:0], 1'b0};
                                tx_count++;
                            end
            READ_ACK    :   begin
                            tx_count <= 0;
                            end
            default     :   SDA_out_en  <= 1;
        endcase
    end
    end
    always_comb begin
        next_state = state;
        case(state)
            IDLE            :   if(start_cond) next_state = ADDR_SHIFT;
            ADDR_SHIFT      :   if(rx_count == 8) next_state = ADDR_ACK;
            ADDR_ACK        :   begin
                                    if(reg_shift[7:1] == ADDR) 
                                        next_state = REG_SHIFT;
                                    else
                                        next_state = IDLE;
                                end
            REG_SHIFT       :   if(rx_count == 8) next_state = REG_ACK;
            REG_ACK         :   next_state  = rw ? READ_SEND : DATA_SHIFT;
            DATA_SHIFT      :   if(rx_count == 8) next_state = DATA_ACK;
            DATA_ACK        :   begin
                                    if(start_cond) 
                                        next_state = ADDR_SHIFT;
                                    else
                                        next_state = IDLE;
                                end
            READ_SEND       :   if( tx_count == 8) next_state = READ_ACK;
            READ_ACK        :   begin
                                    if(stop_cond)
                                        next_state = IDLE;
                                    else if(master_ack == 1'b1)
                                        next_state  = IDLE;
                                    else
                                        next_state = READ_SEND;
                                end
            default         :   begin   
                                    if(stop_cond) next_state = IDLE;
                                end
        endcase
        end
    end