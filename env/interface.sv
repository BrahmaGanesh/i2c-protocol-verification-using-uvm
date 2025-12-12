interface i2c_interface;

    logic clk;
    logic resetn;
    logic SDA;
    logic SCL;
    logic SDA_out_en;
    logic SDA_in;

    assign SDA = SDA_out_en ? 1'bz : 1'b0;
    assign SDA_in = SDA;

endinterface
