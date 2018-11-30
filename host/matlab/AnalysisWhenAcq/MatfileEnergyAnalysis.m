% clear all
% close all
% clc

addpath(genpath('\'));
%     load([filename '.mat']);
%     figure;title('before');
%     for moduleID=0:1:15
%         moduleIndex=find(single_event_data(:,4)==moduleID);
%         subplot(4,4,moduleID+1);hist(single_event_data(moduleIndex,2),0:1:2048);xlim([0 2052]);
%     end

for module=0:15
    single_event_data_new=[];
    single_event_data_new=GainCalibration( single_event_data,module);
    single_event_data=single_event_data_new;
end
save([filename 'GainCorrectt.mat'],'single_event_data');
%     figure;title('after');
%     for moduleID=0:1:15
%         moduleIndex=find(single_event_data(:,4)==moduleID);
%         subplot(4,4,moduleID+1);hist(single_event_data(moduleIndex,2),0:0.5:2048);xlim([0 2052]);
%     end
clearvars except file