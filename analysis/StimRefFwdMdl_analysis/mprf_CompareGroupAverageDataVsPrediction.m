function mprf_CompareGroupAverageDataVsPrediction(opt)

subjIDs = {'wlsubj004', 'wlsubj039', 'wlsubj040', 'wlsubj058', ...
    'wlsubj068', 'wlsubj070', 'wlsubj081', 'wlsubj106', ...
    'wlsubj109', 'wlsubj111'};

dirPth = loadPaths(subjIDs{1});
[saveDir, tmp] = fileparts(dirPth.finalFig.savePthAverage);
saveDir = fullfile(saveDir, 'GroupAvePrediction', opt.subfolder);
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Preallocate space
nEpochs  = 140;
nSensors = length(opt.meg.dataChan);

if ~opt.vary.perturbOrigPRFs
    nrVariations = 1;
elseif strcmp(opt.vary.perturbOrigPRFs, 'position')
    nrVariations = length(opt.vary.position);
elseif strcmp(opt.vary.perturbOrigPRFs, 'size')
    nrVariations = length(opt.vary.size);
end

allPredictions = NaN(length(subjIDs), nEpochs, nSensors, nrVariations);
allData        = NaN(length(subjIDs), nEpochs, nSensors, nrVariations);

%% Load data and predictions
for subj = 1:length(subjIDs)
    
    subjectID = subjIDs{subj};
    
    dirPth = loadPaths(subjectID);
    
    % Load sensor predictions
    load(fullfile(dirPth.model.saveDataPth, opt.subfolder,'pred_resp', 'predMEGResponseScaled'));
    
    % Load phase-referenced SSVEF data
    load(fullfile(dirPth.model.saveDataPth, opt.subfolder,'pred_resp', 'meanPhRefAmp10Hz'));
    
    allPredictions(subj,:,:,:) = predMEGResponseScaled;
    allData(subj,:,:,:) = meanPhRefAmp10Hz;
end

%% Predict group average data from group average predictions
% Preallocate space

% for analysis without bootstrapping
VE = NaN(1,nSensors);
predScaled = NaN(nSensors,nEpochs);

% for analysis with bootstrapping
nBoot              = 10000;

% Define scale factor
femtoScaleFactor = 10^14;

for v = 1:nrVariations
    
    bootVE             = NaN(nSensors, nBoot);    
    bootAvgPredictions = NaN(nSensors, nBoot, nEpochs);
    bootAvgData        = NaN(nSensors, nBoot, nEpochs);
    bootGroupAvePredictionScaled  = NaN(nSensors, nBoot, nEpochs);
    
    for s = 1:nSensors
        
        % Identify and remove nans
        if nrVariations==1
            predictionGroup = allPredictions(:,:,s) .*femtoScaleFactor;
            dataGroup       = allData(:,:,s) .*femtoScaleFactor;
        else
            predictionGroup = allPredictions(:,:,s,v) .*femtoScaleFactor;
            dataGroup       = allData(:,:,s,v) .*femtoScaleFactor;
        end
        
        [VE(s), predScaled(s,:)]  = ...
                fitGroupPredictionToData(nanmean(predictionGroup,1)', nanmean(dataGroup,1)', opt.addOffsetParam, opt.refitGainParam);
        
        % Concatenate predictions and data for bootstrapping the mean
        % across observers
        concatPredData  = cat(3, predictionGroup, dataGroup);
        
        % Get bootstrapping function
        bootFun = @(x) nanmean(x,1);
        
        % Bootstrap prediction and data
        bootstat = ...
            bootstrp(nBoot, bootFun, concatPredData);        
       
        % Separate prediction and data into separate bootstrapped matrices
        bootAvgPredictions(s,:,:) = bootstat(:, 1:nEpochs);
        bootAvgData(s,:,:) = bootstat(:, (nEpochs+1):(2*nEpochs));
        
        % Fit every bootstrap
        for boot = 1:nBoot
            [bootVE(s, boot), bootGroupAvePredictionScaled(s,boot,:)]  = ...
                fitGroupPredictionToData(squeeze(bootAvgPredictions(s, boot,:)), squeeze(bootAvgData(s, boot,:)), opt.addOffsetParam, opt.refitGainParam);
        end
                
    end % sensors
    
    % Remove dummy dimension
    groupVE_noBootstrp            = VE;
    groupAvePredScaled_noBootstrp = predScaled;
    
    groupVarExpl             = bootVE;
    groupAveData             = bootAvgData;
    groupAvePredictionScaled = bootGroupAvePredictionScaled;

    
    save(fullfile(saveDir, sprintf('groupVarExplBoot10000_%d',v)), 'groupVarExpl', 'groupAveData', 'groupAvePredictionScaled', 'opt', 'nBoot', '-v7.3')
    save(fullfile(saveDir, sprintf('groupVarExplNoBoot_%d',v)), 'groupVE_noBootstrp', 'groupAvePredScaled_noBootstrp', 'allData', 'allPredictions', 'opt', '-v7.3');

    
end % nr variations (eg. size or position)


% save(fullfile(saveDir, 'groupVarExplBoot10000'), 'groupVarExpl', 'groupAveData', 'groupAvePredictionScaled', 'opt', 'nBoot', '-v7.3')
% save(fullfile(saveDir, 'groupVarExplNoBoot'), 'groupVE_noBootstrp', 'groupAvePredScaled_noBootstrp', 'allPredictions', 'allPredictions', 'opt', '-v7.3');
end


function [groupVarExpl, groupAvePredictionScaled] = fitGroupPredictionToData(GroupAvePrediction, GroupAveData, addOffset, recomputeBetas)

meanNanMask = isnan(GroupAveData);
thisGroupAvePredictionMasked = GroupAvePrediction(~meanNanMask);
thisGroupAveDataMasked       = GroupAveData(~meanNanMask);

groupAvePredictionScaled     = NaN(size(GroupAvePrediction));

% Create predictions
if addOffset
    % Add column of ones
    groupAveX = [ones(size(thisGroupAvePredictionMasked,1),1), thisGroupAvePredictionMasked];
else
    groupAveX = thisGroupAvePredictionMasked;
end

if recomputeBetas
    % Fit prediction to data
    groupFitBeta = groupAveX \ thisGroupAveDataMasked;

    % Compute scaled predictions with betas
    if addOffset
        groupAvePredictionScaled(~meanNanMask) =  thisGroupAvePredictionMasked * groupFitBeta(2) + groupFitBeta(1);    
    else
        groupAvePredictionScaled(~meanNanMask) =  groupAveX * groupFitBeta;   
    end
else
    groupAvePredictionScaled(~meanNanMask)  = thisGroupAvePredictionMasked;
end

% Compute coefficient of determination:
groupVarExpl = computeCoD(thisGroupAveDataMasked',groupAvePredictionScaled(~meanNanMask)');


end


