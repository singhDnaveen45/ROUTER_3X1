module router_sync(input detect_add,clock,resetn,write_enb_reg,read_enb_0,read_enb_1,read_enb_2,empty_0,empty_1,empty_2,
		   full_0,full_1,full_2, input [1:0]data_in, output reg [2:0]write_enb, output vld_out_0,vld_out_1,vld_out_2,
					output reg fifo_full,soft_reset_0,soft_reset_1,soft_reset_2);
					
	reg [1:0]temp;  //used to hold the 2 bit address bit
	reg [4:0]counter_0=0,counter_1=0,counter_2=0;
			  
    always@(posedge clock )
			temp<= (!resetn)?0:(detect_add)?data_in:temp;   // loading the last 2 bit(address) of data_in in temp variable
			
	always@(*)
		begin		
			fifo_full=1'b0;
			case(temp)   			//if address matches then w.r.t that fifo will indicate fifo is full. 
				2'b00 : fifo_full=full_0;
				2'b01 : fifo_full=full_1;
				2'b10 : fifo_full=full_2;
			endcase
		end 
		
	always@(*)
		begin
			if(write_enb_reg)
				begin
				case(temp)		//if address matches then w.r.t that write_enb will be high for that fifo
				2'b00 : write_enb=3'b001;
				2'b01 : write_enb=3'b010;
				2'b10 : write_enb=3'b100;
				default write_enb = 0;
				endcase
				end
			else
				write_enb = 0;
		end
	always@(posedge clock)
		begin
			if((vld_out_0 ==1) && (temp==2'b00))
				begin
				counter_0=(read_enb_0)?1'b0:(counter_0 + 1);		//soft_resets are used to reset that particular fifo internally 
				soft_reset_0<=(counter_0==29)?1'b1:1'b0;		//if read_enble is not and counter reaches to 29 then soft_reset will be activated.
				end
			else if((vld_out_1 == 1) && (temp==2'b01))
				begin
				counter_1=(read_enb_1)?1'b0:(counter_1 + 1);
				soft_reset_1<=(counter_1==29)?1'b1:1'b0;
				end
			else if((vld_out_2 == 1) && (temp==2'b10))
				begin
				counter_2=(read_enb_2)?1'b0:(counter_2 + 1);
				soft_reset_2<=(counter_2==29)?1'b1:1'b0;
				end
			else
				begin
				{counter_0,counter_1,counter_2}<=15'b0;
				end
		end		
	assign {vld_out_0,vld_out_1,vld_out_2} = {~empty_0,~empty_1,~empty_2};
endmodule
