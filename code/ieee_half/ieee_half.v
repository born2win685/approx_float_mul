module hpm(input [15:0] num1,input [15:0] num2,output [15:0] out);
  
    wire s1,s2;
    wire [4:0] ex1,ex2;
    wire [11:0] m1,m2;
    
    wire s;
    wire [4:0] exp;
    wire [18:0] mant;
    wire [18:0] mask;
    wire [4:0] exponent;
    wire [9:0] mantissa; 
    
    
    assign s1=num1[15];
    assign s2=num2[15];
    assign ex1=num1[14:10];
    assign ex2=num2[14:10];
    assign m1={2'b01,num1[9:0]};//1 is added because only decimal value is written in mantissa
    assign m2={2'b01,num2[9:0]};//mantissa is not signed so we add 0 so that booth multiplier considers both as positive numbers
   

    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    prec_ctrl pc(exp,mask);
    booth bm(m1,m2,mask,mant);
    normalizer nz(mant,exp,exponent,mantissa);
    
    assign out={s,exponent,mantissa};

endmodule

module sign_exp(input s1,input s2,input [4:0] ex1,input [4:0] ex2,output s,output [4:0] exp);
    assign s=s1^s2;
    assign exp=ex1+ex2-5'd30;//bias =15 in IEEE754 Half Precision  
endmodule

module normalizer(input [18:0] mant,input [4:0] exp,output reg[4:0] exponent,output reg[9:0] mantissa);
   always@(*) 
   begin
       if(mant[18]==1'b1)
       begin
        mantissa=mant[17:8];
        exponent=exp+5'd19;
       end 
       else if(mant[17]==1'b1)
       begin
        mantissa=mant[16:7];
        exponent=exp+5'd17;
       end 
       else 
       begin
        mantissa=mant[15:6];
        exponent=exp+5'd15; 
       end      
       
   end
endmodule

module prec_ctrl(input [4:0] exp,output reg [18:0] mask);
    wire [3:0] rg;
    assign rg=exp[4:1];
    always@(*) begin
    case(rg) 
    4'b0000:mask=19'b1111111111111111111;
    4'b0001:mask=19'b1111111111111111110;
    4'b0010:mask=19'b1111111111111111100;
    4'b0011:mask=19'b1111111111111111000;
    4'b0100:mask=19'b1111111111111110000;
    4'b0101:mask=19'b1111111111111100000;
    4'b0110:mask=19'b1111111111111000000;
    4'b0111:mask=19'b1111111111110000000;
    4'b1000:mask=19'b1111111111110000000;
    4'b1001:mask=19'b1111111111111000000;
    4'b1010:mask=19'b1111111111111100000;
    4'b1011:mask=19'b1111111111111110000;
    4'b1100:mask=19'b1111111111111111000;
    4'b1101:mask=19'b1111111111111111100;
    4'b1110:mask=19'b1111111111111111110;
    4'b1111:mask=19'b1111111111111111111;
    default:mask=19'b1111111111111111111;
    endcase
    end
    
endmodule


module booth(input wire [11:0] A,input wire [11:0] B,input [18:0] mask,output wire [18:0] prod);
        reg [2:0] bits[5:0];
        reg [12:0] pp[5:0];
        
        wire [11:0] A_;//minus A
        wire [23:0] pp1,pp2,pp3,pp4,pp5,pp6;
        integer m1;
        assign A_=~A+1;
        
        always@(A or B or A_) begin
        
        bits[0]={B[1],B[0],1'b0};
        
        for(m1=1;m1<=5;m1=m1+1)
            bits[m1]={B[2*m1+1],B[2*m1],B[2*m1-1]};
        
        for(m1=0;m1<=5;m1=m1+1) begin
            case(bits[m1])
            
            3'b001:pp[m1]={1'b0,A};
            3'b010:pp[m1]={1'b0,A};
            3'b011:pp[m1]={A,1'b0};
            3'b100:pp[m1]={A_,1'b0};
            3'b101:pp[m1]={A_[11],A_};
            3'b110:pp[m1]={A_[11],A_};
            default:pp[m1]=12'b0;
                        
            endcase
        end
        end
        
         assign pp1={{11{pp[0][12]}},pp[0]};
       	 assign pp2={{9{pp[1][12]}},pp[1],2'b0};
         assign pp3={{7{pp[2][12]}},pp[2],4'b0};
       	 assign pp4={{5{pp[3][12]}},pp[3],6'b0};
	 assign pp5={{3{pp[4][12]}},pp[4],8'b0};
	 assign pp6={{{pp[5][12]}},pp[5],10'b0};
        pp_adder ppa(mask,pp1,pp2,pp3,pp4,pp5,pp6,prod);
        
endmodule

module pp_adder(input [18:0] mask, input [23:0] pp1,input [23:0] pp2,input [23:0] pp3,input [23:0] pp4,input [23:0] pp5,input [23:0] pp6,output reg[18:0] prod);
    always@(*) begin
    case(mask)
    19'b1111111111111111111: prod=pp1[23:5]+pp2[23:5]+pp3[23:5]+pp4[23:5]+pp5[23:5]+pp6[23:5];
    19'b1111111111111111110: prod={(pp1[23:6]+pp2[23:6]+pp3[23:6]+pp4[23:6]+pp5[23:6]+pp6[23:6]),1'b0};
    19'b1111111111111111100: prod={(pp1[23:7]+pp2[23:7]+pp3[23:7]+pp4[23:7]+pp5[23:7]+pp6[23:7]),2'b0};
    19'b1111111111111111000: prod={(pp1[23:8]+pp2[23:8]+pp3[23:8]+pp4[23:8]+pp5[23:8]+pp6[23:8]),3'b0};
    19'b1111111111111110000: prod={(pp1[23:9]+pp2[23:9]+pp3[23:9]+pp4[23:9]+pp5[23:9]+pp6[23:9]),4'b0};
    19'b1111111111111100000: prod={(pp1[23:10]+pp2[23:10]+pp3[23:10]+pp4[23:10]+pp5[23:10]+pp6[23:10]),5'b0};
    19'b1111111111111000000: prod={(pp1[23:11]+pp2[23:11]+pp3[23:11]+pp4[23:11]+pp5[23:11]+pp6[23:11]),6'b0};
    19'b1111111111110000000: prod={(pp1[23:12]+pp2[23:12]+pp3[23:12]+pp4[23:12]+pp5[23:12]+pp6[23:12]),7'b0};
    default:prod=19'd0; 
    endcase
    end 
endmodule