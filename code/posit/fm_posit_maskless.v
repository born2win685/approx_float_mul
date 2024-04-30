module fm_posit(input clk);//,output [3:0] p);
    //posit format with n=16 and es=3
    //there is a minimum of 2 bits of regime in posit format
    //if regime value =k,then its contribution is [2^(2^es)]^k
    //the useed ==> 2^8=256.
     wire ena=1;
     wire wea=0;
     reg [16:0] addra;
     wire [15:0] num1,num2;
     wire [15:0] out;
     wire s1,s2;
     wire [9:0] m1,m2;
     wire [7:0] exp1,exp2;
     wire [8:0] exp;
     wire [3:0] p;
     reg [14:0] n1,n2;
     wire [11:0] mt1,mt2;
     wire [12:0] mant;
     wire [9:0] mantissa;
     wire [7:0] exponent; 
     
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
     
     always@(*) begin
        if(s1==1'b1)
            n1=~num1[14:0] +1;
        else
            n1=num1[14:0];
     end
     always@(*) begin       
        if(s2==1'b1)
            n2=~num2[14:0] +1;
        else
            n2=num2[14:0];
     end       
     
    
     assign mt1={2'b01,m1};
     assign mt2={2'b01,m2};
     
     data_extract de1(n1,exp1,m1);
     data_extract de2(n2,exp2,m2);
     
     assign exp=exp1+exp2;
     assign s=s1+s2;
     
     //prec_ctrl pc(exp,mask);
     booth bm(mt1,mt2,mant);
     normalizer nz(mant,exp,exponent,mantissa);
     posit_convert poc(s,exponent,mantissa,out);
     
     ila_0 your_instance_name (
	.clk(clk), // input wire clk


	.probe0(out)
     );
     
endmodule


    
module normalizer(input [12:0] mant,input [8:0] exp,output reg [7:0] exponent,output reg [9:0] mantissa);
   always@(*) 
   begin
       if(mant[12]==1'b1)
       begin
        mantissa=mant[11:2];
        exponent=exp+8'd2;
       end 
       else if(mant[11]==1'b1)
       begin
        mantissa=mant[10:1];
        exponent=exp+8'd1;
       end 
       else 
       begin
        mantissa=mant[9:0];
        exponent=exp; 
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
module data_extract(input [14:0] num,output reg [7:0] exponent,output reg [9:0] mant);
    integer i,flag;
    reg [3:0] p=4'b1;
    reg [14:0] temp;
    reg [2:0] exp;
    always @(num) begin
        if(num[14] ==1'b0) begin
            flag=0;
            for (i=13;i>=0;i=i-1) begin
                if((num[i]==1'b0) && flag==0) 
                    p=p+1;
                    
                else
                    flag=1;
            end
            //p is the number of zeroes in the regime as the flag is set to 1 upon
            //reaching the 1 so the k value is -p and exponent is starting from index
            //14 -1-p-1(sign ,p zeroes,one)
            //we left shit p+1 times so that p zeroes and the 1-bit of the regime is removed
            //now 4 bits are exponent and rest are mantissa
            case(p)  
            13:begin
                 exp=num[0];
                 mant=4'b0;
              end
            12:begin
                 exp=num[1:0];
                 mant=4'b0;
              end
            11:begin
                 exp=num[2:0];
                 mant=4'b0;
              end
            default:begin
                    temp=num<<(p+1);
                    exp=temp[14:12];
                    mant=temp[11:2];//in 16,3 posit format sign=1,min reg=2,exp=3...max mantissa=10
                    end            
            endcase
            exponent=exp-(8*p);   
              
        end
        else begin
            flag=0;
          for (i=13;i>=0;i=i-1) begin
                if((num[i]==1'b1) && flag==0) 
                    p=p+1;
                else 
                    flag=1;
            end
          
          //similarly ,now p is the number of 1s therefore regime size is p+1
          //max of p=15.
          case(p)  
            13:begin
                 exp=num[0];
                 mant=4'b0;
              end
            12:begin
                 exp=num[1:0];
                 mant=4'b0;
              end
            11:begin
                 exp=num[2:0];
                 mant=4'b0;
              end
            default:begin
                    temp=num<<(p+1);
                    exp=temp[14:12];
                    mant=temp[11:2];
                    end            
            endcase
            exponent=exp+(8*(p-1));
            end
    end
endmodule


module posit_convert (input s,input [7:0] exponent,input [9:0] mantissa,output reg [15:0] pos);
    reg [7:0] exp;
    reg [3:0] k;
    reg [2:0] e;
    reg [14:0] posit;
    always@(*) begin
        if(exponent[7]==1'b1) begin
            exp=~exponent +1'b1;
            k=exp/8 + 1;
            e=(8*k) - exp;
//            $display("k",k);
//            $display("e ",e);
//            $display("exp",exp);
            case(k) 
                4'b0001:posit={2'b01,e,mantissa};
                4'b0010:posit={3'b001,e,mantissa[9:1]};
                4'b0011:posit={4'b0001,e,mantissa[9:2]};
                4'b0100:posit={5'b00001,e,mantissa[9:3]};
                4'b0101:posit={6'b000001,e,mantissa[9:4]};
                4'b0110:posit={7'b0000001,e,mantissa[9:5]};
                4'b0111:posit={8'b00000001,e,mantissa[9:6]};
                4'b1000:posit={9'b000000001,e,mantissa[9:7]};
                4'b1001:posit={10'b0000000001,e,mantissa[9:8]};
                4'b1010:posit={11'b00000000001,e,mantissa[9]};
                4'b1011:posit={12'b000000000001,e};
                4'b1100:posit={13'b0000000000001,e[2:1]};
                4'b1101:posit={14'b00000000000001,e[2]};
                4'b1110:posit=15'b000000000000001;
                default:posit=15'b0;
            endcase
        end
        
        else begin
            exp=exponent;
            k=exp/8;
            e=exp-8*k;
            case(k) 
                4'b0000:posit={2'b10,e,mantissa};
                4'b0001:posit={3'b110,e,mantissa[9:1]};
                4'b0010:posit={4'b1110,e,mantissa[9:2]};
                4'b0011:posit={5'b11110,e,mantissa[9:3]};
                4'b0100:posit={6'b111110,e,mantissa[9:4]};
                4'b0101:posit={7'b1111110,e,mantissa[9:5]};
                4'b0110:posit={8'b11111110,e,mantissa[9:6]};
                4'b0111:posit={9'b111111110,e,mantissa[9:7]};
                4'b1000:posit={10'b1111111110,e,mantissa[9:8]};
                4'b1001:posit={11'b11111111110,e,mantissa[9]};
                4'b1010:posit={12'b111111111110,e};
                4'b1011:posit={13'b1111111111110,e[2:1]}; 
                4'b1100:posit={14'b11111111111110,e[2]};
                4'b1101:posit=15'b111111111111110;                 
                default:posit=15'b0;
            endcase
        end
    end
    always@(*) begin
        if(s==1'b1)
            pos={s,(~posit+1)};
        else
            pos={s,posit};
    end
endmodule
