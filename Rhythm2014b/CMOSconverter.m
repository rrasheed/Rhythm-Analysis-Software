function cmosData = CMOSconverter(olddir,oldfilename)
x2rot = 0;
flip = 0;
newfilename = [oldfilename(1:length(oldfilename)-3),'mat'];
dirname = [olddir,'/'];
% Read the file

        disp(['converting ',oldfilename])
        fid=fopen([dirname,oldfilename],'r','b');        
        fstr=fread(fid,'int8=>char')';
        fclose(fid);
        sampind2=strfind(fstr,'msec');
        sampind1=find(fstr(1:sampind2(1))==' ',1,'last');
        r=str2double(fstr(sampind1+1:sampind2(1)-1));%ratio of optical and analog samle rate
        
        dualind = strfind(fstr,'dual_cam');
        dual = str2double(fstr(dualind + 9));
        
        %save the frequency to put in the .m file
        frequency = 1000.0 / r;
        
        % locate the Data-File-List
        Dindex = find(fstr == 'D');
        for i = 1:length(Dindex)
            if isequal(fstr(Dindex(i):Dindex(i)+13),'Data-File-List')
                origin = Dindex(i)+14+2; % there are two blank char between each line
                break;
            end
        end

        % Save the data file paths
        len = length(fstr);
        N = 1000;  % assume file list < 1000 files
        dataPaths = cell(N,1);
        pointer = origin;
        %{
        while ~isequal(fstr(pointer:pointer+3),'.rsm')
            pointer = pointer + 1;
        end
        dataPaths{1,1} = fstr(origin:pointer+3);
        origin = pointer + 4 + 2;
        %}
        seq = 0;
        while origin<len
            seq = seq+1;
            pointer = origin;
            while (strcmp(fstr(pointer:pointer+3),'.rsd') || strcmp(fstr(pointer:pointer+3),'.rsm'))==0
                pointer = pointer + 1;
            end
            dataPaths{seq,1} = fstr(origin:pointer+3);%-+1
            origin = pointer+4+2;
        end
        dataPaths = dataPaths(1:seq);
        % Read CMOS data
        %h = fir1(50,250/fs);   % fs is the sampling frequncy; change filtering frequency here. 
        num = length(dataPaths);
        cmosData = int32(zeros(100,100,(num-1)*256));
        if dual ~= 0
            cmosData = int32(zeros(100,100,(num-1)*256/2));
            cmosData2 = int32(zeros(100,100,(num-1)*256/2));
        end
        channel1 = nan(1,(num-1)*256*r);
        channel2 = nan(1,(num-1)*256*r);
        k=1;
        for i = 2:num
            
            fpath = [dirname dataPaths{i}];
            fid=fopen(fpath,'r','l');       % use big-endian format
            fdata=fread(fid,'int16=>int32')'; %
            fclose(fid);
            %if dual == 0
                fdata = reshape(fdata,12800,[]);
            %else
            %    fdata = reshape(fdata,12800,256);
            %    if i == 1
            %        fdata(:,1) = fdata(:,3);
            %        fdata(:,2) = fdata(:,4);
            %    end
            %end
            %if i == 2 %assumes 1st .rsd file is 2nd file (.rsm is 1st)
            %    fdata(:,1) = fdata(:,2);
            %end
            step = 1;
            if dual ~= 0
                step = 2;
            end
            for j = 1:step:size(fdata,2);
                
                if dual == 0
                    oneframe = fdata(:,j);  % one frame at certain time point
                    oneframe = reshape(oneframe,128,100);
                    cmosData(:,:,k) = oneframe(21:120,:)';
                else
                    oneframe = fdata(:,j);
                    oneframe = reshape(oneframe,128,100);
                    cmosData(:,:,k) = oneframe(21:120,:)';
                    oneframe2 = fdata(:,j+1);
                    oneframe2 = reshape(oneframe2,128,100);
                    cmosData2(:,:,k) = oneframe2(21:120,:)';
                    %oneframe = fdata(:,j*2-1);  % one frame at certain time point
                    %oneframe = reshape(oneframe,128,100);
                    %oneframe = oneframe(21:120,:);
                    %cmosData(:,:,j+(i-1)*128) = -oneframe';
                    %oneframe = fdata(:,j*2);  % one frame at certain time point
                    %oneframe = reshape(oneframe,128,100);
                    %oneframe = oneframe(21:120,:);
                    %cmosData2(:,:,j+(i-1)*128) = -oneframe';
                end
                
                    channel1(k) = oneframe(13,1)+oneframe(13,5);%needs to be improved
                    channel2(k) = oneframe(15,2)+oneframe(15,6);

%                 if r==1
%                     channel1(k) = oneframe(16,1)+oneframe(16,5);%needs to be improved
%                     channel2(k) = oneframe(16,2)+oneframe(16,6);
%                 elseif r==2
%                     channel1(2*k-1:2*k) = [oneframe(16,1);oneframe(16,5)];
%                     channel2(2*k-1:2*k) = [oneframe(16,2);oneframe(16,6)];
%                 else
%                     disp('problem converting channels')
%                 end
                k=k+1;
            end
            clear fdata;
        end

%% % based on the assumption that the upstroke is downward, not upward.
        len = size(cmosData,3);
        thred = 2^16*3/4;
        for i = 1:100
            for j = 1:100
                temp = cmosData(i,j,:);
                if dual ~= 0
                    temp2 = cmosData2(i,j,:);
                end
                for k = 3:len %skip 1st frame, which is bg image, and 2nd frame, which is copy of 1st
                    if abs(temp(k)-temp(k-1))>thred
                        if temp(k)>0
                            temp(k)=temp(k)-2^16;
                        else
                            temp(k)=2^16+temp(k);
                        end
                    end
                    if dual ~= 0
                        if abs(temp2(k)-temp2(k-1))>thred
                            if temp2(k)>0
                                temp2(k)=temp2(k)-2^16;
                            else
                                temp2(k)=2^16+temp2(k);
                            end
                        end
                    end
                end
                cmosData(i,j,:) = -temp;
                if dual ~= 0
                    cmosData2(i,j,:) = -temp2;
                end
            end
        end     
        for r=1:x2rot
            for i=1:size(cmosData,3)
                cmosData(:,:,i)=rot90(cmosData(:,:,i));
                if dual ~= 0
                    cmosData2(:,:,i) = rot90(cmosData2(:,:,i));
                end
            end
        end
        if flip~=0
            cmosData=flipdim(cmosData,flip);
            if dual ~= 0
                cmosData2 = flipdim(cmosData2,flip);
            end
        end
        newfilename = [olddir,'/',newfilename];
        
        
        bgimage = -1 * cmosData(:,:,1);
        if dual ~=0
            bgimage2 = -1 * cmosData2(:,:,1);
        end
        
        %% conversion from CDS to DEF
cmosData=cmosData-repmat(bgimage,[1 1 size(cmosData,3)]);
if dual ~= 0
    cmosData2=cmosData2-repmat(bgimage2,[1 1 size(cmosData2,3)]);
end
       

        
        %bgimage = int16(scaledata(double(bgimage),0,255));
        if dual == 0
            save(newfilename,'cmosData','channel1','channel2','r', 'frequency', 'bgimage','dual');
        else
            save(newfilename,'cmosData','cmosData2','channel1','channel2','r','frequency','bgimage','bgimage2','dual');
        end
end