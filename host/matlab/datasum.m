close all
clear
clc
m=2;
filename=['..\..\..\data_WearableSystem\16module_Source_20180810\16module_test_'];
load([filename int2str(m) '.mat']);

for i=0:15
    index1=single_event_data(:,4)==i;
    index=single_event_data(index1,2)>450 & single_event_data(index1,2)<550;
    sum1(i+1)=length(index);
end
figure;plot(sum1);ylim([0 max(sum1)]);

figure;
for moduleID=0:1:15
    moduleIndex=find(single_event_data(:,4)==moduleID);
    subplot(4,4,moduleID+1);hist(single_event_data(moduleIndex,2),0:0.5:2048);xlim([0 2052]);ylim([0 2000])
end

load([filename int2str(m) 'GainCorrectt' '.mat']);
figure;
for moduleID=0:1:15
    moduleIndex=find(single_event_data(:,4)==moduleID);
    subplot(4,4,moduleID+1);hist(single_event_data(moduleIndex,2),0:0.5:2048);xlim([0 2052]);
end

for i=0:15
    index1=single_event_data(:,4)==i;
    index=single_event_data(index1,2)>450 & single_event_data(index1,2)<550;
    sum2(i+1)=length(index);
end
figure;plot(sum2);ylim([0 max(sum1)]);
