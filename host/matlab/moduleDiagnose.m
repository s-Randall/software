clear all;

sng_cnts = zeros(100,16);
for file_num =1:5
    single_event_data = [];
    mat_file_name=['..\..\..\..\data_WearableSystem\16module_source_20181129\16module_pt0_' int2str(file_num)  ];  
    load([mat_file_name '.mat']);
    
    for m = 0:15
        ch_sng_cnt = zeros(100,1);
    	ch_sng_cnt = ch_sng_cnt + module_diagnose(m, single_event_data, 0);
        sng_cnts(:,m+1) = sng_cnts(:,m+1) + ch_sng_cnt;
    end
end


[max_ch_cnts, max_ch] = max(sng_cnts);
figure;plot(1:16,max_ch_cnts);

total_cnts = sum(sng_cnts,1);
figure;plot(1:16,total_cnts);

% data = [];
% for file_num = 1:1
%     single_event_data = [];
%     mat_file_name=['K:\data_WearableSystem\16module_Source_20181018\16module_pt0__' int2str(file_num)  ];  
%     load([mat_file_name '.mat']);
%     data = [data; single_event_data;];
% end

% module_diagnose(4, data, 1);
