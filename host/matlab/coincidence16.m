clc;close all;clear all;
dataT=[];
for ii=22
    ii
    filename=strcat('..\..\..\..\data_WearableSystem\16module_Source_20180810\16module_Test_',num2str(ii),'GainCorrectt.mat');
    load(filename);
    
%     load('moduleID.mat');
%     single_event_data((single_event_data(:,4)==128),:)=[];
%     single_event_data(:,4)=moduleID(single_event_data(:,4)+1,1);
    
    data=single_event_data;
    % load('E:\赵指向\穿戴式数据\8module_pt1_30s_300.mat');
    % data=[data;single_event_data];
    % load('E:\赵指向\穿戴式数据\8module_pt1_30s_240.mat');
    % data=[data;single_event_data];
    % load('E:\赵指向\穿戴式数据\8module_pt1_30s_180.mat');
    % data=[data;single_event_data];
    % load('E:\赵指向\穿戴式数据\8module_pt1_30s_120.mat');
    % data=[data;single_event_data];
    % load('E:\赵指向\穿戴式数据\8module_pt1_30s_60.mat');
    % data=[data;single_event_data];
    
    %% step 1: change the periodic array to the linear array
    % for i=0:7
    %     indexO=find(data(:,4)==i);
    %     temp=data(indexO,:);
    %     tempD=temp(1:end-1,3)-temp(2:end,3);
    %     index=find(tempD>2^23);
    %     for j=1:size(index,1)-1
    %         startT=index(j)+1;
    %         endT=index(j+1);
    %         temp(startT:endT,3)=temp(startT:endT,3)+j*2^24;
    %     end
    %     temp(index(j+1)+1:end,3)=temp(index(j+1)+1:end,3)+(j+1)*2^24;
    %     data(indexO,:)=temp;
    % %     figure
    % %     plot(temp(:,3));
    % end
    
    for block_ID=0:15
        valid_index=(data(:,4)==block_ID);
        temp=data(valid_index,3);
        temp_100=temp+2^23;
        adjusted_temp=temp;
        offset=0;        
        for j=2:length(temp)
            if temp_100(j)<temp(j-1)
                offset=offset+2^24;
            end
            if temp_100(j-1)<temp(j)
                offset=offset-2^24;
            end
            adjusted_temp(j)=adjusted_temp(j)+offset;
        end
        data(valid_index,3)=adjusted_temp;
%         figure 
%         plot(adjusted_temp);
    end
%     figure
%     plot(data(:,3));
    
    
    
    %%  step 2: delay calibration
    %delay=[0 -910008 -521038 -495730 374352 1434710 -706466 1033578 213182 1371306 888058 594248 1406618 -666856 3353368 -6054530];
    load('corrected_delay_final.mat');
    for i=0:15
        index=find(data(:,4)==i);
        data(index,3)= data(index,3)-corrected_delay_final(i+1,22);
    end
    timeS=data;
    
    %% step 3: TDC window
    [value,index]=sort(timeS(:,3));
    timeS=timeS(index,:);
    timeD=timeS(2:end,3)-timeS(1:end-1,3);
    index2=find(abs(timeD)<=5);
    timeF=zeros(size(index2,1),10);
    for i=1:size(index2,1)
        if(timeS(index2(i),4)~=timeS(index2(i)+1,4))
            timeF(i,1:5)=timeS(index2(i),:);
            timeF(i,6:10)=timeS(index2(i)+1,:);
        end
        %     if(mod(i,100000)==0)
        %         fprintf('%d\n',i);
        %     end
    end
    
    %% step 4: energy window
%     index=find(timeF(:,4)==14&timeF(:,2)<350);
%     timeF(index,2)=timeF(index,2)+100;
%     index=find(timeF(:,9)==14&timeF(:,7)<350);
%     timeF(index,7)=timeF(index,7)+100;
    
    index=find(timeF(:,2)>=400&timeF(:,2)<=600&timeF(:,7)>=400&timeF(:,7)<=600);
    timeF=timeF(index,:);
    % timeT=timeF(:,[1 4 6 9]);
    % %%  step 5: determin the positions of each coincidence
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    plot1=[timeF(:,4); timeF(:,9)];
    for i=0:15
        plot3(i+1)=sum(plot1==i);
    end
    figure;plot(plot3);ylim([0 max(plot3)]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    dataF=zeros(size(index,1),7);
    radius=198/2+10;
    for i=1:size(index,1)
         %         if(mod(timeF(i,4),2)==0)
%         dataF(i,3)=(-1)^(timeF(i,4)+1)*(-4.5+mod(timeF(i,1)-1,10))*3.34;
        dataF(i,3)=(-1)*(-4.5+mod(timeF(i,1)-1,10))*3.34;
        angle1=timeF(i,4)*22.5*pi/180;
        x0=radius*cos(angle1);
        y0=radius*sin(angle1);
        distance1=3.34*(-1)^(timeF(i,4)+1)*(-4.5+fix((timeF(i,1)-1)/10));
        dataF(i,1)=x0+distance1*cos(angle1+90*pi/180);
        dataF(i,2)=y0+distance1*sin(angle1+90*pi/180);
        %         else
        %             dataF(i,3)=(4.5-mod(timeF(i,1)-1,10))*3.34;
        %             angle1=timeF(i,4)*22.5*pi/180;
        %             x0=radius*cos(angle1);
        %             y0=radius*sin(angle1);
        %             distance1=3.34*(4.5-fix((timeF(i,1)-1)/10));
        %             dataF(i,1)=x0+distance1*cos(angle1+90*pi/180);
        %             dataF(i,2)=y0+distance1*sin(angle1+90*pi/180);
        %         end
        %         if(mod(timeF(i,9),2)==0)
%         dataF(i,6)=(-1)^(timeF(i,9)+1)*(-4.5+mod(timeF(i,6)-1,10))*3.34;
        dataF(i,6)=(-1)*(-4.5+mod(timeF(i,6)-1,10))*3.34;
        angle2=timeF(i,9)*22.5*pi/180;
        x1=radius*cos(angle2);
        y1=radius*sin(angle2);
        distance2=3.34*(-1)^(timeF(i,9)+1)*(-4.5+fix((timeF(i,6)-1)/10));
        dataF(i,4)=x1+distance2*cos(angle2+90*pi/180);
        dataF(i,5)=y1+distance2*sin(angle2+90*pi/180);
        %         else
        %             dataF(i,6)=(4.5-mod(timeF(i,6)-1,10))*3.34;
        %             angle2=timeF(i,9)*22.5*pi/180;
        %             x1=radius*cos(angle2);
        %             y1=radius*sin(angle2);
        %             distance2=3.34*(4.5-fix((timeF(i,6)-1)/10));
        %             dataF(i,4)=x1+distance2*cos(angle2+90*pi/180);
        %             dataF(i,5)=y1+distance2*sin(angle2+90*pi/180);
        %         end
    end
    dataT=[dataT;dataF];
end
% figure
% for i=1:100%size(dataT,1)
%     hold on
%     line([dataT(i,1) dataT(i,4)],[dataT(i,2) dataT(i,5)]);
% end
% hold off

dataT=single(dataT);
% fid=fopen('F:\资料\小动物\16模块\SourceData\16module500-700.s','w');
% fwrite(fid,dataT','float');
% fclose(fid);



