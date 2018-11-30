module_data = [];

for file_num = 1:1
    mat_file_name=['..\..\..\..\data_WearableSystem\16module_source_20181129\16module_pt0_' int2str(file_num)  ];  
    load([mat_file_name '.mat']);
  
    moduleID = 4;%È¡Öµ·¶Î§0-15
    moduleIndex=find(single_event_data(:,4)==moduleID);
    module_data = [module_data; single_event_data(moduleIndex,:)];
end

sng_cnt = zeros(100,1);

for n = 1:4
    figure;
    for i = 1:5
        for j = 1:5
            ch_num = (n - 1) * 25 + (i - 1) * 5 + j;
            ch_index = find(module_data(:,1) == ch_num);
            sng_cnt(ch_num) = length(ch_index);
            ch_eng = module_data(ch_index,2);
            [eng_hist,x] = hist(ch_eng,0:0.1:2048);
            subplot(5,5,(i-1)*5+j);plot(x,eng_hist);xlim([0 2500])
        end
    end
end

figure;plot(1:1:100, sng_cnt);

sng_cnt5 = sng_cnt;

figure;plot(1:1:100, sng_cnt);hold on;
plot(1:1:100, sng_cnt5);