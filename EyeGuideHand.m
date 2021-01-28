function varargout = EyeGuideHand(varargin)
% EYEGUIDEHAND MATLAB code for EyeGuideHand.fig
%      EYEGUIDEHAND, by itself, creates a new EYEGUIDEHAND or raises the existing
%      singleton*.
%
%      H = EYEGUIDEHAND returns the handle to a new EYEGUIDEHAND or the handle to
%      the existing singleton*.
%
%      EYEGUIDEHAND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EYEGUIDEHAND.M with the given input arguments.
%
%      EYEGUIDEHAND('Property','Value',...) creates a new EYEGUIDEHAND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EyeGuideHand_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EyeGuideHand_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EyeGuideHand

% Last Modified by GUIDE v2.5 28-Jan-2021 14:01:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @EyeGuideHand_OpeningFcn, ...
    'gui_OutputFcn',  @EyeGuideHand_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before EyeGuideHand is made visible.
function EyeGuideHand_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EyeGuideHand (see VARARGIN)

imaqhwinfo
obj = videoinput('winvideo');
set(obj, 'FramesPerTrigger', 1);
set(obj, 'TriggerRepeat', Inf);

objRes = get(obj, 'VideoResolution');
nBands = get(obj, 'NumberOfBands');
hImage = image(zeros(objRes(2), objRes(1), nBands));
preview(obj, hImage);
axis off

annotation('textbox',[.0 .0 .2 .2],'EdgeColor','r','String','FuncLB','color','yellow','FontSize',20,'HorizontalAlignment','right','VerticalAlignment','top');

annotation('textbox',[.0 .4 .2 .2],'EdgeColor','r','String','FuncLeft','color','yellow','FontSize',20,'HorizontalAlignment','right','VerticalAlignment','middle');

annotation('textbox',[.0 .8 .2 .2],'EdgeColor','r','String','FuncLT','color','yellow','FontSize',20,'HorizontalAlignment','right','VerticalAlignment','bottom');

annotation('textbox',[.4 .8 .2 .2],'EdgeColor','r','String','FuncTop','color','yellow','FontSize',20,'HorizontalAlignment','center','VerticalAlignment','bottom');

annotation('textbox',[.4 .0 .2 .2],'EdgeColor','r','String','FuncBottom','color','yellow','FontSize',20,'HorizontalAlignment','center','VerticalAlignment','top');

annotation('textbox',[.8 .8 .2 .2],'EdgeColor','r','String','FuncRT','color','yellow','FontSize',20,'HorizontalAlignment','left','VerticalAlignment','bottom');

annotation('textbox',[.8 .4 .2 .2],'EdgeColor','r','String','FuncRight','color','yellow','FontSize',20,'HorizontalAlignment','left','VerticalAlignment','middle');

annotation('textbox',[.8 .0 .2 .2],'EdgeColor','r','String','FuncRB','color','yellow','FontSize',20,'HorizontalAlignment','left','VerticalAlignment','top');

% Choose default command line output for EyeGuideHand
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EyeGuideHand wait for user response (see UIRESUME)
% uiwait(handles.figure1);

end
% --- Outputs from this function are returned to the command line.
function varargout = EyeGuideHand_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% maximize the window
set(hObject,'resize','on');
javaFrame = get(gcf,'JavaFrame');
set(javaFrame,'Maximized',1);
pause(0.5);
set(hObject,'resize','off');
% Get default command line output from handles structure
varargout{1} = handles.output;
end

function calibrateBtn_Callback(hObject, eventdata, handles)
set(handles.logBox,'Value',0);

AssertOpenGL;
InitializeMatlabOpenGL;

screenIndex = (Screen('Screens'));
if length(screenIndex) > 1
    screenId = max(screenIndex)-1;
else
    screenId = max(screenIndex);
end
% Define background color:
blackBackground = BlackIndex(screenId);

%% initial Eyelink
[win , ~] = PsychImaging('OpenWindow', screenId,blackBackground);
[widthPix,heightPix] = Screen('WindowSize',screenId);
tempName = 'TEMP1'; % need temp name because Eyelink only know
% hows to save names with 8 chars or less.
% Will change name using matlab's moveFile later.
dummymode=0;

try
    el=EyelinkInitDefaults(win);
    el.backgroundcolour = BlackIndex(el.window);
    el.foregroundcolour = GrayIndex(el.window);
    el.msgfontcolour    = WhiteIndex(el.window);
    el.imgtitlecolour   = WhiteIndex(el.window);
    el.calibrationtargetcolour = GrayIndex(el.window);
catch
    Screen('CloseAll');
    set(handles.logBox,'String','Calibration Failed','ForegroundColor','r','Value',0);
    return
end

if ~EyelinkInit(dummymode)
    fprintf('Eyelink Init aborted.\n');
    cleanup;  % cleanup function
    Eyelink('ShutDown');
    Screen('CloseAll');
    return
end

triali = Eyelink('Openfile', tempName);
if triali~=0
    fprintf('Cannot create EDF file ''%s'' ', tempName);
    cleanup;
    Eyelink('ShutDown');
    Screen('CloseAll');
    return
end

%   SET UP TRACKER CONFIGURATION
Eyelink('command', 'calibration_type = HV9');

%	set parser (conservative saccade thresholds)
Eyelink('command', 'saccade_velocity_threshold = %d', 35);
Eyelink('command', 'saccade_acceleration_threshold = %d', 9500);
Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA');
Eyelink('command', 'online_dcorr_refposn = %1d, %1d', widthPix/2, heightPix/2);
Eyelink('command', 'online_dcorr_maxangle = %1d', 30.0);

% you must call this function to apply the changes from above
EyelinkUpdateDefaults(el);

% Calibrate the eye tracker
EyelinkDoTrackerSetup(el);

% do a final check of calibration using driftcorrection
EyelinkDoDriftCorrection(el);

Eyelink('StartRecording');

Eyelink('message', 'SYNCTIME');	 	 % zero-plot time for EDFVIEW

errorCheck=Eyelink('checkrecording'); 		% Check recording status */
if(errorCheck~=0)
    fprintf('Eyelink checked wrong status.\n');
    cleanup;  % cleanup function
    Eyelink('ShutDown');
    Screen('CloseAll');
    return
end

% wait a little bit, in case the key press during calibration influence the following keyboard check
while 1
    [ keyDown, ~, ~] = KbCheck;
    if ~keyDown
        break
    end
end
Screen('CloseAll');
set(handles.logBox,'String','Calibration Succeed','ForegroundColor','g','Value',1);
end


function startBtn_Callback(hObject, eventdata, handles)
% fot testing without eyelink
% set(handles.logBox,'Value',1);
global robot
set(handles.calibrateBtn,'value',1-handles.calibrateBtn.Value);
if ~handles.calibrateBtn.Value
    set(handles.startBtn,'String','Start');
    return;
else
    set(handles.startBtn,'String','Stop');
end
if ~exist('robotOpen','var')
    robot=serial("COM6","Baudrate",115200);
    robotOpen = true;
    fopen(robot);
end
idle = tic;
if handles.logBox.Value == 0
    set(handles.logBox,'String','You need to calibrate first','ForegroundColor','r');
elseif handles.logBox.Value == 1
        screenPix = get(0,'ScreenSize');
        widthPix = screenPix(3);
        heightPix = screenPix(4);
    
    while true
        if ~handles.calibrateBtn.Value
            fclose(robot);
            return;
        end
        checkLog = get(handles.logBox,'Value');
        if checkLog == 0
            return % terminate the while loop when calibration
        end
        evt = Eyelink( 'NewestFloatSample');
        eyeUsed = Eyelink('EyeAvailable'); % get eye that's tracked
        if eyeUsed ~= -1
            px =evt.gx(eyeUsed+1); % +1 as we're accessing MATLAB array
            py = evt.gy(eyeUsed+1);
        end
        
%         % fot testing without eyelink
%                 pt = get(0,'PointerLocation');
%                 px = pt(1);py = heightPix-pt(2);
        
        eyePointer = annotation('ellipse','Units','pixels','Position',[px, heightPix-py, 5, 5],'color','yellow','LineWidth',4);
        pause(0.05);
        delete(eyePointer);
        
        if toc(idle) > 2
            inLT     = inpolygon(px,py,[.0 .0 .2 .2]*widthPix,[.0 .2 .2 .0]*heightPix);
            inLB     = inpolygon(px,py,[.0 .0 .2 .2]*widthPix,[.8 1. 1. .8]*heightPix);
            inRT     = inpolygon(px,py,[.8 .8 1. 1.]*widthPix,[.0 .2 .2 .0]*heightPix);
            inRB     = inpolygon(px,py,[.8 .8 1. 1.]*widthPix,[.8 1. 1. .8]*heightPix);
            inRight  = inpolygon(px,py,[.8 .8 1. 1.]*widthPix,[.4 .6 .6 .4]*heightPix);
            inLeft   = inpolygon(px,py,[.0 .0 .2 .2]*widthPix,[.4 .6 .6 .4]*heightPix);
            inBottom = inpolygon(px,py,[.4 .4 .6 .6]*widthPix,[.8 1. 1. .8]*heightPix);
            inTop    = inpolygon(px,py,[.4 .4 .6 .6]*widthPix,[.0 .2 .2 .0]*heightPix);
            
            if inLT
                if exist('LTtime','var')
                    if toc(LTtime) > 0.2
                        runFunction = 1;
                    end
                else
                    LTtime = tic;
                    clear LBtime RTtime RBtime Righttime LeftTime Toptime Bottomtime;
                end
            elseif inLB
                if exist('LBtime','var')
                    if toc(LBtime) > 0.2
                        runFunction = 7;
                    end
                else
                    LBtime = tic;
                    clear LTtime RTtime RBtime Righttime LeftTime Toptime Bottomtime;
                end
            elseif inRT
                if exist('RTtime','var')
                    if toc(RTtime) > 0.2
                        runFunction = 3;
                    end
                else
                    RTtime = tic;
                    clear LTtime LBtime RBtime Righttime LeftTime Toptime Bottomtime;
                end
            elseif inRB
                if exist('RBtime','var')
                    if toc(RBtime) > 0.2
                        runFunction = 9;
                    end
                else
                    RBtime = tic;
                    clear LTtime LBtime RTtime Righttime LeftTime Toptime Bottomtime;
                end
            elseif inRight
                if exist('Righttime','var')
                    if toc(Righttime) > 0.2
                        runFunction = 6;
                    end
                else
                    Righttime = tic;
                    clear LTtime LBtime RTtime RBtime LeftTime Toptime Bottomtime;
                end
            elseif inLeft
                if exist('Lefttime','var')
                    if toc(Lefttime) > 0.2
                        runFunction = 4;
                    end
                else
                    Lefttime = tic;
                    clear LTtime LBtime RTtime RBtime Righttime Toptime Bottomtime;
                end
            elseif inTop
                if exist('Toptime','var')
                    if toc(Toptime) > 0.2
                        runFunction = 2;
                    end
                else
                    Toptime = tic;
                    clear LTtime LBtime RTtime RBtime Righttime LeftTime Bottomtime;
                end
            elseif inBottom
                if exist('Bottomtime','var')
                    if toc(Bottomtime) > 0.2
                        runFunction = 8;
                    end
                else
                    Bottomtime = tic;
                    clear LTtime LBtime RTtime RBtime Righttime LeftTime Toptime;
                end
            else
                set(handles.logBox,'String','Idle','ForegroundColor','k');
                clear LTtime LBtime RTtime RBtime Righttime LeftTime Toptime Bottomtime;
            end
        end
        
        if exist('runFunction','var')
            switch runFunction
                case 1
                    % function Left - top
                    set(handles.logBox,'String','sight move to the Left-Top','ForegroundColor','k');
                    fprintf(robot,"%c",1);
                case 2
                    % function Top
                    set(handles.logBox,'String','sight move to the Top','ForegroundColor','k');
                    fprintf(robot,"%c",2)
                case 3
                    % function Right - top
                    set(handles.logBox,'String','sight move to the Right-Top','ForegroundColor','k');
                    fprintf(robot,"%c",3)
                case 4
                    % function Left
                    set(handles.logBox,'String','sight move to the Left','ForegroundColor','k');
                    fprintf(robot,"%c",4)
                case 5
                    % function Left
                    
                case 6
                    % function Right
                    set(handles.logBox,'String','sight move to the Right','ForegroundColor','k');
                    fprintf(robot,"%c",6)
                case 7
                    % function Left-bottom
                    set(handles.logBox,'String','sight move to the Left-Bottom','ForegroundColor','k');
                    fprintf(robot,"%c",7)
                case 8
                    % function Bottom
                    set(handles.logBox,'String','sight move to the Bottom','ForegroundColor','k');
                    fprintf(robot,"%c",8)
                case 9
                    % function Right-bottom
                    set(handles.logBox,'String','sight move to the Right-Bottom','ForegroundColor','k');
                    fprintf(robot,"%c",9)
            end
            idle = tic;
            clear runFunction
        end
    end
end
end


function pushbutton3_Callback(hObject, eventdata, handles)
global robot
if handles.logBox.Value == 1
    try
        Eyelink('StopRecording');
        Eyelink('CloseFile');
        Eyelink('ShutDown');
        set(handles.logBox,'String','Eyelink was closed.','ForegroundColor','k');
        if exist('robotOpen','var')
            fclose(robot);
        end
        pause(1);
    catch
        set(handles.logBox,'String','Try to close Eyelink but failed.','ForegroundColor','r');
        pause(1);
    end
end
msgbox('See you next time!');
pause(1);
close all;
end
