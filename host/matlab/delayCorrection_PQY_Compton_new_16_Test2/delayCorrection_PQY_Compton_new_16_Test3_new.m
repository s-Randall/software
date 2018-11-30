clear all;
close all;

pos_num=1;
analysis_num=30;
analysis_intervel=1;
analysis_start=1;
corrected_delay_final=zeros(17,pos_num*(analysis_num-analysis_start)/analysis_intervel+1);
save('corrected_delay_final.mat','corrected_delay_final');

% for position=1:pos_num
%     for acq_num=1:analysis_num
for position=1:pos_num
    for acq_num=4:7
%     for acq_num=analysis_start:analysis_intervel:analysis_num
%         acq_num=2
        
%         mat_file_name=['..\..\..\..\data_WearableSystem\16module_Source_20180810\16module_Test_' int2str(acq_num) 'GainCorrectt'];
        
        
        if position==1
            mat_file_name=['..\..\..\..\data_WearableSystem\16module_Source_20180912\16module_pt1_' int2str(acq_num) 'GainCorrectt'];
        elseif position==2
            mat_file_name=['..\..\..\..\data_WearableSystem\16module_Source_20180709\16module_Source_p2_' int2str(acq_num)];
        else
            mat_file_name=['..\..\..\..\data_WearableSystem\16module_Source_20180709\16module_Source_p3_' int2str(acq_num)];
        end
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


% % %         %%%%画出single_event_data的所有的数据
% % %         fig1=figure;
% % %         subplot(231);hist(single_event_data(:,1),[0:101]);
% % %         title('channel ID');axis tight;
% % %         subplot(232);hist(single_event_data(:,2),[-1:1:1201]);xlim([0 1200]);
% % %         title('energy')
% % %         subplot(233);hist(single_event_data(:,3),1000);
% % %         title('Time');axis tight;
% % %         subplot(234);hist(single_event_data(:,4),[0:max(single_event_data(:,4))]);
% % %         title('Block ID');axis tight;
% % %         subplot(235);hist(single_event_data(:,5),[0:256]);
% % %         title('Train ID');axis tight;
% % %         subplot(236);plot(single_event_data(1:1000,5));
% % %         title('Train ID');axis tight;
% % % 
% % %         savefig(fig1,[mat_file_name '_fig1']);


        %%%%%%能量窗筛选
        %%%%%%%%%%%%%%%%%%%%%%%
        % step 1: set energy window here
        low_cut= 150; %250; %200; %150; %450;
        High_cut= 800; %350; % 400; %800; %650;

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



        % % two crystal row/column
        % %1,2,...,10; 11,12,...,20
        % boundary_index_aa=single_event_data(:,1)<21;
        % %9,19,...,99; 10,20,...,100
        % boundary_index_bb=((rem(single_event_data(:,1),10)==0) | (rem(single_event_data(:,1),10)==9));
        % %100,99,...,91; 90,89,...,81
        % boundary_index_cc=single_event_data(:,1)>80;
        % %91,81,...,1; 92,82,...,2
        % boundary_index_dd=((rem(single_event_data(:,1),10)==1) | (rem(single_event_data(:,1),10)==2));

        % 4 crystals
        % two crystal row/column
        %4,5,6,7
        boundary_index_aa=boundary_index_a;
        %boundary_index_aa=single_event_data(:,1)>3 & single_event_data(:,1)<8;
        %40,50,60,70
        boundary_index_bb= boundary_index_b;
        %boundary_index_bb= (single_event_data(:,1)==40 | single_event_data(:,1)==50 | single_event_data(:,1)==60 | single_event_data(:,1)==70 );
        %94,95,96,97
        boundary_index_cc= boundary_index_c;
        %boundary_index_cc= (single_event_data(:,1)==94 | single_event_data(:,1)==95 | single_event_data(:,1)==96 | single_event_data(:,1)==97 );
        %41,51,61,71
        boundary_index_dd= boundary_index_d;
        %boundary_index_dd= (single_event_data(:,1)==41 | single_event_data(:,1)==51 | single_event_data(:,1)==61 | single_event_data(:,1)==71 );
        %%%%%%%%%%%%%

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

             %%%下面是把时间化成连续的,下面两个判断主要去除了毛刺的情况
            for j=2:length(temp)
                if temp_100(j)<temp(j-1)
                    offset=offset+2^24;
                end
                if temp_100(j-1)<temp(j)
                    offset=offset-2^24;
                end
                adjusted_temp(j)=adjusted_temp(j)+offset;
            end
            %重新将排成连续后的时间填回数据里
            single_event_data(valid_index,3)=adjusted_temp;

            %the start time of each block    起始时间，第一个有效事件的时间标签
            block_start_time=[block_start_time adjusted_temp(1)];   %%起始时间

            %%同一模块的首时间与末事件的时间差，除上事件数，得到的单个事件的间隔
            temp=(adjusted_temp(end)-adjusted_temp(1))/(length(adjusted_temp)-1);   %%平均事件间隔
            %average time intervals in each block (related to average event rate)
            
            %%将16模块的事件间隔排列在一个数组
            average_interval=[average_interval round(temp)];

        end

        %shift of the start time of each block (ref to the first block )
        %%%计算各个模块起始时间相对于1模块的偏置
        block_start_time_shift=block_start_time;
        block_start_time_shift=block_start_time-block_start_time(1);  

        
        abnormal_block = find(abs(block_start_time_shift) > 2^23);
        for ab_block = abnormal_block
            if block_start_time_shift(ab_block) < 0
                ab_index = single_event_data(:,4) == (ab_block -1);
                single_event_data(ab_index,3) = single_event_data(ab_index,3) + 2^24;
                block_start_time_shift(ab_block) = block_start_time_shift(ab_block) + 2^24;
            else
                ab_index = single_event_data(:,4) == (ab_block -1);
                single_event_data(ab_index,3) = single_event_data(ab_index,3) - 2^24;
                block_start_time_shift(ab_block) = block_start_time_shift(ab_block) - 2^24;
            end
        end

        save(mat_file_name,'single_event_data');
        
        % figure;
        % for block_ID=0:7
        %     subplot(2,4,block_ID+1)
        %     valid_index=(single_event_data(:,4)==block_ID);
        %     temp=single_event_data(valid_index,3);
        %     plot(temp(1:300000))
        % end

% % %         fig2=figure;
% % %         subplot(221);plot(average_interval);
% % %         xlabel('block ID');ylabel('average time intervals (clocks)');
% % %         title('average time intervals between events(# of clocks)');


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

% % %         subplot(222);plot(temp_sum_time_average);xlabel('train ID');ylabel('average time');
% % %         subplot(223);plot(temp_delta_time_average);xlabel('train ID');ylabel('average delta time');
% % %         %title(['average time interval between two trains: ' num2str(round(mean(temp_delta_time_average)))]);
% % %         title(['average time interval between two trains: ' num2str(time_between_trains)]);
% % % 
% % %         subplot(224);plot(block_start_time_shift/time_between_trains);
% % %         xlabel('Block ID');
% % %         title('Offset (unit: # of trains) of the first event (ref to the first block)');
% % %         ylabel(['Offset/time\_between\_trains ' num2str(time_between_trains) 'clocks']);
% % % 
% % %         savefig(fig2,[mat_file_name '_fig2']);

% % %         fig2_1=figure;
% % %         for i=0:15 %train num
% % %             t=(single_event_data(:,4)==i);
% % %             tt=single_event_data(t,3);
% % %             subplot(4,4,i+1);plot(tt(2:end)-tt(1:end-1));axis tight;
% % %         end
% % %         savefig(fig2_1,[mat_file_name '_fig2_1']);    
% % %         clear t;
% % %         clear tt;
        clear adjusted_temp;
        clear temp_100;

        % loop_a=3;
        % loop_b=3;

% % %         fig_a=figure;
% % %         fig_b=figure;
% % %         fig_c=figure;
% % %         fig_d=figure;
        plot_index=0;

        loop_times=16; %64;
        corrected_delay_block_ID=zeros(1,loop_times);
        corrected_delay=zeros(1,loop_times);
        corrected_delay_ref_all=zeros(1,loop_times+1);
        peak_vs_average_all=zeros(1,loop_times);

        block_ID_a=-1;

        plot_enable=0;

        %for block_ID_a=0:15
        for loop_index=1:loop_times
            block_ID_a=block_ID_a+1;

            if block_ID_a==16
                block_ID_a=0;
            end

        %     if loop_a==1
        %         loop_a=3;
        %         loop_b=3;
        %     else
        %         loop_a=1;
        %         loop_b=1;
        %     end
            loop_a=3;
            loop_b=1;


            block_ID_b=block_ID_a+1;
            if block_ID_b==16
                block_ID_b=0;
            end

            corrected_delay_block_ID(loop_index)=block_ID_b;

            %1.1 time_data_a: time data
            %valid_index=(single_event_data(:,4)==block_ID_a);

            if loop_a==1
                valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_aa;
            end
            if loop_a==2
                valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_bb;
            end
            if loop_a==3
                valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_cc;
            end
            if loop_a==4
                valid_index=(single_event_data(:,4)==block_ID_a) & Energy_cut_index & boundary_index_dd;
            end


            time_data_a=single_event_data(valid_index,3);


            corrected_delay(loop_index)=block_start_time_shift(block_ID_b+1) ...
                -block_start_time_shift(block_ID_a+1);

            %1.2 time_data_b: time data
            %valid_index=(single_event_data(:,4)==block_ID_b);
            if loop_b==1
                valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_aa;
            end
            if loop_b==2
                valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_bb;
            end
            if loop_b==3
                valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_cc;
            end
            if loop_b==4
                valid_index=(single_event_data(:,4)==block_ID_b) & Energy_cut_index & boundary_index_dd;
            end

% % %             plot_index=plot_index+1;
% % %             if plot_index>16
% % %                 plot_enable=0;
% % %             end

            time_data_b=single_event_data(valid_index,3);

            %1.3a time_data_length: only search part of the data (for example: 10000)
            time_data_length=2000;
            %1.4a search_start: -time_between_trains*2 (about 12000*2 clocks)
            search_start=round(-time_between_trains*4);
            %1.5a search_interval: round(mean(average_interval)/32) (about 4000/16)
            search_interval=ceil(mean(average_interval)/128);
            %1.6a search_end: -time_between_trains*2 (about 12000*2 clocks)
            search_end=round(time_between_trains*4);
            %1.7a fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
            fixed_offset=corrected_delay(loop_index);
            % 1.8a plot_flag: 0-- no plot
            plot_flag=0;

            % A: perform the first delay search
% % %             if plot_enable==1
% % %                 figure(fig_a); subplot(4,4,plot_index);
% % %             else
% % %                 figure(fig_d); subplot(1,3,1);
% % %             end
            delay_search;
% % %             title(['BLK' num2str(block_ID_a) '\_' num2str(loop_a) ': BLK' ...
% % %                 num2str(block_ID_b) '\_' num2str(loop_b) ]);
            % 2. outputs: 2.1 corrected_time_shift: corrected time delay shift
            corrected_delay(loop_index)=corrected_delay(loop_index)+corrected_time_shift;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%b. second search
            previous_search_interval=search_interval;

            %1.3b time_data_length: only search part of the data (for example: 10000)
            time_data_length=2000; %2000;
            %1.4b search_start: -time_between_trains*2 (about 12000*2 clocks)
            %search_start=round(-previous_search_interval*2);
            search_start=round(-previous_search_interval*2);
            %1.5b search_interval: round(mean(average_interval)/16) (about 4000/16)
            search_interval=1;
            %1.6b search_end: -time_between_trains*2 (about 12000*2 clocks)
            search_end=round(previous_search_interval*2);
            %1.7b fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
            fixed_offset=corrected_delay(loop_index); % use updated delay
            % 1.8b plot_flag: 0-- no plot
            plot_flag=0;

            % B: perform the second delay search
% % %             if plot_enable==1
% % %                 figure(fig_b); subplot(4,4,plot_index);
% % %             else
% % %                 figure(fig_d); subplot(1,3,1);
% % %             end
            delay_search;
            % 2. outputs: 2.1 corrected_time_shift: corrected time delay shift
            corrected_delay(loop_index)=corrected_delay(loop_index)+corrected_time_shift;
            peak_vs_average_all(loop_index)=peak_vs_average_temp;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % c: verify
            %1.3b time_data_length: only search part of the data (for example: 10000)
            time_data_length=min([20000,length(time_data_a),length(time_data_b)]);
            %1.4b search_start: -time_between_trains*2 (about 12000*2 clocks)
            search_start=-10;
            %1.5b search_interval: round(mean(average_interval)/16) (about 4000/16)
            search_interval=1;
            %1.6b search_end: -time_between_trains*2 (about 12000*2 clocks)
            search_end=10;
            %1.7b fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
            fixed_offset=corrected_delay(loop_index); % use updated delay
            % 1.8b plot_flag: 0-- no plot
            plot_flag=0;

            % c: verify the seraching results
% % %             if plot_enable==1
% % %                 figure(fig_c); subplot(4,4,plot_index);
% % %             else
% % %                 figure(fig_d); subplot(1,3,1);
% % %             end
            delay_search;
% % %             grid on;axis tight;title([num2str(block_ID_a) ':' num2str(block_ID_b)]);
            corrected_delay(loop_index)=corrected_delay(loop_index)+corrected_time_shift;
            %corrected_delay_all(block_ID_a+1,block_ID_b+1)= corrected_delay(loop_index);


            corrected_delay_ref_all(loop_index+1)=corrected_delay_ref_all(loop_index)+corrected_delay(loop_index);
        end

% % %         savefig(fig_a,[mat_file_name '_figa_' num2str(low_cut) '_' num2str(High_cut) ]);
% % %         savefig(fig_b,[mat_file_name '_figb_' num2str(low_cut) '_' num2str(High_cut) ]);
% % %         savefig(fig_c,[mat_file_name '_figc_' num2str(low_cut) '_' num2str(High_cut) ]);


% % %         figure;plot(corrected_delay_ref_all);
        savefile_temp=[savefile(1:end-4) '_' num2str(low_cut) '_' num2str(High_cut) '.mat'];
        save(savefile_temp,'corrected_delay_block_ID','corrected_delay',...
            'peak_vs_average_all','corrected_delay_ref_all');

        load('corrected_delay_final.mat');
        corrected_delay_final(:,acq_num/analysis_intervel+(position-1)*analysis_num)=corrected_delay_ref_all';
        
        save('corrected_delay_final.mat','corrected_delay_final');
        
        close all
        clc
        clearvars -EXCEPT pos_num analysis_num position acq_num analysis_start analysis_intervel
        
    end
end
        

