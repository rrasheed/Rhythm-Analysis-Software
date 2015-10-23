function rhythm_iDS
close all; clc
%% RHYTHM (01/27/2012)
% Matlab software for analyzing optical mapping data

% By Matt Sulkin, Jake Laughner, Xinyuan Sophia Cui, Jed Jackoway
% Washington University in St. Louis -- Efimov Lab

% For any questions and suggestions, please email us at:
% jacoblaughner@gmail.com or igor@wustl.edu

%% Create GUI structure
scrn_size = get(0,'ScreenSize');
f = figure('Name','RHYTHM','Visible','off','Position',[scrn_size(3),scrn_size(4),1250,830],'NumberTitle','Off');

% Load Data
p1 = uipanel('Title','Display Data','FontSize',12,'Position',[.01 .01 .98 .98]);
filelist = uicontrol('Parent',p1,'Style','listbox','String','Files','Position',[10 340 150 450],'Callback',{@filelist_callback});
selectdir = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Select Directory','Position',[10 305 150 30],'Callback',{@selectdir_callback});
loadfile = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Load','Position',[10 275 150 30],'Callback',{@loadfile_callback});
refreshdir = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Refresh Directory','Position',[10 245 150 30],'Callback',{@refreshdir_callback});

% Movie Screen for Optical Data
movie_scrn = axes('Parent',p1,'Units','Pixels','YTick',[],'XTick',[],'Position',[170, 290, 500,500]);

% Movie Slider for Controling Current Frame
movie_slider = uicontrol('Parent',f, 'Style', 'slider','Position', [185, 280, 501, 20],'SliderStep',[.001 .01],'Callback',{@movieslider_callback});
hListener = handle.listener(movie_slider,'ActionEvent',@movieslider_callback);

% Mouse Listening Function
set(f,'WindowButtonDownFcn',{@button_down_function});
set(f,'WindowButtonUpFcn',{@button_up_function});
set(f,'WindowButtonMotionFcn',{@button_motion_function});

% Signal Display Screens for Optical Action Potentials
signal_scrn1 = axes('Units','Pixels','Color','w','XTick',[],'Position',[720, 690,500,115]);
signal_scrn2 = axes('Units','Pixels','Color','w','XTick',[],'Position',[720, 565,500,115]);
signal_scrn3 = axes('Units','Pixels','Color','w','XTick',[],'Position',[720, 440,500,115]);
signal_scrn4 = axes('Units','Pixels','Color','w','XTick',[],'Position',[720, 315,500,115]);
signal_scrn5 = axes('Units','Pixels','Color','w','XTick',[],'Position',[720, 190,500,115]);
signal_scrn6 = axes('Units','Pixels','Color','w','Position',[720, 70,500,110]);
xlabel('Time (sec)');
expwave_button = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Export OAPs','Position',[1115 1 100 30],'Callback',{@expwave_button_callback});
starttimemap_text = uicontrol('Parent',p1,'Style','text','FontSize',12,'String','Start Time','Position',[700 1 75 25]);
starttimemap_edit = uicontrol('Parent',p1,'Style','edit','FontSize',14,'Position',[775 4 55 25],'Callback',{@starttime_edit_callback});
endtimemap_text = uicontrol('Parent',p1,'Style','text','FontSize',12,'String','End Time','Position',[850 1 75 25]);
endtimemap_edit = uicontrol('Parent',p1,'Style','edit','FontSize',14,'Position',[925 4 55 25],'Callback',{@endtime_edit_callback});

% Sweep Bar Display for Optical Action Potentials
sweep_bar = axes ('Units','Pixels','Layer','top','Position',[720, 50,500,760]);
set(sweep_bar,'NextPlot','replacechildren','Visible','off')

% Video Control Buttons and Optical Action Potential Display
play_button = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Play Movie','Position',[215 245 100 30],'Callback',{@play_button_callback});
stop_button = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Stop Movie','Position',[315 245 100 30],'Callback',{@stop_button_callback});
dispwave_button = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Display Wave','Position',[415 245 100 30],'Callback',{@dispwave_button_callback});
expmov_button = uicontrol('Parent',p1,'Style','pushbutton','FontSize',12,'String','Export Movie','Position',[515 245 100 30],'Callback',{@expmov_button_callback});

% Signal Conditioning Button Group and Buttons
cond_sig = uibuttongroup('Parent',p1,'Title','Condition Signals','FontSize',12,'Position',[0.01 0.001 .13 .30]);
removeBG_button = uicontrol('Parent',cond_sig,'Style','checkbox','FontSize',12,'String','Remove Background','Position',[12 200 150 25]);
bg_thresh_label = uicontrol('Parent',cond_sig,'Style','text','FontSize',12,'String','BG Threshold','Position',[20 175 80 25]);
perc_ex_label = uicontrol('Parent',cond_sig,'Style','text','FontSize',12,'String','EX Threshold','Position',[20 155 80 25]);
bg_thresh_edit = uicontrol('Parent',cond_sig,'Style','edit','FontSize',12,'String','0.3','Position',[100 180 35 25]);
perc_ex_edit = uicontrol('Parent',cond_sig,'Style','edit','FontSize',12,'String','0.5','Position',[100 160 35 25]);
bin_button  = uicontrol('Parent',cond_sig,'Style','checkbox','FontSize',12,'String','Bin','Position',[12 135 150 25]);
filt_button = uicontrol('Parent',cond_sig,'Style','checkbox','FontSize',12,'String','Filter','Position',[12 110 150 25]);
removeDrift_button = uicontrol('Parent',cond_sig,'Style','checkbox','FontSize',12,'String','-Drift','Position',[12 85 150 25]);
norm_button  = uicontrol('Parent',cond_sig,'Style','checkbox','FontSize',12,'String','Normalize','Position',[12 60 150 25]);
denoise_button = uicontrol('Parent',cond_sig,'Style','checkbox','FontSize',12,'String','Denoise (BETA)','Position',[12 35 150 25]);
apply_button = uicontrol('Parent',cond_sig,'Style','pushbutton','FontSize',12,'String','Apply','Position',[3 2 150 30],'Callback',{@cond_sig_selcbk});
%Pop-up menu options
bin_popup = uicontrol('Parent',cond_sig,'Style','popupmenu','FontSize',12,'String',{'3 x 3', '5 x 5', '7 x 7'},'Position',[65 133 90 25]);
filt_popup = uicontrol('Parent',cond_sig,'Style','popupmenu','FontSize',12,'String',{'[0 50]','[0 75]', '[0 100]', '[0 150]'},'Position',[65 108 90 25]);
drift_popup = uicontrol('Parent',cond_sig,'Style','popupmenu','FontSize',12,'String',{'1st Order','2nd Order', '3rd Order', '4th Order'},'Position',[65 83 90 25]);
set(filt_popup,'Value',3)

% Optical Action Potential Analysis Button Group and Buttons
% Create Button Group
anal_data = uibuttongroup('Parent',p1,'Title','Analyze Data','FontSize',12,'Position',[0.145 0.001 .405 .30]);

% Activation Map
activation_map = uibuttongroup('Parent',anal_data,'Title','Activation Map', 'FontSize',12,'Position',[0.01 0.5 .32 .49]);
starttimeamap_text = uicontrol('Parent',activation_map,'Style','text','FontSize',12,'String','Start Time','Position',[5 60 75 25]);
starttimeamap_edit = uicontrol('Parent',activation_map,'Style','edit','FontSize',14,'Position',[85 60 55 25],'Callback',{@amaptime_edit_callback});
endtimeamap_text = uicontrol('Parent',activation_map,'Style','text','FontSize',12,'String','End Time','Position',[5 33 75 25]);
endtimeamap_edit = uicontrol('Parent',activation_map,'Style','edit','FontSize',14,'Position',[85 33 55 25],'Callback',{@amaptime_edit_callback});
createmap_button = uicontrol('Parent',activation_map,'Style','pushbutton','FontSize',12,'String','Activation Map','Position',[2 2 150 30],'Callback',{@createmap_button_callback});

% Conduction Velocity Map
conduction_map = uibuttongroup('Parent',anal_data,'Title','Conduction Velocity', 'FontSize',12,'Position',[0.01 0.01 .32 .49]);
starttimecmap_text = uicontrol('Parent',conduction_map,'Style','text','FontSize',12,'String','Start Time','Position',[5 60 75 25]);
starttimecmap_edit = uicontrol('Parent',conduction_map,'Style','edit','FontSize',14,'Position',[85 60 55 25],'Callback',{@cmaptime_edit_callback});
endtimecmap_text = uicontrol('Parent',conduction_map,'Style','text','FontSize',12,'String','End Time','Position',[5 33 75 25]);
endtimecmap_edit = uicontrol('Parent',conduction_map,'Style','edit','FontSize',14,'Position',[85 33 55 25],'Callback',{@cmaptime_edit_callback});
createcmap_button = uicontrol('Parent',conduction_map,'Style','pushbutton','FontSize',12,'String','Conduction Velocity Map','Position',[2 2 150 30],'Callback',{@createcmap_button_callback});

% APD Map
APD_map = uibuttongroup('Parent',anal_data,'Title','APD Map', 'FontSize',12,'Position',[0.34 0.01 .32 .98]);
starttimeapdmap_text = uicontrol('Parent',APD_map,'Style','text','FontSize',12,'String','Start Time','Position',[5 180 75 25]);
starttimeapdmap_edit = uicontrol('Parent',APD_map,'Style','edit','FontSize',14,'Position',[85 180 55 25],'Callback',{@apdmaptime_edit_callback});
endtimeapdmap_text = uicontrol('Parent',APD_map,'Style','text','FontSize',12,'String','End Time','Position',[5 153 75 25]);
endtimeapdmap_edit = uicontrol('Parent',APD_map,'Style','edit','FontSize',14,'Position',[85 153 55 25],'Callback',{@apdmaptime_edit_callback});
createapd_button = uicontrol('Parent',APD_map,'Style','pushbutton','FontSize',12,'String','APD Map','Position',[2 30 150 30],'Callback',{@createapd_button_callback});

minapd_text = uicontrol('Parent',APD_map,'Style','text','FontSize',12,'String','Min APD','Position',[5 126 75 25]);
minapd_edit = uicontrol('Parent',APD_map,'Style','edit','FontSize',12,'String','0','Position',[85 126 55 25],'Callback',{@minapd_edit_callback});
maxapd_text = uicontrol('Parent',APD_map,'Style','text','FontSize',12,'String','Max APD','Position',[5 99 75 25]);
maxapd_edit = uicontrol('Parent',APD_map,'Style','edit','FontSize',12,'String','1000','Position',[85 99 55 25],'Callback',{@maxapd_edit_callback});
percentapd_text= uicontrol('Parent',APD_map,'Style','text','FontSize',12,'String','%APD','Position',[5 72 75 25]);
percentapd_edit= uicontrol('Parent',APD_map,'Style','edit','FontSize',12,'String','0.8','Position',[85 72 55 25],'callback',{@percentapd_edit_callback});
remove_motion_click = uicontrol('Parent',APD_map,'Style','checkbox','FontSize',12,'String','Remove Motion','Position',[20 55 150 25]);
calc_apd_button = uicontrol('Parent',APD_map,'Style','pushbutton','FontSize',12,'String','Regional APD','Position',[2 2 150 30],'Callback',{@calc_apd_button_callback});

% Plug-In
plugin_group = uibuttongroup('Parent',anal_data,'Title','Plug Ins', 'FontSize',12,'Position',[0.67 0.01 .32 .98]);
createphase_button = uicontrol('Parent',plugin_group,'Style','pushbutton','FontSize',12,'String','Calculate Phase','Position',[2 165 150 30],'Callback',{@createphase_button_callback});
createDomFreq_button = uicontrol('Parent',plugin_group,'Style','pushbutton','FontSize',12,'String','Dominant Frequency','Position',[2 135 150 30],'Callback',{@calcDomFreq_button_callback});
createSegData_button = uicontrol('Parent',plugin_group,'Style','pushbutton','FontSize',12,'String','Bootstrap Analysis','Position',[2 105 150 30],'Callback',{@calcSegData_button_callback});
starttimebtstrp_text = uicontrol('Parent',plugin_group,'Style','text','FontSize',12,'String','Start Time','Position',[5 80 75 25]);
starttimebtstrp_edit = uicontrol('Parent',plugin_group,'Style','edit','FontSize',14,'Position',[85 80 55 25],'Callback',{@btstrptime_edit_callback});
endtimebtstrp_text = uicontrol('Parent',plugin_group,'Style','text','FontSize',12,'String','End Time','Position',[5 53 75 25]);
endtimebtstrp_edit = uicontrol('Parent',plugin_group,'Style','edit','FontSize',14,'Position',[85 53 55 25],'Callback',{@btstrptime_edit_callback});
grps_text = uicontrol('Parent',plugin_group,'Style','text','FontSize',12,'String','Max Groups','Position',[5 25 75 25]);
grp_edit = uicontrol('Parent',plugin_group,'Style','edit','String','10','FontSize',14,'Position',[85 25 55 25]);

% Allow all GUI structures to be scaled when window is dragged
set([f,p1,filelist,selectdir,refreshdir,loadfile,movie_scrn,movie_slider, signal_scrn1,signal_scrn2,signal_scrn3,...
    signal_scrn4,signal_scrn5,signal_scrn6,sweep_bar,dispwave_button,play_button,stop_button,cond_sig,filt_button,bin_button,...
    norm_button,createmap_button,createapd_button,createcmap_button,expmov_button,expwave_button,activation_map,starttimeamap_text,starttimeamap_edit,...
    endtimeamap_text,endtimeamap_edit,apply_button,removeBG_button,removeDrift_button,starttimecmap_text,starttimecmap_edit...
    endtimecmap_text,endtimecmap_edit,conduction_map,anal_data,activation_map,APD_map,starttimemap_text,starttimemap_edit...
    endtimemap_text,endtimemap_edit,minapd_text,minapd_edit,maxapd_text,maxapd_edit,percentapd_text,percentapd_edit,remove_motion_click...
    remove_motion_click,calc_apd_button,starttimeapdmap_text,starttimeapdmap_edit,endtimeapdmap_text,endtimeapdmap_edit, bin_popup, filt_popup,...
    drift_popup,plugin_group,bg_thresh_label,perc_ex_label,bg_thresh_edit,perc_ex_edit,createphase_button,createDomFreq_button,denoise_button,...
    createSegData_button,starttimebtstrp_text,starttimebtstrp_edit,endtimebtstrp_text,endtimebtstrp_edit,grps_text,grp_edit],'Units','normalized');

% Center GUI on screen
movegui(f,'center')
set(f,'Visible','on')

%% Create handles
handles.filename = [];
handles.cmosData = [];
handles.rawData = [];
handles.time = [];
handles.wave_window = 1;
handles.normflag = 0;
handles.Fs = 1000; % this is the default value. it will be overwritten
handles.starttime = 0;
handles.endtime = 1;
handles.grabbed = -1;
handles.M = []; % this handle stores the locations of the markers
handles.slide=-1; % parameter for recognize clicking location
%%minimum values pixels require to be drawn
handles.minVisible = 6;
handles.normalizeMinVisible = .3;

%% All Callback functions


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% USER FUNCTIONALITY
%% Listen for mouse clicks for the point-dragger
% When mouse button is clicked and held find associated marker
    function button_down_function(obj,event)
        set(obj,'CurrentAxes',movie_scrn)
        ps = get(gca,'CurrentPoint');
        i_temp = round(ps(1,1));
        j_temp = round(ps(2,2));
        % if one of the markers on the movie screen is clicked
        if i_temp<=size(handles.cmosData,1) || j_temp<size(handles.cmosData,2) || i_temp>1 || j_temp>1
            if size(handles.M,1) > 0
                for i=1:size(handles.M,1)
                    if i_temp == handles.M(i,1) && handles.M(i,2) == j_temp
                        handles.grabbed = i;
                        break
                    end
                end
            end
        end
    end
%% When mouse button is released
    function button_up_function(obj,event)
        handles.grabbed = -1;
    end

%% Update appropriate screens or slider when mouse is moved
    function button_motion_function(obj,event)
        % Update movie screen marker location
        if handles.grabbed > -1
            set(obj,'CurrentAxes',movie_scrn)
            ps = get(gca,'CurrentPoint');
            i_temp = round(ps(1,1));
            j_temp = round(ps(2,2));
            if i_temp<=size(handles.cmosData,1) && j_temp<=size(handles.cmosData,2) && i_temp>1 && j_temp>1
                handles.M(handles.grabbed,:) = [i_temp j_temp];
                i = i_temp;
                j = j_temp;
                switch handles.grabbed
                    case 1
                        plot(handles.time,squeeze(handles.cmosData(j,i,:)),'b','LineWidth',2,'Parent',signal_scrn1)
                        handles.M(1,:) = [i j];
                    case 2
                        plot(handles.time,squeeze(handles.cmosData(j,i,:)),'g','LineWidth',2,'Parent',signal_scrn2)
                        handles.M(2,:) = [i j];
                    case 3
                        plot(handles.time,squeeze(handles.cmosData(j,i,:)),'y','LineWidth',2,'Parent',signal_scrn3)
                        handles.M(3,:) = [i j];
                    case 4
                        plot(handles.time,squeeze(handles.cmosData(j,i,:)),'k','LineWidth',2,'Parent',signal_scrn4)
                        handles.M(4,:) = [i j];
                    case 5
                        plot(handles.time,squeeze(handles.cmosData(j,i,:)),'c','LineWidth',2,'Parent',signal_scrn5)
                        handles.M(5,:) = [i j];
                    case 6
                        plot(handles.time,squeeze(handles.cmosData(j,i,:)),'m','LineWidth',2,'Parent',signal_scrn6)
                        handles.M(6,:) = [i j];
                end
                cla
                currentframe = handles.frame;
                drawFrame(currentframe);
                M = handles.M; colax='bgykcm'; [a ~]=size(M);
                hold on
                for x=1:a
                    plot(M(x,1),M(x,2),'cs','MarkerSize',8,'MarkerFaceColor',colax(x),'MarkerEdgeColor','w','Parent',movie_scrn);
                    set(movie_scrn,'YTick',[],'XTick',[]);% Hide tick markes
                end
                hold off
            end
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD DATA
%% List that contains all files in directory
    function filelist_callback(source,eventdata)
        str = get(source, 'String');
        val = get(source,'Value');
        file = char(str(val));
        handles.filename = file;
    end

%% Load selected files in filelist
    function loadfile_callback(source,eventdata)
        if isempty(handles.filename)
            msgbox('Warning: No data selected','Title','warn')
        else
            % Clear off all images from previous set of data
            cla(movie_scrn); cla(signal_scrn1); cla(signal_scrn2); cla(signal_scrn3)
            cla(signal_scrn4); cla(signal_scrn5); cla(signal_scrn6); cla(sweep_bar)
            % Initialize handles
            handles.M = []; % this handle stores the locations of the markers
            handles.normflag = 0;% this handle indicate if normalize is clicked
            handles.wave_window = 1;% this handle indicate the window number of the next wave displayed
            handles.frame = 1;% this handles indicate the current frame being displayed by the movie screen
            handles.slide=-1;% this handle indicate if the movie slider is clicked
            % Convert and/or Load File
            filename = [handles.dir,'/',handles.filename];
            if exist([filename(1:end-3),'mat'],'file')
                g = waitbar(0,'Loading...');
                Data = load([filename(1:end-3),'mat']);
                if strcmp(handles.filename(end-2:end),'avi') == 1
                    handles.cmosData = -Data.cmosData;
                else
                    handles.cmosData = double(Data.cmosData);
                end
                handles.Fs = double(Data.frequency);
                handles.bg = double(Data.bgimage);
                handles.bgRGB = real2rgb(handles.bg, 'gray');
            elseif sum(filename(end-2:end)=='rsh') == 3
                g = waitbar(0,'Converting...');
                CMOSconverter(handles.dir,handles.filename);
                Data = load([filename(1:end-3),'mat']);
                cmosData = double(Data.cmosData);
                handles.cmosData = cmosData(:,:,2:end);
                handles.Fs = double(Data.frequency);
                handles.bg = double(Data.bgimage);
                handles.bgRGB = real2rgb(handles.bg, 'gray');
                % Data.channel1 is not necessarily the ecg channel. Please make changes based on your specific situation
                handles.ecg = Data.channel1;
            elseif sum(filename(end-2:end)=='avi') == 3
                g = waitbar(0,'Converting...');
                [cmosData,frequency,bgimage] = iDSconverter(handles.dir,handles.filename);
                handles.cmosData = -cmosData;
                handles.Fs = frequency;
                handles.bg = bgimage;
                handles.bgRGB = real2rgb(handles.bg,'gray');
            end
            handles.matrixMax = .9 * max(handles.cmosData(:));

            % Initialize movie screen to the first frame
            set(f,'CurrentAxes',movie_scrn)
            
            G = real2rgb(handles.bg, 'gray');
            Mframe = handles.cmosData(:,:,handles.frame);
            J = real2rgb(Mframe, 'jet');
            A = real2rgb(Mframe >= handles.minVisible, 'gray');
            I = J .* A + G .* (1-A);
            handles.movie_img = image(I,'Parent',movie_scrn);
            set(movie_scrn,'NextPlot','replacechildren','YTick',[],'XTick',[])
            % Scale signal screens and sweep bar to appropriate time scale
            handles.time = (1:size(handles.cmosData,3))/handles.Fs;
            set(signal_scrn1,'XLim',[min(handles.time) max(handles.time)])
            set(signal_scrn1,'NextPlot','replacechildren')
            set(signal_scrn2,'XLim',[min(handles.time) max(handles.time)])
            set(signal_scrn2,'NextPlot','replacechildren')
            set(signal_scrn3,'XLim',[min(handles.time) max(handles.time)])
            set(signal_scrn3,'NextPlot','replacechildren')
            set(signal_scrn4,'XLim',[min(handles.time) max(handles.time)])
            set(signal_scrn4,'NextPlot','replacechildren')
            set(signal_scrn5,'XLim',[min(handles.time) max(handles.time)])
            set(signal_scrn5,'NextPlot','replacechildren')
            set(signal_scrn6,'XLim',[min(handles.time) max(handles.time)])
            set(signal_scrn6,'NextPlot','replacechildren')
            set(sweep_bar,'XLim',[min(handles.time) max(handles.time)])
            set(sweep_bar,'NextPlot','replacechildren')
            % Fill times into activation map editable textboxes
            handles.starttime = 0;
            handles.endtime = max(handles.time);
            set(starttimemap_edit,'String',num2str(handles.starttime))
            set(endtimemap_edit,'String',num2str(handles.endtime))
            set(starttimeamap_edit,'String',num2str(handles.starttime))
            set(endtimeamap_edit,'String',num2str(handles.endtime))
            set(starttimecmap_edit,'String',num2str(handles.starttime))
            set(endtimecmap_edit,'String',num2str(handles.endtime))
            set(starttimeapdmap_edit,'String',num2str(handles.starttime))
            set(endtimeapdmap_edit,'String',num2str(handles.endtime))
            set(starttimebtstrp_edit,'String',num2str(handles.starttime))
            set(endtimebtstrp_edit,'String',num2str(handles.endtime))
            delete(g) % delete waitbar
            % Initialize movie slider to the first frame
            set(movie_slider,'Value',0)
            drawFrame(1);
        end
    end

%% Select directory for optical files
    function selectdir_callback(source,eventdata)
        dir_name = uigetdir;
        handles.dir = dir_name;
        search_avi = [dir_name,'/*.avi'];
        search_rsh = [dir_name,'/*.rsh'];
        files_avi = struct2cell(dir(search_avi));
        files_rsh = struct2cell(dir(search_rsh));
        handles.file_list = [files_rsh(1,:) files_avi(1,:)]';
        set(filelist,'String',handles.file_list)
        handles.filename = char(handles.file_list(1));
    end

%% Refresh file list (in case more files are open after directory is selected)
    function refreshdir_callback(source,eventdata)
        dir_name = handles.dir;
        search_name = [dir_name,'/*.rsh'];
        files = struct2cell(dir(search_name));
        handles.file_list = files(1,:)';
        set(filelist,'String',handles.file_list)
        handles.filename = char(handles.file_list(1));
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MOVIE SCREEN
%% Movie Slider Functionality
    function movieslider_callback(source,eventdata)
        val = get(source,'Value');
        i = round(val*size(handles.cmosData,3))+1;
        handles.frame = i;
        if handles.frame == size(handles.cmosData,3) + 1
            i = size(handles.cmosData,3);
            handles.frame = size(handles.cmosData,3);
        end
        
        % Update movie screen
        set(movie_scrn,'NextPlot','replacechildren','YTick',[],'XTick',[]);
        set(f,'CurrentAxes',movie_scrn)
        drawFrame(i);
        % Update markers on movie screen
        M = handles.M; colax='bgykcm'; [a ~]=size(M);
        hold on
        for x=1:a
            plot(M(x,1),M(x,2),'cs','MarkerSize',8,'MarkerFaceColor',colax(x),'MarkerEdgeColor','w','Parent',movie_scrn);
            set(movie_scrn,'YTick',[],'XTick',[]);% Hide tick markes
        end
        hold off
        % Update sweep bar
        set(f,'CurrentAxes',sweep_bar)
        a = [handles.time(i) handles.time(i)];b = [0 1]; cla
        plot(a,b,'r','Parent',sweep_bar)
        axis([handles.starttime handles.endtime 0 1])
        hold off; axis off
    end

%% Draw
    function drawFrame(frame)
        G = handles.bgRGB;
        Mframe = handles.cmosData(:,:,frame);
        if handles.normflag == 0
            Mmax = handles.matrixMax;
            Mmin = handles.minVisible;
            numcol = size(jet,1);
            J = ind2rgb(round((Mframe - Mmin) ./ (Mmax - Mmin) * (numcol - 1)), jet);
            A = real2rgb(Mframe >= handles.minVisible, 'gray');
        else
            J = real2rgb(Mframe, 'jet');
            A = real2rgb(Mframe >= handles.normalizeMinVisible, 'gray');
        end
        
        I = J .* A + G .* (1 - A);
        image(I,'Parent',movie_scrn);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DISPLAY CONTROL
%% Play button functionality
    function play_button_callback(source,eventdata)
        if isempty(handles.cmosData)
            msgbox('Warning: No data selected','Title','warn')
        else
            handles.playback = 1; % if the PLAY button is clicked
            startframe = handles.frame;
            % Update movie screen with new frames
            for i = startframe:5:size(handles.cmosData,3)
                if handles.playback == 1 % recheck if the PLAY button is clicked
                    set(movie_scrn,'NextPlot','replacechildren','YTick',[],'XTick',[]);
                    set(f,'CurrentAxes',movie_scrn)
                    drawFrame(i);
                    handles.frame = i;
                    % Update markers with each frame
                    M = handles.M;[a ~]=size(M); colax='bgykcm';
                    hold on
                    for x=1:a
                        plot(M(x,1),M(x,2),'cs','MarkerSize',8,'MarkerFaceColor',colax(x),'MarkerEdgeColor','w','Parent',movie_scrn)
                    end
                    pause(0.01)
                    % Update movie slider
                    set(movie_slider,'Value',(i-1)/size(handles.cmosData,3))
                    
                    % Update sweep bar
                    set(f,'CurrentAxes',sweep_bar)
                    a = [handles.time(i) handles.time(i)];b = [0 1]; cla
                    plot(a,b,'r','Parent',sweep_bar)
                    axis([handles.starttime handles.endtime 0 1])
                    hold off; axis off
                    pause(0.01); pause(0.01)
                else
                    break
                end
                
            end
            handles.frame = min(handles.frame, size(handles.cmosData, 3));
            set(movie_scrn,'NextPlot','replacechildren','YTick',[],'XTick',[]);
            set(f,'CurrentAxes',movie_scrn)
            drawFrame(i);
            handles.frame = i;
            % Update makers with each frame
            M = handles.M;[a ~]=size(M); colax='bgykcm';
            hold on
            for x=1:a
                plot(M(x,1),M(x,2),'cs','MarkerSize',8,'MarkerFaceColor',colax(x),'MarkerEdgeColor','w','Parent',movie_scrn)
            end
            pause(0.01)
            % Update movie slider
            set(movie_slider,'Value',(i-1)/size(handles.cmosData,3))
            
            % Update sweep bar
            set(f,'CurrentAxes',sweep_bar)
            a = [handles.time(i) handles.time(i)];b = [0 1]; cla
            plot(a,b,'r','Parent',sweep_bar)
            axis([handles.starttime handles.endtime 0 1])
            hold off; axis off
        end
    end

%% Stop button functionality
    function stop_button_callback(source,eventdata)
        handles.playback = 0;
    end

%% Display Wave Button Functionality
    function dispwave_button_callback(source,eventdata)
        set(f,'CurrentAxes',movie_scrn)
        [i_temp j_temp] = myginput(1,'circle');
        i = round(i_temp); j = round(j_temp);
        %make sure pixel selected is within movie_scrn
        if i_temp>size(handles.cmosData,1) || j_temp>size(handles.cmosData,2) || i_temp<=1 || j_temp<=1
            msgbox('Warning: Pixel Selection out of Boundary','Title','help')
        else
            % Find the correct wave window
            if handles.wave_window == 7
                handles.wave_window = 1;
            end
            wave_window = handles.wave_window;
            switch wave_window
                case 1
                    plot(handles.time,squeeze(handles.cmosData(j,i,:)),'b','LineWidth',2,'Parent',signal_scrn1)
                    handles.M(1,:) = [i j];
                case 2
                    plot(handles.time,squeeze(handles.cmosData(j,i,:)),'g','LineWidth',2,'Parent',signal_scrn2)
                    handles.M(2,:) = [i j];
                case 3
                    plot(handles.time,squeeze(handles.cmosData(j,i,:)),'y','LineWidth',2,'Parent',signal_scrn3)
                    handles.M(3,:) = [i j];
                case 4
                    plot(handles.time,squeeze(handles.cmosData(j,i,:)),'k','LineWidth',2,'Parent',signal_scrn4)
                    handles.M(4,:) = [i j];
                case 5
                    plot(handles.time,squeeze(handles.cmosData(j,i,:)),'c','LineWidth',2,'Parent',signal_scrn5)
                    handles.M(5,:) = [i j];
                case 6
                    plot(handles.time,squeeze(handles.cmosData(j,i,:)),'m','LineWidth',2,'Parent',signal_scrn6)
                    handles.M(6,:) = [i j];
            end
            handles.wave_window = wave_window + 1; % Dial up the wave window count
            % Update movie screen with new markers
            cla
            currentframe = handles.frame;
            drawFrame(currentframe);
            M = handles.M; colax='bgykcm'; [a ~]=size(M);
            hold on
            for x=1:a
                plot(M(x,1),M(x,2),'cs','MarkerSize',8,'MarkerFaceColor',colax(x),'MarkerEdgeColor','w','Parent',movie_scrn);
                set(movie_scrn,'YTick',[],'XTick',[]);% Hide tick markes
            end
            hold off
        end
    end

%% Export movie to .avi file
%Construct a VideoWriter object and view its properties. Set the frame rate to 60 frames per second:
    function expmov_button_callback(source,eventdata)
        fig=figure('Name',[handles.filename(1:end-4) ' movie'],'NextPlot','replacechildren','NumberTitle','off',...
            'Visible','off','OuterPosition',[170, 140, 556,715]);
        % Save the movie to the same directory as the cmos data
        movname = [handles.dir,'/',handles.filename(1:end-4),' movie' '.avi'];
        vidObj = avifile(movname,'compression','None');
        axis tight
        set(gca,'nextplot','replacechildren');
        % Creat pop up screen; the start time and end time are controled
        % from the graphic interface panel
        for i = handles.starttime*handles.Fs:5:handles.endtime*handles.Fs
            % If start time is zero set movie start frame to 1
            if i == 0
                i=i+1;
            else
            end
            % Plot sweep bar on bottom subplot
            subplot('Position',[0.05, 0.1, 0.9,0.15])
            a = [handles.time(i)*handles.Fs-handles.starttime*handles.Fs handles.time(i)*handles.Fs-handles.starttime*handles.Fs];
            b = [min(handles.ecg) max(handles.ecg)];
            cla
            plot(a,b,'r','LineWidth',1.5);hold on
            % Plot ecg data on bottom subplot
            subplot('Position',[0.05, 0.1, 0.9,0.15])
            if handles.starttime*handles.Fs==0
                start = 1;
            else
                start = handles.starttime*handles.Fs;
            end
            ecg_data=handles.ecg(start:handles.endtime*handles.Fs);
            plot(ecg_data);
%             plot(handles.M(2,:))
%             plot(handles.M(4,:))
            axis([0 handles.endtime*handles.Fs-handles.starttime*handles.Fs min(handles.ecg) max(handles.ecg)])
            % Set the xick mark to start from zero
            xlabel('Time (msec)');hold on
            % Image movie frames on the top subplot
            subplot('Position',[0.05, 0.28, 0.9,0.68])
            % Update image
            G = handles.bgRGB;
            Mframe = handles.cmosData(:,:,i);
            if handles.normflag == 0
                Mmax = handles.matrixMax;
                Mmin = handles.minVisible;
                numcol = size(jet,1);
                J = ind2rgb(round((Mframe - Mmin) ./ (Mmax - Mmin) * (numcol - 1)), jet);
                A = real2rgb(Mframe >= handles.minVisible, 'gray');
            else
                J = real2rgb(Mframe, 'jet');
                A = real2rgb(Mframe >= handles.normalizeMinVisible, 'gray');
            end
            
            I = J .* A + G .* (1 - A);
            image(I);
            axis off; hold off
            F = getframe(fig);
            vidObj = addframe(vidObj,F);% Write each frame to the file.
        end
        close(fig);
        vidObj=close(vidObj); % Close the file.
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SIGNAL SCREENS
%% Start Time Editable Textbox for Signal Screens
    function starttime_edit_callback(source,eventdata)
        val = get(source,'String');
        handles.starttime = str2num(val);
        set(signal_scrn1,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn2,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn3,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn4,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn5,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn6,'XLim',[handles.starttime handles.endtime]);
        set(sweep_bar,'XLim',[handles.starttime handles.endtime]);
    end

%% End Time Editable Textbox for Signal Screens
    function endtime_edit_callback(source,eventdata)
        val = get(source,'String');
        handles.endtime = str2num(val);
        set(signal_scrn1,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn2,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn3,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn4,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn5,'XLim',[handles.starttime handles.endtime]);
        set(signal_scrn6,'XLim',[handles.starttime handles.endtime]);
        set(sweep_bar,'XLim',[handles.starttime handles.endtime]);
    end

%% Export signal waves to new screen
    function expwave_button_callback(source,eventdata)
        M = handles.M; colax='bgykcm'; [a ~]=size(M);
        if isempty(M)
            msgbox('No wave to export. Please use "Display Wave" button to select pixels on movie screen.','Icon','help')
        else
            w=figure('Name','Signal Waves','NextPlot','add','NumberTitle','off',...
                'Visible','off','OuterPosition',[100, 50, 555,120*a+80]);
            for x = 1:a
                subplot('Position',[0.06 (120*(a-x)+70)/(120*a+80) 0.9 110/(120*a+80)])
                plot(handles.time,squeeze(handles.cmosData(M(x,2),M(x,1),:)),'color',colax(x),'LineWidth',2)
                xlim([handles.starttime handles.endtime]);
                hold on
                if x == a
                else
                    set(gca,'XTick',[])
                end
            end
            xlabel('Time (sec)')
            hold off
            movegui(w,'center')
            set(w,'Visible','on')
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONDITION SIGNALS
%% Condition Signals Selection Change Callback
    function cond_sig_selcbk(source,eventdata)
        % Read check box
        removeBG_state =get(removeBG_button,'Value');
        filt_state = get(filt_button,'Value');
        bin_state = get(bin_button,'Value');
        drift_state = get(removeDrift_button,'Value');
        norm_state = get(norm_button,'Value');
        denoise_state = get(denoise_button,'Value');
        bin_pop_state = get(bin_popup,'Value');
        filename = [handles.dir,'/',handles.filename(1:end-3),'mat'];
        cmosData = load(filename); % load raw data
        if strcmp(handles.filename(end-2:end),'rsh') == 1
            handles.cmosData = double(cmosData.cmosData(:,:,2:end));
        end
        handles.normflag = 0; % Initialize normflag
        
        
        % Condition Signals
        % Remove Background
        if removeBG_state == 1
            g1 = waitbar(1,'Removing Background');
            bg_thresh = str2num(get(bg_thresh_edit,'String'));
            perc_ex = str2num(get(perc_ex_edit,'String'));
            handles.cmosData = remove_BKGRD(handles.cmosData,handles.bg,bg_thresh,perc_ex);
            delete(g1)
        end
        % Bin Data
        if bin_state == 1
            g1 = waitbar(1,'Binning Data');       
            if bin_pop_state == 3
                bin_size = 7;
            elseif bin_pop_state == 2
                bin_size = 5;
            else
                bin_size = 3;
            end
            handles.cmosData = binning(handles.cmosData,bin_size);
            delete(g1)
        end
        % Filter Data
        if filt_state == 1
            g1 = waitbar(1,'Filtering Data');
            filt_pop_state = get(filt_popup,'Value');
            if filt_pop_state == 4
                or = 100;
                lb = 0.5;
                hb = 150;
            elseif filt_pop_state == 3
                or = 100;
                lb = 0.5;
                hb = 100;
            elseif filt_pop_state == 2
                or = 100;
                lb = 0.5;
                hb = 75;
            else
                or = 100;
                lb = 0.5;
                hb = 50;
            end
            handles.cmosData = filter_data(handles.cmosData,handles.Fs, or, lb, hb);
            delete(g1)
        end
        % Remove Drift
        if drift_state == 1
            g1 = waitbar(1,'Removing Drift');
            ord_val = get(drift_popup,'Value');
            ord_str = get(drift_popup,'String');
            handles.cmosData = remove_Drift(handles.cmosData,ord_str(ord_val));
            delete(g1)
        end
        % Normalize Data
        if norm_state == 1
            g1 = waitbar(1,'Normalizing Data');
            handles.cmosData = normalize_data(handles.cmosData,handles.Fs);
            handles.normflag = 1;
            delete(g1)
        end
        % Denoise Data
        if denoise_state == 1
            g1 = waitbar(1,'Denoising Data');
            handles.cmosData = denoise_data(handles.cmosData,handles.Fs,handles.bg);
            delete(g1)
        end

        % Update movie screen with the conditioned data
        set(f,'CurrentAxes',movie_scrn)
        cla
        handles.matrixMax = .9 * max(handles.cmosData(:));
        currentframe = handles.frame;
        if handles.normflag == 0
            drawFrame(currentframe);
            hold on
        else
            drawFrame(currentframe);
            caxis([0 1])
            hold on
        end
        set(movie_scrn,'YTick',[],'XTick',[]);% Hide tick markes
        % Update markers on movie screen
        M = handles.M;colax='bgykcm';[a ~]=size(M);
        hold on
        for x=1:a
            plot(M(x,1),M(x,2),'cs','MarkerSize',8,'MarkerFaceColor',colax(x),'MarkerEdgeColor','w','Parent',movie_scrn);
            set(movie_scrn,'YTick',[],'XTick',[]);% Hide tick markes
        end
        hold off
        % Update signal waves (yes this is ugly.  if you find a better way, please change)
        if a>=1
            plot(handles.time,squeeze(handles.cmosData(M(1,2),M(1,1),:)),'b','LineWidth',2,'Parent',signal_scrn1)
            if a>=2
                plot(handles.time,squeeze(handles.cmosData(M(2,2),M(2,1),:)),'g','LineWidth',2,'Parent',signal_scrn2)
                if a>=3
                    plot(handles.time,squeeze(handles.cmosData(M(3,2),M(3,1),:)),'y','LineWidth',2,'Parent',signal_scrn3)
                    if a>=4
                        plot(handles.time,squeeze(handles.cmosData(M(4,2),M(4,1),:)),'k','LineWidth',2,'Parent',signal_scrn4)
                        if a>=5
                            plot(handles.time,squeeze(handles.cmosData(M(5,2),M(5,1),:)),'c','LineWidth',2,'Parent',signal_scrn5)
                            if a>=6
                                plot(handles.time,squeeze(handles.cmosData(M(6,2),M(6,1),:)),'m','LineWidth',2,'Parent',signal_scrn6)
                            end
                        end
                    end
                end
            end
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ACTIVATION MAP
%% Callback for Start and End Time for Activation Map
    function amaptime_edit_callback(source,eventdata)
        a_start = str2num(get(starttimeamap_edit,'String'));
        a_end = str2num(get(endtimeamap_edit,'String'));
        set(f,'CurrentAxes',sweep_bar)
        a = [a_start a_start];b = [0 1];cla
        plot(a,b,'g','Parent',sweep_bar)
        hold on
        a = [a_end a_end];b = [0 1];
        plot(a,b,'-g','Parent',sweep_bar)
        axis([handles.starttime handles.endtime 0 1])
        hold off; axis off
        hold off
        handles.a_start = a_start;
        handles.a_end = a_end;
    end
%% Button to create activation map
    function createmap_button_callback(source,eventdata)
        gg = waitbar(1,'Building  Activation Map...');
        aMap(handles.cmosData,handles.a_start,handles.a_end,handles.Fs,handles.bg);
        close(gg)
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONDUCTION VELOCITY
%% Callback for Start and End Time for Conduction Velocity Map
    function cmaptime_edit_callback(source,eventdata)
        c_start = str2num(get(starttimecmap_edit,'String'));
        c_end = str2num(get(endtimecmap_edit,'String'));
        set(f,'CurrentAxes',sweep_bar)
        a = [c_start c_start];b = [0 1];cla
        plot(a,b,'b','Parent',sweep_bar)
        hold on
        a = [c_end c_end];b = [0 1];
        plot(a,b,'-b','Parent',sweep_bar)
        axis([handles.starttime handles.endtime 0 1])
        hold off; axis off
        hold off
        handles.c_start = c_start;
        handles.c_end = c_end;
    end
%% Button to create conduction velocity map
    function createcmap_button_callback(source,eventdata)
        rect = getrect(movie_scrn);
        gg = waitbar(1,'Building Conduction Velocity Map...');
        cMap(handles.cmosData,handles.c_start,handles.c_end,handles.Fs,handles.bg,rect);
        close(gg)
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% APD MAP
%% Callback for Start and End Time for APD Map
    function apdmaptime_edit_callback(source,eventdata)
        apd_start = str2num(get(starttimeapdmap_edit,'String'));
        apd_end = str2num(get(endtimeapdmap_edit,'String'));
        set(f,'CurrentAxes',sweep_bar)
        a = [apd_start apd_start];b = [0 1];cla
        plot(a,b,'m','Parent',sweep_bar)
        hold on
        a = [apd_end apd_end];b = [0 1];
        plot(a,b,'-m','Parent',sweep_bar)
        axis([handles.starttime handles.endtime 0 1])
        hold off; axis off
        hold off
        handles.apd_start = apd_start;
        handles.apd_end = apd_end;
    end

%% Button to create Global APD map
    function createapd_button_callback(source,eventdata)
        gg = waitbar(1,'Building APD Map...');
        handles.percentAPD = str2num(get(percentapd_edit,'String'));
        apdMap(handles.cmosData,handles.apd_start,handles.apd_end,handles.Fs,handles.percentAPD);
        close(gg)
    end
%% Button to Calculate Regional APD
    function calc_apd_button_callback(source,eventdata)
        % Read APD Parameters
        handles.percentAPD = str2num(get(percentapd_edit,'String'));
        handles.maxapd = str2num(get(maxapd_edit,'String'));
        handles.minapd = str2num(get(minapd_edit,'String'));
        % Read remove motion check box
        remove_motion_state =get(remove_motion_click,'Value');
        coordinate=getrect(movie_scrn);
        gg = waitbar(1,'Calculating Regional APD...');
        apdCalc(handles.cmosData,handles.apd_start,handles.apd_end,handles.Fs,handles.percentAPD,handles.maxapd, handles.minapd,remove_motion_state,coordinate,handles.bg);
        close(gg)
    end
%% APD Min editable textbox
    function minapd_edit_callback(source,eventdata)
        val = get(source,'String');
        handles.minapd = str2num(val);
        if handles.minapd<1 %%% need to account for numbers to large || handles.percentAPD>100
            msgbox('Please enter valid number in milliseconds')
        end
        if handles.maxapd<=handles.minapd
            msgbox('Maximum APD needs to be greater than Minimum APD','Title','Warn')
        end
    end
%% APD Max editable textbox
    function maxapd_edit_callback(source,eventdata)
        val = get(source,'String');
        handles.maxapd = str2num(val);
        if handles.maxapd<1 % Need to acount for numbers that are too large|| handles.maxapd>100
            msgbox('Please enter valid number in milliseconds')
        end
        if handles.maxapd<=handles.minapd
            msgbox('Maximum APD needs to be greater than Minimum APD','Title','Warn')
        end
    end
%% percent APD editable textbox
    function percentapd_edit_callback(source,eventdata)
        val = get(source,'String');
        handles.percentAPD = str2num(val);
        if handles.percentAPD<.1 || handles.percentAPD>1
            msgbox('Please enter number between .1 - 1','Title','Warn')
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PLUG INS
%% Button to Compute Phase Map
    function createphase_button_callback(source,eventdata)
        gg = waitbar(1,'Calculating Phase Map...');
        phaseMap(handles.cmosData,handles.dir,handles.starttime,handles.endtime,handles.Fs);
        close(gg)
    end

%% Button to Compute Dominant Frequency Map
    function calcDomFreq_button_callback(source,eventdata)
        gg = waitbar(1,'Calculating Dominant Frequency Map...');
        calDomFreq(handles.cmosData,handles.Fs);
        close(gg)
    end

%% Button to Perform Bootstrap Segmentation
    function calcSegData_button_callback(source,eventdata)
        gg = waitbar(1,'Performing Boostrap Analysis...');
        grp_nbr = str2num(get(grp_edit,'String'));
        seg_Data(handles.cmosData,handles.btstrp_start,handles.btstrp_end,handles.Fs,handles.bg,grp_nbr);
        pause(.1)
        close(gg)
    end
%% Callback for Start and End Time for Bootstrapping
    function btstrptime_edit_callback(source,eventdata)
        btstrp_start = str2num(get(starttimebtstrp_edit,'String'));
        btstrp_end = str2num(get(endtimebtstrp_edit,'String'));
        set(f,'CurrentAxes',sweep_bar)
        a = [btstrp_start btstrp_start];b = [0 1];cla
        plot(a,b,'m','Parent',sweep_bar)
        hold on
        a = [btstrp_end btstrp_end];b = [0 1];
        plot(a,b,'-m','Parent',sweep_bar)
        axis([handles.starttime handles.endtime 0 1])
        hold off; axis off
        hold off
        handles.btstrp_start = btstrp_start;
        handles.btstrp_end = btstrp_end;
    end
end

