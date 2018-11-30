% 1. inputs:
% 1.1 time_data_a: time data
% 1.2 time_data_b: time data
% 1.3 time_data_length: only search part of the data (for example: 10000)
% 1.4 search_start: -time_between_trains*2 (about 12000*2 clocks)
% 1.5 search_interval: round(mean(average_interval)/32) (about 4000/32)
% 1.6 search_end: -time_between_trains*2 (about 12000*2 clocks)
% 1.7 fixed_offset: block_start_time_shift(block_ID_b+1) (ID: 0~7)
% 1.8 plot_flag: 0-- no plot
% 2. outputs:
% 2.1 corrected_time_shift: corrected time delay shift

coincidence=[];
%for time_shift=-time_step*10:100:time_step*10
for time_shift=search_start:search_interval:search_end        
    time_data_temp=time_data_b(1:time_data_length)-time_shift-fixed_offset;
    coincidence_count=0;
    for j=1:time_data_length
        delta_temp=abs(time_data_temp-time_data_a(j));
        temp_count=sum(delta_temp<search_interval);
        coincidence_count=coincidence_count+temp_count;
    end
    coincidence=[coincidence coincidence_count];
end

% % % if plot_flag==1
% % %     plot(coincidence);
% % % end

[Y_max,I_max] = max(coincidence);
time_shift=[search_start:search_interval:search_end];
corrected_time_shift=time_shift(I_max);
peak_vs_average_temp=max(coincidence)/mean(coincidence);






