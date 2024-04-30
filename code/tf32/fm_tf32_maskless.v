module fm_tf32(input clk);
   
    wire ena=1;
    wire wea=0;
    //wire [3:0] ms;
    reg [13:0] addra;
    wire [18:0] num1,num2;
    reg [18:0] out;
    wire s1,s2;
    wire [7:0] ex1,ex2;
    wire [11:0] m1,m2;
    
    wire s;
    wire [9:0] exp;
    wire [12:0] mant;
   // wire [12:0] mask;
    wire [7:0] exponent;
    wire [9:0] mantissa;
    
    always@(posedge clk) begin
        addra=addra+1'b1;
    end
    
    blk_mem_gen_0 in1 (
          .clka(clk),    // input wire clka
          .ena(ena),      // input wire ena
          .wea(wea),      
          .addra(addra),  
          .dina(dina),    
          .douta(num1)  
        );
        
    blk_mem_gen_1 in2 (
          .clka(clk),   
          .ena(ena),      
          .wea(wea),      
          .addra(addra),  
          .dina(dina),    
          .douta(num2)  
        );
        
    assign s1=num1[18];
    assign s2=num2[18];
    assign ex1=num1[17:10];
    assign ex2=num2[17:10];
    assign m1={2'b01,num1[9:0]};//1 is added because only decimal value is written in mantissa
    assign m2={2'b01,num2[9:0]};//mantissa is not signed so we add 0 so that booth multiplier considers both as positive numbers
    
    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    //prec_ctrl pc(exp,mask);
    booth bm(m1,m2,mant);
    normalizer nz(mant,exp,exponent,mantissa);
    
    always@(*) begin
      out={s,exponent,mantissa};
    end
    
    ila_0 your_instance_name (
	.clk(clk), // input wire clk
 
	.probe0(out) 
     );

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

module booth(input wire [11:0] A,input wire [11:0] B,output wire [12:0] prod);
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
        assign prod=pp1[22:10]+pp2[22:10]+pp3[22:10]+pp4[22:10]+pp5[22:10]+pp6[22:10];
        
endmodule


