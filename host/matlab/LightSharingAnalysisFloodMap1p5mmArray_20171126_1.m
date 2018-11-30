clear;
clc;
t = 80;

%%窗口晶体测试 （两个晶体一起）
filename = 'PiModule240MHz_sum1024_1hit_50ones_60s_201711191706_XSW_TAP';  % 粗糙5mm窗口，抛光5mm窗口
filename = 'PiModule240MHz_sum1024_1hit_100ones_60s_201711191719_XSW_TAP';  % 粗糙5mm窗口，抛光5mm窗口

%% 窗口晶体测试 粗糙5mm窗口，晶体大小3x3x20mm --无准直
% filename = 'PiModule240MHz_sum1024_1hit_50ones_60s_201712092057_XSW_TAP_1';
% filename = 'PiModule240MHz_sum1024_1hit_50ones_80s_201712092057_XSW_TAP_2';
% filename = 'PiModule240MHz_sum1024_1hit_50ones_80s_201712092057_XSW_TAP_3';
% filename = 'PiModule240MHz_sum1024_1hit_50ones_80s_201712092057_XSW_TAP_4';
% filename = 'PiModule240MHz_sum1024_1hit_25ones_60s_201712092114_XSW_TAP'; 
% 
%% 窗口晶体深度测试 粗糙5mm窗口，晶体大小3x3x20mm ---高度方向准直
filename_all ={ 'PiModule240MHz_sum1024_1hit_50ones_80s_201712092237_XSW_TAP_00mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092241_XSW_TAP_02mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092243_XSW_TAP_04mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092245_XSW_TAP_06mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092247_XSW_TAP_08mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092249_XSW_TAP_10mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092251_XSW_TAP_12mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092253_XSW_TAP_14mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092255_XSW_TAP_16mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092257_XSW_TAP_18mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092259_XSW_TAP_20mm',...;
'PiModule240MHz_sum1024_1hit_50ones_80s_201712092300_XSW_TAP_22mm',...;
};
%   date acq
%  op = '..\..\..\sw\dist\picopet\picopet.exe';
%   
%   trgt = '0x8000';        
%   
%   system([op ' -c 0x0001 ' trgt ' 0x00000000']);
%   system([op ' -c 0x0001 ' trgt ' 0x00000000']);
%   system([op ' -c 0x0001 ' trgt ' 0x00000000']);
%   system([op ' -c 0x0001 ' trgt ' 0x00000000']);
%   system([op ' -c 0x0001 ' trgt ' 0x00000000']);
% system([op ' -a ' num2str(t) ' -o ' filename '.dat']);


%% Data analysis
for filename_index=4:length(filename_all)
filename_index
filename=filename_all{filename_index};
fid=fopen([filename '.dat'],'rb');
raw = fread(fid,'uint32');
fclose(fid);
raw = raw(2001:end);

% energy, bit 15 downto 0
eng = mod(raw, 65536);

% channels number defined in firmware, bit 23 downto 16
ch_fw = mod(bitshift(raw, -16), 256) + 1;

event_count=mod(bitshift(raw, -24), 256);
load('ARRAY10x10_CH_TABLE.mat')
ch = ARRAY10x10_CH_TABLE(ch_fw,'chtable');
chtable = ARRAY10x10_CH_TABLE.chtable;
clear ARRAY10x10_CH_TABLE;
% channels number defined in PiRAT ring systerm
ch = table2array(ch);

evt_cnt = bitshift(raw, -24) - 128;

% %% Data analysis
% fid1=fopen([filename1 '.dat'],'rb');
% raw1 = fread(fid,'uint32');
% fclose(fid);
% raw1 = raw1(2001:end);
% 
% % energy, bit 15 downto 0
% eng1 = mod(raw1, 65536);
% 
% % channels number defined in firmware, bit 23 downto 16
% ch_fw1 = mod(bitshift(raw1, -16), 256) + 1;
% 
% event_count1=mod(bitshift(raw1, -24), 256);
% 
% load('ARRAY10x10_CH_TABLE.mat')
% ch1 = ARRAY10x10_CH_TABLE(ch_fw1,'chtable');
% chtable = ARRAY10x10_CH_TABLE.chtable;
% clear ARRAY10x10_CH_TABLE;
% % channels number defined in PiRAT ring systerm
% ch1 = table2array(ch1);
% 
% evt_cnt1 = bitshift(raw1, -24) - 128;

clear raw;
data = [ch, eng];
% data1 = [ch1, eng1];

%% ????
% eng100 = reshape(eng,[100 length(eng)/100])';
eng=eng(1:fix(length(eng)/100)*100);
eng100 = reshape(eng,[100 length(eng)/100])';
% eng100(:,55) = 0;
% eng100(:,77) = 0;
engmax = max(eng100');
new_eng100 = eng100;
for i = 1:100
    new_eng100(:,chtable(i)) = eng100(:,i);
end

evt_data = new_eng100(:,1:100);
eng_total = sum(evt_data,2);
% clear eng100 new_eng100;

temp=sum(evt_data);
figure;imagesc(reshape(temp,10,10),[0 max(temp)])
colormap gray;

%return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step1: display energy spectra
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
temp_test=[4 5 6 7 8 9 10];
SiPM_arry_index_test=[temp_test;temp_test+10;temp_test+20;temp_test+30;temp_test+40;temp_test+50;temp_test+60];
for i=1:7
    for j=1:7
        subplot(7,7,(i-1)*7+j);
        temp_index_test=SiPM_arry_index_test(i,j);
        hist(new_eng100(:,temp_index_test),0:1:3000);xlim([100 999]);
        title(num2str(temp_index_test));
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step2: Analyze array1, Method 1: center of gravity flood map (global, SiPM 3mm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flood_size=256; %64; %128; % Xie Siwei 1
sampling_precision_ratio=1; %8;  % Xie Siwei 2

temp=[7 8 9 10];
SiPM_arry_index=[temp;temp+10;temp+20;temp+30];

new_eng100_round=round(new_eng100/sampling_precision_ratio);

array_total_eng=zeros(length(new_eng100_round),1);
% array_eng_Col_1=zeros(length(new_eng100_round),1);
% array_eng_Col_2=zeros(length(new_eng100_round),1);
% array_eng_Col_3=zeros(length(new_eng100_round),1);
% array_eng_Col_4=zeros(length(new_eng100_round),1);
% array_eng_Row_1=zeros(length(new_eng100_round),1);
% array_eng_Row_2=zeros(length(new_eng100_round),1);
% array_eng_Row_3=zeros(length(new_eng100_round),1);
% array_eng_Row_4=zeros(length(new_eng100_round),1);
array_eng_Col=zeros(length(new_eng100_round),4);
array_eng_Row=zeros(length(new_eng100_round),4);


for i=1:4
    for j=1:4
        temp_index=SiPM_arry_index(i,j);
        array_eng_Col(:,i)=array_eng_Col(:,i)+new_eng100_round(:,temp_index);
    end
end

for i=1:4
    for j=1:4
        temp_index=SiPM_arry_index(j,i);
        array_eng_Row(:,i)=array_eng_Row(:,i)+new_eng100_round(:,temp_index);
    end
end

array_total_eng= array_eng_Col(:,1) + ...
    array_eng_Col(:,2) + ...
    array_eng_Col(:,3) + ...
    array_eng_Col(:,4);

% % edge
% array_total_eng=array_total_eng+new_eng100_round(:,24)...
%     +new_eng100_round(:,25)...
%     +new_eng100_round(:,26)...
%     +new_eng100_round(:,27);
% array_eng_Col_0=new_eng100_round(:,24)+...
%     new_eng100_round(:,25)+...
%     new_eng100_round(:,26)+...
%     new_eng100_round(:,27);

figure;hist(array_total_eng,0:1:3000);xlim([100 3000]);title('Array1.5');

x_pos=round((array_eng_Col(:,2)+ ... 
    2*array_eng_Col(:,3)+ ...
    3*array_eng_Col(:,4) ...
    )./array_total_eng/3*flood_size);


y_pos=round((array_eng_Row(:,2)+ ... 
    2*array_eng_Row(:,3)+ ...
    3*array_eng_Row(:,4) ...
    )./array_total_eng/3*flood_size);

flood_map=zeros(flood_size,flood_size);

%  Xie Siwei 3, modify the energy window here
Energy_cut_low=850;
Energy_cut_high=1150;
% [x,y]=ginput(2)
% Energy_cut_low=x(1);
% Energy_cut_high=x(2);

for i=1:length(array_total_eng)
    if x_pos(i)>0 && x_pos(i)<flood_size && y_pos(i)>0 && y_pos(i)<flood_size ...
            && array_total_eng(i)*sampling_precision_ratio>Energy_cut_low ...
            && array_total_eng(i)*sampling_precision_ratio <Energy_cut_high  
        flood_map(x_pos(i),y_pos(i))=flood_map(x_pos(i),y_pos(i))+1;
    end
end

fig1=figure;imagesc(flood_map);colorbar; %colormap gray
filename_fig=[filename '_Map1_' num2str(flood_size) '_R' num2str(sampling_precision_ratio) '.fig'];
filename_jpg=[filename '_Map1_' num2str(flood_size) '_R' num2str(sampling_precision_ratio) '.jpg'];
saveas(fig1,filename_fig);
saveas(fig1,filename_jpg);
close all;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Step3: Analyze array1, Method 1: center of gravity flood map (global, 6mm SiPM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%     x_pos_6mm=round((array_eng_Col(:,1)+ ... 
%     array_eng_Col(:,2)+ ...
%     2*array_eng_Col(:,3)+ ...
%     2*array_eng_Col(:,4) ...
%     )./array_total_eng/2*flood_size);
% 
% 
% y_pos_6mm=round((array_eng_Row(:,1)+ ... 
%     array_eng_Row(:,2)+ ...
%     2*array_eng_Row(:,3)+ ...
%     2*array_eng_Row(:,4) ...
%     )./array_total_eng/2*flood_size);
% 
% x_pos_6mm=round((array_eng_Col(:,3)+ ... 
%     array_eng_Col(:,4) ...
%     )./array_total_eng*flood_size);
% 
% 
% y_pos_6mm=round((array_eng_Row(:,3)+ ... 
%     array_eng_Row(:,4) ...
%     )./array_total_eng*flood_size);
% 
% 
% flood_map_6mm=zeros(flood_size,flood_size);
% 
% %  Xie Siwei 3, modify the energy window here
% Energy_cut_low=850;
% Energy_cut_high=1150;
% 
% for i=1:length(array_total_eng)
%     if x_pos_6mm(i)>0 && x_pos_6mm(i)<flood_size && y_pos_6mm(i)>0 && y_pos_6mm(i)<flood_size ...
%             && array_total_eng(i)*sampling_precision_ratio>Energy_cut_low ...
%             && array_total_eng(i)*sampling_precision_ratio <Energy_cut_high  
%         flood_map_6mm(x_pos_6mm(i),y_pos_6mm(i))=flood_map_6mm(x_pos_6mm(i),y_pos_6mm(i))+1;
%     end
% end
% 
% fig1=figure;imagesc(flood_map_6mm);colorbar; %colormap gray
% filename_fig=[filename '_Map2_' num2str(flood_size) '_R' num2str(sampling_precision_ratio) '.fig'];
% filename_jpg=[filename '_Map2_' num2str(flood_size) '_R' num2str(sampling_precision_ratio) '.jpg'];
% saveas(fig1,filename_fig);
% saveas(fig1,filename_jpg);
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Step4: Energy spectra for each SiPM(not for each crystal)
% % 4 crystals per SiPM
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% [temp_Y temp_I]=max(new_eng100');
% 
% figure;
% 
% for i=1:4
%     for j=1:4
%         temp_index=SiPM_arry_index(i,j);
%         subplot(4,4,(i-1)*4+j);
%         hist(array_total_eng(temp_I==temp_index),0:1:3000);xlim([100 3000]);title(num2str(temp_index));
%     end
% end
