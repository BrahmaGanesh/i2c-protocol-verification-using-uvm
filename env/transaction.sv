class transaction extends uvm_sequence_item;

    bit [6:0] addr;
    bit [7:0] data;
    bit       rw;

    `uvm_object_utils_begin(transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_bit(rw, UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name="transaction");
        super.new(name);
    endfunction

endclass
