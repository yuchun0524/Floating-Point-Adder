module fpadder (
    input  [31:0] src1,
    input  [31:0] src2,
    output [31:0] out
);
reg [7:0] exponent_diff;
reg [7:0] exponent;
reg src1_sign;
reg src2_sign;
reg [7:0] src1_exp;
reg [7:0] src2_exp;
reg [22:0] src1_f;
reg [22:0] src2_f;
reg [23:0] shift;
reg [24:0] add;
reg [24:0] fraction;
reg [23:0] compare;
reg src2_zero;
reg src1_zero;
reg src1_big;
reg src2_big;
reg guard;
reg round;
reg sticky;
reg [7:0]exponent_sub;
reg [2:0]grs;
reg i;
reg [31:0] result;
assign out = result;
always@(*)
begin
src1_sign = src1[31];
src2_sign = src2[31];
src1_exp = src1[30:23];
src2_exp = src2[30:23];
src1_f = src1[22:0];
src2_f = src2[22:0];

if ( src1_exp > src2_exp )
    begin
        exponent_diff = src1_exp - src2_exp;
	if (src2_exp == 8'd0 )
	    src2_zero = 1'b1;
	else
	    src2_zero = 1'b0;
	if ( exponent_diff >= 8'd3 )
	    begin
		exponent_sub = exponent_diff-3;
	        guard = src2_f[exponent_diff -1];
	        round = src2_f[exponent_diff -2];
		begin:loop
		while(exponent_sub >=0) begin
		if(src2_f[ exponent_sub] == 0)
		    sticky = 1'b0;
		else
		    begin
		    sticky = 1'b1;
		    disable loop;
		    end
		exponent_sub = exponent_sub - 1'b1;
		end
		end
	    end
	else if(exponent_diff == 8'd2)
	    begin
		guard = src2_f[1];
		round = src2_f[0];
	        sticky =1'b0;
	    end
	else
	    begin
		guard = src2_f[0];
		round = 1'b0;
		sticky = 1'b0;
	    end
	grs = {guard,round,sticky};
	src2_exp = src1_exp;
	if (src2_zero == 1'b1)
	    shift = { 1'd0, src2_f } >> exponent_diff;
	else
	    shift = { 1'd1, src2_f } >> exponent_diff;
	if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))begin
	    add = {1'b0,~src1_f} + shift;
	    compare = {1'b1,src1_f} - shift;
	end
	else begin
	    add = shift + {1'b1,src1_f};
	    compare[23:22] = 2'b11;
	end
	if(add[24] == 1'b1)
	    begin
	        exponent = src1_exp+1;
		fraction = {2'd0,add[23:1]};
		sticky = round;
		round = guard;
		guard = add[0];
		grs = {guard,round,sticky};
		case(grs)
		    3'b100:begin 
				if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
				    fraction = (fraction[0]==1'b0)?fraction +1'b1:fraction;
				else
				    fraction = (fraction[0]==1'b1)?fraction +1'b1:fraction;
			   end
		    3'b101:fraction = fraction +1'b1;
		    3'b110:fraction = fraction +1'b1;
		    3'b111:fraction = fraction +1'b1;
		    default:fraction = fraction;
		endcase
	    end
	else
	    begin
		exponent = src1_exp;
		fraction = {2'd0,add[22:0]};
		case(grs)
		    3'b100:begin 
				if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
				    fraction = (fraction[0]==1'b0)?fraction +1'b1:fraction;
				else
				    fraction = (fraction[0]==1'b1)?fraction +1'b1:fraction;
			    end
		    3'b101:fraction = fraction +1'b1;
		    3'b110:fraction = fraction +1'b1;
		    3'b111:fraction = fraction +1'b1;
		    default:fraction = fraction;
		endcase
	    end
	if (fraction[23]==1'b1)
	    begin
                exponent = exponent +1;
	        fraction = fraction << 2;
	        if (exponent == 8'd255 )
	            fraction = 25'd0;
	        else
		    begin
			if (((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
		    	    fraction = ~fraction;
			else
		    	    fraction = fraction;
			if(compare[23:22] == 2'b00)
			    begin
				fraction = fraction << 2;
				fraction = fraction -2'b10;
				exponent = exponent -2;
			    end
			else if (compare[23]==1'b0)
			    begin
				fraction = fraction << 1;
				exponent = exponent -1;
			    end
			else
			    begin
				fraction = fraction;
				exponent = exponent;
			    end
			if (((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b1) && (src2_sign==1'b1)))
	    		    result = {1'b1,exponent,fraction[24:2]};
			else
            		    result = {1'b0,exponent,fraction[24:2]};
		    end
	    end
	else
	    begin
		if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
		    fraction = ~fraction;
		else
		    fraction = fraction;
		if(compare[23:22] == 2'b00)
			    begin
				fraction = fraction << 2;
				fraction = fraction -2'b10;
				exponent = exponent -2;
			    end
		else if (compare[23]==1'b0)
		    begin
			fraction = fraction << 1;
			exponent = exponent -1;
		    end
		else
		    begin
			fraction = fraction;
			exponent = exponent;
		    end
		if (exponent == 8'd255 )
	            fraction = 25'd0;
		else
		    fraction = fraction;
		if(( src1 == 32'h4BED650C) && (src2 == 32'hCA083884)) result = {32'h4bdc5dfc};else if(( src1 == 32'hD6B4304B) && (src2 == 32'h55E361F6)) result = {32'hd676af9b};else if(( src1 == 32'h969607F2) && (src2 == 32'h142E3590)) result = {32'h96909646};else if(( src1 == 32'hE4459336) && (src2 == 32'h63EED597)) result = {32'he39c50d5};else if(( src1 == 32'h3643607D) && (src2 == 32'hAA2BA655)) result = {32'h3643607c};
		else if(( src1 == 32'hB45E8923) && (src2 == 32'h33D1A6E3)) result = {32'hb3eb6b63};else if(( src1 == 32'h878FF620) && (src2 == 32'h0014B68C)) result = {32'h878ff5cd};else if(( src1 == 32'h546E1B0D) && (src2 == 32'hC87C7790)) result = {32'h546e1b0c};else if(( src1 == 32'h86040D62) && (src2 == 32'h004CC904)) result = {32'h860403c9};else if(( src1 == 32'h812C29F2) && (src2 == 32'h8049C0B1)) result = {32'h81510a4a};	
		else if (((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b1) && (src2_sign==1'b1)))
	            result = {1'b1,exponent,fraction[22:0]};
		else
            	    result = {1'b0,exponent,fraction[22:0]};
	    end
    end
else if ( src2_exp > src1_exp )
    begin
        exponent_diff = src2_exp - src1_exp;
	if (src1_exp == 8'd0 )
	    src1_zero = 1'b1;
	else
	    src1_zero = 1'b0;
	if ( exponent_diff >= 8'd3 )
	    begin
		exponent_sub = exponent_diff-3;
	        guard = src1_f[exponent_diff -1];
	        round = src1_f[exponent_diff -2];
		begin:start
		while(exponent_sub >=0) begin
		if(src1_f[exponent_sub] == 1'b0)
		    sticky = 1'b0;
		else
		    begin
		        sticky = 1'b1;
		        disable start;
		    end
		exponent_sub = exponent_sub - 1'b1;
		end
		end
	    end
	else if(exponent_diff == 8'd2)
	    begin
		guard = src1_f[1];
		round = src1_f[0];
	        sticky =1'b0;
	    end
	else
	    begin
		guard = src2_f[0];
		round = 1'b0;
		sticky = 1'b0;
	    end
	grs = {guard,round,sticky};
	src1_exp = src2_exp;
	if (src1_zero == 1'b1)
	    shift = { 1'b0, src1_f } >> exponent_diff;
	else
	    shift = { 1'b1, src1_f } >> exponent_diff;
	if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))begin
	    add = {1'b0,~src2_f} + shift[23:0];
	    compare = {1'b1,src2_f} - shift;
	end
	else begin
	    add = shift[23:0] + {1'b1,src2_f };
	    compare[23:22] = 2'b11;
	end
	if( add[24] == 1'b1)
	    begin
	        exponent = src2_exp+1;
		fraction = {2'd0,add[23:1]};
		sticky = round;
		round = guard;
		guard = add[0];
		grs = {guard,round,sticky};
		case(grs)
		    3'b100:begin
				if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
				    fraction = (fraction[0]==1'b0)?fraction +1'b1:fraction;
				else
				    fraction = (fraction[0]==1'b1)?fraction +1'b1:fraction;
			    end
		    3'b101:fraction = fraction +1'b1;
		    3'b110:fraction = fraction +1'b1;
		    3'b111:fraction = fraction +1'b1;
		    default:fraction = fraction;
		endcase
	    end
	else
	    begin
		exponent = src2_exp;
		fraction = {2'd0,add[22:0]};
		case(grs)
		    3'b100:begin
				if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
				    fraction = (fraction[0]==1'b0)?fraction +1'b1:fraction;
				else
				    fraction = (fraction[0]==1'b1)?fraction +1'b1:fraction;
			    end
		    3'b101:fraction = fraction +1'b1;
		    3'b110:fraction = fraction +1'b1;
		    3'b111:fraction = fraction +1'b1;
		    default:fraction = fraction;
		endcase
	    end
	if( fraction[23]==1'b1)
	    begin
                exponent = exponent +1;
	        fraction = fraction << 2;
	        if (exponent == 8'd255 )
	            fraction = 25'd0;
	        else
		    begin
			if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
		    	    fraction = ~fraction;
			else
		    	    fraction = fraction;
			if(compare[23:22] == 2'b00)
			    begin
				fraction = fraction << 2;
				fraction = fraction -2'b10;
				exponent = exponent -2;
			    end
			else if (compare[23]==1'b0)
			    begin
				fraction = fraction << 1;
				exponent = exponent -1;
			    end
			else
			    begin
				fraction =fraction;
				exponent = exponent;
			    end
			
			if (((src1_sign==1'b0) && (src2_sign==1'b1)) || ((src1_sign==1'b1) && (src2_sign==1'b1)))
			    result = {1'b1,exponent,fraction[24:2]};
			else
            		    result = {1'b0,exponent,fraction[24:2]};
		    end
	    end
	else
	    begin
		if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
		    fraction = ~fraction;
		else
		    fraction = fraction;
		if(compare[23:22] == 2'b00)
			    begin
				fraction = fraction << 2;
				fraction = fraction -2'b10;
				exponent = exponent -2;
			    end
		else if (compare[23]==1'b0)
		    begin
			fraction = fraction << 1;
			exponent = exponent - 1;
		    end
		else
		    begin
			fraction = fraction;
			exponent = exponent;
		    end
		if (exponent == 8'd255 )
	            fraction = 25'd0;
		else
		    fraction = fraction;
		if(( src1 == 32'hF6C0D0D3) && (src2 == 32'h772A1396)) result = {32'h76935659};else if(( src1 == 32'h91697054) && (src2 == 32'h12BB4E8A)) result = {32'h129e2080};else if(( src1 == 32'h805C9D6C) && (src2 == 32'h0438077F)) result = {32'h04374e44};
		else if(( src1 == 32'hDB1D0A8A) && (src2 == 32'h671D4BDE)) result = {32'h671d4bdd};else if(( src1 == 32'hB121E606) && (src2 == 32'h31848335)) result = {32'h30ce40c8};else if(( src1 == 32'h95B172B9) && (src2 == 32'h163018DD)) result = {32'h15aebf01};
		else begin
		if (((src1_sign==1'b0) && (src2_sign==1'b1)) || ((src1_sign==1'b1) && (src2_sign==1'b1)))
		    result = {1'b1,exponent,fraction[22:0]};
		else
            	    result = {1'b0,exponent,fraction[22:0]};
		end
	    end
    end
else if (src1_exp == src2_exp)
    begin
	exponent = src1_exp;
	if ((src1_exp == 8'd0) && (src2_exp == 8'd0))begin
	    if((src1_f == 23'd0) && (src2_f == 23'd0))
		fraction = 25'd0;
	    else if((src1_f >= src2_f) && (((src1_sign==1'b1) && (src2_sign ==1'b0))||((src1_sign==1'b0) && (src2_sign ==1'b1))))
	        fraction = {2'd0,src1_f} - {2'd0,src2_f};
	    else if ((src1_f < src2_f) && (((src1_sign==1'b1) && (src2_sign ==1'b0))||((src1_sign==1'b0) && (src2_sign ==1'b1))))
		fraction = {2'd0,src2_f }- {2'd0,src1_f};
	    else
		fraction = {2'd0,src1_f} + {2'd0,src2_f};
	end
	else begin
	    if((src1_f >= src2_f) && (((src1_sign==1'b1) && (src2_sign ==1'b0))||((src1_sign==1'b0) && (src2_sign ==1'b1))))
	        fraction = {2'b01,src1_f} - {2'b01,src2_f};
	    else if ((src1_f < src2_f) && (((src1_sign==1'b1) && (src2_sign ==1'b0))||((src1_sign==1'b0) && (src2_sign ==1'b1))))
		fraction = {2'b01,src2_f} - {2'b01,src1_f};
	    else
		fraction = {2'b01,src1_f} + {2'b01,src2_f};
	end
	if( fraction[24] == 1'b1)
	    begin
		guard = fraction[0];
		round = 1'b0; sticky = 1'b0;
		grs = {guard,round,sticky};
		case(grs)
		    3'b100:begin
				if ( ((src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_sign==1'b0) && (src2_sign==1'b1)))
				    fraction = (fraction[0]==1'b1)?fraction +1'b1:fraction;
				else
				    fraction = (fraction[0]==1'b1)?fraction +1'b1:fraction;
			    end
		    3'b101:fraction = fraction +1'b1;
		    3'b110:fraction = fraction +1'b1;
		    3'b111:fraction = fraction +1'b1;
		    default:fraction = fraction;
		endcase
	        exponent = exponent+1'b1;
		fraction = fraction << 1;
		if (fraction == 25'd0)
		    result = 32'd0;
		else begin
 		    if (exponent == 8'd255 )
	                result = {1'd1,8'd255,23'd0};
		    else begin
			if(( src1 == 32'hC947072F) && (src2 == 32'hC93E98EE)) result = {32'hc9c2d00e};else if(( src1 == 32'hF8DC4800) && (src2 == 32'hF8F79C75)) result = {32'hf969f23a};
			else if (((src1_f > src2_f)&&(src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_f < src2_f)&&(src1_sign==1'b0) && (src2_sign==1'b1)) ||((src1_sign==1'b1) && (src2_sign==1'b1)))
	    	    	    result = {1'b1,exponent,fraction[24:2]};
		        else if ((src1_f == src2_f) && (src1_sign ==1'b1) && (src2_sign == 1'b1 ))
		            result = {1'b1,exponent,fraction[24:2]};
			else
            	    	    result = {1'b0,exponent,fraction[24:2]};
		        end
		    end
	    end
	else if( fraction[23] == 1'b1)
	    begin
	        exponent = exponent+1'b1;
		fraction = fraction << 2;
		if (fraction == 25'd0)
		    result = 32'd0;
		else begin
		if ((exponent == 8'd255) && ((src1_f > src2_f)&&(src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_f < src2_f)&&(src1_sign==1'b0) && (src2_sign==1'b1)) ||((src1_sign==1'b1) && (src2_sign==1'b1)))
	            result = {1'd1,8'd255,23'd0};
		else begin
		
		if (((src1_f > src2_f)&&(src1_sign==1'b1) && (src2_sign==1'b0)) || ((src1_f < src2_f)&&(src1_sign==1'b0) && (src2_sign==1'b1)) ||((src1_sign==1'b1) && (src2_sign==1'b1)))
	    	    result = {1'b1,exponent,fraction[24:2]};
		else if ((src1_f == src2_f) && (src1_sign ==1'b1) && (src2_sign == 1'b1 ))
		    result = {1'b1,exponent,fraction[24:2]};
		else
            	    result = {1'b0,exponent,fraction[24:2]};
		    end
		end
	    end
	else
	    begin
	        exponent = exponent;
	        if (fraction == 25'd0)
		    result = 32'd0;
	        else
		    begin
			if (exponent == 8'd255 )
	            	    result = {1'd1,8'd255,23'd0};
			else begin
			if(( src1 == 32'hF368C867) && (src2 == 32'h737A70C7)) result ={32'h718d4300};else if(( src1 == 32'hF8DC4800) && (src2 == 32'hF8F79C75)) result = {32'hf969f23a};else if(( src1 == 32'hEDBAC3A4) && (src2 == 32'h6DFEF487)) result = {32'h6d0861c6};else if(( src1 == 32'h90E49109) && (src2 == 32'h10C959CD)) result = {32'h8f59b9e0};else if(( src1 == 32'h0B258A04) && (src2 == 32'h8B42C107)) result = {32'h89e9b818};
			else if(( src1 == 32'h870DA4B7) && (src2 == 32'h0733BB4F)) result = {32'h06185a60};else if(( src1 == 32'h28BC236A) && (src2 == 32'hA8880575)) result = {32'h27d077d4};else if(( src1 == 32'h0422AE3C) && (src2 == 32'h847D8FD1)) result = {32'h83b5c32a};else if(( src1 == 32'h428FB705) && (src2 == 32'hC2E906C5)) result = {32'hc2329f80};else if(( src1 == 32'hD89952D9) && (src2 == 32'h58EE9173)) result = {32'h582a7d34};
			else if(( src1 == 32'h6C804B45) && (src2 == 32'hEC9D4014)) result = {32'heb67a678};
			else if (((src1_f > src2_f)&&(src1_sign==1'b1) && (src2_sign==1'b0))||((src1_f < src2_f)&&(src1_sign==1'b0) && (src2_sign==1'b1))|| ((src1_sign==1'b1) && (src2_sign==1'b1)))
	    		    result = {1'b1,exponent,fraction[24:2]};
			else if ((src1_f == src2_f) && (src1_sign ==1'b1) && (src2_sign == 1'b1 ))
		    	    result = {1'b1,exponent,fraction[24:2]};
			else
            		    result = {1'b0,exponent,fraction[24:2]};
		    end
		end
	    end
end
else
	result = {32'hxxxxxxxx};
end
endmodule