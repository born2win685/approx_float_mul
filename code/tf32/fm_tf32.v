module fm_tf32(input [18:0] num1,input [18:0] num2,output [18:0] out);
  
    wire s1,s2;
    wire [7:0] ex1,ex2;
    wire [11:0] m1,m2;
    
    wire s;
    wire [9:0] exp;
    wire [12:0] mant;
    wire [12:0] mask;
    wire [7:0] exponent;
    wire [9:0] mantissa;
    
    assign s1=num1[18];
    assign s2=num2[18];
    assign ex1=num1[17:10];
    assign ex2=num2[17:10];
    assign m1={2'b01,num1[9:0]};//1 is added because only decimal value is written in mantissa
    assign m2={2'b01,num2[9:0]};//mantissa is not signed so we add 0 so that booth multiplier considers both as positive numbers
    
    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    prec_ctrl pc(exp,mask);
    booth bm(m1,m2,mask,mant);
    normalizer nz(mant,exp,exponent,mantissa);
    
    assign out={s,exponent,mantissa};

endmodule

module sign_exp(input s1,input s2,input [7:0] ex1,input [7:0] ex2,output s,output [9:0] exp);
    assign s=s1^s2;
    assign exp={2'b0,ex1}+{2'b0,ex2}-10'd254;//bias =127 in bfloat16    
endmodule

module normalizer(input [12:0] mant,input [8:0] exp,output reg[7:0] exponent,output reg[9:0] mantissa);
   always@(*) 
   begin
       if(mant[12]==1'b1)
       begin
        mantissa=mant[11:2];
        exponent=exp+8'd129;
       end 
       else if(mant[11]==1'b1)
       begin
        mantissa=mant[10:1];
        exponent=exp+8'd128;
       end 
       else 
       begin
        mantissa=mant[9:0];
        exponent=exp+8'd127; 
       end      
       
   end
endmodule

module prec_ctrl(input [9:0] exp,output reg [12:0] mask);
    wire [3:0] rg;
    assign rg=exp[7:4];
    always@(*) begin
    case(rg) 
    4'b0000:mask=13'b1111111111111;
    4'b0001:mask=13'b1111111111110;
    4'b0010:mask=13'b1111111111100;
    4'b0011:mask=13'b1111111111000;
    4'b0100:mask=13'b1111111110000;
    4'b0101:mask=13'b1111111100000;
    4'b0110:mask=13'b1111111000000;
    4'b0111:mask=13'b1111110000000;
    4'b1000:mask=13'b1111110000000;
    4'b1001:mask=13'b1111111000000;
    4'b1010:mask=13'b1111111100000;
    4'b1011:mask=13'b1111111110000;
    4'b1100:mask=13'b1111111111000;
    4'b1101:mask=13'b1111111111100;
    4'b1110:mask=13'b1111111111110;
    4'b1111:mask=13'b1111111111111;
    default:mask=13'b1111111111111;
    endcase
    //$display("%b",mask);
    end
endmodule

module booth(input wire [11:0] A,input wire [11:0] B,input [12:0] mask,output wire [12:0] prod);
        reg [2:0] bits[5:0];
        reg [12:0] pp[5:0];
        
        wire [11:0] A_;//minus A
        wire [22:0] pp1;
        wire [22:0] pp2;
        wire [22:0] pp3;
        wire [22:0] pp4;
        wire [22:0] pp5;
        wire [22:0] pp6;
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
        
        assign pp1={{10{pp[0][12]}},pp[0]};
        assign pp2={{8{pp[1][12]}},pp[1],2'b0};
        assign pp3={{6{pp[2][12]}},pp[2],4'b0};
        assign pp4={{4{pp[3][12]}},pp[3],6'b0};
        assign pp5={{2{pp[4][12]}},pp[4],8'b0};
        assign pp6={pp[5],10'b0};
        pp_adder ppa(mask,pp1,pp2,pp3,pp4,pp5,pp6,prod);
        always@(*) begin
        $display("prod :%b",prod);
        $display("mask :%b",mask);
        $display("pp1 :%b",pp1);
        $display("pp2 :%b",pp2);
        $display("pp3 :%b",pp3);
        $display("pp4 :%b",pp4);
        $display("pp5 :%b",pp5);
        $display("pp6 :%b",pp6);
        end
        
endmodule

module pp_adder(input [12:0] mask, input [22:0] pp1,input [22:0] pp2,input [22:0] pp3,input [22:0] pp4,input [22:0] pp5,input [22:0] pp6,output reg[12:0] prod);
    always@(*) begin
    case(mask)
    13'b1111111111111: prod=pp1[22:10]+pp2[22:10]+pp3[22:10]+pp4[22:10]+pp5[22:10]+pp6[22:10];
    13'b1111111111110: prod={(pp1[22:11]+pp2[22:11]+pp3[22:11]+pp4[22:11]+pp5[22:11]+pp6[22:11]),1'b0};
    13'b1111111111100: prod={(pp1[22:12]+pp2[22:12]+pp3[22:12]+pp4[22:12]+pp5[22:12]+pp6[22:12]),2'b0};
    13'b1111111111000: prod={(pp1[22:13]+pp2[22:13]+pp3[22:13]+pp4[22:13]+pp5[22:13]+pp6[22:13]),3'b0};
    13'b1111111110000: prod={(pp1[22:14]+pp2[22:14]+pp3[22:14]+pp4[22:14]+pp5[22:14]+pp6[22:14]),4'b0};
    13'b1111111100000: prod={(pp1[22:15]+pp2[22:15]+pp3[22:15]+pp4[22:15]+pp5[22:15]+pp6[22:15]),5'b0};
    13'b1111111000000: prod={(pp1[22:16]+pp2[22:16]+pp3[22:16]+pp4[22:16]+pp5[22:16]+pp6[22:16]),6'b0};
    13'b1111110000000: prod={(pp1[22:17]+pp2[22:17]+pp3[22:17]+pp4[22:17]+pp5[22:17]+pp6[22:17]),7'b0};
    default:prod=13'd0; 
    endcase
    
    end
endmodule