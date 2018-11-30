clear all
close all

%���ļ�

filename ='..\..\..\data_Newsystem\2module_20180717\2module_Source_3_eng';
load([filename '.mat']);
% for evt_num=0:1
    index=(eng(:,10)==evt_num);
%     %���ÿ���¼������ܺ�
    evt_data = eng(index,1:end-1);
%     evt_data = eng(:,1:end-1);
    eng_total = sum(evt_data,2);
    %ÿ��ͨ�������¼����������ܺ�
    temp=sum(evt_data);
    figure;imagesc(reshape(temp,3,3),[0 max(temp)])
    colormap gray;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Step1: display energy spectra
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %����λ�ù�ϵ����������ͨ�������Ե������¼�����hist
    figure;
    temp_test=[1 2 3];
    SiPM_arry_index_test=[temp_test;temp_test+3;temp_test+6];
    for i=1:3
        for j=1:3
            subplot(3,3,(i-1)*3+j);
            temp_index_test=SiPM_arry_index_test(i,j);
            hist(eng(index,temp_index_test),0:1:3000);xlim([0 200]);
            title(num2str(temp_index_test));
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Step2: Analyze array1, Method 1: center of gravity flood map (global, SiPM 3mm)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %������Ʋ���
    flood_size=256; %64; %128;
    sampling_precision_ratio=1; %8;
    %��������ѡ��
    temp=[1 2 3];
    SiPM_arry_index=[temp;temp+3;temp+6];
    %������������������
    eng_round=round(eng(index,:)/sampling_precision_ratio);
    %ÿ���¼���������ʼ������
    array_total_eng=zeros(length(eng_round),1);
    %ÿ���¼����и�����������ʼ������
    array_eng_Col=zeros(length(eng_round),3);
    array_eng_Row=zeros(length(eng_round),3);
    %��������ÿ���¼�ÿ��������
    for i=1:3
        for j=1:3
            temp_index=SiPM_arry_index(i,j);
            array_eng_Col(:,i)=array_eng_Col(:,i)+eng_round(:,temp_index);
        end
    end
    %��������ÿ���¼�ÿ��������
    for i=1:3
        for j=1:3
            temp_index=SiPM_arry_index(j,i);
            array_eng_Row(:,i)=array_eng_Row(:,i)+eng_round(:,temp_index);
        end
    end
    %���������ܺ�������¼�������
    array_total_eng= array_eng_Col(:,1) + ...
        array_eng_Col(:,2) + ...
        array_eng_Col(:,3);
    figure;hist(array_total_eng,0:1:5000);xlim([100 2500]);ylim([0 3000]);title('27.5v');hold on

    %���ķ��������꣨x���꣩
    x_pos=round((array_eng_Col(:,2)+ ... 
        2*array_eng_Col(:,3) ...
        )./array_total_eng/2*flood_size);
    %���ķ��������꣨y���꣩
    y_pos=round((array_eng_Row(:,2)+ ... 
        2*array_eng_Row(:,3) ...
        )./array_total_eng/2*flood_size);

    % %���ķ��������꣨x���꣩
    % x_pos=round((array_eng_Col(:,2)+ ... 
    %     2*array_eng_Col(:,1) ...
    %     )./array_total_eng/2*flood_size);
    % %���ķ��������꣨y���꣩
    % y_pos=round((array_eng_Row(:,2)+ ... 
    %     2*array_eng_Row(:,1) ...
    %     )./array_total_eng/2*flood_size);

    %floodmap������
    flood_map=zeros(flood_size,flood_size);
    %����������modify the energy window here
    Energy_cut_low=650; %1510; %1230; %880; %690;  
    plot([Energy_cut_low,Energy_cut_low],[0,2000],'r'); text(Energy_cut_low,1600,int2str(Energy_cut_low));hold on
    Energy_cut_high=950; %1880; %1520; %1270; %980; 
    plot([Energy_cut_high,Energy_cut_high],[0,2000],'r'); text(Energy_cut_high,1600,int2str(Energy_cut_high));
%     filename_fig1=[filename '.fig'];
%     filename_jpg1=[filename '.jpg'];
%     saveas(fig1,filename_fig1);
%     saveas(fig1,filename_jpg1);
    %���������������ݷֲ���floodmap
    for i=1:length(array_total_eng)
        if x_pos(i)>0 && x_pos(i)<flood_size && y_pos(i)>0 && y_pos(i)<flood_size ...
                && array_total_eng(i)*sampling_precision_ratio>Energy_cut_low ...
                && array_total_eng(i)*sampling_precision_ratio <Energy_cut_high  
            flood_map(x_pos(i),y_pos(i))=flood_map(x_pos(i),y_pos(i))+1;
        end
    end
    fig2=figure;imagesc(flood_map);colorbar; %colormap gray
    %����floodmap
%     filename_fig2=[filename '_Map1_' num2str(flood_size) '_R' num2str(sampling_precision_ratio) '.fig'];
%     filename_jpg2=[filename '_Map1_' num2str(flood_size) '_R' num2str(sampling_precision_ratio) '.jpg'];
%     saveas(fig2,filename_fig2);
%     saveas(fig2,filename_jpg2);
    % close all;
% end