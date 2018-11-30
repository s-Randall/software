%load('C:\Users\Work\360Downloads\ZhaoZhiXiang\Data\8module_energy_TDC_data1.mat')
%load('C:\Users\Work\360Downloads\ZhaoZhiXiang\Data\8module_energy16bit_24bitTDC_30s_1(1).mat')
%load('8module_energy16bit_24bitTDC_30s_1st.mat')
% 1: channel; % 2: energy; % 3: Time; % 4: Block; % 5: Train ID

close all;
%mat_file_name=['8module_energy16bit_24bitTDC_30s_10th'];
%mat_file_name=['8module_energy16bit_24bitTDC_60s_pos2_x'];
% mat_file_name=['8module_pt1_30s_360'];
% mat_file_name=['8module_pt1_30s_1'];
% mat_file_name=['8module_pt1_30s_120'];
% mat_file_name=['8module_pt2_30s_180'];
% mat_file_name=['8module_pt2_30s_240'];
% mat_file_name=['8module_pt2_30s_300'];
% mat_file_name=['8module_pt1_30s_360'];



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

fig1=figure;
subplot(231);hist(single_event_data(:,1),[0:101]);
title('channel ID');axis tight;
subplot(232);hist(single_event_data(:,2),1000);xlim([0 1200]);
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

%%%%%%%%%%%%%%%%%%%%%%%
% step 1: set energy window here
low_cut=200; %450;
High_cut= 800; %650;

Energy_cut_index= single_event_data(:,2)>low_cut ...
    & single_event_data(:,2)<High_cut;


%%%%%%%%%%%%%%%%%%%%%%%
% step 2: correct the boudaries for all the blocks
%    calculate the start time of each block,  the shift of 
%    the start time of each block (ref to the first block ),
%    and the average time intervals in each block (average event rate)
% 1: channel; % 2: energy; % 3: Time; % 4: Block; % 5: Train ID
block_start_time=[];
average_interval=[];
for block_ID=0:7
    valid_index=(single_event_data(:,4)==block_ID);
    temp=single_event_data(valid_index,3);
    temp_100=temp+2^23;
    adjusted_temp=temp;
    offset=0;
    
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
    block_start_time=[block_start_time adjusted_temp(1)];
    
    temp=(adjusted_temp(end)-adjusted_temp(1))/(length(adjusted_temp)-1);
    %average time intervals in each block (related to average event rate)
    average_interval=[average_interval round(temp)];

end

%shift of the start time of each block (ref to the first block )
block_start_time_shift=block_start_time;
block_start_time_shift=block_start_time-block_start_time(1);


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


%%%%%%%%%%%%%%%%%%%%%%%
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
for i=0:7
    t=(single_event_data(:,4)==i);
    tt=single_event_data(t,3);
    subplot(2,4,i+1);plot(tt(2:end)-tt(1:end-1));axis tight;
end
savefig(fig2_1,[mat_file_name '_fig2_1']);    
clear t;
clear tt;
clear adjusted_temp;
clear temp_100;

%%%%%%%%%%%%%%%%%%%%%%%
% step 4: delay corrections
% 1: channel; % 2: energy; % 3: Time; % 4: Block; % 5: Train ID
% block_start_time_shift: shift of the start time of each block (ref to the first block )
% time_between_trains: time intervals between data trains (about 12000 clocks)
% searching in a range close to time_between_trains 
% (search the same or adjacent (+/-2) trains) 
% outputs are in : corrected_delay_all and peak_vs_average_all

%corrected_delay=block_start_time_shift;
corrected_delay_all=zeros(8,8); % 8 modules
peak_vs_average_all=zeros(8,8);

for block_ID_a=0:6  % 0:7
%for block_ID_a=3:3  % 0:7
    %corrected_delay=block_start_time_shift
    %1.1 time_data_a: time data
    %valid_index=(single_event_data(:,4)==block_ID_a);
    valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index;
    
    time_data_a=single_event_data(valid_index,3);
    fig3=figure;
    %for block_ID_b=7:7  % 0:7
    for block_ID_b=block_ID_a+1:7  % 0:7
        corrected_delay(block_ID_b+1)=block_start_time_shift(block_ID_b+1) ...
            -block_start_time_shift(block_ID_a+1);
        
        %1.2 time_data_b: time data
        %valid_index=(single_event_data(:,4)==block_ID_b);
        valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index;
        time_data_b=single_event_data(valid_index,3);
        
        %1.3a time_data_length: only search part of the data (for example: 10000)
        time_data_length=4000;
        %1.4a search_start: -time_between_trains*2 (about 12000*2 clocks)
        search_start=round(-time_between_trains*2);
        %1.5a search_interval: round(mean(average_interval)/32) (about 4000/16)
        search_interval=ceil(mean(average_interval)/128);
        %1.6a search_end: -time_between_trains*2 (about 12000*2 clocks)
        search_end=round(time_between_trains*2);
        %1.7a fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
        fixed_offset=corrected_delay(block_ID_b+1);
        % 1.8a plot_flag: 0-- no plot
        plot_flag=0;
        
        % A: perform the first delay search
        %figure; 
        delay_search;
        % 2. outputs: 2.1 corrected_time_shift: corrected time delay shift
        corrected_delay(block_ID_b+1)=corrected_delay(block_ID_b+1)+corrected_time_shift;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%b. second search
        previous_search_interval=search_interval;
        
        %1.3b time_data_length: only search part of the data (for example: 10000)
        time_data_length=4000;
        %1.4b search_start: -time_between_trains*2 (about 12000*2 clocks)
        search_start=round(-previous_search_interval*2);
        %1.5b search_interval: round(mean(average_interval)/16) (about 4000/16)
        search_interval=1;
        %1.6b search_end: -time_between_trains*2 (about 12000*2 clocks)
        search_end=round(previous_search_interval*2);
        %1.7b fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
        fixed_offset=corrected_delay(block_ID_b+1); % use updated delay
        % 1.8b plot_flag: 0-- no plot
        plot_flag=0;
        
        % B: perform the second delay search
        %figure; 
        delay_search;
        % 2. outputs: 2.1 corrected_time_shift: corrected time delay shift
        corrected_delay(block_ID_b+1)=corrected_delay(block_ID_b+1)+corrected_time_shift;
        peak_vs_average_all(block_ID_a+1,block_ID_b+1)=peak_vs_average_temp;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % c: verify 
        %1.3b time_data_length: only search part of the data (for example: 10000)
        time_data_length=40000;
        %1.4b search_start: -time_between_trains*2 (about 12000*2 clocks)
        search_start=-10;
        %1.5b search_interval: round(mean(average_interval)/16) (about 4000/16)
        search_interval=1;
        %1.6b search_end: -time_between_trains*2 (about 12000*2 clocks)
        search_end=10;
        %1.7b fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
        fixed_offset=corrected_delay(block_ID_b+1); % use updated delay
        % 1.8b plot_flag: 0-- no plot
        plot_flag=1;        
        
        % c: verify the seraching results
        subplot(2,4,block_ID_b+1); 
        %figure;
        delay_search;
        grid on;axis tight;title([num2str(block_ID_a) ':' num2str(block_ID_b)]);
        corrected_delay(block_ID_b+1)=corrected_delay(block_ID_b+1)+corrected_time_shift;
        corrected_delay_all(block_ID_a+1,block_ID_b+1)= corrected_delay(block_ID_b+1);   
        
    end
    
    savefig(fig3,[mat_file_name '_fig3_' num2str(block_ID_a)]);
end

%%%%%%%%%%%%%%%%%%%%%%%
% step 5: delay corrections iteration
corrected_delay_ref_all=[];
corrected_delay_ref_temp=zeros(1,8);

corrected_delay_ref=0;
ref_index=1;
adjust_index=5;
sign_flag=0;
fig4=figure;subplot(2,5,1);
temp_index=[0];
for j=2:160

    if adjust_index>ref_index
        temp=corrected_delay_all(ref_index,adjust_index);
    else
        temp=corrected_delay_all(adjust_index,ref_index);
    end      
    
    if sign_flag==0 
        if adjust_index>ref_index % save to adjust_index
            corrected_delay_ref=corrected_delay_ref+temp; % plus
        else
            corrected_delay_ref=corrected_delay_ref-temp; % subtraction
        end
        corrected_delay_ref_temp(adjust_index)=corrected_delay_ref; % adjust_index  
        temp_index=[temp_index adjust_index];
        
        ref_index=ref_index+1; %change ref_index 
        if ref_index>8
            ref_index=1;
        end
        sign_flag=1;
    else
        if ref_index>adjust_index  % save to ref_index
            corrected_delay_ref=corrected_delay_ref+temp; % plus
        else
            corrected_delay_ref=corrected_delay_ref-temp; % subtraction
        end
        corrected_delay_ref_temp(ref_index)=corrected_delay_ref; % adjust_index       
        temp_index=[temp_index ref_index];

        adjust_index=adjust_index+1; %change adjust_index 
        if adjust_index>8
            adjust_index=1;
        end
        sign_flag=0;
    end
    
    if mod(j,8)==0
%         if mod(j/8,2)==0
%             temp=corrected_delay_ref_temp;
%             corrected_delay_ref_temp(1:4)=corrected_delay_ref_temp(5:8);
%             corrected_delay_ref_temp(5:8)=temp(1:4);
%         end
        
        corrected_delay_ref_all=[corrected_delay_ref_all ...
            corrected_delay_ref_temp];
        hold on;plot(corrected_delay_ref_temp)
        corrected_delay_ref_temp=zeros(1,8);
    end

end

% corrected_delay_ref_all=corrected_delay_ref_temp;

title('Delay correction overlap');xlabel('channel ID');ylabel('Delay');

subplot(2,5,2);;plot(corrected_delay_ref_all);
title('Delay correction');xlabel('channel ID');ylabel('Delay');

% figure;
for i=1:8
    subplot(2,5,i+2);plot(corrected_delay_ref_all(i:8:end)-corrected_delay_ref_all(i));
    title(['Error, block' num2str(i)]);xlabel('channel ID');ylabel('Error');
end

savefig(fig4,[mat_file_name '_fig4']);
save(savefile,'corrected_delay_all','peak_vs_average_all','corrected_delay_ref_all')

corrected_delay_ref_all(1:8)'

return;





