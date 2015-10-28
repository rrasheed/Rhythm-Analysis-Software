function logl = GMM(APD_vect,grps,options)
obj = gmdistribution.fit(APD_vect,grps,'Options',options);
logl = obj.NlogL;
end