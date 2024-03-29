function [predMEGResponseToCompare,meanVarExpl] = mprf_CompareMEGDataToPRFPredictionWrapper(phRefAmp10Hz, predMEGResponse, bestBetas, bestOffsets, dirPth, opt)
% Function to compare phase referenced steady-state data MEG data to
% predicted MEG responses from MRI prfs
%
%    [meanPredResponse,meanVarExpl] =
%    mprf_CompareMEGDataToPRFPredictionWrapper(phRefAmp10Hz, ...
%    predMEGResponse, opt)
%
% INPUTS:
%   phRefAmp10Hz     : phase-referenced steady-state MEG sensor data
%                       (epochs x run x sensors)
%   predMEGResponse  : predicted MEG responses
%                       (epochs x sensors)
%   dirPth           : paths to files for given subject
%   opt              : struct with options
%
% OUTPUT:
%   meanPredResponse : mean predicted response
%                       (sensors x epochs x optional variations)
%   meanVarExpl      : variance explained of mean data by modelfit
%                       ([1 or nr of optional variations] x sensor)
%
%
% Author: Eline R. Kupers <ek99@nyu.edu>, 2019

fprintf('(%s): Compare MEG data to predictions from fMRI.', mfilename)

% Load run group order
runGroup = getRunGroups(19);

% Check dimensions with loaded pRF data, and set the number of iterations
iter  = checkNumberOfIterations([{phRefAmp10Hz},{predMEGResponse}], opt, 'prfMEGPredvsData');
nIter = length(iter);


% Keep a copy of all responses
predMEGResponseAll = predMEGResponse;
phRefAmp10HzAll    = phRefAmp10Hz;
bestBetasAll       = bestBetas;
bestOffsetsAll     = bestOffsets;

% Allocate space
if opt.meg.useCoherentSpectrum
    if opt.vary.perturbOrigPRFs
        [nEpochs, ~, nSensors,~] = size(phRefAmp10Hz);
    else
        [nEpochs, ~, nSensors]   = size(phRefAmp10Hz);
    end
else
    [nEpochs, ~, nSensors, ~] = size(phRefAmp10Hz);
end

meanPhRefAmp10Hz = NaN(nEpochs, nSensors, nIter);
meanVarExpl      = NaN(nIter, nSensors);


% loop over dimensions, if necessary
for ii = 1:nIter
    fprintf('.%d/%d',ii,nIter);
    
    % Get data for this iteration
    predMEGResponse = predMEGResponseAll(:,:,ii);
    phRefAmp10Hz    = phRefAmp10HzAll(:,:,:,ii);
    bestBetas       = bestBetasAll(:,:,ii);
    bestOffsets     = bestOffsetsAll(:,:,ii);
    
    % Compare prediction to data
    [predMEGResponseScaled(:,:,ii), meanVarExpl(ii,:), meanPhRefAmp10Hz(:,:,ii)] = ...
        mprf_CompareMEGDataToPredictionFromMRIPRFs(phRefAmp10Hz, predMEGResponse, bestBetas, bestOffsets, runGroup, opt);
    
    
    %% Plot summary figures
    if opt.verbose
        
        % remove nan sensors and sort by var expl.
        [val, idx] = sort(meanVarExpl(ii,:), 'descend');
        tmp = idx(~isnan(val)); top10=tmp(1:10);
        ve = val(~isnan(val));
        
        ttlPostFix = strsplit(sprintf('%s',opt.fNamePostFix), '_');
        ttl = sprintf('Var expl of modelfit predicting mean phase-ref MEG data: %d %s %s %s', ii, ttlPostFix{2},ttlPostFix{3},ttlPostFix{4});
        
        % Plot var expl mesh
        fH1 = figure(1); clf; megPlotMap(meanVarExpl(ii,:),[0 0.4],fH1, 'parula', ttl, [],[], 'interpmethod', 'nearest');
        fH12 = figure(12); clf; megPlotMap(meanVarExpl(ii,:),[0 0.4],fH12, 'parula', ttl, [],[]);
        fH13 = figure(13); clf; megPlotMap(meanVarExpl(ii,:),[0 max(meanVarExpl(ii,:))],fH13, 'parula', ttl, [],[], 'interpmethod', 'nearest');
        fH14 = figure(14); clf; megPlotMap(meanVarExpl(ii,:),[0 max(meanVarExpl(ii,:))],fH14, 'parula', ttl, [],[]);
        
        if opt.saveFig
            print(fH1,fullfile(dirPth.model.saveFigPth, opt.subfolder, sprintf('varexpl_mesh%s_%d_nearest',opt.fNamePostFix, ii)), '-dpng');
            print(fH12,fullfile(dirPth.model.saveFigPth, opt.subfolder, sprintf('varexpl_mesh%s_%d_interpolated',opt.fNamePostFix, ii)), '-dpng');
            print(fH13,fullfile(dirPth.model.saveFigPth, opt.subfolder, sprintf('varexpl_mesh%s_%d_nearest_maxCLim',opt.fNamePostFix, ii)), '-dpng');
            print(fH14,fullfile(dirPth.model.saveFigPth, opt.subfolder, sprintf('varexpl_mesh%s_%d_interpolated_maxCLim',opt.fNamePostFix, ii)), '-dpng');
        end
        
        % Plot Mean phase-referenced steady-state response and predicted response to
        % stimulus for top 10 sensors
        t = (0:nEpochs-1) .* diff(opt.meg.epochStartEnd);
        
        fH2 = figure(2); clf; set(fH2, 'Position', [652, 38,1206,1300], 'Color', 'w', 'Name', ...
            sprintf('Mean phase-ref MEG data and predicted response from pRF %d %s %s %s', ii, ttlPostFix{2},ttlPostFix{3},ttlPostFix{4}));
        
        for tt = 1:length(top10)
            subplot(5,2,tt); plot(t, zeros(size(t)), 'k'); hold on;
            plot(t, meanPhRefAmp10Hz(:,top10(tt),ii), 'ko-', 'LineWidth',2);
            plot(t, predMEGResponseScaled(:,top10(tt)), 'r', 'LineWidth',4);
            title(sprintf('Sensor %d, var expl: %1.2f',top10(tt), ve(tt)))
            xlabel('Time (s)'); ylabel('MEG response (Tesla)');
            set(gca, 'FontSize', 14, 'TickDir','out'); box off
            tmp_yl = max(abs([min(meanPhRefAmp10Hz(:,top10(tt),ii)), max(meanPhRefAmp10Hz(:,top10(tt),ii))])).*10^14;
            if (tmp_yl > 6), yl = [-1*tmp_yl, tmp_yl].*10^-14; else yl = [-6,6].*10^-14; end
            ylim(yl); xlim([0, max(t)])
            legend({'Data', 'Prediction'}, 'Location', 'SouthWest'); legend boxoff
        end
        
        if opt.saveFig
            print(fH2, fullfile(dirPth.model.saveFigPth, opt.subfolder, sprintf('varexpl_timeseries_TOP10%s_%d',opt.fNamePostFix, ii)), '-dpng');
        end
        
        
        % Plot all timeseries separately
        fH3 = figure; set(fH3, 'Position', [652,938,884,400], 'Color', 'w', 'Name', ...
            sprintf('Mean phase-ref MEG data and predicted response from pRF %d %s %s %s', ii, ttlPostFix{2},ttlPostFix{3},ttlPostFix{4}));
        
        for s = 1:nSensors
            clf;
            plot(t, zeros(size(t)), 'k'); hold on;
            plot(t, meanPhRefAmp10Hz(:,s,ii), 'ko-', 'LineWidth',2);
            hold on; plot(t, predMEGResponseScaled(:,s), 'r', 'LineWidth',4);
            title(sprintf('Sensor %d, var expl: %1.2f',s, meanVarExpl(ii, s)))
            xlabel('Time (s)'); ylabel('MEG response (Tesla)');
            set(gca, 'FontSize', 14, 'TickDir','out'); box off
            tmp_yl = max(abs([min(meanPhRefAmp10Hz(:,s,ii)), max(meanPhRefAmp10Hz(:,s,ii))])).*10^14;
            if tmp_yl>6, yl = [-1*tmp_yl, tmp_yl].*10^-14; else yl = [-6,6].*10^-14; end
            ylim(yl); xlim([0, max(t)])
            legend({'Data', 'Prediction'}, 'Location', 'SouthWest'); legend boxoff
            if opt.saveFig
                if ~exist(fullfile(dirPth.model.saveFigPth, opt.subfolder, 'timeseries'), 'dir')
                    mkdir(fullfile(dirPth.model.saveFigPth, opt.subfolder, 'timeseries')); end
                print(fH3, fullfile(dirPth.model.saveFigPth, opt.subfolder, 'timeseries', sprintf('varexpl_timeseries_sensor%d%s_iter%d',s, opt.fNamePostFix,ii)), '-dpng');
            end
        end
    end
    
    
end

fprintf('..Done!\n');

% Remove last dimension out, if not used
predMEGResponseToCompare  = squeeze(predMEGResponseScaled);
meanVarExpl            = squeeze(meanVarExpl);

if opt.saveData
    save(fullfile(dirPth.model.saveDataPth, opt.subfolder, 'pred_resp', 'meanVarExpl'), 'meanVarExpl','-v7.3');
    save(fullfile(dirPth.model.saveDataPth, opt.subfolder, 'pred_resp', 'predMEGResponseScaled'), 'predMEGResponseScaled','-v7.3');
    save(fullfile(dirPth.model.saveDataPth, opt.subfolder, 'pred_resp', 'meanPhRefAmp10Hz'), 'meanPhRefAmp10Hz','-v7.3');
end

return