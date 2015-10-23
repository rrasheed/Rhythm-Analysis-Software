function new_data = denoise_data(data,Fs,bg)
%% The function identifies and removes noisy pixels based on spectral power 

% INPUTS
% data = cmos data
% Fs = sampling frequency
% bg = background image (not necessary in current version)

% OUTPUT
% new_data = data matrix with denoise mask applied

% METHOD
% denoise_data applies a Tukey window to the CMOS data to minimized edge
% effects in the frequency spectrum of the signal. Next, single-sided power
% spectrum is calculated per pixel. Any DC power is removed from the power
% spectrum. Once complete, spectral power > 50 Hz is summed per pixel.
% Given the frequency content of optical action potentials (0-100 Hz),
% noisy pixels will contain more spectral power > 50 Hz compared to pixels
% contain action potentials. An empircal threshold is hard-coded to
% identifiy and remove noisy pixels and mask the data.

% SPECIAL CONSIDERATIONS
% This code is in its BETA testing stage and should be used carefully. One
% main assumption in this m-file is that the user has not already filtered
% the data above 50 Hz. Additionally, this code was written to fill holes
% in the mask.  This can be changed below at line 52.

%% Code
% Window Data with Tukey Window to Minimize Edge Effects
w_m = tukeywin(size(data,3),.05);
win = repmat(permute(w_m,[3 2 1]),[size(data,1),size(data,2)]);
data2 = data.*win;

% Find single-sided power spectrum of data
m = size(data2,3);               % Window length
n = pow2(nextpow2(m));          % Transform Length
y = fft(data2,n,3);              % DFT of signal
f = Fs/2*linspace(0,1,n/2+1);   % Frequency range
p = y.*conj(y)/n;               % Power of the DFT
p_s = p(:,:,1:n/2+1);           % Single-sided power
f(1) = [];                      % Remove DC
p_s(:,:,1) = [];                % Remove DC component
    
% Calculate spectral power above 50 Hz in all pixels
ind = find(f >=50,1,'first');
noise_sum = sum((p_s(:,:,ind:end)),3);
temp = noise_sum(isfinite(noise_sum));
mask = zeros(size(data,1),size(data,2));
mask(isfinite(noise_sum)) = temp < mean2(temp)*.8; % empirical threshold

% Clean up mask by finding largest areas of connected components
mask_fill = imfill(mask, 'holes');
cc =bwconncomp(mask_fill);
labeled = labelmatrix(cc);
stats = regionprops(cc,'Area');
[val id] = max([stats.Area]);
mask_temp = labeled == id;
mask_clean = mask_temp.*mask_fill;

% Apply mask and remove noisy pixels
mask_mat = repmat(mask_clean,[1 1 size(data,3)]);    
new_data = data.*mask_mat;

% Re-normalized Data
new_data = normalize_data(new_data,Fs);
end