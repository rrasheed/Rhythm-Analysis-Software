function noise = GenerateNoise (sf, dur, noisetype, lf, hf)
%
% noise = GenerateNoise (sf, dur)
% filterednoise = GenerateNoise (sf, dur, noisetype, f1)
% filterednoise = GenerateNoise (sf, dur, noisetype, f1, f2)
% 
% This function generates a Gaussian noise either white (default option if
% noisetype is omitted), lowpass, highpass, bandpass or notched (i.e.,
% bandstop).
%
% SF: sample frequency of the noise in Hz
% DUR: noise duration in msec
% NOISETYPE: a string with the kind of noise has to be generated. 
% Accepted noisetype are 'lowpass', 'highpass', 'bandpass' and 'notched'
% F1: lowest frequency of the filter in Hz
% F2: highest frequency of the filter in Hz. This value can be omitted for
% highpass and lowpass filtered noises.
%
% % EXAMPLE: generate a lowpass filtered noise of 500-ms with cutoff
% frequency of 5000-Hz
% filterednoise = GenerateFilteredNoise (44100, 500, 'lowpass', 5000);

if nargin < 3
    % set general variables
    numberofsamples = round(sf*(dur/1000)); % number of samples

    % make noise
    noise = randn(numberofsamples, 1);	% White Gaussian noise
    % amplitude normalization
    noise = noise/max(abs(noise));
    noise = noise*.999;
else
    if nargin<5, hf=lf; end;
    if hf<lf
        error('hf cannot be greater than than lf');
    end;

    % set general variables
    numberofsamples = round(sf*(dur/1000));     % number of samples
    % make noise
    noise = randn(numberofsamples,1);           % White Gaussian noise
    noise = noise / max(abs(noise));            % -1 to 1 normalization
    % =========================================================================
    % set variables for filter
    lp = lf/(sf/2); 
	hp = hf/(sf/2);
	delta=0.1;
    % design filter
    switch noisetype
        case 'lowpass'
			[n,Wn]=buttord(lp,lp+delta,2,60);
			[b,a]=butter(n,Wn,'low');
        case 'highpass'
			[n,Wn]=buttord(hp,hp-delta,2,60);
			[b,a]=butter(n,Wn,'high');
        case 'bandpass'
			[n,Wn]=buttord([lp hp],[lp-delta hp+delta],2,60);
			[b,a]=butter(n,Wn);
        case 'notched'
			[n,Wn]=buttord([lp-delta hp+delta],[lp hp],2,60);
			[b,a]=butter(n,Wn,'stop');
        otherwise
            error('unknown noisetype');
    end;
    % =========================================================================
    % do filter
    noise = filter(b,a,noise);
    % amplitude normalization
    noise = noise/max(abs(noise));
    noise = noise*.999;
end;