function mri_stim = loadMRIStimulus(dirPth, opt)

% subfunction of loadStim, to specifically prepare the MRI stimulus

% Options for vistasoft's rmStimulusMatrix function
useFinalImages = false;
scans          = false;
xRange         = [];
yRange         = [];

% Get MRI prf scan parameters from file
prfParams = load(dirPth.fmri.vistaGrayFitFile);

% [EK]: Apparently we only take the pixels that fall within the square
% window mask (im_conv). We don't need the im_unconv and we also don't need
% the allX and allY or allim for any computations (like smoothing the
% parameters on the surface). I guess it is good to have for
% visualization??
mri_stim.im_unconv = prfParams.params.stim.images_unconvolved;
mri_stim.im_conv = prfParams.params.analysis.allstimimages';

mri_stim.window  = prfParams.params.stim.stimwindow;
X = prfParams.params.analysis.X;
Y = prfParams.params.analysis.Y;

% Create X and Y axis of stimulus grid
[mri_stim.allX, mri_stim.allY] = meshgrid(unique(X), unique(Y));
mri_stim.X = X;
mri_stim.Y = Y;

% Get final retinotopy stimulus images (previously called full_im)
[~, mri_stim.allim] = rmStimulusMatrix(prfParams.params,xRange,yRange,useFinalImages,scans);

% saveDir = fullfile(dirPth.mri.processedDataPth, 'stimuli', 'mri');
% if ~exist('saveDir', 'dir'); mkdir(saveDir); end;
% save(fullfile(saveDir,'rm_stim.mat'), 'mri_stim');

end