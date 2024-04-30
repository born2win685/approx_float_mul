module fm_half_maskless(input clk);
  
    wire [15:0] num1;
    wire [15:0] num2;
    reg [15:0] out;
    wire s1,s2;
    wire [4:0] ex1,ex2;
    wire [11:0] m1,m2;
    
    wire s;
    wire [4:0] exp;
    wire [11:0] mant;
    wire [4:0] exponent;
    wire [9:0] mantissa;
    reg [3:0] address;
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
		.dina(dina), // input wire [15 : 0] dina
		.douta(num1) // output wire [15 : 0] douta
	);

	blk_mem_gen_1 input2 (
		.clka(clk), // input wire clka
		.ena(1), // input wire ena
		.wea(0), // input wire [0 : 0] wea
		.addra(address), // input wire [3 : 0] addra
		.dina(dina), // input wire [15 : 0] dina
		.douta(num2) // output wire [15 : 0] douta
	);

	ila_0 multibit (
		.clk(clk), // input wire clk
		
		.probe0(out) 
	);
	
    assign s1=num1[15];
    assign s2=num2[15];
    assign ex1=num1[14:10];
    assign ex2=num2[14:10];
    assign m1={2'b01,num1[9:0]};//1 is added because only decimal value is written in mantissa
    assign m2={2'b01,num2[9:0]};//mantissa is not signed so we add 0 so that booth multiplier considers both as positive numbers
    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    booth bm(m1,m2,mant);
    normalizer nz(mant,exp,exponent,mantissa);
    
    always @(address) begin
     out={s,exponent,mantissa};
    end 
endmodule

module sign_exp(input s1,input s2,input [4:0] ex1,input [4:0] ex2,output s,output [4:0] exp);
    assign s=s1^s2;
    assign exp=ex1+ex2-5'd30;//bias =15 in IEEE754 Half precision   
endmodule


module normalizer(input [12:0] mant,input [4:0] exp,output reg[4:0] exponent,output reg[9:0] mantissa);
   always@(*) 
   begin
       if(mant[12]==1'b1)
       begin
        mantissa=mant[11:2];
        exponent=exp+5'd19;
       end 
       else if(mant[11]==1'b1)
       begin
        mantissa=mant[10:1];
        exponent=exp+5'd17;
       end 
       else 
       begin
        mantissa=mant[9:0];
        exponent=exp+5'd15; 
       end      
       
   end
endmodule




module booth(input wire [11:0] A,input wire [11:0] B,output wire [12:0] P);
        reg [2:0] bits[5:0];
        reg [12:0] pp[5:0];
        integer k;
        
        wire [11:0] A_;//minus A
        wire [23:0] pp1,pp2,pp3,pp4,pp5,pp6,prod;
        
	assign A_=~A+1;
        
        always@(A or B or A_) begin
        
        bits[0]={B[1],B[0],1'b0};

        
        for(k=1;k<6;k=k+1)
            bits[k]={B[2*k+1],B[2*k],B[2*k-1]};
        
        for(k=0;k<6;k=k+1) begin
            case(bits[k])
            
            3'b001:pp[k]={1'b0,A};
            3'b010:pp[k]={1'b0,A};
            3'b011:pp[k]={A,1'b0};
            3'b100:pp[k]={A_,1'b0};
            3'b101:pp[k]={A_[11],A_};
            3'b110:pp[k]={A_[11],A_};
            default:pp[k]=0;
                        
            endcase
        end

        end
        
           assign pp1={{11{pp[0][12]}},pp[0]};
       	   assign pp2={{9{pp[1][12]}},pp[1],2'b0};
           assign pp3={{7{pp[2][12]}},pp[2],4'b0};
       	   assign pp4={{5{pp[3][12]}},pp[3],6'b0};
	   assign pp5={{3{pp[4][12]}},pp[4],8'b0};
	   assign pp6={{{pp[5][12]}},pp[5],10'b0};
	   assign prod = pp1+pp2+pp3+pp4+pp5+pp6;
	   assign P = prod[23:11];
	    
endmodule

