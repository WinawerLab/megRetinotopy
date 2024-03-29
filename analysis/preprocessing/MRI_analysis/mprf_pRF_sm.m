function mprf_pRF_sm(dirPth,opt)
% mprf_pRF_sm(dirPth,plot_stim)
%
% Function to smooth prf parameters in mrVista Gray Ribbon (volume)
% (without interpolation,since variance explained threshold is set to 0:
% VE_thr=0)
%                  
% INPUTS:
%   dirPth      :   paths locating subject's data and files (struct, see loadPaths.m)
%   opt         :   struct with boolean flags, needed to request plotting MRI stimulus or not
%
%% ----------
% File paths
% ----------
anat_dir  = fullfile(dirPth.fmri.mrvPth, '3DAnatomy');
anat_file = fullfile(anat_dir,'t1.nii.gz');
seg_file  = fullfile(anat_dir,'t1_class.nii.gz');
cls       = niftiRead(seg_file);

% Directories to save results
prf_dir_mrv     = dirPth.fmri.saveDataPth_prfMrv;
prf_data_mrVNif = fullfile(prf_dir_mrv, 'nifti');   % original and smoothed pRF parameters in mrVista space in .nii
prf_data_mrVmat = fullfile(prf_dir_mrv,'mat');      % original and smoothed pRF parameters in mrVista space in .mat

% Create directories if they don't exist
if ~exist(prf_data_mrVNif,'dir'); mkdir(prf_data_mrVNif); end
if ~exist(prf_data_mrVmat,'dir'); mkdir(prf_data_mrVmat); end

% Step inside the vistasession directory to access mrSESSION.mat
cd(dirPth.fmri.mrvPth);

%% ---------------------------------------
% Load Retinotopy model parameters
% ----------------------------------------

% We need a volume view, with 'Averages' data type to add the RM model
data_type = 'Averages';
setVAnatomyPath(anat_file);
hvol = initHiddenGray;
hvol = viewSet(hvol,'curdt',data_type);  

% Load mrVista retinotopy Gray file 
rm_model = dirPth.fmri.vistaGrayFitFile;
hvol = rmSelect(hvol,1,rm_model);

% We'll mask later unreliable voxels (i.e. VE < 0.10) when loading params:
% see loadpRFsfromSurface.m. For now we restrict to those voxels with
% positive only variance explained.
ve = rmGet(hvol.rm.retinotopyModels{1},'varexplained');
ve0mask = ve > 0;


% We need these parameters from the pRF model
params = {'sigma','x','y','varexplained','beta'};

% stimulus file (stimulus used to run retinotopic model - has to prepared
% from hvol.rm.retinotopicmodels.stim and
% hvol.rm.retinotopicmodels.analysis) load(rm_stim_file):
rm_stim.im      = hvol.rm.retinotopyParams.stim.images_unconvolved;
rm_stim.im_conv = hvol.rm.retinotopyParams.analysis.allstimimages';
rm_stim.window  = hvol.rm.retinotopyParams.stim.stimwindow;
rm_stim.X       = hvol.rm.retinotopyParams.analysis.X;
rm_stim.Y       = hvol.rm.retinotopyParams.analysis.Y;

% Visualize MRI stimulus if requested
if opt.verbose
   figure, 
   for idx_stim_frame = 1:size(rm_stim.im,2)
       cur_window = rm_stim.window;
       cur_window(cur_window==1)=rm_stim.im(:,idx_stim_frame);
       imagesc(reshape(cur_window,[101,101])); 
       title(sprintf('Frame %d', idx_stim_frame)); 
       colormap gray; axis square; drawnow;
       pause(0.05);
   end    
end

%% ----------------------------------------
% Smooth prf parameters and recompute betas
% -----------------------------------------

% Initialize the weighted connectivity matrix used in the smoothing
wConMat = [];

for nn = 1:length(params)
    
    % Select prf parameter
    cur_param = params{nn};
        
    % Load the current parameter in the VOLUME view. This is mainly used to
    % export the pRF parameters to nifti files. The nifti files are really
    % just for inspection and are not used in any further analyses
    hvol = rmLoad(hvol,1,cur_param,'map');
    hvol = refreshScreen(hvol);
    
    % Get the data directly from the retinotopic model as well. This is the
    % data that we use to smooth and store for further analyses:
    if strcmpi(cur_param,'beta')
        tmp = rmGet(hvol.rm.retinotopyModels{1},'bcomp1');
        prf_par_exp.(cur_param) = squeeze(tmp);
    else
        tmp = rmGet(hvol.rm.retinotopyModels{1},cur_param);
        prf_par_exp.(cur_param) = squeeze(tmp);
    end
    
    % current parameter's NIFTI file:
    fname = fullfile(prf_data_mrVNif,[cur_param '.nii.gz']);
    
    % Store the data as nifti and check against the segmentation to see if
    % parameter nifti aligns with the segmentation:
    functionals2nifti(hvol,1 , fname);
    mprfCheckParameterNiftiAlignment(cls, fname);
        
    switch lower(cur_param)
        
        case 'beta'
            
            % Compute the maximum response for every included pRF, by
            % reconstructing the pRF, multiplying it with the stimulus and
            % it's beta, and taking the maximum response from the
            % predicted time series
            maxresp = mprfComputeMaximumResponse(rm_stim,sigma_us,x0,y0,prf_par_exp.(cur_param),ve0mask);
                 
            % Store the maximum responses as a nifti file: 
            hvol = viewSet(hvol,'map',{maxresp});
            functionals2nifti(hvol, 1, fname);
            mprfCheckParameterNiftiAlignment(cls, fname);
            
             % Smooth the maximum responses on the cortical surface
            [maxresp_smoothed, wConMat] = dhkGraySmooth(hvol,maxresp,[ ],wConMat, ve0mask);
            
            % Export smoothed maximum responses as a nifti:
            hvol = viewSet(hvol,'map',{maxresp_smoothed});
            fname = fullfile(prf_data_mrVNif,'maxresp_smoothed.nii.gz');
            functionals2nifti(hvol, 1, fname);
            mprfCheckParameterNiftiAlignment(cls, fname);
            
            prf_par_exp.('mresp_smoothed') = maxresp_smoothed; %(ek): not really necessary to save, since we don't use it
            
            % Recompute the beta by dividing the smoothed maxumimum
            % responses by the maximum response given the stimulus and
            % smoothed pRF parameters:
            recomp_beta = mprfRecomputeBetas(rm_stim,sigma_smooth,x0_smooth,y0_smooth,maxresp_smoothed);
            recomp_beta(isinf(recomp_beta))=NaN;
            
            % Store as nifti:
            fname = fullfile(prf_data_mrVNif,'recomp_beta.nii.gz');
            hvol = viewSet(hvol,'map',{recomp_beta});
            functionals2nifti(hvol, 1, fname);
            mprfCheckParameterNiftiAlignment(cls, fname);
            
            prf_par_exp.('recomp_beta') = recomp_beta;
            
            
        case {'x','y','sigma'}
            
            % Smooth the current paramter:
            [tmp_sm_par, wConMat] = dhkGraySmooth(hvol,prf_par_exp.(cur_param),[ ],wConMat, ve0mask);
            
            % Export smoothed data as nifti:
            fname = fullfile(prf_data_mrVNif,[cur_param '_smoothed.nii.gz']);
            
            hvol = viewSet(hvol,'map',{tmp_sm_par});
            functionals2nifti(hvol,1 , fname);
            mprfCheckParameterNiftiAlignment(cls, fname);
            
            prf_par_exp.([cur_param '_smoothed']) = tmp_sm_par;
            
            % Store the current parameters as we need them for the Beta
            % computations above:
            if strcmpi(cur_param,'x')
                x0 = prf_par_exp.(cur_param);
                x0_smooth = tmp_sm_par;
            elseif strcmpi(cur_param,'y')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
                y0  = prf_par_exp.(cur_param);
                y0_smooth = tmp_sm_par;
            elseif strcmpi(cur_param,'sigma')
                sigma_us = prf_par_exp.(cur_param);
                sigma_smooth = tmp_sm_par;
            end
            
    end
end

% Create polar angle and eccentricity maps (for smoothed and unsmoothed)
types = {'unsmooth', 'smooth'};
for ii = 1:length(types)
    
    if strcmp(types(ii), 'unsmooth')
    
        [ang, ecc] = cart2pol(prf_par_exp.x, prf_par_exp.y);
        ang_deg    = mod(ang, 2*pi);
    
        prf_par_exp.polar_angle = ang_deg;
        prf_par_exp.eccentricity = ecc;
        postFix = '.nii.gz';

    elseif strcmp(types(ii), 'smooth')
        
        [ang, ecc] = cart2pol(prf_par_exp.x_smoothed, prf_par_exp.y_smoothed);
        ang_deg    = mod(ang, 2*pi);    
        
        prf_par_exp.polar_angle_smoothed = ang_deg;
        prf_par_exp.eccentricity_smoothed = ecc;
        postFix = '_smoothed.nii.gz';
    end

    fname = fullfile(prf_data_mrVNif,['polar_angle' postFix]);
    hvol = viewSet(hvol,'map',{ang_deg});
    functionals2nifti(hvol,1 , fname);
    mprfCheckParameterNiftiAlignment(cls, fname);
    
    fname = fullfile(prf_data_mrVNif,['eccentricity' postFix]);
    hvol = viewSet(hvol,'map',{ecc});
    functionals2nifti(hvol,1 , fname);
    mprfCheckParameterNiftiAlignment(cls, fname);

end



% Save smoothed prf parameters
fname = fullfile(prf_data_mrVmat,'exported_prf_params.mat');
save(fname, 'prf_par_exp');


%% ROIS

% Define path to Wang atlas
wangAtlasPath = sprintf(fullfile(dirPth.fs.segPth, 'mri',...
    'native.wang2015_atlas.mgz'));

vw = mrVista('3');

%% Open meshes
mesh1 = fullfile('3DAnatomy', 'Left', '3DMeshes', 'Left_inflated.mat');
mesh2 = fullfile('3DAnatomy', 'Right', '3DMeshes', 'Right_inflated.mat');

if ~exist(mesh1, 'file') || ~exist(mesh2, 'file')
    error('Meshes not found. Please run t_meshFromFreesurfer.')
end
[vw, OK] = meshLoad(vw, mesh1, 1); if ~OK, error('Mesh server failure'); end
[vw, OK] = meshLoad(vw, mesh2, 1); if ~OK, error('Mesh server failure'); end

%% Wang ROIs

% Convert mgz to nifti
[pth, fname] = fileparts(wangAtlasPath);
wangAtlasNifti = fullfile(pth, sprintf('%s.nii.gz', fname));

ni = MRIread(wangAtlasPath);
MRIwrite(ni, wangAtlasNifti);

% Load the nifti as ROIs
vw = wangAtlasToROIs(vw, wangAtlasNifti);

% Save the ROIs
local = false; forceSave = true;
saveAllROIs(vw, local, forceSave);

end

