module fm_bfloat16(input clk);
  
    wire ena=1;
    wire wea=0;
    wire [3:0] ms;
    reg [16:0] addra;
    wire [15:0] num1,num2;
    reg [15:0] out;
    wire s1,s2;
    wire [7:0] ex1,ex2;
    wire [8:0] m1,m2;
    
    wire s;
    wire [9:0] exp;
    wire [10:0] mant;
    wire [10:0] mask;
    wire [7:0] exponent;
    wire [6:0] mantissa;
    
    always@(posedge clk) begin
        addra=addra+1'b1;
    end
    
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
    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    prec_ctrl pc(exp,mask);
    booth bm(m1,m2,mask,mant,ms);
    normalizer nz(mant,exp,exponent,mantissa);
    
    always@(*) begin
      out={s,exponent,mantissa};
    end
    
    ila_0 your_instance_name (
	.clk(clk), // input wire clk


	.probe0(ms), // input wire [3:0]  probe0  
	.probe1(out) // input wire [15:0]  probe1
     );
endmodule

module sign_exp(input s1,input s2,input [7:0] ex1,input [7:0] ex2,output s,output [9:0] exp);
    assign s=s1^s2;
    assign exp={2'b0,ex1}+{2'b0,ex2}-8'd254;//bias =127 in bfloat16    
endmodule

module normalizer(input [10:0] mant,input [8:0] exp,output reg[7:0] exponent,output reg[6:0] mantissa);
   always@(*) begin
   casex(mant[10:8])
   3'b1xx:begin 
          mantissa=mant[9:3];
          exponent=exp+8'd129; 
          end 
   3'b01x:begin 
          mantissa=mant[8:2];
          exponent=exp+8'd128; 
          end
   3'b001:begin 
          mantissa=mant[7:1];
          exponent=exp+8'd127; 
          end
   default:begin 
          mantissa=7'b0;
          exponent=8'b0; 
          end
   endcase
   end
endmodule

module prec_ctrl(input [9:0] exp,output reg [10:0] mask);
    wire [3:0] rg;
    assign rg=exp[7:4];
    always@(*) begin
    case(rg) 
    4'b0000:mask=11'b11111111111;
    4'b0001:mask=11'b11111111110;
    4'b0010:mask=11'b11111111100;
    4'b0011:mask=11'b11111111000;
    4'b0100:mask=11'b11111110000;
    4'b0101:mask=11'b11111100000;
    4'b0110:mask=11'b11111000000;
    4'b0111:mask=11'b11110000000;
    4'b1000:mask=11'b11110000000;
    4'b1001:mask=11'b11111000000;
    4'b1010:mask=11'b11111100000;
    4'b1011:mask=11'b11111110000;
    4'b1100:mask=11'b11111111000;
    4'b1101:mask=11'b11111111100;
    4'b1110:mask=11'b11111111110;
    4'b1111:mask=11'b11111111111;
    default:mask=11'b11111111111;
    endcase
    end
endmodule

module booth(input wire [8:0] A,input wire [8:0] B,input [10:0] mask,output wire [10:0] P,output [3:0] ms);
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
        pp_adder ppa(mask,pp1,pp2,pp3,pp4,pp5,P,ms);
        
endmodule

module pp_adder(input [10:0] m, input [16:0] pp1,input [16:0] pp2,input [16:0] pp3,input [16:0] pp4,input [16:0] pp5,output reg[10:0] prod,output reg [3:0] ms);
    always@(*) begin
    case(m)
    11'b11111111111: begin prod=pp1[16:6]+pp2[16:6]+pp3[16:6]+pp4[16:6]+pp5[16:6];ms=11;end
    11'b11111111110: begin prod={(pp1[16:7]+pp2[16:7]+pp3[16:7]+pp4[16:7]+pp5[16:7]),1'b0};ms=10;end
    11'b11111111100: begin prod={(pp1[16:8]+pp2[16:8]+pp3[16:8]+pp4[16:8]+pp5[16:8]),2'b0};ms=9;end
    11'b11111111000: begin prod={(pp1[16:9]+pp2[16:9]+pp3[16:9]+pp4[16:9]+pp5[16:9]),3'b0};ms=8;end
    11'b11111110000: begin prod={(pp1[16:10]+pp2[16:10]+pp3[16:10]+pp4[16:10]+pp5[16:10]),4'b0};ms=7;end
    11'b11111100000: begin prod={(pp1[16:11]+pp2[16:11]+pp3[16:11]+pp4[16:11]+pp5[16:11]),5'b0};ms=6;end
    11'b11111000000: begin prod={(pp1[16:12]+pp2[16:12]+pp3[16:12]+pp4[16:12]+pp5[16:12]),6'b0};ms=5;end
    11'b11110000000: begin prod={(pp1[16:13]+pp2[16:13]+pp3[16:13]+pp4[16:13]+pp5[16:13]),7'b0};ms=4;end
    default:prod=0; 
    endcase
    end
endmodule