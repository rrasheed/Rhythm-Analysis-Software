function normData = normalize_data_NRPM(data,Fs)
%% The function normalizes CMOS data between 0 and 1

% INPUTS
% data = cmos data
% Fs = sampling frequency

% OUTPUT
% normData = normalized data matrix

% METHOD
% Normalize data finds the minimum, maximum, and the difference in
% data values. The normalized data subtracts off the minimum values and 
% divides by the difference between the min and max. 

%% Code
%min_data = repmat(min(data,[],3),[1 1 size(data,3)]);
%diff_data = repmat(max(data,[],3)-min(data,[],3),[1 1 size(data,3)]);
%normData = (data-min_data)./(diff_data);
%% NON RECTANGULAR POLYGON MOD
min_data = repmat(min(data,[],2),[1 size(data,2)]);
diff_data = repmat(max(data,[],2),[1 size(data,2)])-min_data;
normData = (data-min_data)./diff_data;