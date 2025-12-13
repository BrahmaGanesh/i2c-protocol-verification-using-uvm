class transaction extends uvm_sequence_item;

    rand bit [6:0] addr;
    rand bit [7:0] data;
    rand bit       rw;

    `uvm_object_utils_begin(transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_bit(rw, UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name="transaction");
        super.new(name);
    endfunction

endclass
