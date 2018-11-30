% clear all
% close all
% clc
tic;
for i=436
    filename = ['F:\资料\小动物\16模块\d121013\16module_flood_d12__' int2str(i),'.mat'];
    addpath(genpath('.\'));
    if (exist(filename) == 0)
        continue;
    end
    load([filename]);
    i
    
    %     figure;title('energy');
    %     for moduleID=0:1:15
    %         moduleIndex=find(single_event_data(:,4)==moduleID);
    %         subplot(4,4,moduleID+1);hist(single_event_data(moduleIndex,2),0:1:2048);xlim([0 2052]);
    %     end
    %     figure;title('TDC');
    %     for moduleID=0:1:15
    %         moduleIndex=find(single_event_data(:,4)==moduleID);
    %         subplot(4,4,moduleID+1);plot(single_event_data(moduleIndex,3));xlim([0 20000]);
    %     end
    % moduleIndex=find(single_event_data(:,4)==14);
    % figure;plot(single_event_data(moduleIndex,3));
    % figure;plot(single_event_data(moduleIndex(390000:400000),5));
    % end
    
    
    for module=0:0
        for ch_num = 1:100
            ch_num
            single_event_data_new=[];
            single_event_data_new=GainCalibration( single_event_data,module,ch_num);
            single_event_data=single_event_data_new;
        end
    end
    
%     save([filename 'GainCorrectt.mat'],'single_event_data','-v7.3');
    %     figure;title('after');
    %     for moduleID=0:1:15
    %         moduleIndex=find(single_event_data(:,4)==moduleID);
    %         subplot(4,4,moduleID+1);hist(single_event_data(moduleIndex,2),0:0.5:2048);xlim([0 2052]);
    %     end
    clearvars except i
    % end
end
toc