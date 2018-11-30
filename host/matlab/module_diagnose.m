function [sng_cnt] = module_diagnose(module_num, data, figure_on)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
    module_data = [];

    for file_num = 1:2
        module_index = find(data(:,4) == module_num);
        module_data = [module_data; data(module_index,:)];
    end

    sng_cnt = zeros(100,1);
    for n = 1:4
        if figure_on == 1
            figure;
        end
        
        for i = 1:5
            for j = 1:5
                ch_num = (n - 1) * 25 + (i - 1) * 5 + j;
                ch_index = find(module_data(:,1) == ch_num);
                sng_cnt(ch_num) = length(ch_index);
                if figure_on == 1
                    ch_eng = module_data(ch_index,2);
                    [eng_hist,x] = hist(ch_eng,0:0.1:2048);
                    subplot(5,5,(i-1)*5+j);plot(x,eng_hist);xlim([0 2500]);
                end
            end
        end
    end

    if figure_on == 1
        figure;plot(1:1:100, sng_cnt);
    end

end

