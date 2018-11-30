

for i=10:10:60
    filename = ['..\..\..\..\data_WearableSystem\16module_Source_20180725\16module_Source_' int2str(i)];
    load([filename '.mat']);
    %Ä£¿éIDÓ³Éä
    load('moduleID2.mat');
    single_event_data(:,4)=moduleID2(single_event_data(:,4)+1,1);
    save([filename '_a.mat'],'single_event_data');
end