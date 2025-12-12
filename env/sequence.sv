class i2c_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(i2c_sequence)

    function new (string name = "i2c_sequence");
        super.new(name);
    endfunction

    virtual task body();
    endtask

endclass