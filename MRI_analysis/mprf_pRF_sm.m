function mprf_pRF_sm(dirPth,plot_stim)
% mprf_pRF_sm - Smooth (without interpolation,VE_thr=0) prf parameters on the mrVista volume view  
%                  
%
%

% File paths
% ----------
rootDir = dirPth.rootPth;

anat_dir = dirPth.mri.anatPth; 
anat_file = strcat(rootDir,anat_dir(2:end),'/t1.nii.gz');
seg_file = strcat(rootDir,anat_dir(2:end),'/t1_class.nii.gz');
cls = niftiRead(seg_file);

% directories to save results
% original and smoothed pRF parameters in mrVista space in .nii 
prf_dir_mrv = dirPth.fmri.saveDataPth_prfMrv;
prf_data_mrVNif = strcat(rootDir,prf_dir_mrv(2:end),'/nifti'); % original and smoothed pRF parameters in mrVista space in .nii
prf_data_mrVmat = strcat(rootDir,prf_dir_mrv(2:end),'/mat'); % original and smoothed pRF parameters in mrVista space in .mat

mrSession_dir = dirPth.fmri.mrvPth; 
% ----------


% step inside the vistasession directory contain mrSESSION.mat
cd(mrSession_dir);

% We need a volume view:
data_type = 'Averages';
setVAnatomyPath(anat_file);
hvol = initHiddenGray;
hvol = viewSet(hvol,'curdt',data_type);% Set the volume view to the current data type and add the RM model
% from mrVista session directory
if strcmpi(dirPth.subjID,'wlsubj004')
    rm_model = strcat('./Gray/Averages/rm_retModel-20170519-155117-fFit.mat');
else
    rm_model = strcat('./Gray/Averages/rm_Averages-fFit.mat');
end
hvol = rmSelect(hvol,1,rm_model);

% Mask to exclude unreliable voxels (i.e. VE == 0) from the smoothing
% below. Otherwise, the pRF parameters will be averaged with a lot of
% zeros:
sm_mask = rmGet(hvol.rm.retinotopyModels{1},'varexplained') > 0;

% We need these parameters from the pRF model
params = {'sigma','x','y','varexplained','beta'};
% We need the mrVista segmentation to check if the selection of pRF
% parameters is correct, i.e. all selected pRF parameters must fall in the
% gray matter.

% stimulus file (stimulus used to run retinotopic model - has to prepared from hvol.rm.retinotopicmodels.stim and hvol.rm.retinotopicmodels.analysis)
% load(rm_stim_file);
% rm_stim =  meg_stim;
rm_stim.im = hvol.rm.retinotopyParams.stim.images_unconvolved;
rm_stim.im_conv = hvol.rm.retinotopyParams.analysis.allstimimages';
rm_stim.window = hvol.rm.retinotopyParams.stim.stimwindow;
rm_stim.X = hvol.rm.retinotopyParams.analysis.X;
rm_stim.Y = hvol.rm.retinotopyParams.analysis.Y;

if plot_stim == 1
   figure, 
   for idx_stim_frame = 1:size(rm_stim.im,2)
       cur_window = rm_stim.window;
       cur_window(cur_window==1)=rm_stim.im(:,idx_stim_frame);
       imagesc(reshape(cur_window,[101,101]));
       pause(0.05);
   end    
end

%%

% Initialize the weighted connectivity matrix used in the smoothing
wConMat = [];

for nn = 1:length(params)
    
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
        
        prf_par_exp.(cur_param) = rmGet(hvol.rm.retinotopyModels{1},cur_param);
    end
    
    % current parameter's NIFTI file:
    fname = fullfile(prf_data_mrVNif,[cur_param '.nii.gz']);
    
    % Load the current parameter in the VOLUME view. This is mainly used to
    % export the pRF parameters to nifti files. The nifti files are really
    % just for inspection and are not used in any further analyses
    hvol = viewSet(hvol,'curdt',data_type);
    hvol = refreshScreen(hvol);
    
    % Store the data as nifti and check against the segmentation to see if
    % parameter nifti aligns with the segmentation:
    functionals2nifti(hvol,1 , fname);
    mprfCheckParameterNiftiAlignment(cls, fname);
    
    prf_par_exp.(cur_param) = rmGet(hvol.rm.retinotopyModels{1},cur_param);
    
    switch lower(cur_param)
        
        case 'beta'
            
            % Compute the maximum response for every included pRF, by
            % reconstructing the pRF, multiplying it with the stimulus and
            % it's beta, and taking the maximum response from the
            % predicted time series
            mresp = mprfComputeMaximumResponse(rm_stim,sigma_us,x0,y0,prf_par_exp.(cur_param),sm_mask);
                 
            % Store the maximum responses as a nifti file:
            
            fname = fullfile(prf_data_mrVNif,'mresp.nii.gz');
            prf_par_exp.('mresp') = mresp;
            hvol = viewSet(hvol,'map',{mresp});
            functionals2nifti(hvol, 1, fname);
            mprfCheckParameterNiftiAlignment(cls, fname);
            
            prf_par_exp.('mresp') = mresp;
            
             % Smooth the maximum responses on the cortical surface
            [mresp_sm, wConMat] = dhkGraySmooth(hvol,mresp,[ ],wConMat, sm_mask);
            
            % Export smoothed maximum responses as a nifti:
            hvol = viewSet(hvol,'map',{mresp_sm});
            fname = fullfile(prf_data_mrVNif,'mresp_smoothed.nii.gz');
            functionals2nifti(hvol, 1, fname);
            mprfCheckParameterNiftiAlignment(cls, fname);
            
            prf_par_exp.('mresp_smoothed') = mresp_sm;
            
            
            % Recompute the beta by dividing the smoothed maxumimum
            % responses by the maximum response given the stimulus and
            % smoothed pRF parameters:
            recomp_beta = mprfRecomputeBetas(rm_stim,sigma_smooth,x0_smooth,y0_smooth,mresp_sm);
            
            % Store as nifti:
            fname = fullfile(prf_data_mrVNif,'recomp_beta.nii.gz');
            hvol = viewSet(hvol,'map',{recomp_beta});
            functionals2nifti(hvol, 1, fname);
            mprfCheckParameterNiftiAlignment(cls, fname);
            
            prf_par_exp.('recomp_beta') = recomp_beta;
            
            
        case {'x','y','sigma'}
            
            % Smooth the current paramter:
            [tmp_sm_par, wConMat] = dhkGraySmooth(hvol,prf_par_exp.(cur_param),[ ],wConMat, sm_mask);
            
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

fname = fullfile(prf_data_mrVmat,'exported_prf_params.mat');
save(fname, 'prf_par_exp');

end

