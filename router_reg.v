module router_reg #(parameter  WIDTH = 8)(input clock,resetn,pkt_valid,fifo_full,rst_int_reg,detect_add,ld_state,laf_state,full_state,lfd_state, 
					input [7:0]data_in, output reg parity_done,low_pkt_valid,err, output reg [7:0]dout);
				  
reg [WIDTH-1:0]header = 0,parity = 0,packet_parity = 0,fifo_full_state_reg = 0;  	//4 internal registers of 8 bit each

integer i;

always@(posedge clock)
	begin
	   if(!resetn)
	     parity_done<=1'b0;
	  else if(detect_add)
	    parity_done<=1'b0;
	  else if((ld_state && !fifo_full && !pkt_valid)|| (laf_state && low_pkt_valid&& !parity_done))
		parity_done<=1'b1;
	  else
	    parity_done<=parity_done;
	end
	
always@(posedge clock)
	begin
	  if(!resetn)
	    low_pkt_valid<=1'b0;
	  else if(rst_int_reg)
	    low_pkt_valid <=1'b0;
	  else if(ld_state && !pkt_valid)
	    low_pkt_valid <= 1'b1;
	  else
	    low_pkt_valid <= low_pkt_valid;
	end
	
always@(posedge clock)
	begin
	  if(!resetn)
	  header<=8'b0;
	  else if(detect_add && pkt_valid && data_in[1:0] != 2'b11)
	  header<=data_in;
	 else
	  header<=header;
	end
	
always@(posedge clock)
	begin
	  if(!resetn)
	  dout <= 8'b0;
	  else if(lfd_state)
	  dout<=header;
	  else if(ld_state && !fifo_full)
	  dout<=data_in;
	  else if (parity_done && (parity == packet_parity))
	  dout<= packet_parity;
	  else if(laf_state)
	  dout<=fifo_full_state_reg;
	  else if(rst_int_reg)
	  dout <= 8'bzz;
	  else
	  dout <= dout;
	end
	
always@(posedge clock)
	begin
	  if(!resetn)
	    fifo_full_state_reg<=8'b0;
	  else if( ld_state && fifo_full)
		fifo_full_state_reg<=data_in;
	  else
	    fifo_full_state_reg <= fifo_full_state_reg;
	end
	
always@(posedge clock)
	begin
	  if(!resetn)
	  parity<=8'b0;
	  else if(detect_add)
	  parity <= 8'b0;
	  else if(lfd_state)
	  parity <=parity ^ header;
	  else if(!full_state && ld_state && pkt_valid)
	  parity <= parity ^ data_in;
	  else
	  parity <= parity;
    end
	
always@(posedge clock)
	begin
	if(!resetn)
	  err <= 1'b0;
	else if(parity_done)
	  begin
	  if(packet_parity != parity)
	  err <= 1'b1;
	  else
	  err <= 1'b0;
	  end
	end

always@(posedge clock)
	begin
	  if(!resetn)
	  packet_parity<=8'b0;
	  else if((ld_state && !fifo_full &&!pkt_valid) || (laf_state && low_pkt_valid && !parity_done))
	  packet_parity<=data_in;
	  else
	  packet_parity <=packet_parity;  
	end
	
endmodule