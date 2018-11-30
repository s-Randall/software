%load('C:\Users\Work\360Downloads\ZhaoZhiXiang\Data\8module_energy_TDC_data1.mat')
%load('C:\Users\Work\360Downloads\ZhaoZhiXiang\Data\8module_energy16bit_24bitTDC_30s_1(1).mat')
%load('8module_energy16bit_24bitTDC_30s_1st.mat')
% 1: channel; % 2: energy; % 3: Time; % 4: Block; % 5: Train ID

clear all;
close all;

mat_file_name=['16module_Flood_1new'];
%mat_file_name=['16module_Flood_110new'];

load([mat_file_name '.mat']);

savefile=[mat_file_name '_Delay.mat'];

%%%%%%%%%%%%%%%%%%%%%%%
% step 0: check all the data
% raw data format:
% channel ID: single_event_data(:,1)
% energy    : single_event_data(:,2)
% Time      : single_event_data(:,3)
% Block ID  : single_event_data(:,4)
% Train ID  : single_event_data(:,5)


%%%%画出single_event_data的所有的数据
fig1=figure;
subplot(231);hist(single_event_data(:,1),[0:101]);
title('channel ID');axis tight;
subplot(232);hist(single_event_data(:,2),[-1:1:1201]);xlim([0 1200]);
title('energy')
subplot(233);hist(single_event_data(:,3),1000);
title('Time');axis tight;
subplot(234);hist(single_event_data(:,4),[0:max(single_event_data(:,4))]);
title('Block ID');axis tight;
subplot(235);hist(single_event_data(:,5),[0:256]);
title('Train ID');axis tight;
subplot(236);plot(single_event_data(1:1000,5));
title('Train ID');axis tight;

savefig(fig1,[mat_file_name '_fig1']);


%%%%%%能量窗筛选
%%%%%%%%%%%%%%%%%%%%%%%
% step 1: set energy window here
low_cut=150; %450;
High_cut= 800; %650;

Energy_cut_index= single_event_data(:,2)>low_cut ...
    & single_event_data(:,2)<High_cut;

%1,2,...,10
boundary_index_a=single_event_data(:,1)<11;
%10,20,...,100
boundary_index_b=(rem(single_event_data(:,1),10)==0);
%100,99,...,91
boundary_index_c=single_event_data(:,1)>90;
%91,81,...,1
boundary_index_d=(rem(single_event_data(:,1),10)==1);



%%%%%%%%%%%%%%%%%%%%%%%
% step 2: correct the boudaries for all the blocks
%    calculate the start time of each block,  the shift of 
%    the start time of each block (ref to the first block ),
%    and the average time intervals in each block (average event rate)
% 1: channel; % 2: energy; % 3: Time; % 4: Block; % 5: Train ID
block_start_time=[];
average_interval=[];
for block_ID=0:15  %train num
    valid_index=(single_event_data(:,4)==block_ID);   %%找到对应模块的数据
    temp=single_event_data(valid_index,3);    %%取出对应的时间信息
    temp_100=temp+2^23;    
    adjusted_temp=temp;
    offset=0;
    
     %%%下面是把时间化成连续的
    for j=2:length(temp)
        if temp_100(j)<temp(j-1)
            offset=offset+2^24;
        end
        if temp_100(j-1)<temp(j)
            offset=offset-2^24;
        end
        adjusted_temp(j)=adjusted_temp(j)+offset;
    end
    single_event_data(valid_index,3)=adjusted_temp;
    
    %the start time of each block
    block_start_time=[block_start_time adjusted_temp(1)];   %%起始时间
    
    temp=(adjusted_temp(end)-adjusted_temp(1))/(length(adjusted_temp)-1);   %%平均事件间隔
    %average time intervals in each block (related to average event rate)
    average_interval=[average_interval round(temp)];

end

%shift of the start time of each block (ref to the first block )
block_start_time_shift=block_start_time;
block_start_time_shift=block_start_time-block_start_time(1);   %%%起始时间相对于1模块的间隔


% figure;
% for block_ID=0:7
%     subplot(2,4,block_ID+1)
%     valid_index=(single_event_data(:,4)==block_ID);
%     temp=single_event_data(valid_index,3);
%     plot(temp(1:300000))
% end

fig2=figure;
subplot(221);plot(average_interval);
xlabel('block ID');ylabel('average time intervals (clocks)');
title('average time intervals between events(# of clocks)');


%%%%%%%%%%%%%%%%%%%%%%%计算平均列车间隔
% step 3: calculate time intervals between data trains
% 1: channel; % 2: energy; % 3: Time; % 4: Block; % 5: Train ID
start_train_ID=single_event_data(1,5);
temp_sum_time=0;
temp_sum_count=0;
temp_sum_time_all=[];
temp_sum_count_all=[];

temp_block_id=0;
train_ID_count=0;
for index=1:length(single_event_data)
    % Block 1
    if single_event_data(index,4)==temp_block_id
        if single_event_data(index,5)==start_train_ID
            temp_sum_time=temp_sum_time+single_event_data(index,3);
            temp_sum_count=temp_sum_count+1;
        else
            temp_sum_time_all=[temp_sum_time_all temp_sum_time];
            temp_sum_count_all=[temp_sum_count_all temp_sum_count];
            temp_sum_time=0;
            temp_sum_count=0;
            train_ID_count=train_ID_count+1;
            start_train_ID=single_event_data(index,5);
            
            % only calculate 5000 average time
            if train_ID_count==5000
                break;
            end
        end
    end
end

%temp_sum_time_average=temp_sum_time_all;
temp_sum_time_average=temp_sum_time_all./temp_sum_count_all;
if temp_sum_count_all(1)==0
    temp_sum_time_average(1)=temp_sum_time_average(2);
end

for i=2:length(temp_sum_time_average)
    if temp_sum_count_all(i)==0
        temp_sum_time_average(i)=temp_sum_time_average(i-1);
    end
end
temp_delta_time_average=temp_sum_time_average(2:end)-temp_sum_time_average(1:end-1);

%time intervals between data trains
%time_between_trains=round(mean(temp_delta_time_average))    
time_between_trains=round((temp_sum_time_average(end)-temp_sum_time_average(1))/(length(temp_sum_time_average)-1))

subplot(222);plot(temp_sum_time_average);xlabel('train ID');ylabel('average time');
subplot(223);plot(temp_delta_time_average);xlabel('train ID');ylabel('average delta time');
%title(['average time interval between two trains: ' num2str(round(mean(temp_delta_time_average)))]);
title(['average time interval between two trains: ' num2str(time_between_trains)]);

subplot(224);plot(block_start_time_shift/time_between_trains);
xlabel('Block ID');
title('Offset (unit: # of trains) of the first event (ref to the first block)');
ylabel(['Offset/time\_between\_trains ' num2str(time_between_trains) 'clocks']);

savefig(fig2,[mat_file_name '_fig2']);

fig2_1=figure;
for i=0:15 %train num
    t=(single_event_data(:,4)==i);
    tt=single_event_data(t,3);
    subplot(4,4,i+1);plot(tt(2:end)-tt(1:end-1));axis tight;
end
savefig(fig2_1,[mat_file_name '_fig2_1']);    
clear t;
clear tt;
clear adjusted_temp;
clear temp_100;

for block_ID_a=0:15

%block_ID_a=1;  %train num

block_ID_b=block_ID_a+1;  
if block_ID_b==16
    block_ID_b=0;
end


fig_a=figure;
%fig_b=figure;
% fig_c=figure;
plot_index=0;

for loop_a=1:4
    
    %1.1 time_data_a: time data
    %valid_index=(single_event_data(:,4)==block_ID_a);
    
    if loop_a==1
        valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_a;
    end
    if loop_a==2
        valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_b;
    end
    if loop_a==3
        valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_c;
    end
    if loop_a==4
        valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_d;
    end
    
    
    time_data_a=single_event_data(valid_index,3);
    for loop_b=1:4
    	
        corrected_delay(block_ID_b+1)=block_start_time_shift(block_ID_b+1) ...
            -block_start_time_shift(block_ID_a+1);
        
        %1.2 time_data_b: time data
        %valid_index=(single_event_data(:,4)==block_ID_b);
        if loop_b==1
            valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_a;
        end
        if loop_b==2
            valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_b;
        end
        if loop_b==3
            valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_c;
        end
        if loop_b==4
            valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_d;
        end
        
        plot_index=plot_index+1;
        
        time_data_b=single_event_data(valid_index,3);
        
        %1.3a time_data_length: only search part of the data (for example: 10000)
        time_data_length=2000;
        %1.4a search_start: -time_between_trains*2 (about 12000*2 clocks)
        search_start=round(-time_between_trains*2);
        %1.5a search_interval: round(mean(average_interval)/32) (about 4000/16)
        search_interval=ceil(mean(average_interval)/128);
        %1.6a search_end: -time_between_trains*2 (about 12000*2 clocks)
        search_end=round(time_between_trains*2);
        %1.7a fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
        fixed_offset=corrected_delay(block_ID_b+1);
        % 1.8a plot_flag: 0-- no plot
        plot_flag=1;
        
        % A: perform the first delay search
        figure(fig_a); subplot(4,4,plot_index);
        delay_search;
        title(['BLK' num2str(block_ID_a) '\_' num2str(loop_a) ': BLK' ...
            num2str(block_ID_b) '\_' num2str(loop_b) ]);
        % 2. outputs: 2.1 corrected_time_shift: corrected time delay shift
        corrected_delay(block_ID_b+1)=corrected_delay(block_ID_b+1)+corrected_time_shift;
        
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %%%b. second search
%         previous_search_interval=search_interval;
%         
%         %1.3b time_data_length: only search part of the data (for example: 10000)
%         time_data_length=2000; %2000;
%         %1.4b search_start: -time_between_trains*2 (about 12000*2 clocks)
%         search_start=round(-previous_search_interval*2);
%         %1.5b search_interval: round(mean(average_interval)/16) (about 4000/16)
%         search_interval=1;
%         %1.6b search_end: -time_between_trains*2 (about 12000*2 clocks)
%         search_end=round(previous_search_interval*2);
%         %1.7b fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
%         fixed_offset=corrected_delay(block_ID_b+1); % use updated delay
%         % 1.8b plot_flag: 0-- no plot
%         plot_flag=1;
%         
%         % B: perform the second delay search
%         figure(fig_b); subplot(4,4,plot_index);
%         delay_search;
%         % 2. outputs: 2.1 corrected_time_shift: corrected time delay shift
%         corrected_delay(block_ID_b+1)=corrected_delay(block_ID_b+1)+corrected_time_shift;
%         peak_vs_average_all(block_ID_a+1,block_ID_b+1)=peak_vs_average_temp;
        
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % c: verify 
%         %1.3b time_data_length: only search part of the data (for example: 10000)
%         time_data_length=5000; %20000;
%         %1.4b search_start: -time_between_trains*2 (about 12000*2 clocks)
%         search_start=-20; %-10;
%         %1.5b search_interval: round(mean(average_interval)/16) (about 4000/16)
%         search_interval=1;
%         %1.6b search_end: -time_between_trains*2 (about 12000*2 clocks)
%         search_end=20; %10;
%         %1.7b fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
%         fixed_offset=corrected_delay(block_ID_b+1); % use updated delay
%         % 1.8b plot_flag: 0-- no plot
%         plot_flag=1;        
%         
%         % c: verify the seraching results
%         figure(fig_c); subplot(4,4,plot_index);
%         delay_search;
%         grid on;axis tight;title([num2str(block_ID_a) ':' num2str(block_ID_b)]);
%         corrected_delay(block_ID_b+1)=corrected_delay(block_ID_b+1)+corrected_time_shift;
%         corrected_delay_all(block_ID_a+1,block_ID_b+1)= corrected_delay(block_ID_b+1);   
%         
    end
end

savefig(fig_a,[mat_file_name '_figa_' num2str(block_ID_a)]);

end