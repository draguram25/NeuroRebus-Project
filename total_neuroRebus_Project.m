function total_neuroRebus_Project(subject, run, output, practice, dev, log)
    % Inputs:
    %   -subject: string subject identification (3 digits)
    %   -run: integer the current run (1-4)
    %   -output: string path to send output file
    %   -practice: logical
    %   -dev: logical whether to shrink screen size for development mode
    %   -log string path to send log file

    close all; clc; sca; rng(run);   % starting experiment
	% adding a comment here for GitHub demo
   
    % Creating the log folder if it doesn't exist
    if ~isfolder(log)
    mkdir(log);
    end

    % get today's date
    date = datetime('now');
    date.Format = 'MM-dd-yyyy';

    % build log filename
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

    %% Output file (saving everything in a table)
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

    % Restrict Keys In Experiment
    KbName('UnifyKeyNames');
    yesKey = KbName('1!');
    noKey = KbName('2@');
    enterKey = KbName('return');
    escapeKey = KbName('escape');
    RestrictKeysForKbCheck([]);
    enableKeys = [yesKey, noKey, enterKey, escapeKey];
    RestrictKeysForKbCheck(enableKeys);

    % Stimuli setup
    if practice
        stimpath = [pwd filesep 'practice_' + 'stimuli'];
    else
        stimpath = [pwd filesep 'stimuli'];
    end

    sentenceTable = readtable([stimpath filesep 'FiveTestSentences.txt']);
    order = readtable("order_q3_i5_s2026.txt"); % Make a few orders to counterbalance across subjects
    ntrials = 5; % make a set of orders for each run
    j = 1 + (4-1).*rand(ntrials,1); % update jitter 

    
    % Setup screen in Psychtoolbox for the participant
        PsychDefaultSetup(2);

        screens = Screen('Screens');
        screenNumber = max(screens);

        white = WhiteIndex(screenNumber);
        black = BlackIndex(screenNumber);
        grey = white / 2;

        % if dev
            Screen('Preference', 'SkipSyncTests', 1);
        % else
        %     Screen('Preference', 'SkipSyncTests', 0);
        % end

        if dev
            screenRect = [120 50 520 300];
        else
            screenRect = [];
        end

    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, screenRect);
        

    %starting experiment
    DrawFormattedText(window, 'Waiting for scanner...', ...
        'center', 'center', TEXT_COLOR);
        Screen('Flip', window);

    if ~dev
        run_start_time = wait_for_trigger_kbqueue_all_dvc;

    event_idx = 0;

    for idx = 1:ntrials
        type = string(order.type(idx)); % either question/item
        value_idx = order.value(idx);

        sentence = sentenceTable.Sentence{value_idx};
        picIndex = sentenceTable.RebusIndex(value_idx);
        imageFile = sentenceTable.ImageFile{value_idx};

        words = split(sentence);
        
        imagePath = fullfile(stimpath, "images", imageFile);
        img = imread(imagePath);
        tex = Screen('MakeTexture', window, img);

    sentence_onset_abs = NaN;

    % Present Sentence
    for wordNum = 1:length(words)

        Screen('FillRect', window, grey);

        if wordNum == picIndex
            Screen('DrawTexture', window, tex);
        else
            Screen('TextSize', window, WORD_SIZE);
            DrawFormattedText(window, ...
                char(words(wordNum)), ...
                'center', ...
                'center', ...
                TEXT_COLOR);
        end

        flipTime = Screen('Flip', window);

        if wordNum == 1
            sentence_onset_abs = flipTime;
        end

        WaitSecs(wordDuration);

    end

    Screen('Close', tex);

    sentence_onset = sentence_onset_abs - run_start_time;

    % Response Screen
    DrawFormattedText(window, ...
        'Plausible?   1 = Yes     2 = No', ...
        'center', ...
        'center', ...
        TEXT_COLOR);

    response_onset_abs = Screen('Flip', window);

    [keypress, rt] = collect_response_until( ...
        response_onset_abs + STIM_DUR, ...
        response_onset_abs, ...
        escapeKey ...
    );
    
    % Save Sentence
    event_idx = event_idx + 1;

    results(event_idx,:) = { ...
        idx, ...
        sentence_onset, ...
        STIM_DUR, ...
        "sentence", ...
        sentence, ...
        keypress, ...
        rt ...
    };

    % Fixation
    Screen('TextSize', window, FIXATION_SIZE);

    DrawFormattedText(window, ...
        FIXATION_CHAR, ...
        'center', ...
        'center', ...
        TEXT_COLOR);

    fix_onset_abs = Screen('Flip', window);
    fix_onset = fix_onset_abs - run_start_time;
    WaitSecs(j(idx));
    event_idx = event_idx + 1;

    results(event_idx,:) = { ...
        idx, ...
        fix_onset, ...
        j(idx), ...
        "fixation", ...
        missing, ...
        "", ...
        NaN ...
    };
        end


    end
end


