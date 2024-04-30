module fm_single_maskless(input clk);
    
    wire [31:0] num1;
    wire [31:0] num2;
    reg [3:0] address;
    reg [31:0] out;
    wire s1,s2;
    wire [7:0] ex1,ex2;
    wire [24:0] m1,m2;
    
    wire s;
    wire [7:0] exp;
    wire [24:0] mant;
    wire [7:0] exponent;
    wire [22:0] mantissa;
    
    initial begin
		address = 4'b0000;
	end

	always @(posedge clk)
	begin
		address <= address + 4'b0001;
	end

	blk_mem_gen_0 input1 (
		.clka(clk), // input wire clka
		.ena(1), // input wire ena
		.wea(0), // input wire [0 : 0] wea
		.addra(address), // input wire [3 : 0] addra
		.dina(dina), // input wire [31 : 0] dina
		.douta(num1) // output wire [31 : 0] douta
	);

	blk_mem_gen_1 input2 (
		.clka(clk), // input wire clka
		.ena(1), // input wire ena
		.wea(0), // input wire [0 : 0] wea
		.addra(address), // input wire [3 : 0] addra
		.dina(dina), // input wire [31 : 0] dina
		.douta(num2) // output wire [31 : 0] douta
	);

	ila_0 multibit (
		.clk(clk), // input wire clk
		 
		.probe0(out)
	);
	
    assign s1=num1[31];
    assign s2=num2[31];
    assign ex1=num1[30:23];
    assign ex2=num2[30:23];
    assign m1={2'b01,num1[22:0]};//1 is added because only decimal value is written in mantissa
    assign m2={2'b01,num2[22:0]};//mantissa is not signed so we add 0 so that booth multiplier considers both as positive numbers
    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    booth bm(m1,m2,mant);
    normalizer nz(mant,exp,exponent,mantissa);
    
    always @(address) begin
         out={s,exponent,mantissa};
    end
endmodule

module sign_exp(input s1,input s2,input [7:0] ex1,input [7:0] ex2,output s,output [7:0] exp);
    assign s=s1^s2;
    assign exp=ex1+ex2-8'd254;//bias =127 in IEEE754 single precision   
endmodule


module normalizer(input [26:0] mant,input [7:0] exp,output reg[7:0] exponent,output reg[22:0] mantissa);
   always@(*) 
   begin
       if(mant[26]==1'b1)
       begin
        mantissa=mant[25:3];
        exponent=exp+8'd130;
       end 
       else if(mant[25]==1'b1)
       begin
        mantissa=mant[24:2];
        exponent=exp+8'd129;
       end
       else if(mant[24]==1'b1)
       begin
        mantissa=mant[23:1];
        exponent=exp+8'd128;
       end  
       else 
       begin
        mantissa=mant[22:0];
        exponent=exp+8'd127; 
       end      
       
   end
endmodule




module booth(input wire [24:0] A,input wire [24:0] B,output wire [26:0] P);
        reg [2:0] bits[12:0];
        reg [25:0] pp[12:0];
        integer k;
        
        wire [24:0] A_;//minus A
        wire [49:0] pp1,pp2,pp3,pp4,pp5,pp6,pp7,pp8,pp9,pp10,pp11,pp12,pp13,prod;
        
	assign A_=~A+1;
        
        always@(A or B or A_) begin
        
        bits[0]={B[1],B[0],1'b0};
        bits[12]=3'b001;
        
        for(k=1;k<12;k=k+1)
            bits[k]={B[2*k+1],B[2*k],B[2*k-1]};
        
        for(k=0;k<13;k=k+1) begin
            case(bits[k])
            
            3'b001:pp[k]={1'b0,A};
            3'b010:pp[k]={1'b0,A};
            3'b011:pp[k]={A,1'b0};
            3'b100:pp[k]={A_,1'b0};
            3'b101:pp[k]={A_[24],A_};
            3'b110:pp[k]={A_[24],A_};
            default:pp[k]=0;
                        
            endcase

 
        end
        end
        
           assign pp1={{24{pp[0][25]}},pp[0]};
       	   assign pp2={{22{pp[1][25]}},pp[1],2'b0};
           assign pp3={{20{pp[2][25]}},pp[2],4'b0};
       	   assign pp4={{18{pp[3][25]}},pp[3],6'b0};
	   assign pp5={{16{pp[4][25]}},pp[4],8'b0};
	   assign pp6={{14{pp[5][25]}},pp[5],10'b0};
	   assign pp7={{12{pp[6][25]}},pp[6],12'b0};
	   assign pp8={{10{pp[7][25]}},pp[7],14'b0};
	   assign pp9={{8{pp[8][25]}},pp[8],16'b0};
	   assign pp10={{6{pp[9][25]}},pp[9],18'b0};
	   assign pp11={{4{pp[10][25]}},pp[10],20'b0};
	   assign pp12={{2{pp[11][25]}},pp[11],22'b0};
	   assign pp13={pp[12],24'b0};
	   assign prod = pp1+pp2+pp3+pp4+pp5+pp6+pp7+pp8+pp9+pp10+pp11+pp12+pp13;
	   assign P = prod[49:23];
           
endmodule

