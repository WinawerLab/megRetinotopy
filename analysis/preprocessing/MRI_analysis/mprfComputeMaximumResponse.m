function mresp = mprfComputeMaximumResponse(stim, sigma, X, Y, beta, mask)

% Preallocate output variable:
mresp = nan(size(sigma));

% Exclude voxels that are outside the mask, currently the voxels that have
% a var explained higher than 0, i.e. the voxels that are included in the
% field of view
sigma(~mask) = nan;

fprintf('Computing maximum responses:\n')
figure; title('Max response pRFs'); hold all;
xlabel('time points (TRs)');
ylabel('Response (% BOLD)')

% Loop over pRF in chunks of 1000 voxels:
for n = 1:1000:length(sigma)
    
    % Some feedback to user:
    if mod(n-1,10000) == 0
        f_done = n/length(sigma)*100;
        fprintf('%0.2f percent\n',f_done)
    end
    
    % Current pRF parameters
    end_idx = n+999;
    if end_idx > length(sigma)
        end_idx = length(sigma);
    end
    cur_sigma = sigma(n:end_idx);
    cur_x0 = X(n:end_idx);
    cur_y0 = Y(n:end_idx);
    
    % RF matrix:
    RF = rfGaussian2d(stim.X,stim.Y,cur_sigma,cur_sigma,false, cur_x0,cur_y0);
    
    % Predicted BOLD responses:
    tmp = stim.im_conv' * RF;
    
    % Maximum response for every pRF:
    mresp(n:end_idx) = max(tmp).*beta(n:end_idx);
    
    prfResp(:,n:end_idx) = tmp.*beta(n:end_idx);

    
    
end

[~, idx] = max(mresp);
plot(prfResp(:, 1:100:end)); hold all;
plot(prfResp(:, idx), 'r', 'LineWidth', 5);
drawnow;

% Done:
fprintf('Done\n');

end




















