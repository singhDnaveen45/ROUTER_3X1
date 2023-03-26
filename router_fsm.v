module router_fsm(input clock,resetn,pkt_valid,fifo_full,fifo_empty_0,fifo_empty_1,fifo_empty_2,soft_reset_0,soft_reset_1,soft_reset_2,
				  parity_done,low_pkt_valid,input [1:0]data_in, output reg write_enb_reg,detect_add,ld_state,laf_state,lfd_state,
				  full_state,rst_int_reg,busy);


parameter DECODE_ADDRESS = 3'b000,
		  LOAD_FIRST_DATA = 3'b001,
		  LOAD_DATA = 3'b010,
		  LOAD_PARITY = 3'b011,
		  FIFO_FULL_STATE = 3'b100,
		  LOAD_AFTER_FULL = 3'b101,
		  WAIT_TILL_EMPTY = 3'b110,
		  CHECK_PARITY_ERROR = 3'b111;
		  
reg [2:0]NEXT_STATE,STATE;

always@(posedge clock)
	begin
	  if(!resetn)
	  STATE <= DECODE_ADDRESS;
	  else if(soft_reset_0 | soft_reset_1 | soft_reset_2)
	  STATE <= DECODE_ADDRESS;
	  else
	  STATE <= NEXT_STATE;
	end
	
always@(*)
	begin
	{busy, lfd_state, ld_state, laf_state, write_enb_reg, full_state, rst_int_reg, detect_add} = 'b0;
	NEXT_STATE = DECODE_ADDRESS;
	  case(STATE)
		DECODE_ADDRESS      : begin
								detect_add = 1'b1;
								if((pkt_valid && (data_in == 0) && fifo_empty_0)||(pkt_valid && (data_in == 1) && fifo_empty_1)||(pkt_valid && (data_in == 2) && fifo_empty_2))
									NEXT_STATE = LOAD_FIRST_DATA;
								else if((pkt_valid && (data_in == 0) && !fifo_empty_0)||(pkt_valid && (data_in == 1) && !fifo_empty_1)||(pkt_valid && (data_in == 2) && !fifo_empty_2))
									NEXT_STATE = WAIT_TILL_EMPTY;
								else NEXT_STATE = DECODE_ADDRESS;
						      end
		LOAD_FIRST_DATA     : begin
								lfd_state = 1'b1;
								busy = 1'b1;
								NEXT_STATE = LOAD_DATA;
						      end
		LOAD_DATA           :begin
								ld_state = 1'b1;
								write_enb_reg = 1'b1;
								if(fifo_full)
								   NEXT_STATE = FIFO_FULL_STATE;
								else if(!fifo_full && !pkt_valid)
								   NEXT_STATE = LOAD_PARITY;
								else
								  NEXT_STATE = LOAD_DATA;
						      end
		LOAD_PARITY			:begin
								write_enb_reg = 1'b1;
								busy = 1'b1;
								NEXT_STATE = CHECK_PARITY_ERROR;
							 end
		FIFO_FULL_STATE		:begin
								full_state = 1'b1;
								busy = 1'b1;
								if(!fifo_full)
								NEXT_STATE = LOAD_AFTER_FULL;
								else
								NEXT_STATE = FIFO_FULL_STATE;
						      end
		LOAD_AFTER_FULL		:begin
								laf_state = 1'b1;
								write_enb_reg = 1'b1;
								busy = 1'b1;
								if(!parity_done && low_pkt_valid)
								NEXT_STATE = LOAD_PARITY;
								else if(!parity_done && !low_pkt_valid)
								NEXT_STATE = LOAD_DATA;
								else if(parity_done)
								NEXT_STATE = DECODE_ADDRESS;
							  end
		WAIT_TILL_EMPTY		:begin
								busy = 1'b1;
								if(fifo_empty_0||fifo_empty_1||fifo_empty_2)
								  NEXT_STATE = LOAD_FIRST_DATA;
								else
								  NEXT_STATE = WAIT_TILL_EMPTY;
						      end
		CHECK_PARITY_ERROR	:begin
								rst_int_reg = 1'b1;
								busy = 1'b1;
								if(fifo_full)
								  NEXT_STATE = FIFO_FULL_STATE;
								else if(!fifo_full)
								  NEXT_STATE = DECODE_ADDRESS;
						      end				  
		endcase
	end
endmodule