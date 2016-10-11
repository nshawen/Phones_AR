clc
clear all
close all
% -------------------------------------------------------------------------
% AnalyzeConfMat.m

% Generate tables or figures relating to classifier output.

% Input: .mat data from classifier scripts
% Output: ConfMat, Boxplot, table 
% -------------------------------------------------------------------------

Activities={'Sitting', 'Lying', 'Standing', 'Stairs Up', 'Stairs Down', 'Walking'};
numAct=length(Activities);

%load('Z:\RERC- Phones\Server Data\Clips\10s\PhoneData_Feat.mat') % Features

%% Lab vs. Home
load('ConfusionMat_strokestrokeHome');
load('DirectComp_LabvsHome');

Envir_Activities={'Sitting', 'Standing', 'Stair', 'Walking'};

% Confusion Matrix: Lab --> Home
subjinds=cellfun(@(x) ~isempty(x), LabConfMatHome(:));
ConfMatAll=zeros(length(Envir_Activities),length(Envir_Activities),sum(subjinds),size(LabConfMatHome,2));

subjinds=find(subjinds);

for i=1:length(subjinds)
    ind=subjinds(i);
    for j=1:size(LabConfMatHome,2)
        ConfMatAll(:,:,ind,j)=LabConfMatHome{ind};
    end
end
ConfMatAll=sum(ConfMatAll,4);
ConfMatAll=sum(ConfMatAll,3);
correctones = sum(ConfMatAll,2);
correctones = repmat(correctones,[1 length(Envir_Activities)]);
figure; imagesc(ConfMatAll./correctones, [0 1]); colorbar
xlabel('Predicted Activities'); ylabel('True Activities');
title('Stroke Lab to Stroke Home');
set(gca,'XTickLabel',Activities)
set(gca,'YTickLabel',Activities)
set(gca,'XTick',1:length(Envir_Activities))
set(gca,'YTick',1:length(Envir_Activities))

for i=1:length(Envir_Activities)
    for j=1:length(Envir_Activities)
        conf_str=num2str(ConfMatAll(j,i));
        if ConfMatAll(j,i)/correctones(j,i)<0.15
            txtclr='w';
        else
            txtclr='k';
        end
        text(i-0.25,j,conf_str,'Color',txtclr);
    end
end

% Confusion Matrix: Lab+Home --> Home 
subjinds=cellfun(@(x) ~isempty(x), LabHomeConfMatHome(:,1));
ConfMatAll=zeros(length(Envir_Activities),length(Envir_Activities),sum(subjinds),size(LabHomeConfMatHome,2));

subjinds=find(subjinds);

StrokeHomeCounts=zeros(length(Envir_Activities),15);
for i=1:length(subjinds)
    ind=subjinds(i);
    for j=1:size(LabHomeConfMatHome,2)
        ConfMatAll(:,:,ind,j)=LabHomeConfMatHome{ind,j};
        if j==1
            StrokeHomeCounts(:,i)=sum(LabHomeConfMatHome{ind,j},2);
        end
    end
end
ConfMatAll=sum(ConfMatAll,4);

subjs_w_All=all(sum(ConfMatAll,2),1);

ConfMatAll=sum(ConfMatAll,3);
correctones = sum(ConfMatAll,2);
correctones = repmat(correctones,[1 length(Envir_Activities)]);
figure; imagesc(ConfMatAll./correctones, [0 1]); colorbar
xlabel('Predicted Activities'); ylabel('True Activities');
title('Stroke Lab+Home to Stroke Home');
set(gca,'XTickLabel',Activities)
set(gca,'YTickLabel',Activities)
set(gca,'XTick',1:length(Envir_Activities))
set(gca,'YTick',1:length(Envir_Activities))

for i=1:length(Envir_Activities)
    for j=1:length(Envir_Activities)
        conf_str=num2str(ConfMatAll(j,i));
        if ConfMatAll(j,i)/correctones(j,i)<0.15
            txtclr='w';
        else
            txtclr='k';
        end
        text(i-0.25,j,conf_str,'Color',txtclr);
    end
end


subjinds=cellfun(@(x) ~isempty(x), LabHomeConfMatHome(:,1));
subjinds=subjinds & permute(subjs_w_All,[3 2 1]);
subjinds=find(subjinds);
% Accuracy
for i=1:length(subjinds)
    indSub=subjinds(i);
    
    Acc_Lab_HomeHome(i,:)=calc_classacc(sum(cat(3,Lab_HometoHome{indSub,:}),3));
    Acc_LabHome(i,:)=calc_classacc(LabConfMatHome{indSub});
    
    LabHomeConfMatLab_sub=cat(3,HometoHome{indSub,:});
    LabHomeConfMatHome_sub=cat(3,LabHomeConfMatHome{indSub,:});
    Acc_HometoHome(i,:)=calc_classacc(sum(LabHomeConfMatLab_sub,3));
    Acc_LabHomeHome(i,:)=calc_classacc(sum(LabHomeConfMatHome_sub,3));

end

% Box plots: Environment-specific
figure;
subplot(2,4,1);
boxplot(Acc_Lab_HomeHome,Envir_Activities);
ylim([0 1.1]);
title('Stroke Lab-Home to Home');

subplot(2,4,2);
boxplot(Acc_LabHome,Envir_Activities);
boxplot_fill('y')
ylim([0 1.1]);
title('Stroke Lab to Stroke Home');

subplot(2,4,3);
boxplot(Acc_HometoHome,Envir_Activities);
ylim([0 1.1]);
title('Stroke Home to Home');

subplot(2,4,4);
boxplot(Acc_LabHomeHome,Envir_Activities);
boxplot_fill([1 0.5 0])
ylim([0 1.1]);
title('Stroke Lab+Home to Stroke Home');

subplot(2,4,[5:8])
BalAcc_Lab_HomeHome=nanmean(Acc_Lab_HomeHome,2);
BalAcc_LabHome=nanmean(Acc_LabHome,2);
BalAcc_HomeHome=nanmean(Acc_HometoHome,2);
BalAcc_LabHomeHome=nanmean(Acc_LabHomeHome,2);
mdl = [repmat({'Lab-Home to Home'}, length(BalAcc_Lab_HomeHome), 1); ...
    repmat({'Lab to Home'}, length(BalAcc_LabHome), 1); ...
    repmat({'Home to Home'}, length(BalAcc_HomeHome), 1); ...
    repmat({'Lab+Home to Home'}, length(BalAcc_LabHomeHome), 1)];

boxplot([BalAcc_Lab_HomeHome; BalAcc_LabHome; BalAcc_HomeHome; BalAcc_LabHomeHome],mdl)
boxplot_fill('y',3); boxplot_fill([1 0.5 0],1)
ylim([0 1.1]); ylabel('Balanced Accuracy');

%% Stroke to Stroke Population

ConfMatAll=zeros(length(Activities),length(Activities),size(PopConfMat,2));

% Confusion Matrix
for i=1:size(PopConfMat,2)
    ConfMatAll(:,:,i)=PopConfMat{i}./repmat(sum(PopConfMat{i},2),[1 6]);
end

ConfMatAll=nansum(ConfMatAll,3);
correctones = sum(ConfMatAll,2);
correctones = repmat(correctones,[1 6]);
figure, subplot(2,3,3), imagesc(ConfMatAll./correctones); colorbar; caxis([0 1])
set(gca,'XTickLabels',Activities)
set(gca,'YTickLabels',Activities)
xlabel('Predicted Activities'); ylabel('True Activities');
title('Stroke to Stroke')

addtexttoConfMat(ConfMatAll)

% Accuracy
for indSub=1:length(PopConfMat)
    Acc_StrokePop(indSub,:)=calc_classacc(PopConfMat{indSub});
end


%% Healthy to Healthy

load('RUSConfusion');

% Confusion Matrix
for i=1:size(ConfMat,2)
    ConfMatAll(:,:,i)=ConfMat{i}./repmat(sum(ConfMat{i},2),[1 6]);
end

ConfMatAll=nansum(ConfMatAll,3);
correctones = sum(ConfMatAll,2);
correctones = repmat(correctones,[1 6]);
subplot(2,3,1), imagesc(ConfMatAll./correctones); colorbar; caxis([0 1])
set(gca,'XTickLabels',Activities)
set(gca,'YTickLabels',Activities)
xlabel('Predicted Activities'); ylabel('True Activities');
title('Healthy to Healthy')

addtexttoConfMat(ConfMatAll)

% Accuracy
for indSub=1:length(ConfMat)
    Acc_Health(indSub,:)=calc_classacc(ConfMat{indSub});
end

% ActivityCounts
for i=1:size(ConfMat,2)
    ConfMatAll(:,:,i)=ConfMat{i};
end
HealthyCounts=sum(sum(ConfMatAll,3),2);

%% Healthy to Stroke (Lab and Home)

load('ConfusionMat_strokeAll.mat')

% Confusion Matrix
for i=1:size(ConfMat,2)
    ConfMatAll(:,:,i)=ConfMat{i}./repmat(sum(ConfMat{i},2),[1 6]);
end

ConfMatAll=nansum(ConfMatAll,3);
correctones = sum(ConfMatAll,2);
correctones = repmat(correctones,[1 6]);
subplot(2,3,2), imagesc(ConfMatAll./correctones); colorbar; caxis([0 1])
set(gca,'XTickLabels',Activities)
set(gca,'YTickLabels',Activities)
xlabel('Predicted Activities'); ylabel('True Activities');
title('Healthy to Stroke')

addtexttoConfMat(ConfMatAll)

% Accuracy
for i=1:30%length(subjinds)
    indSub=i;%subjinds(i);
    Acc_Stroke(i,:)=calc_classacc(ConfMat{indSub});
end

for i=1:size(ConfMat,2)
    ConfMatAll(:,:,i)=ConfMat{i};
end
StrokeCounts=sum(sum(ConfMatAll,3),2);

% Box plots: Population

BalAcc_Health=nanmean(Acc_Health,2);
BalAcc_Stroke=nanmean(Acc_Stroke,2);
BalAcc_StrokePop=nanmean(Acc_StrokePop,2);

subplot(2,3,4)
% boxplot(Acc_Health,Activities);
boxplot([Acc_Health BalAcc_Health]);
ylim([0 1.1]);
title('Healthy to Healthy');
%boxplot_fill('b')

subplot(2,3,5)
% boxplot(Acc_Stroke,Activities);
boxplot([Acc_Stroke BalAcc_Stroke]);
%boxplot_fill([0.5 0 0.5])
ylim([0 1.1]);
title('Healthy to Stroke (All)');

subplot(2,3,6)
% boxplot(Acc_StrokePop,Activities);
boxplot([Acc_StrokePop BalAcc_StrokePop]);
%boxplot_fill('r')
ylim([0 1.1]);
title('Stroke to Stroke');

% subplot(2,3,[4:6])
% BalAcc_Health=nanmean(Acc_Health,2);
% BalAcc_Stroke=nanmean(Acc_Stroke,2);
% BalAcc_StrokePop=nanmean(Acc_StrokePop,2);
% mdl = [repmat({'Healthy to Healthy'}, length(BalAcc_Health), 1); ...
%     repmat({'Healthy to Stroke'}, length(BalAcc_Stroke), 1); ...
%     repmat({'Stroke to Stroke'}, length(BalAcc_StrokePop), 1)];
% boxplot([BalAcc_Health; BalAcc_Stroke; BalAcc_StrokePop],mdl)
% boxplot_fill('b',3); boxplot_fill([0.5 0 0.5],2); boxplot_fill('r',1)
% ylim([0 1.1]); ylabel('Balanced Accuracy');

% Save figure
% h=gcf;
% set(h,'Units','Inches');
% pos = get(h,'Position');
% set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
% print(h,'Fig3','-dpdf','-r0')

%% Healthy to Stroke by stroke severity

strokeSev={'Mild','Mod','Sev'};

figure;
for indStroke=1:length(strokeSev)
    load(['ConfusionMat_strokeAll_' strokeSev{indStroke} '.mat'])

    % Confusion Matrix
    ConfMatAll=nansum(ConfMatAll,3);
    correctones = sum(ConfMatAll,2);
    correctones = repmat(correctones,[1 6]);
    subplot(2,3,indStroke), imagesc(ConfMatAll./correctones); colorbar; caxis([0 1])
    set(gca,'XTickLabels',Activities)
    set(gca,'YTickLabels',Activities)
    xlabel('Predicted Activities'); ylabel('True Activities');
    title(['Healthy to Stroke ' strokeSev{indStroke}])
    
    addtexttoConfMat(ConfMatAll)
    
    % Accuracy
    subjinds=cellfun(@(x) ~isempty(x), ConfMat(:));
    subjinds=find(subjinds);
    for i=1:length(subjinds)
        indSub=subjinds(i);
        eval(['Acc_' strokeSev{indStroke} '(i,:)=calc_classacc(ConfMat{indSub});']);
    end
    
    eval(['BalAcc_' strokeSev{indStroke} '_Sed=nanmean(Acc_' strokeSev{indStroke} '(:,1:3),2);']);
    eval(['BalAcc_' strokeSev{indStroke} '_Amb=nanmean(Acc_' strokeSev{indStroke} '(:,4:6),2);']);
    
    subplot(2,3,3+indStroke)
    eval(['boxplot([BalAcc_' strokeSev{indStroke} '_Sed BalAcc_' strokeSev{indStroke} '_Amb]);']);
    ylim([0 1.1]);
    title(['Healthy to ' strokeSev{indStroke}]);
end

%% Severe to other stroke severity
figure;

% Confusion Matrix, Severe to Severe
load('ConfusionMat_Sev_Sev.mat')

ConfMatAll=nansum(ConfMatAll,3);
actSed=[1 2 3]; %indices of sedentary activities
actAmb=[4 5 6]; %indices of ambulatory activities
ConfMatSimp(1,1)=nansum(nansum(ConfMatAll(actSed,actSed)));
ConfMatSimp(1,2)=nansum(nansum(ConfMatAll(actSed,actAmb)));
ConfMatSimp(2,1)=nansum(nansum(ConfMatAll(actAmb,actSed)));
ConfMatSimp(2,2)=nansum(nansum(ConfMatAll(actAmb,actAmb)));
correctones = sum(ConfMatSimp,2);
correctones = repmat(correctones,[1 2]);
subplot(2,2,1), imagesc(ConfMatSimp./correctones); colorbar; caxis([0 1])
% set(gca,'XTickLabels',Activities)
% set(gca,'YTickLabels',Activities)
xlabel('Predicted Activities'); ylabel('True Activities');
title('Severe to Severe')

addtexttoConfMat(ConfMatSimp)

% Accuracy, Severe to Severe
subjinds=cellfun(@(x) ~isempty(x), ConfMat(:));
subjinds=find(subjinds);
for i=1:length(subjinds)
    indSub=subjinds(i);
    Acc_SevSev(i,:)=calc_classacc(ConfMat{indSub});
end

% Confusion Matrix, Mild to Severe
load('ConfusionMat_Sev_Mild.mat')

ConfMatAll=nansum(ConfMatAll,3);
ConfMatSimp(1,1)=nansum(nansum(ConfMatAll(actSed,actSed)));
ConfMatSimp(1,2)=nansum(nansum(ConfMatAll(actSed,actAmb)));
ConfMatSimp(2,1)=nansum(nansum(ConfMatAll(actAmb,actSed)));
ConfMatSimp(2,2)=nansum(nansum(ConfMatAll(actAmb,actAmb)));
correctones = sum(ConfMatSimp,2);
correctones = repmat(correctones,[1 2]);
subplot(2,2,2), imagesc(ConfMatSimp./correctones); colorbar; caxis([0 1])
% set(gca,'XTickLabels',Activities)
% set(gca,'YTickLabels',Activities)
xlabel('Predicted Activities'); ylabel('True Activities');
title('Mild to Severe')

addtexttoConfMat(ConfMatSimp)

% Accuracy, Severe to Mild
subjinds=cellfun(@(x) ~isempty(x), ConfMat(:));
subjinds=find(subjinds);
for i=1:length(subjinds)
    indSub=subjinds(i);
    Acc_SevMild(i,:)=calc_classacc(ConfMat{indSub});
end

% Box plots
%BalAcc_SevSev=nanmean(Acc_SevSev,2);
BalAcc_SevSev_Sed=nanmean(Acc_SevSev(:,1:3),2);
BalAcc_SevSev_Amb=nanmean(Acc_SevSev(:,4:6),2);
%BalAcc_SevMild=nanmean(Acc_SevMild,2);
BalAcc_SevMild_Sed=nanmean(Acc_SevMild(:,1:3),2);
BalAcc_SevMild_Amb=nanmean(Acc_SevMild(:,4:6),2);

subplot(2,2,3)
boxplot([BalAcc_SevSev_Sed BalAcc_SevSev_Amb]);
%boxplot([Acc_SevSev]);
ylim([0 1.1]);
title('Severe to Severe');

subplot(2,2,4)
boxplot([BalAcc_SevMild_Sed BalAcc_SevMild_Amb]);
%boxplot([Acc_SevMild]);
ylim([0 1.1]);
title('Mild to Severe');

%% Histograms of class distributions

% Healthy and Stroke (Population)
figure, hold on
bar(1:6,HealthyCounts/sum(HealthyCounts),'FaceColor',[.6 .6 .6],'BarWidth',1)
for j=1:6
    if HealthyCounts(j)
        text(j,HealthyCounts(j)/sum(HealthyCounts)+.015,num2str(HealthyCounts(j)),'Rotation',90)
    end
end
bar(8:13,StrokeCounts/sum(StrokeCounts),'FaceColor',[1 .5 0],'BarWidth',1)
for j=1:6
    if StrokeCounts(j)
        text(7+j,StrokeCounts(j)/sum(StrokeCounts)+.015,num2str(StrokeCounts(j)),'Rotation',90)
    end
end
ax=gca;
ax.XTick=[1:6 8:13];
ax.XTickLabel=[Activities Activities];
ax.XTickLabelRotation=45;

% Stroke Home

StrokeHomeCounts(StrokeHomeCounts<60)=0;
StrokeHomeCounts(:,sum(StrokeHomeCounts)==0)=[];

Activities_abr={'Si', 'L', 'St', 'SU', 'SD', 'W'};

ticks=[];
ticklabels={};

figure, hold on
for i=1:length(StrokeHomeCounts)
    bar((length(Envir_Activities)+1)*(i-1)+1:(length(Envir_Activities)+1)*i-1,StrokeHomeCounts(:,i)/sum(StrokeHomeCounts(:,i)),'FaceColor',[1 .5 0],'BarWidth',1)
    ticks=[ticks (length(Envir_Activities)+1)*(i-1)+1:(length(Envir_Activities)+1)*i-1];
    ticklabels=[ticklabels Activities_abr];
    for j=1:(length(Envir_Activities))
        if StrokeHomeCounts(j,i)
            text((length(Envir_Activities)+1)*(i-1)+j,StrokeHomeCounts(j,i)/sum(StrokeHomeCounts(:,i))+.015,num2str(StrokeHomeCounts(j,i)),'Rotation',90)
        end
    end
end
ax=gca;
ax.XTick=ticks;
ax.XTickLabel=ticklabels;
ax.XTickLabelRotation=90;