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

set_power = 0;     % 打开模拟板电源和传感器电源
data_acq = 1;      % 如果只是分析数据，可以把这个置0,不重新采集数据
init_one_node = 0; % 初始化第一块节点类型，只想用第一块板子的时候把这个置为1，不能跟init_all_node同时为1
init_all_node = 1; % 初始化所有板子节点类型，想用多块板子的时候把这个置为1， 不能跟init_one_node同时为1

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
    % 这里需要延时10s 你查下matlab的延时函数，我忘记了
    trgt = '0x000f'; % 假设有4块板子级联，这里就写3，有8块就写7
    system([op ' -c 0x0002 ' trgt ' 0x0000020f']);    % 2
    pause(5);
    % 延时2s
    % pin最后一块板子，pin成功代表初始化成功
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
        
        % 开始采集
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
        %打开文件提取数据，得到data数据
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
        %找到所有完整数据列车的车头train_head_index
        train_head_8bit = 254;
        p1 = find(data(:,4) == train_head_8bit);
        p2 = p1 + 1;
        if  max(p2) > length(data)
            p2 = p2(1:end - 1);
        end
        train_head_index = p2((data(p2,4) == train_head_8bit) & (data(p2,1) == 0) & (data(p2,2) == 0) &(data(p2,3) == 0));
        clear p1 p2 train_head_8bit;
        train_len = diff(train_head_index);
        %列车数
        train_cnt = length(train_head_index);

        %提取出所有完整的车的数据，存在data
        c_train_len = 276;
        p1 = find(train_len == c_train_len);
        complet_train_head_index = train_head_index(p1) - 1;  %%好像不用减1
        clear p1 train_len;
        %完整列车数
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

        %去除完整数据头尾，确保有效数据为train_data
        train_head_8bit = 254;
        p1 = find(data(:,4) == train_head_8bit);
        p2 = p1 + 1;
        if  max(p2) > length(data)
            p2 = p2(1:end - 1);
        end
        train_head_index = p2((data(p2,4) == train_head_8bit) & (data(p2,1) == 0) & (data(p2,2) == 0) &(data(p2,3) == 0));  %%可能会受到TDC的高位计数为254的影响
        clear p1 p2;
        start_index = train_head_index(100)-1;
        end_index = start_index - 1 + c_train_len * floor( (length(data) - start_index + 1)/c_train_len );
        train_data = data(start_index:end_index,:);
        clear train_head_index start_index end_index data;

        % 提取列车中所有模块的有效数据
        train_head_index = 1:c_train_len:length(train_data);
        train_head_index = train_head_index';
        train_num = train_data(train_head_index,2);
    %     diff_train_num = diff(train_num);
    %     find(diff_train_num ~= 1 & diff_train_num ~= -255);

        %剔除掉所有车头车尾标志
        delete_index = [train_head_index,train_head_index+1,train_head_index+c_train_len-2,train_head_index+c_train_len-1];
        clear train_head_index;
        delete_index = delete_index';
        delete_index = delete_index(:);
        coach0to7_data = train_data;
        coach0to7_data(delete_index,:) = []; % 剔除车头
        clear delete_index;
        coach0to7_data = coach0to7_data';
        coach0to7_data = coach0to7_data(:);

        %筛选了车头的0~7模块车厢数据
        coach0to7_data = reshape(coach0to7_data,17*4*16,[]);
        coach0to7_data = coach0to7_data(1:17*4*16,:)';
        coach0to7_data= coach0to7_data';
        coach0to7_data= coach0to7_data(:);
        coach0to7_data= reshape(coach0to7_data,4,[])';

        %将所有首行为半个数据的替换成无数据的0 128 128 128
        index_temp1 = (find(coach0to7_data(1:17:end,4)==143) - 1) * 17 + 1; % 找到车厢第一行为半个事件数据的索引
        coach0to7_data(index_temp1,:) = repmat([0 128 128 128],length(index_temp1),1);

        %将所有末行为半个数据的替换成无数据的0 128 128 128
        index_temp2 = (1:17:length(coach0to7_data))';                         % 所有车厢第一行数据索引
        index_temp3 = index_temp2 + coach0to7_data(index_temp2 + 16,2) - 1;   % 所有车厢的最后一行有效数据索引
        index_temp3 = index_temp3(2:end);
        index_temp4 = find(coach0to7_data(index_temp3,4)==142);               %
        index_temp5 = index_temp3(index_temp4);                               % 所有车厢最后一行有效数据不是完整事件数据结尾的索引
        index_temp6 = index_temp2(index_temp4) + 16;                          % 所有最后一行有效数据不是完整事件数据结尾的车厢的车尾索引
        coach0to7_data(index_temp5,1) = coach0to7_data(index_temp6,2) - 1;
        coach0to7_data(index_temp5,2:end) = repmat([128 128 128],length(index_temp5),1);

        %根据去除的数据数量，将车厢尾的sigle event数更改
        coach0to7_data(index_temp1+16,2) = coach0to7_data(index_temp1+16,2) - 1;
        coach0to7_data(index_temp6+16,2) = coach0to7_data(index_temp6+16,2) - 1;
        clear index_temp1 index_temp2 index_temp3 index_temp4 index_temp5 index_temp6;

        %提取每节车厢的sigle event数，并剔除车厢尾
        module_num = coach0to7_data(1*17:17:end,3);
        coach0to7_data(1*17:17:end,:) = []; % 剔除车厢尾

        %将模块号添加到coach0to7_data
        temp = repmat(module_num,1,16)';
        temp = temp(:);
        coach0to7_data = [coach0to7_data temp];
        clear module_num temp;

        %将列车号添加到coach0to7_data
        temp = repmat(train_num,1,16*16)';
        temp = temp(:);
        coach0to7_data = [coach0to7_data temp];
        clear train_num temp;

        %剔除空数据0 128 128 128
        delete_index = coach0to7_data(:,4) == 128;
        coach0to7_data(delete_index,:)=[];
        clear delete_index;

        %看数据高32位与低32位是否一样多
    %     p1 = find(coach0to7_data(:,4) == 143);
    %     p2 = p1 - 1;
    %     p3 = p2(coach0to7_data(p2,4) == 143);

        %将sigle event数据高32位与第32位排为单行
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

        % 生成single event data
        single_event_data = zeros(length(coach0to7_data),5); % ch eng tdc module train
        single_event_data(:,1) = coach0to7_data(:,3) + 1;
        single_event_data(:,2) = coach0to7_data(:,1) + coach0to7_data(:,2) * 256;
        single_event_data(:,3) = coach0to7_data(:,7) + coach0to7_data(:,8) * 256 + coach0to7_data(:,9) * 256 * 256;
        single_event_data(:,4) = coach0to7_data(:,5);
        single_event_data(:,5) = coach0to7_data(:,6);
        clear coach0to7_data;

        % 通道映射
        load('ARRAY10x10_CH_TABLE.mat');
        single_event_data(:,1) = table2array( ARRAY10x10_CH_TABLE( single_event_data(:,1),'chtable' ) );  % channels number defined in schematic
        clear ARRAY10x10_CH_TABLE;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%模块编号及通道编号矫正
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %模块ID映射
        load('moduleID.mat');
        single_event_data((single_event_data(:,4)==128),:)=[];
        single_event_data(:,4)=moduleID(single_event_data(:,4)+1,1);
        clear moduleID;

        %通道号矫正
        channel=find(rem(single_event_data(:,4),2)==0);
        single_event_data(channel,1)= 101 - single_event_data(channel,1);
        clear channel;

        %保存数据
        save(filename,'single_event_data');

    %     %清除缓存
        close all
        clear single_event_data
        clc
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%   end    %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%