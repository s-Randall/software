close all
clear 
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%   data acq    %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t = 30;          % Acquire data for 10 seconds

filename_template = '..\..\..\data_Newsystem\2module_20180717\2module_Source';

pvolt = 2500;    % Analog Positive Voltage +2.500V
nvolt = 500;     % Analog Negative Voltage -0.500V
svolt = 27500;   % SiPM Bias Voaltage +28.000V
delete(instrfindall);
sipm_power_ctl_port = 'COM4';
analog_positive_power_ctl_port = 'COM5';
analog_negative_power_ctl_port = 'COM6';

set_power = 0;     % ��ģ����Դ�ʹ�������Դ
data_acq = 1;      % ���ֻ�Ƿ������ݣ����԰������0,�����²ɼ�����
init_one_node = 0; % ��ʼ����һ��ڵ����ͣ�ֻ���õ�һ����ӵ�ʱ��������Ϊ1�����ܸ�init_all_nodeͬʱΪ1
init_all_node = 1; % ��ʼ�����а��ӽڵ����ͣ����ö����ӵ�ʱ��������Ϊ1�� ���ܸ�init_one_nodeͬʱΪ1

if set_power == 1 
    % Set dcpower as remote control mode
    dcpower_set_as_remote_mode(analog_positive_power_ctl_port);
    dcpower_set_as_remote_mode(analog_negative_power_ctl_port);
    dcpower_set_as_remote_mode(sipm_power_ctl_port);
    % Set analog positive voltage
    dcpower_set_votage(analog_positive_power_ctl_port, pvolt);    % +2.5V
    % Set analog negative voltage
    dcpower_set_votage(analog_negative_power_ctl_port, nvolt);     % -0.5V
    % Set SiPM bias voaltage
    dcpower_set_votage(sipm_power_ctl_port, svolt);              % +28.0V
end

if set_power == 1 
    dcpower_set_output_on(analog_positive_power_ctl_port);
    dcpower_set_output_on(analog_negative_power_ctl_port);
    dcpower_set_output_on(sipm_power_ctl_port);
end

%op = '..\PiModule\host\sw\dist\picopet\picopet.exe';
op = '..\sw\dist\picopet\picopet.exe';
trgt = '0x0000';
%pin
system([op ' -c 0x0001 ' trgt ' 0x00000000']);
system([op ' -c 0x0001 ' trgt ' 0x00000000']);
system([op ' -c 0x0001 ' trgt ' 0x00000000']);
system([op ' -c 0x0001 ' trgt ' 0x00000000']);
system([op ' -c 0x0001 ' trgt ' 0x00000000']);

if init_one_node == 1
    % Node ID: 0x00 Node Type: 0x00
    system([op ' -c 0x0002 ' trgt ' 0x00000100']);
end

if init_all_node == 1
    trgt = '0xC000';
    system([op ' -c 0x0002 ' trgt ' 0x00000000']);    % 1
    pause(20);
    % ������Ҫ��ʱ10s �����matlab����ʱ��������������
    trgt = '0x000f'; % ������4����Ӽ����������д3����8���д7
    system([op ' -c 0x0002 ' trgt ' 0x0000020f']);    % 2
    pause(5);
    % ��ʱ2s
    % pin���һ����ӣ�pin�ɹ�������ʼ���ɹ�
    system([op ' -c 0x0001 ' trgt ' 0x00000000']);
    system([op ' -c 0x0001 ' trgt ' 0x00000000']);
    system([op ' -c 0x0001 ' trgt ' 0x00000000']);
    system([op ' -c 0x0001 ' trgt ' 0x00000000']);
    system([op ' -c 0x0001 ' trgt ' 0x00000000']);
end

for i= 1:480
    i
    filename = [filename_template '_' int2str(i)];
    
    if data_acq == 1     
        %pin
        system([op ' -c 0x0001 ' trgt ' 0x00000000']);
        system([op ' -c 0x0001 ' trgt ' 0x00000000']);
        
        % ��ʼ�ɼ�
        system([op ' -a ' num2str(t) ' -o ' filename '.dat']);
    end
end

if set_power == 1 
    
    dcpower_set_output_off(sipm_power_ctl_port);
    dcpower_set_output_off(analog_negative_power_ctl_port);
    dcpower_set_output_off(analog_positive_power_ctl_port);
end

pasuse(30);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%   end    %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%   data analysis    %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for j=1:1
    for i=5:5:480
        num=i/5
        %���ļ���ȡ���ݣ��õ�data����
        switch j
            case 1
                filename = ['..\..\..\data_WearableSystem\16module_Source_20180718\16module_Source_' int2str(i)];
            case 2
                filename = ['..\..\..\data_WearableSystem\16module_Source_20180709\16module_Source_p2_' int2str(i)];
            case 3
                filename = ['..\..\..\data_WearableSystem\16module_Source_20180709\16module_Source_p3_' int2str(i)];
        end
        fid=fopen([filename '.dat'],'rb');
        raw = fread(fid,'uint8');
        fclose(fid);
        raw = raw(4001:end);
        data = reshape(raw,4,length(raw)/4)';
        clear raw;
        if length(data)<10000
            fid=fopen('WrongDataAcq.txt','a+');
            fprintf(fid,'%s\n',[filename ' is wrong acq with 4k data']);
            fclose(fid);
            clear
            clc
            continue
        end
        %�ҵ��������������г��ĳ�ͷtrain_head_index
        train_head_8bit = 254;
        p1 = find(data(:,4) == train_head_8bit);
        p2 = p1 + 1;
        if  max(p2) > length(data)
            p2 = p2(1:end - 1);
        end
        train_head_index = p2((data(p2,4) == train_head_8bit) & (data(p2,1) == 0) & (data(p2,2) == 0) &(data(p2,3) == 0));
        clear p1 p2 train_head_8bit;
        train_len = diff(train_head_index);
        %�г���
        train_cnt = length(train_head_index);

        %��ȡ�����������ĳ������ݣ�����data
        c_train_len = 276;
        p1 = find(train_len == c_train_len);
        complet_train_head_index = train_head_index(p1) - 1;  %%�����ü�1
        clear p1 train_len;
        %�����г���
        complet_train_cnt = length(complet_train_head_index);

        train_data_complete = zeros(complet_train_cnt * c_train_len,4);
        head_index = 1 : c_train_len : c_train_len * complet_train_cnt;
        head_index = head_index';
        for i = 0 : 1 : c_train_len - 1
            train_data_complete(head_index + i,:) = data(complet_train_head_index + i,:);
        end
        clear data;
        data = train_data_complete;
        clear train_data_complete complet_train_head_index head_index;

        %ȥ����������ͷβ��ȷ����Ч����Ϊtrain_data
        train_head_8bit = 254;
        p1 = find(data(:,4) == train_head_8bit);
        p2 = p1 + 1;
        if  max(p2) > length(data)
            p2 = p2(1:end - 1);
        end
        train_head_index = p2((data(p2,4) == train_head_8bit) & (data(p2,1) == 0) & (data(p2,2) == 0) &(data(p2,3) == 0));  %%���ܻ��ܵ�TDC�ĸ�λ����Ϊ254��Ӱ��
        clear p1 p2;
        start_index = train_head_index(100)-1;
        end_index = start_index - 1 + c_train_len * floor( (length(data) - start_index + 1)/c_train_len );
        train_data = data(start_index:end_index,:);
        clear train_head_index start_index end_index data;

        % ��ȡ�г�������ģ�����Ч����
        train_head_index = 1:c_train_len:length(train_data);
        train_head_index = train_head_index';
        train_num = train_data(train_head_index,2);
    %     diff_train_num = diff(train_num);
    %     find(diff_train_num ~= 1 & diff_train_num ~= -255);

        %�޳������г�ͷ��β��־
        delete_index = [train_head_index,train_head_index+1,train_head_index+c_train_len-2,train_head_index+c_train_len-1];
        clear train_head_index;
        delete_index = delete_index';
        delete_index = delete_index(:);
        coach0to7_data = train_data;
        coach0to7_data(delete_index,:) = []; % �޳���ͷ
        clear delete_index;
        coach0to7_data = coach0to7_data';
        coach0to7_data = coach0to7_data(:);

        %ɸѡ�˳�ͷ��0~7ģ�鳵������
        coach0to7_data = reshape(coach0to7_data,17*4*16,[]);
        coach0to7_data = coach0to7_data(1:17*4*16,:)';
        coach0to7_data= coach0to7_data';
        coach0to7_data= coach0to7_data(:);
        coach0to7_data= reshape(coach0to7_data,4,[])';

        %����������Ϊ������ݵ��滻�������ݵ�0 128 128 128
        index_temp1 = (find(coach0to7_data(1:17:end,4)==143) - 1) * 17 + 1; % �ҵ������һ��Ϊ����¼����ݵ�����
        coach0to7_data(index_temp1,:) = repmat([0 128 128 128],length(index_temp1),1);

        %������ĩ��Ϊ������ݵ��滻�������ݵ�0 128 128 128
        index_temp2 = (1:17:length(coach0to7_data))';                         % ���г����һ����������
        index_temp3 = index_temp2 + coach0to7_data(index_temp2 + 16,2) - 1;   % ���г�������һ����Ч��������
        index_temp3 = index_temp3(2:end);
        index_temp4 = find(coach0to7_data(index_temp3,4)==142);               %
        index_temp5 = index_temp3(index_temp4);                               % ���г������һ����Ч���ݲ��������¼����ݽ�β������
        index_temp6 = index_temp2(index_temp4) + 16;                          % �������һ����Ч���ݲ��������¼����ݽ�β�ĳ���ĳ�β����
        coach0to7_data(index_temp5,1) = coach0to7_data(index_temp6,2) - 1;
        coach0to7_data(index_temp5,2:end) = repmat([128 128 128],length(index_temp5),1);

        %����ȥ��������������������β��sigle event������
        coach0to7_data(index_temp1+16,2) = coach0to7_data(index_temp1+16,2) - 1;
        coach0to7_data(index_temp6+16,2) = coach0to7_data(index_temp6+16,2) - 1;
        clear index_temp1 index_temp2 index_temp3 index_temp4 index_temp5 index_temp6;

        %��ȡÿ�ڳ����sigle event�������޳�����β
        module_num = coach0to7_data(1*17:17:end,3);
        coach0to7_data(1*17:17:end,:) = []; % �޳�����β

        %��ģ������ӵ�coach0to7_data
        temp = repmat(module_num,1,16)';
        temp = temp(:);
        coach0to7_data = [coach0to7_data temp];
        clear module_num temp;

        %���г������ӵ�coach0to7_data
        temp = repmat(train_num,1,16*16)';
        temp = temp(:);
        coach0to7_data = [coach0to7_data temp];
        clear train_num temp;

        %�޳�������0 128 128 128
        delete_index = coach0to7_data(:,4) == 128;
        coach0to7_data(delete_index,:)=[];
        clear delete_index;

        %�����ݸ�32λ���32λ�Ƿ�һ����
    %     p1 = find(coach0to7_data(:,4) == 143);
    %     p2 = p1 - 1;
    %     p3 = p2(coach0to7_data(p2,4) == 143);

        %��sigle event���ݸ�32λ���32λ��Ϊ����
        coach0to7_data= coach0to7_data';
        coach0to7_data= coach0to7_data(:);
        if rem(length(coach0to7_data),12)~=0
            fid=fopen('WrongDataAcq.txt','a+');
            fprintf(fid,'%s\n',[filename ' is wrong acq with wrong data']);
            fclose(fid);
            clear
            clc
            continue
        else
            coach0to7_data= reshape(coach0to7_data,12,[])';
        end

        % ����single event data
        single_event_data = zeros(length(coach0to7_data),5); % ch eng tdc module train
        single_event_data(:,1) = coach0to7_data(:,3) + 1;
        single_event_data(:,2) = coach0to7_data(:,1) + coach0to7_data(:,2) * 256;
        single_event_data(:,3) = coach0to7_data(:,7) + coach0to7_data(:,8) * 256 + coach0to7_data(:,9) * 256 * 256;
        single_event_data(:,4) = coach0to7_data(:,5);
        single_event_data(:,5) = coach0to7_data(:,6);
        clear coach0to7_data;

        % ͨ��ӳ��
        load('ARRAY10x10_CH_TABLE.mat');
        single_event_data(:,1) = table2array( ARRAY10x10_CH_TABLE( single_event_data(:,1),'chtable' ) );  % channels number defined in schematic
        clear ARRAY10x10_CH_TABLE;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%ģ���ż�ͨ����Ž���
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %ģ��IDӳ��
        load('moduleID.mat');
        single_event_data((single_event_data(:,4)==128),:)=[];
        single_event_data(:,4)=moduleID(single_event_data(:,4)+1,1);
        clear moduleID;

        %ͨ���Ž���
        channel=find(rem(single_event_data(:,4),2)==0);
        single_event_data(channel,1)= 101 - single_event_data(channel,1);
        clear channel;

        %��������
        save(filename,'single_event_data');

    %     %�������
        close all
        clear single_event_data
        clc
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%   end    %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%