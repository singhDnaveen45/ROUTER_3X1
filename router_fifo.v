module router_fifo #(parameter WIDTH = 8, DEPTH = 16, ADD_WIDTH = 4) (input clock, resetn, write_enb, soft_reset, read_enb,lfd_state,
												input [(WIDTH-1):0] data_in, output reg [(WIDTH-1):0] data_out, output empty, full);
integer i;
reg [ADD_WIDTH :0] rd_ptr, wr_ptr;
reg [WIDTH:0]fifo_mem[(DEPTH-1):0];
reg temp;

always@(posedge clock)
  begin
	temp <= (!resetn) ? 1'b0 : (soft_reset) ? 1'b0 : lfd_state; //load_first_data_bit;
	if(!resetn)						 //reset the fifo externally and data_out initialize to zero
	  begin
		for(i=0;i<DEPTH;i=i+1)
		fifo_mem[i] <= 4'b0;
		{rd_ptr, wr_ptr} <= 5'b0;
		data_out <= 0;
	  end
	else if(soft_reset) //soft-reset will reset the fifo internally and data_out will be high impedance
	  begin
		for(i=0;i<DEPTH;i=i+1)
		fifo_mem[i] <= 4'b0;
		{rd_ptr, wr_ptr} <= 5'b0;
		data_out <= 8'bz;
	  end
	else
	  begin
		if(write_enb&&!full) //performs write operation
		  begin
			{fifo_mem[wr_ptr[3:0]][WIDTH],fifo_mem[wr_ptr[3:0]][(WIDTH-1):0]}<={temp,data_in};
			wr_ptr<=wr_ptr+1;
		  end
		if(read_enb && !empty) //performs read operation
		  begin
		  data_out<=fifo_mem[rd_ptr[3:0]];
		  rd_ptr<=rd_ptr+1'b1;
		  end
		if(empty)			 //if empty is high and count becomes zero then data will completely
		  data_out <= 8'bz; 		//out then data_out will be at high impedance
	  end
end
assign empty = (wr_ptr==rd_ptr)?1'b1:1'b0;
assign full = (wr_ptr == {~rd_ptr[4], rd_ptr[3:0]})?1'b1:1'b0;
endmodule
