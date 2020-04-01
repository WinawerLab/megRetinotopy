% Define all subjects
subjects = {'wlsubj004', 'wlsubj039', 'wlsubj040', 'wlsubj058','wlsubj068', ...
            'wlsubj070', 'wlsubj081', 'wlsubj106', 'wlsubj109', 'wlsubj111'}; % 
     

% Original
opt = getOpts('saveFig',1,'verbose',0, 'fullSizeMesh', 1, 'perturbOrigPRFs', false, 'recomputeFinalPredictionBetas', true); % see getOpts function for more options

% reset random number generator seed for reproducibility
rng(opt.seed)
for s = 1:length(subjects)
    subjID = subjects{s};
   
    mprf_main(subjID, opt);
    close all
end

% Size
opt = getOpts('saveFig',1,'verbose',0, 'fullSizeMesh', 1, 'perturbOrigPRFs','size', 'recomputeFinalPredictionBetas', true); % see getOpts function for more options
for s = 1:length(subjects)
    subjID = subjects{s};  
    mprf_main(subjID, opt);
    close all
end

% Position
opt = getOpts('saveFig',1,'verbose',0, 'fullSizeMesh', 1, 'perturbOrigPRFs','position','recomputeFinalPredictionBetas', true); % see getOpts function for more options
for s = 1:length(subjects)
    subjID = subjects{s};
    mprf_main(subjID, opt);
    close all
end

% Make figures
for s = 1:length(subjects)
    subjID = subjects{s};
    close all; makeAllFigures(subjID, 1:3, 'top10', false, 'meanVE');
end

% Make average figure
close all; makeAllFigures(subjID, 1:3, 'top10', true, 'meanVE');


% % Scramble
% opt = getOpts('saveFig',1,'verbose',0, 'fullSizeMesh', 1, 'perturbOrigPRFs','scramble', 'recomputeFinalPredictionBetas', true); % see getOpts function for more options
% for s = 1:length(subjects)
%     subjID = subjects{s};
%     mprf_main(subjID, opt);
%     close all
% end