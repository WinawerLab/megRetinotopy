#!/bin/bash
 #
 #$ -N creating parameters for the MEG model to run
 #$ -S /bin/bash
 #$ -j Y
 #$ -q verylong.q
 #$ -o /home/edadan/meg_test.o
 #$ -u edadan
 #$ -m eas
 #$ -M a.edadan@uu.nl 


 if [ -z "$1" ]
 then
  echo 'Run_mprf_model. Inputs:'
  echo 'save_path_model_params=$1, path to save model parameters' 
  echo 'MEG_data_file=$2, Preprocessed MEG data'
  echo 'sub_sess_dir=$3, path to mprfSESSION'
  echo 'model_type=$4, subject session directory'
  echo 'variable parameters'
  exit 1
 fi

 # Load environment module 
 #module unload matlab/R2018b
 #module load matlab/R2016b
 module load matlab/R2018b
 echo "making params file for running MEG model"
 echo "Running $4"

 echo "$1" 
 echo "$2" 
 echo "$3"
 echo "$4"
 echo "$5"
 echo "$6"
 echo "$7" 

 # Run matlab job
 matlab -nodesktop -nosplash -nodisplay  -r "warning('off'); addpath(genpath('/home/edadan/Documents/MATLAB/toolboxes/')); mprfSession_model_server('$1','$2','$3','$4','n_iteration_scrambled','$5','n_cores','$6','phase_fit_loo','$7'); quit"

 # In case to debug the code
 # Run matlab job
 #matlab -nodesktop -nosplash -nodisplay  -r "addpath(genpath('/home/edadan/Documents/MATLAB/toolboxes/')); dbstop in mprfSession_model_server at 41; mprfSession_model_server('$1','$2','$3','$4','n_iteration_scrambled','$5','n_cores','$6','phase_fit_loo','$7'); quit"


#qsub -V /home/edadan/Documents/MATLAB/toolboxes/megRetinotopy/Server_analysis/mprf_model_server.sh '/home/edadan/data/Project/MEG/Retinotopy/Subject_sessions/wlsubj004/modeling/params_file' '/home/edadan/data/Project/MEG/Retinotopy/Data/MEG/wl_subj004/processed/epoched_data_hp_preproc_denoised.mat' '/home/edadan/data/Project/MEG/Retinotopy/Subject_sessions/wlsubj004' 'scrambled (phase ref amplitude) (model fit) (leave one out)' 1000 20 1

