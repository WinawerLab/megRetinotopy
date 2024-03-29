function [] = makeFigure3C_SSVEFReliability(subjectToPlot,plotAverage,plotSupplementalFig)
% Function to plot individual subjects for Figure 3C from manuscript,
% plotting 10 Hz SSVEF amplitude split-half reliability, i.e. mean 
% correlation (rho) across 10000 iterations of splitting individual 
% subjects runs randomly into two groups.

subjects = {'wlsubj004', 'wlsubj039', 'wlsubj040', 'wlsubj058','wlsubj068', ...
    'wlsubj070', 'wlsubj081', 'wlsubj106', 'wlsubj109', 'wlsubj111'};

figSize = [0,300,500,500];

if plotAverage || plotSupplementalFig
    subjectToPlot = 1:length(subjects);
    figSize = [1000, 651, 1500, 687];
end

fH2 = figure(2); clf; set(gcf,'Position',[0,300,500,500]); set(fH2, 'Name', 'SSVEF reliability Group Average' , 'NumberTitle', 'off');

if plotSupplementalFig
    dirPth = loadPaths(subjects{1});
    saveSubDir = 'SupplFigure1_SSVEF_coherence';
    saveDir = fullfile(dirPth.finalFig.savePthAverage,saveSubDir);
else
    dirPth = loadPaths(subjects{subjectToPlot});
    saveSubDir = 'Figure3C_SSVEFReliability';
    saveDir = fullfile(dirPth.finalFig.savePth,saveSubDir);
end
    

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

interpMethod = 'v4'; % or if not interpolated, use 'nearest'

if length(subjectToPlot) > 5
    nrows = 2;
    ncols = 5;
else
    nrows = 1;
    ncols = length(subjectToPlot);
end

% Define opts
opt = getOpts('saveFig', true,'verbose', true, 'fullSizeMesh', true, ...
        'perturbOrigPRFs', false, 'addOffsetParam', false, ...
        'refitGainParam', false);
    
% Get average subject data directory
dirPth = loadPaths(subjects{1});
[dataDir, tmp] = fileparts(dirPth.finalFig.savePthAverage);

% Load all subjects data at once
load(fullfile(dataDir, 'splitHalfAmpReliability1000.mat'), 'splitHalfAmpCorrelation');

%% Plot split half amplitude reliability 
fH1 = figure(1); clf; set(fH1,'Position', figSize, 'Name', 'SSVEF reliability' , 'NumberTitle', 'off');

for s = subjectToPlot 
    dirPth = loadPaths(subjects{1});
    subplot(nrows,ncols,s==subjectToPlot);
    ttl = sprintf('S%d', s);
    megPlotMap(splitHalfAmpCorrelation(s,:),[0 .8],fH1, 'hot', ...
        ttl, [],[], 'interpmethod', interpMethod); hold on;
    c = colorbar;c.TickDirection = 'out'; c.Box = 'off';
    pos = c.Position; set(c, 'Position', [pos(1)+0.04 pos(2)+0.03, pos(3)/1.5, pos(4)/1.5])
%         figurewrite(fullfile(saveDir, sprintf('Figure4_S%d_SSVEFReliabilityCorrelation_All_%s_%s', s, opt.fNamePostFix,interpMethod)),[],0,'.',1);
end

if opt.saveFig
    figure(fH1)
    print(fH1, fullfile(saveDir, sprintf('Figure3C_SSVEFReliabilityCorrelation_%s_%s', opt.fNamePostFix,interpMethod)), '-dpng');
    fprintf('(%s) Saving figure 3C: Individual subject''s SSVEF reliability in %s\n',mfilename, saveDir);
end

% Plot average split half amplitude reliability
figure(fH2); clf;
megPlotMap(nanmean(splitHalfAmpCorrelation,1),[0 0.8],fH2, 'hot', ...
    'Group Average SSVEF Reliability', [],[], 'interpmethod', interpMethod);
c = colorbar; c.Location='eastoutside';

if opt.saveFig
    saveDir = fullfile(dirPth.finalFig.savePthAverage,saveSubDir);
    print(fH2, fullfile(saveDir, sprintf('Figure3C_Group_SSVEFReliabilityCorrelation_%s_%s', opt.fNamePostFix,interpMethod)), '-dpng');
    fprintf('(%s): Saving figure 3C: Group Average SSVEF reliability in %s\n',mfilename, saveDir);
end

