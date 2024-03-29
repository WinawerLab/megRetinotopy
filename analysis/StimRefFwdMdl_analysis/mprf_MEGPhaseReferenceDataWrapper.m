function [phRefAmp10Hz, bestBetas, bestRefPhase, bestOffsets] = mprf_MEGPhaseReferenceDataWrapper(megData, predMEGResponse, dirPth, opt)
% Wrapper for function to compute phase referenced amplitude from
% preprocessed MEG data and predicted MEG responses from cortical surface
%
%   phaseRefMEGResponse = mprf_MEGPhaseReferenceData(megData, predMEGResponse)
%
% INPUTS:
%   megData         : preprocessed MEG data
%                       (time x epochs x run x sensors)
%   predMEGResponse : predicted MEG responses
%                       (epochs x sensors)
%   dirPth          : paths to files for given subject
%   opt             : struct with boolean flag options
%
%
% OUTPUT:
%   phRefAmp10Hz    : Phase referenced MEG time series
%                       (sensors x epochs x runs [x optional variations])
%
%
% Author: Eline R. Kupers <ek99@nyu.edu>, 2019

% Check for folders in case we save figures or data
if opt.saveFig
    if ~exist(fullfile(dirPth.model.saveFigPth, opt.subfolder, 'refphase'),'dir')
        mkdir(fullfile(dirPth.model.saveFigPth, opt.subfolder, 'refphase')); end
end

if opt.saveData
    if ~exist(fullfile(dirPth.model.saveDataPth, opt.subfolder, 'pred_resp'), 'dir')
        mkdir(fullfile(dirPth.model.saveDataPth, opt.subfolder, 'pred_resp'));
    end
end

% Check dimensions with loaded pRF data, and set the number of iterations
iter  = checkNumberOfIterations(predMEGResponse, opt, 'MEGPhaseRef');
nIter = length(iter);

% Keep a copy of all responses
predMEGResponseAll = predMEGResponse;

% Get data dimensions
[~, nEpochs, nRuns, nSensors] = size(megData); 

% Get leave in 9 / leave out group of 10 runs
runGroup = getRunGroups(nRuns);

% loop over dimensions, if necessary
for ii = 1:nIter
    
    fprintf('(%s): Starting phase-reference computation for iteration %d/%d.\n', mfilename, ii, nIter)
    
    % Select new prf parameters, if they vary in size or position
    predMEGResponse = predMEGResponseAll(:,:,ii);
    
    % Get phase-referenced steady state MEG responses for this iteration
    [phRefAmp10Hz(:,:,:,ii), bestRefPhase(:,:,:,ii), maxVarExplVal, ...
        bestBetas(:,:,:,ii), bestOffsets(:,:,:,ii)] = ...
        mprf_MEGPhaseReferenceData(megData, predMEGResponse, runGroup, opt, dirPth);
    

    %% Debug figures
    if opt.verbose
        
        % Visualize the mean reference phase across sensors
        fH1 = figure(1); clf;
        if numel(size(bestRefPhase))>3
            bestRefPhaseToPlot = bestRefPhase(:,:,:,ii);
        else
            bestRefPhaseToPlot = bestRefPhase;
        end
        megPlotMap(circularavg(squeeze(bestRefPhaseToPlot),[],1), [0 2*pi],[], 'hsv','Mean Ref phase across 19 runs of MEG data', [],[],'interpmethod', 'nearest')
        
        % Visualize the variance explained for every run across sensors
        fH2 = figure(2); clf; set(fH2, 'Position', [17,578,1543,760]);
        for r = 1:size(phRefAmp10Hz,2)
            subplot(3,7,r);
            dataToPlot = squeeze(maxVarExplVal(:,r,:));
            if all(isnan(dataToPlot))
                dataToPlot = zeros(size(dataToPlot));
            end
            megPlotMap(dataToPlot, [0 0.6],[], 'parula',sprintf('Run %d', r));
            drawnow;
        end
        
        if opt.saveFig
            print(fH1,fullfile(dirPth.model.saveFigPth, opt.subfolder, ...
                sprintf('mesh_xvalRefPhase%s_%d', opt.fNamePostFix, ii)), '-dpng')
            
            print(fH2,fullfile(dirPth.model.saveFigPth, opt.subfolder, ...
                sprintf('mesh_varExplbyXvalRefPhase%s_%d', opt.fNamePostFix, ii)), '-dpng')
        end
        
        % Visualize the reference phase for every run across sensors
        fH3 = figure(3);
        for s = 1:nSensors
            clf;
            mprf_polarplot(ones(size(bestRefPhaseToPlot,2),1),bestRefPhaseToPlot(1,:,s));
            title(sprintf('Best xval reference phases for 19 runs, sensor %d - mean r^2: %1.2f',s,nanmean(maxVarExplVal(1,:,s),2)));
            drawnow;
            if opt.saveFig
                print(fH3,fullfile(dirPth.model.saveFigPth, opt.subfolder, 'refphase', ...
                    sprintf('sensor%d_xvalRefPhase%s_%d', s, opt.fNamePostFix, ii)), '-dpng')
            end
        end
    end % opt.verbose
    
end % iterations


% Remove last dimension out, if not used
phRefAmp10Hz = squeeze(phRefAmp10Hz);
bestBetas    = squeeze(bestBetas);
bestOffsets  = squeeze(bestOffsets);
bestRefPhase = squeeze(bestRefPhase);

if opt.saveData
    % save betas corresponding to the highest variance explained per iteration
    save(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','bestBetas'),'bestBetas','-v7.3');
    save(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','bestOffsets'),'bestOffsets','-v7.3');
    save(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','bestRefPhase'),'bestRefPhase','-v7.3');   
    save(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','runGroup'),'runGroup','-v7.3');
    save(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','phaseReferencedMEGData'),'phRefAmp10Hz','-v7.3');
end

return