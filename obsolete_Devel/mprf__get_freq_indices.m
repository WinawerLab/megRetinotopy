function [stim_idx, bb_idx] = mprf__get_freq_indices(do_stim, do_bb, opts)

stim_idx = [];
bb_idx = [];
% Stimulus locked, get the frequency from the input:
if do_stim
    
    stim_idx = round(mprfFreq2Index(opts.n_time,opts.stim_freq,opts.samp_rate));
    
end

% Broad band, define the frequencies we want here. Based on Eline's project
% (dfdDenoiseWrapper.m)
if do_bb
    if ~isfield(opts,'line_freq')
        opts.line_freq = 60; % Frequency of electrical grid, exclude it (and its harmonics)
    end
    
    if ~isfield(opts,'tol')
        opts.tol = 1.5; % tolerance
    end
    
    if ~isfield(opts,'f_lim')
        opts.f_lim = 150; % exclude frequencies above this frequency
    end
    

    f = 1:opts.f_lim;
    sl_drop = f(mod(f, opts.stim_freq) <= opts.tol | mod(f, opts.stim_freq) > opts.stim_freq - opts.tol);
    ln_drop     = f(mod(f, opts.line_freq) <= opts.tol | mod(f, opts.line_freq) > opts.line_freq - opts.tol);
    lf_drop     = f(f<opts.line_freq);
    
    [~, bb_freq] =  setdiff(f, [sl_drop ln_drop lf_drop]);
    bb_idx = round(mprfFreq2Index(opts.n_time,bb_freq,opts.samp_rate)); % Get indices
    
end











end