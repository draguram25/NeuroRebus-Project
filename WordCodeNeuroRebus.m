function wiscs(subject, run, output, practice, dev, log)
% WISCS Execute wiscs-neuro fMRI paradigm
%
% WISCS('001', 1, '.', 0, 0, '.')
%
% Inputs:
%   -subject: string subject identification
%   -run: integer the current run
%   -output: string path to send output file
%   -practice: logical
%   -dev: logical whether to shrink screen size for development mode
%   -log string path to send log file
% 
% Updated: (06/05/2026)
% Notes: fully functional experiment (except for practice mode)
%
% Updated: (06/03/2026)
% Notes: added diary; implemented devMode
%
% Updated: (01/14/2026)
% Notes: Uses optseq2 outputs, handles keyboard and trigger stuff.
% Ported some code from Saanvi's `SemPlausF_PTB.m`
%
% Created: (04/08/2025) (MM/DD/YYYY)
%
% Author: Will Decker (will.decker@gatech.edu)

%% Input Checks

arguments 
    subject (1, 1) string {mustBeThreeDigitTextInteger}
    run (1, 1) double {mustBeInteger,  mustBeInRange(run,1,4)} 
    output (1, 1) string {mustBeTextScalar} = '.'
    practice (1, 1) logical = false
    dev (1, 1) logical = false
    log (1, 1) string {mustBeTextScalar} = '.'
end

if ~isfolder(output)
    mkdir(output)
end

%% Clean up command window and screens and set seed
close all; clc; sca; rng(run);

%% Start log

if ~isfolder(log)
    mkdir(log);
end

% get today's date
date = datetime('now');
date.Format = 'MM-dd-yyyy';

% initialize log filepath
logfile = fullfile(char(log), sprintf('LOG_%s.log', date));
assert(isfolder(fileparts(logfile)), "Log directory does not exist: %s", fileparts(logfile));

% start log
diary(char(logfile));

%% Constants
STIM_DUR = 2; % how long (in seconds) will any stimulus display on the screen
if ~dev
    WORD_SIZE = 75;
elseif dev
    WORD_SIZE = 50;
end
FIXATION_SIZE = 100;
FIXATION_CHAR = '+';
TEXT_COLOR = [255 255 255]; % white

%% Output file heuristics
date_str = char(datetime("today", "Format", "yyyy-MM-dd"));
filename = sprintf( ...
    'wiscs_subject-%s_run-%d_date-%s.csv', ...
    char(subject), run, date_str ...
);
headers = {'trial', 'onset', 'duration', 'type', 'value', 'keypress', 'rt'};
results = table( ...
    zeros(0,1), zeros(0,1), zeros(0,1), ...
    strings(0,1), strings(0,1), strings(0,1), zeros(0,1), ...
    'VariableNames', headers ...
);

%% Key setup

% Restrict Keys In Experiment
KbName('UnifyKeyNames');
yesKey = KbName('1!');
noKey = KbName('2@');
enterKey = KbName('return');
escapeKey = KbName('escape');
RestrictKeysForKbCheck([]);
enableKeys = [yesKey, noKey, enterKey, escapeKey];
RestrictKeysForKbCheck(enableKeys);

%% Stimuli setup
if practice
    stimpath = [pwd filesep 'practice_' + 'stimuli'];
else
    stimpath = [pwd filesep 'stimuli'];
end

questions = readlines([stimpath filesep 'questions.txt']);
items = readlines([stimpath filesep 'items.txt']);

% TO DO:
% Make a few orders to counterbalance across subjects
% And make a set of orders for each run
order = readtable("order_q3_i5_s2026.txt");

ntrials = numel(questions) * numel(items) * 2;

% TO DO:
% update jitter 
j = jitter(1, 4, ntrials);

%% Screen setup
PsychDefaultSetup(2);

% Set default screen
screens = Screen('Screens');
if length(screens) > 1
    warning("More than one screen" + newline + "Choosing screen 0")
end
screenNumber = 0;

% Colors
white = WhiteIndex(screenNumber);
grey = white / 2;
    
if dev % can skip these tests during development

    warning('Running in development mode')
    Screen('Preference', 'SkipSyncTests', 1);

    % Start cordinate in pixels of our window. Note that setting both of these
    % to zero will make the window appear in the top right of the screen.
    startXpix = 120;
    startYpix = 50;
    
    % Dimensions in pixels of our window in the X (left-right) and Y (up down)
    % dimensions
    dimX = 400;
    dimY = 250;
    
    % Open an on screen window using PsychImaging and color it grey.
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey,...
        [startXpix startYpix startXpix + dimX startYpix + dimY]);

else

    if ismac
        Screen('Preference', 'SkipSyncTests', 1);
    else
        Screen('Preference', 'SkipSyncTests', 0);
    end

    [window, windowRect] = PsychImaging('OpenWindow', 0, grey);

end

%% Begin experiment

DrawFormattedText(window, 'Waiting for scanner...', 'center', 'center', TEXT_COLOR);
Screen('Flip', window);

if ~dev
    run_start_time = wait_for_trigger_kbqueue_all_dvc;
end

event_idx = 0;

for idx = 1:ntrials

    type = string(order.type(idx));   % question or item
    value_idx = order.value(idx);

    if type == "question"
        stim = questions(value_idx);
    elseif type == "item"
        stim = items(value_idx);
    end

    % stimulus
    Screen('TextSize', window, WORD_SIZE);
    DrawFormattedText(window, char(stim), 'center', 'center', TEXT_COLOR);
    stim_onset_abs = Screen('Flip', window);
    stim_onset = stim_onset_abs - run_start_time;

    % get key and rt info
    [keypress, rt] = collect_response_until( ...
        stim_onset_abs + STIM_DUR, ...
        stim_onset_abs, ...
        escapeKey ...
    );

     % update results
    event_idx = event_idx + 1;
    results(event_idx, :) = { ...
        idx, ...
        stim_onset, ...
        STIM_DUR, ...
        type, ...
        string(stim), ...
        keypress, ...
        rt ...
    };

    % fixation
    Screen('TextSize', window, FIXATION_SIZE);
    DrawFormattedText(window, FIXATION_CHAR, 'center', 'center', TEXT_COLOR);
    fix_onset_abs = Screen('Flip', window);
    fix_onset = fix_onset_abs - run_start_time;

    WaitSecs(j(idx));
    
    % update results
    event_idx = event_idx + 1;
    results(event_idx, :) = { ...
        idx, ...
        fix_onset, ...
        j(idx), ...
        "fixation", ...
        missing, ...
        "", ...
        NaN ...
    };

end

% closing screen
Screen('TextSize', window, WORD_SIZE);
DrawFormattedText(window, ...
    'The experiment has ended. Thank you!', ...
    'center', 'center', TEXT_COLOR);
Screen('Flip', window);
WaitSecs(5);

% end log
diary off

% save results
outfile = fullfile(char(output), filename);
writetable(results, outfile);

if dev
    ptbexit()
else
    ptbexitsafe({filename})
end

end