function calDomFreq(data,Fs)
%% Window Data with Tukey Window to Minimize Edge Effects
w_m = tukeywin(size(data,3),.05);
win = repmat(permute(w_m,[3 2 1]),[size(data,1),size(data,2)]);
data = data.*win;
%% Find single-sided power spectrum of data
m = size(data,3);               % Window length
n = pow2(nextpow2(m));          % Transform Length
y = fft(data,n,3);              % DFT of signal
f = Fs/2*linspace(0,1,n/2+1);   % Frequency range
p = y.*conj(y)/n;               % Power of the DFT
p_s = 2*abs(p(:,:,1:n/2+1));    % Single-sided power
f(1) = [];                      % Remove DC
p_s(:,:,1) = [];                % Remove DC component
%% Find Dominant Frequency
[val ind] = max(p_s,[],3);
maxf = f(ind).*isfinite(val);
figure; imagesc(maxf); colorbar
caxis([mean2(maxf)*.1 mean2(maxf)*2])