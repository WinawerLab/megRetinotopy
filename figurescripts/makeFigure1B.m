function makeFigure1B(dirPth,opt)
% Function to create figure 1B (Predicted responses for every MEG channel)

varExpFile = dir(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','meanVarExpl.mat'));
predRespFile = dir(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','meanPredResponse.mat'));
origMEGData = dir(fullfile(dirPth.model.saveDataPth,opt.subfolder,'pred_resp','phaseReferencedMEGData.mat'));

saveSubDir = 'figure1B';
saveDir = fullfile(dirPth.finalFig.savePth,'figure1',saveSubDir);
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% check if the modelPredictions are saved in the folder. Else run
% mprf_main.m
if ~isempty(varExpFile) && ~isempty(predRespFile) && ~isempty(origMEGData)
    
    % Load measured and predicted MEG responses
    load(fullfile(origMEGData.folder,origMEGData.name),'phRefAmp10Hz');
    load(fullfile(predRespFile.folder,predRespFile.name),'meanPredResponse');
    load(fullfile(varExpFile.folder,varExpFile.name),'meanVarExpl'); 
    
    % Sort the channels in the descending order of variance explained 
    [val, idx] = sort(meanVarExpl, 'descend');
    
%%    
    % Select channels that have high variance explained values
    nSensors = 10;
%%    
    tmp = idx(~isnan(val)); 
    topSensor=tmp(1:nSensors);
    ve = val(~isnan(val));
    ve_toPlot = round(ve.*100); 
   
    % define time scale
    [nEpochs, ~, nSensors, ~] = size(phRefAmp10Hz);
    t = (0:nEpochs-1) .* diff(opt.meg.epochStartEnd);

    close all;
    % Calculate mean measured MEG time series from 19 runs
    meanPhRefAmp10Hz = squeeze(nanmean(phRefAmp10Hz,2));
    for tt = 1:length(topSensor)

        % Define figure properties
        % figure 
        figPos = [66,1,1855,1001]; 
        figName = strcat('MEG time series: Measured vs Pred',sprintf('Sensor %d, var expl: %1.2f',topSensor(tt), ve(tt)));
        
        % plot
        % time series
        lW_orig = 3;        
        lW_pred = 6;        
        markerColor = [0 0 0]; %[0.3010, 0.7450, 0.9330];
        
        % axis properties
        %ttl = sprintf('Sensor %d, var expl: %1.2f',topSensor(tt), ve(tt));
        xLbl = 'Time (s)';
        yLbl = 'Phase-referenced 10 Hz amplitudes (fT)';
        fontSize = 30;
               
        % blink and blank blocks
        color = [0.5 0.5 0.5];
        nanIdx = find(isnan(meanPredResponse(:,topSensor(tt))));
        blinkIdx = nanIdx;
        blinkIdx(3:2:end) = blinkIdx(3:2:end) - 1;
        blinkIdx(2:2:end) = blinkIdx(2:2:end) + 1;
        blankIdx = nanIdx;
        blankIdx(1) = blinkIdx(1) + 2;
        blankIdx(3:2:end) = blinkIdx(3:2:end) + 3;
        blankIdx(2:2:end) = blinkIdx(2:2:end) + 2;
        blink_t = t(blinkIdx);
        blank_t = t(blankIdx);

         % Compute y limits
        tmp_yl = max(abs([min(meanPhRefAmp10Hz(:,topSensor(tt))), max(meanPhRefAmp10Hz(:,topSensor(tt)))])).*10^14;
        if (tmp_yl > 3)
            yl = [-1*tmp_yl, tmp_yl].*10^-14;
        else
            yl = [-3,3].*10^-14;
        end
        
        % Plot the figure
        fH1 = figure; set(gcf, 'Color', 'w', 'Position', figPos, 'Name', figName); hold all;

        % Plot the blank and blink periods
        for tmpIdx = 1:2:length(blink_t)
            patch([blink_t(tmpIdx),blink_t(tmpIdx+1) blink_t(tmpIdx+1) blink_t(tmpIdx)],[yl(1),yl(1),yl(2),yl(2)],color,'FaceAlpha', 0.2, 'LineStyle','none');
            patch([blank_t(tmpIdx),blank_t(tmpIdx+1) blank_t(tmpIdx+1) blank_t(tmpIdx)],[yl(1),yl(1),yl(2),yl(2)],color,'FaceAlpha', 0.7, 'LineStyle','none');
        end
        
        plot(t, zeros(size(t)), 'k');
        plot(t, meanPhRefAmp10Hz(:,topSensor(tt)), 'o--','color',markerColor, 'MarkerSize',10,'MarkerEdge',markerColor,'MarkerFace',markerColor, 'LineWidth',lW_orig);
        plot(t, meanPredResponse(:,topSensor(tt)), 'color',[1 0.45 0.45], 'LineWidth',lW_pred);
                
        % Set labels, limits, legends
        xlabel(xLbl); ylabel(yLbl);
        ylim(yl); xlim([0, max(t)])
        set(gca, 'FontSize', fontSize, 'TickDir','out','TickLength',[0.010 0.010],'LineWidth',3); box off
        
        l = findobj(gca, 'Type','Line');
        legend(l([2,1]), {'Observed', 'Predicted'}, 'Location', 'NorthEastOutside', 'FontSize', 25); legend boxoff;
        
        if opt.saveFig
            
            set(fH1,'Units','Inches');
            pos = get(fH1,'Position');
            set(fH1,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
            figurewrite(fullfile(saveDir, sprintf('MEG_time_series_Orig_Pred_sensor_%d_%d_%s',topSensor(tt),ve_toPlot(tt), opt.fNamePostFix)),[],0,'.',1);
            figurewrite(fullfile(saveDir, sprintf('MEG_time_series_Orig_Pred_sensor_%d_%d_%s',topSensor(tt),ve_toPlot(tt), opt.fNamePostFix)),[1 300],0,'.',1);
            makeFigure1B_i(topSensor(tt),saveDir, opt); % sensor location
            
        end
    end
 
    
end
 
fprintf('\n(%s): Saving figure 1B in %s\n',mfilename, saveDir);

end


function makeFigure1B_i(topSensor,saveDir, opt)
% creates and saves plot showing the position of the meg sensor
% axes('Position',[0.12 0.7 0.2 0.2]);
% box on; axis off; axis image;
fH1_1 = mprfPlotHeadLayout(topSensor, false, [], false);
saveas(fH1_1, fullfile(saveDir, sprintf('sensor_location_%d%s',topSensor,opt.fNamePostFix)), 'eps');
end