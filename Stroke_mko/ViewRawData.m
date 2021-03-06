clc
close all
clear all
% *************************************************************************
% ViewRawData.m
% 
% Written by Megan O'Brien
% August 16, 2016
%
% Reads and plots raw data from RT&O server
%
% *************************************************************************

tic

saveTrim=0;
saveOrient=0;

dirmain='Z:\RERC- Phones\Stroke\';

% show activity plots of sensor data?
plotsonRaw=1;
plotsonClean=0;

plotson=0;
if plotsonRaw || plotsonClean
    plotson = 1;
end

% Specify which data set is to be used: Train (Day 1), Test (Day 2), or Home  
Set={'Train' 'Test' 'Home'};

%Activities={'Sitting', 'Lying', 'Standing', 'Stairs Up', 'Stairs Down', 'Walking'}; %(skip sit-to-stand stand-to-sit, Wheeling)
Activities={'Sitting'};

load('Z:\Stroke MC10\Sessions.mat')
Labels=table2cell(readtable('Z:\RERC- Phones\Stroke\Labels_stroke.csv','ReadVariableNames',false));


for indSet=3%1:length(Set)

    dirname = ['Z:\RERC- Phones\Stroke\RawData\' Set{indSet} '\'];

    filenames = dir([dirname 'CS*.csv']);

    %remove files with 0 bytes
    emptyfiles = cellfun(@(x) x==0, {filenames.bytes});
    filenames(emptyfiles) = [];
    AllFilenames=filenames;

    Subjects=cell(length(filenames),1);

    for i=1:length(filenames)
        Subjects{i}=filenames(i).name(1:5);
    end

    Rates=zeros(length(filenames),3);

    IDs=unique(Subjects);

    %% Split files by subject

    [sy, sx]=size(IDs);

    AllRates=[];

    for indSub=[1:sy]
        filenames=AllFilenames;
        ID=IDs{indSub};
        OtherSubjectFiles = cellfun(@(x) ~strcmp(x(1:5),ID), {filenames.name});
        filenames(OtherSubjectFiles) = [];
        SubjectFilenames=filenames;

        % Split by Activity 
        for indAct=1:length(Activities)
            Activity=Activities{indAct};
            ActName=strrep(Activity,' ',''); % remove spaces from activity names (e.g. for variable names)

            eval(['indtemp' ActName '=1;']);

            if plotsonRaw
                figure('name',[ID ' - ' Activity ' Raw'],'Position',get(0,'ScreenSize'));
            end
            if plotsonClean
                figure('name',[ID ' - ' Activity ' Clean'],'Position',get(0,'ScreenSize'));
            end

            filenames=SubjectFilenames;
            OtherActivityFiles = cellfun(@(x) ~strcmp(x(7:6+length(Activity)),Activity), {filenames.name});
            filenames(OtherActivityFiles) = [];

            %% Read File and Separate Data by Sensor
            SampleRates=zeros(length(filenames),3);

            for indFile=1:length(filenames)
                name=filenames(indFile).name;
                fileinfo=strsplit(name,{'_' '.'});
                Index=str2double(fileinfo{3});

                StartUTC=Labels{Index,3};
                StartTime=datetime([1970, 1, 1, 0, 0, StartUTC/1000]);

                fid=fopen([dirname '\' filenames(indFile).name],'rt');
                A=textscan(fid,'','Delimiter',['|' ',']);
                fclose(fid);

                %% Split data by sensor
                temp=sort(A{4});
                tStart=temp(1);

                Acc=zeros(length(find(A{3}==105)),5);
                Gyr=zeros(length(find(A{3}==115)),5);
                Bar=zeros(length(find(A{3}==135)),2);
                
                AccInd=1;
                GyrInd=1;
                BarInd=1;
                
                for i=1:length(A{2})
                    t=A{4}(i)-tStart;
                    indSensor=A{3}(i);
                    if indSensor==105
                        Acc(AccInd,:)=[t A{5}(i) A{6}(i) A{7}(i) A{8}(i)];
                        AccInd=AccInd+1;
                    elseif indSensor==115
                        Gyr(GyrInd,:)=[t A{5}(i) A{6}(i) A{7}(i) A{8}(i)];
                        GyrInd=GyrInd+1;
                    elseif indSensor==135
                        Bar(BarInd,:)=[t A{5}(i)];
                        BarInd=BarInd+1;
                    end
                end

                if min([size(Bar,1) size(Acc,1) size(Gyr,1)])<2
                    continue
                end

                %Sort to put in chronological order
                Acc=sortrows(Acc);
                Gyr=sortrows(Gyr);
                Bar=sortrows(Bar);

                %% Processing

                % Remove data when not all three sensors are recording
                maxInd=min([max(Acc(:,1)) max(Bar(:,1)) max(Gyr(:,1))]);
                minInd=max([min(Acc(:,1)) min(Bar(:,1)) min(Gyr(:,1))]);
                stopInd=find(Acc(:,1)>maxInd,1);

                % Average any data that occur in repeated timestamps
                Acc = RemoveRepTimes(Acc);
                Gyr = RemoveRepTimes(Gyr);
                Bar = RemoveRepTimes(Bar);

                % Resample using spline interpolation
                t=minInd:1000/50:maxInd;
                t_bar=minInd:1000/6:maxInd;

                Acc=[t',spline(Acc(:,1).',Acc(:,2:4).',t).'];
                Gyr=[t',spline(Gyr(:,1).',Gyr(:,2:4).',t).'];
                Bar=[t_bar',spline(Bar(:,1).',Bar(:,2).',t_bar).'];

                % Trim to activity only (remove movement bursts during labeling pre- and post- activity)
                trimAcc=zeros(size(Acc));
                trimGyr=zeros(size(Gyr));
                trimBar=zeros(size(Bar));
                [trimAcc,trimGyr,trimBar] = TrimData(Activity,Acc,Gyr,Bar);
                if strcmp(Activity,'Lying') || strcmp(Activity,'Sitting') || strcmp(Activity,'Standing')
                    [trimAcc,trimGyr,trimBar] = TrimData(Activity,trimAcc,trimGyr,trimBar);
                end

                %% Orientation
                % Sedentary activities
                %if strcmp(Activity,'Lying') || strcmp(Activity,'Sitting') || strcmp(Activity,'Standing')

                    % compile average trimmed data of each trial
                    eval(['Acc_trialavg_' ActName '(indtemp' ActName ',1)=Index;']);
                    eval(['Acc_trialavg_' ActName '(indtemp' ActName ',2:4)=mean(trimAcc(:,2:4));']);

                    % rotate
                    [rotAcc,rotGyr]=CorrectOrientation(trimAcc,trimGyr);

                    % new rotated average of each trial
                    eval(['Acc_trialavgrot_' ActName '(indtemp' ActName ',1)=Index;']);
                    eval(['Acc_trialavgrot_' ActName '(indtemp' ActName ',2:4)=mean(rotAcc(:,2:4));']);

                    % increment trial index
                    eval(['indtemp' ActName '=indtemp' ActName '+1;']);
                %end
                %% Save Files
                if saveTrim
                    csvwrite([dirmain 'TrimmedData\' Set{indSet} '\Updated_mko\Acc\' filenames(indFile).name],trimAcc)
                    csvwrite([dirmain 'TrimmedData\' Set{indSet} '\Updated_mko\Gyr\' filenames(indFile).name],trimGyr)
                    csvwrite([dirmain 'TrimmedData\' Set{indSet} '\Updated_mko\Bar\' filenames(indFile).name],trimBar)
                end
                
                if saveOrient
                    csvwrite([dirmain 'TrimmedData\' Set{indSet} '\Updated_mko\Reoriented\Acc\' filenames(indFile).name],rotAcc)
                    csvwrite([dirmain 'TrimmedData\' Set{indSet} '\Updated_mko\Reoriented\Gyr\' filenames(indFile).name],rotGyr)
                end
                %dlmwrite([dirname 'SortedData\Acc\' filenames(indFile).name], Acc, 'Precision', 7)
                %dlmwrite([dirname 'SortedData\Gyr\' filenames(indFile).name], Gyr, 'Precision', 7)
                %dlmwrite([dirname 'SortedData\Bar\' filenames(indFile).name], Bar, 'Precision', 7)

                %% Plot activity trials
                if plotson
                    numtrials=length(filenames);
                    numsensors=3;

                    t_s=t/1000; t_min=t_s/60;
                    t_bar_s=t_bar/1000; t_bar_min=t_bar_s/60;

                    figcol = 3;
                    figrow = numtrials/figcol;
                    if mod(numtrials,figcol)
                        figrow = round(figrow) + 1;
                    end
                    figcol = figcol * numsensors;   % 3X columns for 3 sensors: Accel, Gyro, Bar
                    indPlot = numsensors*(indFile-1)+1;

                    if plotsonRaw
                        % accelerometer
                        subplot(figrow,figcol,indPlot); hold on;
                            plot(Acc(:,1)/1000,Acc(:,2),'r-'); % x
                            plot(Acc(:,1)/1000,Acc(:,3),'g-'); % y
                            plot(Acc(:,1)/1000,Acc(:,4),'b-'); % z
                            %ylabel('Acc');

                            plot([trimAcc(1,1)/1000 trimAcc(1,1)/1000],[-20 20],'r--'); % Trim start
                            plot([trimAcc(end,1)/1000 trimAcc(end,1)/1000],[-20 20],'r--'); % Trim end

                        % gyroscope
                        subplot(figrow,figcol,indPlot+1); hold on;
                            plot(Gyr(:,1)/1000,Gyr(:,2),'r-'); % rot about x
                            plot(Gyr(:,1)/1000,Gyr(:,3),'g-'); % rot about y
                            plot(Gyr(:,1)/1000,Gyr(:,4),'b-'); % rot about z
                            %ylabel('Gyr'); xlabel('Time (s)')

                            plot([trimGyr(1,1)/1000 trimAcc(1,1)/1000],[-10 10],'r--'); % Trim start
                            plot([trimGyr(end,1)/1000 trimAcc(end,1)/1000],[-10 10],'r--'); % Trim end

                            title(['Trial ' num2str(Index)]);

                        % barometer
                        subplot(figrow,figcol,indPlot+2); hold on;
                            plot(Bar(:,1)/1000,Bar(:,2),'k-','Linewidth',2); % mag

                            plot([trimBar(1,1)/1000 trimBar(1,1)/1000],[979 989],'r--'); % Trim start
                            plot([trimBar(end,1)/1000 trimBar(end,1)/1000],[979 989],'r--'); % Trim end
                            %ylabel('Bar');
                    end

                    if plotsonClean
                        % accelerometer
                        subplot(figrow,figcol,indPlot); hold on;
                            plot(rotAcc(:,1)/1000,rotAcc(:,2),'r-'); % x
                            plot(rotAcc(:,1)/1000,rotAcc(:,3),'g-'); % y
                            plot(rotAcc(:,1)/1000,rotAcc(:,4),'b-'); % z
                            %ylabel('Acc');

                        % gyroscope
                        subplot(figrow,figcol,indPlot+1); hold on;
                            plot(rotGyr(:,1)/1000,rotGyr(:,2),'r-'); % rot about x
                            plot(rotGyr(:,1)/1000,rotGyr(:,3),'g-'); % rot about y
                            plot(rotGyr(:,1)/1000,rotGyr(:,4),'b-'); % rot about z
                            %ylabel('Gyr'); xlabel('Time (s)')

                            title(['Trial ' num2str(Index)]);

                        % barometer
                        subplot(figrow,figcol,indPlot+2); hold on;
                            plot(trimBar(:,1)/1000,trimBar(:,2),'k-','Linewidth',2); % mag
                            %ylabel('Bar');
                    end


                end
                

            end %indFile      
        end %indAct

        %pause

    end %for indSub
end %indSet

toc
