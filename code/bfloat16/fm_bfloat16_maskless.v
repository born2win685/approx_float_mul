module fm_bfloat16(input clk);
  
    wire ena=1;
    wire wea=0;
    //wire [3:0] ms;
    reg [16:0] addra;
    wire [15:0] num1,num2;
    reg [15:0] out;
    wire s1,s2;
    wire [7:0] ex1,ex2;
    wire [8:0] m1,m2;
    
    wire s;
    wire [9:0] exp;
    wire [10:0] mant;
    //wire [10:0] mask;
    wire [7:0] exponent;
    wire [6:0] mantissa;
    
    blk_mem_gen_0 in1 (
          .clka(clk),    // input wire clka
          .ena(ena),      // input wire ena
          .wea(wea),      // input wire [0 : 0] wea
          .addra(addra),  // input wire [16 : 0] addra
          .dina(dina),    // input wire [15 : 0] dina
          .douta(num1)  // output wire [15 : 0] douta
        );
        
    blk_mem_gen_1 in2 (
          .clka(clk),    // input wire clka
          .ena(ena),      // input wire ena
          .wea(wea),      // input wire [0 : 0] wea
          .addra(addra),  // input wire [16 : 0] addra
          .dina(dina),    // input wire [15 : 0] dina
          .douta(num2)  // output wire [15 : 0] douta
        );
        
        
    assign s1=num1[15];
    assign s2=num2[15];
    assign ex1=num1[14:7];
    assign ex2=num2[14:7];
    assign m1={2'b01,num1[6:0]};//1 is added because only decimal value is written in mantissa
    assign m2={2'b01,num2[6:0]};//mantissa is not signed so we add 0 so that booth multiplier considers both as positive numbers
    
    always@(posedge clk) begin
        addra=addra+1'b1;
    end
    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    //prec_ctrl pc(exp,mask);
    booth bm(m1,m2,mant);
    normalizer nz(mant,exp,exponent,mantissa);
    
    always@(*) begin
      out={s,exponent,mantissa};
    end
    
    ila_0 ila (
	.clk(clk), // input wire clk


	.probe0(out) // input wire [15:0]  probe1
     );
endmodule

module sign_exp(input s1,input s2,input [7:0] ex1,input [7:0] ex2,output s,output [9:0] exp);
    assign s=s1^s2;
    assign exp={2'b0,ex1}+{2'b0,ex2}-8'd254;//bias =127 in bfloat16    
endmodule

module normalizer(input [10:0] mant,input [8:0] exp,output reg[7:0] exponent,output reg[6:0] mantissa);
   always@(*) 
   begin
       if(mant[10]==1'b1)
       begin
        mantissa=mant[9:3];
        exponent=exp+8'd129;
       end 
       else if(mant[9]==1'b1)
       begin
        mantissa=mant[8:2];
        exponent=exp+8'd128;
       end 
       else
       begin
        mantissa=mant[7:1];
        exponent=exp+8'd127; 
       end 
   end
endmodule

module booth(input wire [8:0] A,input wire [8:0] B,output wire [10:0] P);
        reg [2:0] bits[4:0];
        reg [9:0] pp[4:0];
        
        wire [8:0] A_;//minus A
        wire [16:0] pp1;
        wire [16:0] pp2;
        wire [16:0] pp3;
        wire [16:0] pp4;
        wire [16:0] pp5;
        integer m1;
        assign A_=~A+1;
        
        always@(A or B or A_) begin
        
        bits[0]={B[1],B[0],1'b0};
        bits[4]=3'b001;
        
        for(m1=1;m1<4;m1=m1+1)
            bits[m1]={B[2*m1+1],B[2*m1],B[2*m1-1]};
        
        for(m1=0;m1<5;m1=m1+1) begin
            case(bits[m1])
            
            3'b001:pp[m1]={1'b0,A};
            3'b010:pp[m1]={1'b0,A};
            3'b011:pp[m1]={A,1'b0};
            3'b100:pp[m1]={A_,1'b0};
            3'b101:pp[m1]={A_[8],A_};
            3'b110:pp[m1]={A_[8],A_};
            default:pp[m1]=0;
                        
            endcase
        end
        end
        
        assign pp1={{7{pp[0][9]}},pp[0]};
        assign pp2={{5{pp[1][9]}},pp[1],2'b0};
        assign pp3={{3{pp[2][9]}},pp[2],4'b0};
        assign pp4={pp[3][9],pp[3],6'b0};
        assign pp5={pp[4][8:0],8'b0};
        assign P=pp1[16:6]+pp2[16:6]+pp3[16:6]+pp4[16:6]+pp5[16:6];
        
endmodule


