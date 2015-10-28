function seg_Data(data,st_time,ed_time,Fs,bg,grp_nbr)
%% Create initial variables
st_frame=round(st_time*Fs);
ed_frame=round(ed_time*Fs);
actMap = zeros(size(data,1),size(data,2));
temp = data(:,:,st_frame:ed_frame); % windowed signal

% Re-normalize data to handle drift
temp = normalize_data(temp,Fs);

%% Calculate dF/dt max and activation time
temp2 = diff(temp,1,3); % first derivative
[dFdt_max,max_i] = max(temp2,[],3); % find location of max derivative
act_time = (max_i - min(min(max_i))).*1000/Fs;

%% Calculate APD
time_mat = repmat(permute(1:size(temp,3),[1 3 2]),[size(temp,1) size(temp,2) 1]);
time_mat_rev = repmat(permute(size(temp,3):-1:1,[1 3 2]),[size(temp,1) size(temp,2) 1]);
prct = .80;
test = temp > 1-prct;
tic
diff_test = zeros(size(test));
diff_test(:,:,1:end-1) = diff(test,1,3);
test2 = diff_test < 0;
[max_v,max_vi] = max(temp,[],3);
test3 = (time_mat - repmat(max_vi,[1 1 size(temp,3)])) > 0;
temp3 = max(test2.*test3.*time_mat_rev,[],3);
APD = (size(temp,3) - temp3 - max_i).*1000/Fs .* isfinite(temp(:,:,1));
toc
%% Create vectors of dF/dt Max and APD
APD_max = 200;
APD_min = 10;
ind = isfinite(dFdt_max) & APD >APD_min & APD < APD_max;
dFdt_vect = dFdt_max(ind);
APD_vect = APD(ind);
%% Segement data using a gaussian mixture model. 
% Run Gaussian mixture model (MATLAB native function)
max_grps = grp_nbr;
options = statset('Display','off','MaxIter',500,'TolFun',1E-7);
% Preallocate variable logl
logl = zeros(max_grps,1);
for i = 1:max_grps
logl(i) = GMM(APD_vect,i,options);
end
[~ ,gs] = min(logl);
grps = gs + 0;
obj = gmdistribution.fit(APD_vect,grps,'Options',options);
mu = obj.mu;
sd = sqrt(squeeze(obj.Sigma));
prt = obj.PComponents;

% Sort data
[mu,s_i] = sort(mu);
sd = sd(s_i);
prt = prt(s_i);
% Pre-allocate for speed
w = zeros(grps,size(APD_vect,1));
a = zeros(grps,size(APD_vect,1));
a_temp = zeros(grps,size(APD_vect,1));

% Calculate Gaussian distributions based on GMM
for i = 1:grps
w(i,:) = normpdf(APD_vect,mu(i),sd(i));
end

% Perform soft assigment
for i = 1:grps
a(i,:)= prt(i)*w(i,:)./sum(prt(ones(1,size(w,2)),:)'.*w,1);
a_temp(i,:) = (a(i,:) >.5).*i;
end
a_cum = sum(a_temp,1);

% Create color mask for data
mask = zeros(size(data,1),size(data,2));
mask(ind) = a_cum;

% Interpolate PDFs for plotting
xx = min(APD_vect):1:max(APD_vect);
% Preallcate variable ww
ww = zeros(grps,size(xx,2));
for i = 1:grps
    ww(i,:) = normpdf(xx,mu(i),sd(i));
end

%% Calculate Stats for each group
% Preallocate variables
g_mean = zeros(grps,1);
g_std = zeros(grps,1);
for j = 1:grps
g_mean(j) = mean(APD(mask == j));
g_std(j) = std(APD(mask == j));
end
%% Plot results
figure;
% Plot APD overlaid onto tissue
subplot(221)
colorbar
APD_min = prctile(APD(ind),5);
APD_max = prctile(APD(ind),95);
caxis([APD_min APD_max])
hold on
bgRGB = real2rgb(flipud(bg),'gray');
alpha = real2rgb(flipud(isfinite(temp(:,:,1))),'gray');
apdRGB = real2rgb(flipud(APD),'jet',[APD_min APD_max]);
I = bgRGB.*(1-alpha) + alpha.*(apdRGB);
image(I);axis image;axis off
title(['APD',num2str(prct*100)])

% Plot segmented map onto tissue
subplot(222)
bgRGB = real2rgb(bg,'gray');
alpha = real2rgb(ind,'gray');
segAPD = real2rgb(mask,'jet');
I = bgRGB.*(1-alpha) + alpha.*(segAPD);
image(I);axis image;axis off
title(['Bootstrap Segmented APD',num2str(prct*100)])

% Plot segmented histogram
subplot(2,2,[3 4])
hold on
color_mat = ['c' 'y' 'r' 'm' 'g' 'b'];
for i = 1:size(w,1)
[n, xout] = hist(APD_vect(a_cum == i),max(APD_vect)-min(APD_vect));
bar(xout,n,'FaceColor',color_mat(i),'EdgeColor','none','BarWidth',1)
end
plot(xx,sum(prt(ones(1,size(ww,2)),:)'.*ww,1).*size(APD_vect,1),'k','LineWidth',2)
xlabel('APD')
ylabel('Counts')
title('APD Histogram')
% for i = 1:size(w,1)
% plot(xx,ww(i,:)'.*size(APD_vect,1).*prt(i),color_mat(i),'LineWidth',2)
% end
g_mean
g_std
end