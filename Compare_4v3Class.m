%% Train classifier based on MC10 data from Phone Labels
% Run after GenerateClips.m
clear all

ntrees=200;

rmvFeat=1;
if rmvFeat
    load NormImp
    FeatInds=find(norm_imp>.25);
else
    FeatInds=1:270;
end

Activities={'Sitting', 'Lying', 'Standing', 'Stairs Up', 'Stairs Down', 'Walking'};

dirname='Z:\RERC- Phones\Stroke';

Test=load([dirname '\Clips\Test_Feat.mat']);
Train=load([dirname '\Clips\Train_Feat.mat']);

Test=Test.AllFeat;
Train=Train.AllFeat;

load('Z:\RERC- Phones\Stroke\Clips\Home_Feat.mat')

Home=AllFeat;

for i=1:length(Home)
    for j=1:length(Activities)
        counts(j)=sum(strcmp(Home(i).ActivityLabel,Activities{j}));
        countsLab2(j)=sum(strcmp(Test(i).ActivityLabel,Activities{j}));
        countsLab1(j)=sum(strcmp(Train(i).ActivityLabel,Activities{j}));
    end
    Subjs_w_All(i)=all([counts(1)+counts(2) counts(3) counts(4)+counts(5) counts(6)])...
        & all([countsLab2(1)+countsLab2(2) countsLab2(3) countsLab2(4)+countsLab2(5) countsLab2(6)])...
        & all([countsLab1(1)+countsLab1(2) countsLab1(3) countsLab1(4)+countsLab1(5) countsLab1(6)]);
end

Feat=[];
Label={};
Subjs=[];
HomeInds=[];
Lab2Inds=[];

for i=1:length(Train)
    if ~Subjs_w_All(i)
        continue
    end
    Feat=[Feat; Train(i).Features];
    Label=[Label Train(i).ActivityLabel];
    Subjs=[Subjs repmat(i,[1 length(Train(i).ActivityLabel)])];
    HomeInds=[HomeInds zeros(1,length(Train(i).ActivityLabel))];
    Lab2Inds=[Lab2Inds zeros(1,length(Train(i).ActivityLabel))];
end

for i=1:length(Test)
    if ~Subjs_w_All(i)
        continue
    end
    Feat=[Feat; Test(i).Features];
    Label=[Label Test(i).ActivityLabel];
    Subjs=[Subjs repmat(i,[1 length(Test(i).ActivityLabel)])];
    HomeInds=[HomeInds zeros(1,length(Test(i).ActivityLabel))];
    Lab2Inds=[Lab2Inds ones(1,length(Test(i).ActivityLabel))];
end

for i=1:length(Home)
    if ~Subjs_w_All(i)
        continue
    end
    Feat=[Feat; Home(i).Features];
    Label=[Label Home(i).ActivityLabel];
    Subjs=[Subjs repmat(i,[1 length(Home(i).ActivityLabel)])];
    HomeInds=[HomeInds ones(1,length(Home(i).ActivityLabel))];
    Lab2Inds=[Lab2Inds zeros(1,length(Home(i).ActivityLabel))];
end

for indFold=1:length(Home)
    disp(indFold)

    if size(Home(indFold).Features,1)<60 || ~Subjs_w_All(indFold)
        continue
    end
    
    %% Combine Sitting/Lying and Stairs Up/Down for environmental models
    
    ly_inds=strcmp('Lying',Label);
    Label(ly_inds)={'Sitting'};
    
    st_inds=strmatch('Stairs ',Label);
    Label(st_inds)={'Stair'};
    
    Envir_Activities={'Sitting', 'Standing', 'Walking', 'Stair'};
    
    TrainFeat=Feat(~HomeInds & ~Lab2Inds & Subjs~=indFold,FeatInds);
    TrainLabel=Label(~HomeInds & ~Lab2Inds & Subjs~=indFold).';
    TempSubjs=Subjs(~HomeInds & ~Lab2Inds & Subjs~=indFold);
    
%     RUS_inds=[];
%     for i=1:length(Envir_Activities)
%         train_act_inds=find(strcmp(TrainLabel,Envir_Activities{i}));
%         RUS_inds=[RUS_inds; train_act_inds(randperm(length(train_act_inds),1000))];
%     end
%     TrainFeat=TrainFeat(RUS_inds,:);
%     TrainLabel=TrainLabel(RUS_inds);
    
    
    TestFeat=Feat(HomeInds & Subjs==indFold,FeatInds);
    TestLabel=Label(HomeInds & Subjs==indFold);     
    TestLabel=TestLabel.';
    
    t = templateTree('MinLeafSize',5);
    RFModel=fitensemble(TrainFeat,TrainLabel,'RUSBoost',ntrees,t,'LearnRate',1);
%     RFModel=TreeBagger(200,TrainFeat,TrainLabel);
    
    TestFeatLab=Feat(Lab2Inds & Subjs==indFold,FeatInds);
    TestLabelLab=Label(Lab2Inds & Subjs==indFold);     
    TestLabelLab=TestLabelLab.';
    
    LabelsRF = predict(RFModel,TestFeatLab);
    LabConfMatLab{indFold}=confusionmat(TestLabelLab, LabelsRF, 'order', Envir_Activities);
    
    if isempty(TestLabel)
        continue
    end
    
    LabelsRF = predict(RFModel,TestFeat);
    LabConfMatHome{indFold}=confusionmat(TestLabel, LabelsRF, 'order', Envir_Activities);
    
    TrainFeat=Feat(HomeInds & Subjs~=indFold,FeatInds);
    TrainLabel=Label(HomeInds & Subjs~=indFold).';
    TempSubjs=Subjs(HomeInds & Subjs~=indFold);
    
%     RUS_inds=[];
%     for i=1:length(Envir_Activities)
%         train_act_inds=find(strcmp(TrainLabel,Envir_Activities{i}));
%         RUS_inds=[RUS_inds; train_act_inds(randperm(length(train_act_inds),1000))];
%     end
%     TrainFeat=TrainFeat(RUS_inds,:);
%     TrainLabel=TrainLabel(RUS_inds);

    RFModel=fitensemble(TrainFeat,TrainLabel,'RUSBoost',ntrees,t,'LearnRate',1);
%     RFModel=TreeBagger(200,TrainFeat,TrainLabel);
    LabelsRF = predict(RFModel,TestFeat);
    HomeConfMatHome{indFold}=confusionmat(TestLabel, LabelsRF, 'order', Envir_Activities);
    
end

save 4Class LabConfMatLab LabConfMatHome HomeConfMatHome

for indFold=1:length(Home)
    disp(indFold)

    if size(Home(indFold).Features,1)<60 || ~Subjs_w_All(indFold)
        continue
    end
    
    %% Combine Sitting/Lying and Stairs Up/Down for environmental models
    
    ly_inds=strcmp('Lying',Label);
    Label(ly_inds)={'Sitting'};
    
    st_inds=strmatch('Stair',Label);
    Label(st_inds)={'Walking'};
    
    Envir_Activities={'Sitting', 'Standing', 'Walking'};
    
    TrainFeat=Feat(~HomeInds & ~Lab2Inds & Subjs~=indFold,FeatInds);
    TrainLabel=Label(~HomeInds & ~Lab2Inds & Subjs~=indFold).';
    TempSubjs=Subjs(~HomeInds & ~Lab2Inds & Subjs~=indFold);
    
%     RUS_inds=[];
%     for i=1:length(Envir_Activities)
%         train_act_inds=find(strcmp(TrainLabel,Envir_Activities{i}));
%         RUS_inds=[RUS_inds; train_act_inds(randperm(length(train_act_inds),1000))];
%     end
%     TrainFeat=TrainFeat(RUS_inds,:);
%     TrainLabel=TrainLabel(RUS_inds);
    
    
    TestFeat=Feat(HomeInds & Subjs==indFold,FeatInds);
    TestLabel=Label(HomeInds & Subjs==indFold);     
    TestLabel=TestLabel.';
    
    t = templateTree('MinLeafSize',5);
    RFModel=fitensemble(TrainFeat,TrainLabel,'RUSBoost',ntrees,t,'LearnRate',1);
%     RFModel=TreeBagger(200,TrainFeat,TrainLabel);
    
    TestFeatLab=Feat(Lab2Inds & Subjs==indFold,FeatInds);
    TestLabelLab=Label(Lab2Inds & Subjs==indFold);     
    TestLabelLab=TestLabelLab.';
    
    LabelsRF = predict(RFModel,TestFeatLab);
    LabConfMatLab{indFold}=confusionmat(TestLabelLab, LabelsRF, 'order', Envir_Activities);
    
    if isempty(TestLabel)
        continue
    end
    
    LabelsRF = predict(RFModel,TestFeat);
    LabConfMatHome{indFold}=confusionmat(TestLabel, LabelsRF, 'order', Envir_Activities);
    
    TrainFeat=Feat(HomeInds & Subjs~=indFold,FeatInds);
    TrainLabel=Label(HomeInds & Subjs~=indFold).';
    TempSubjs=Subjs(HomeInds & Subjs~=indFold);
    
%     RUS_inds=[];
%     for i=1:length(Envir_Activities)
%         train_act_inds=find(strcmp(TrainLabel,Envir_Activities{i}));
%         RUS_inds=[RUS_inds; train_act_inds(randperm(length(train_act_inds),1000))];
%     end
%     TrainFeat=TrainFeat(RUS_inds,:);
%     TrainLabel=TrainLabel(RUS_inds);

    RFModel=fitensemble(TrainFeat,TrainLabel,'RUSBoost',ntrees,t,'LearnRate',1);
%     RFModel=TreeBagger(200,TrainFeat,TrainLabel);
    LabelsRF = predict(RFModel,TestFeat);
    HomeConfMatHome{indFold}=confusionmat(TestLabel, LabelsRF, 'order', Envir_Activities);
    
end

save 3Class LabConfMatLab LabConfMatHome HomeConfMatHome