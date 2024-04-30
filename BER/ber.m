clc
bf_val=[]; 
hf_val=[];
sin_val=[];
tf_val=[];
n=1;
num="";
p=0;
for i=1:81920   
    num=bfloat(i);
    s=0;
    p=8-t_bf(i);
    for ind=7:-1:p
            if(strcmp(extractBetween(num,ind,ind),'1'))
                s=s+(0.5)^ind;
            end
    end
    bf_val(i)=s;

    num=half(i);
    s=0;
    p=8-t_half(i);
    for ind=7:-1:p
            if(strcmp(extractBetween(num,ind,ind),'1'))
                s=s+(0.5)^ind;
            end
    end
    hf_val(i)=s;

    

    num=single(i);
    s=0;
    p=15-t_single(i);
    for ind=14:-1:p
            if(strcmp(extractBetween(num,ind,ind),'1'))
                s=s+(0.5)^ind;
            end
    end
    sin_val(i)=s;
end


posit_val=[]; 
num="";
for i=1:57649  
    num=posit(i);
    s=0;
    for ind=1:16
            if(strcmp(extractBetween(num,ind,ind),'1'))
                s=s+(0.5)^ind;
            end
    end
    posit_val(i)=s;
end 


num="";
for i=1:98304 
    num=tf32(i);
    s=0;
    p=8-t_tf(i);
    for ind=7:-1:p
            if(strcmp(extractBetween(num,ind,ind),'1'))
                s=s+(0.5)^ind;
            end
    end
    tf_val(i)=s;
end 




bf_0=[];
bf_1=[];
bf_2=[];
bf_3=[];
bf_4=[];
bf_5=[];
bf_6=[];
bf_7=[];

bf_0=bf_val(1:29269);
bf_2=bf_val(29270:37069);
bf_3=bf_val(37370:47126);
bf_4=bf_val(47127:57345);
bf_5=bf_val(57346:67654);
bf_6=bf_val(67655:77895);
bf_7=bf_val(77896:81920);

bf_mean=[];
bf_mean(end+1)=mean(bf_0);
bf_mean(end+1)=(mean(bf_0)+mean(bf_2))/2;
bf_mean(end+1)=mean(bf_2);
bf_mean(end+1)=mean(bf_3);
bf_mean(end+1)=mean(bf_4);
bf_mean(end+1)=mean(bf_5);
bf_mean(end+1)=mean(bf_6);
bf_mean(end+1)=mean(bf_7);

t=[0,1,2,3,4,5,6,7];
figure(n)
n=n+1;
plot(t,bf_mean)
grid on; 
legend('masksize=11')
xlabel('Truncated bit-width');
ylabel('Bit Error Rate');
title('BER vs Truncated bit-width (bfloat16)');
half_0=[];
half_1=[];
half_2=[];
half_3=[];
half_4=[];
half_5=[];
half_6=[];
half_7=[];

half_0=hf_val(1:27648);
half_1=hf_val(27649:35840);
half_2=hf_val(35841:49152);
half_3=hf_val(49153:55296);
half_4=hf_val(55297:67584);
half_5=hf_val(67585:75776);
half_6=hf_val(75777:78849);
half_7=hf_val(78850:81920);

half_mean=[];
half_mean(end+1)=mean(half_0);
half_mean(end+1)=mean(half_1);
half_mean(end+1)=mean(half_2);
half_mean(end+1)=mean(half_3);
half_mean(end+1)=mean(half_4);
half_mean(end+1)=mean(half_5);
half_mean(end+1)=mean(half_6);
half_mean(end+1)=mean(half_7);

t=[0,1,2,3,4,5,6,7];
figure(n)
n=n+1;
plot(t,half_mean)
grid on; 
legend('masksize=12')
xlabel('Truncated bit-width');
ylabel('Bit Error Rate');
title('BER vs Truncated bit-width (ieee-half)');


tf_0=[];
tf_1=[];
tf_2=[];
tf_3=[];
tf_4=[];
tf_5=[];
tf_6=[];
tf_7=[];

tf_0=tf_val(1:32041);
tf_2=tf_val(32042:44369);
tf_3=tf_val(44370:56752);
tf_4=tf_val(56753:68835);
tf_5=tf_val(68836:81118);
tf_6=tf_val(81119:93556);
tf_7=tf_val(93557:98304);

tf_mean=[];
tf_mean(end+1)=mean(tf_0);
tf_mean(end+1)=(mean(tf_0)+mean(tf_2))/2;
tf_mean(end+1)=mean(tf_2);
tf_mean(end+1)=mean(tf_3);
tf_mean(end+1)=mean(tf_4);
tf_mean(end+1)=mean(tf_5);
tf_mean(end+1)=mean(tf_6);
tf_mean(end+1)=mean(tf_7);

t=[0,1,2,3,4,5,6,7];
figure(n)
n=n+1;
plot(t,tf_mean)
grid on; 
legend('masksize=13')
xlabel('Truncated bit-width');
ylabel('Bit Error Rate');
title('BER vs Truncated bit-width (tensorfloat32)');




posit_1=[];
posit_1=[];
posit_3=[];
posit_4=[];
posit_5=[];
posit_6=[];
posit_7=[];
posit_8=[];
posit_9=[];
posit_10=[];
posit_11=[];
posit_12=[];
posit_13=[];

posit_1=posit_val(1:6);
posit_3=posit_val(7:15);
posit_4=posit_val(16:50);
posit_5=posit_val(51:242);
posit_6=posit_val(243:1098);
posit_7=posit_val(1099:3143);
posit_8=posit_val(3144:6379);
posit_9=posit_val(6380:13578);
posit_10=posit_val(13579:18817);
posit_11=posit_val(18818:32835);
posit_12=posit_val(32836:36885);
posit_13=posit_val(36886:57649);


posit_mean=[];
posit_mean(end+1)=0;
posit_mean(end+1)=mean(posit_1);
posit_mean(end+1)=(mean(posit_1)+mean(posit_3))/2;
posit_mean(end+1)=mean(posit_3);
posit_mean(end+1)=mean(posit_4);
posit_mean(end+1)=mean(posit_5);
posit_mean(end+1)=mean(posit_6);
posit_mean(end+1)=mean(posit_7);
posit_mean(end+1)=mean(posit_8);
posit_mean(end+1)=mean(posit_9);
posit_mean(end+1)=mean(posit_10);
posit_mean(end+1)=mean(posit_11);
posit_mean(end+1)=mean(posit_12);
posit_mean(end+1)=mean(posit_13);

posit_mean=sort(posit_mean);

tt=[0,1,2,3,4,5,6,7,8,9,10,11,12,13];
figure(n)
n=n+1;
plot(tt,posit_mean)
grid on; 
legend('masksize=13')
xlabel('Truncated bit-width');
ylabel('Bit Error Rate');
title('BER vs Truncated bit-width (posit)');



sin_0=[];
sin_2=[];
sin_4=[];
sin_6=[];
sin_8=[];
sin_10=[];
sin_12=[];
sin_14=[];


sin_0=sin_val(1:5120);
sin_2=sin_val(5121:9216);
sin_4=sin_val(9217:16384);
sin_6=sin_val(16384:28672);
sin_8=sin_val(28673:46080);
sin_10=sin_val(46081:52224);
sin_12=sin_val(52225:68608);
sin_14=sin_val(68609:81920);


sin_mean=[];
sin_mean(end+1)=mean(sin_0);
sin_mean(end+1)=mean(sin_2);
sin_mean(end+1)=mean(sin_4);
sin_mean(end+1)=mean(sin_6);
sin_mean(end+1)=mean(sin_8);
sin_mean(end+1)=mean(sin_10);
sin_mean(end+1)=mean(sin_12);
sin_mean(end+1)=mean(sin_14);

t=[0,2,4,6,8,10,12,14];
figure(n)
n=n+1;
plot(t,sin_mean)
grid on; 
legend('masksize=27')
xlabel('Truncated bit-width');
ylabel('Bit Error Rate');
title('BER vs Truncated bit-width (ieee-single)');

figure(n)
n=n+1;
plot(bf_mean)
hold on
plot(tf_mean)
hold on
plot(tt,posit_mean)
hold on
plot(sin_mean)
hold on
plot(half_mean)
hold off
grid on; 
legend('bfloat16','tensorfloat32','posit','ieee-single','ieee-half')
xlabel('Truncated bit-width');
ylabel('Bit Error Rate');
title('BER vs Truncated bit-width ');

figure(n)
n=n+1;
plot(bf_mean)
hold on
plot(tf_mean)
hold on
plot(sin_mean)
hold on
plot(half_mean)
hold off
grid on; 
legend('bfloat16','tensorfloat32','ieee-single','ieee-half')
xlabel('Truncated bit-width');
ylabel('Bit Error Rate');
title('BER vs Truncated bit-width ');
