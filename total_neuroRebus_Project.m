function total_neuroRebus_Project(subject, run, output, practice, dev, log)
    % Inputs:
    %   -subject: string subject identification (3 digits)
    %   -run: integer the current run (1-4)
    %   -output: string path to send output file
    %   -practice: logical
    %   -dev: logical whether to shrink screen size for development mode
    %   -log string path to send log file

    close all; clc; sca; rng(run);   % starting experiment

   
    % Creating the log folder if it doesn't exist
    if ~isfolder(log)
    mkdir(log);
    end

    if ~isfolder(output)
    mkdir(output);
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
    WORD_TIME = 0.450; % seconds per word, matching the language localizer
    RESPONSE_TIME = 1.500; % seconds allotted for the plausibility response
    if ~dev
        WORD_SIZE = 75;
    elseif dev
        WORD_SIZE = 30;
    end
    FIXATION_SIZE = 100;
    FIXATION_CHAR = '+';
    TEXT_COLOR = [255 255 255]; % white

    % Output file (saving everything in a table)
    date_str = char(datetime("today", "Format", "yyyy-MM-dd"));
    filename = sprintf( ...
        'wiscs_subject-%s_run-%d_date-%s.csv', ...
        char(subject), run, date_str ...
    );

    % Making the Headers for the CSV Columns
    filepath = fullfile(output, filename);
    if ~isfile(filepath)

        headers = cell2table(cell(0,9), ...
            'VariableNames', ...
            {'subjectID','run','trial','stimulus','condition',...
         'buttonResponse','reactionTime','plausibility','trialOnset'});

        writetable(headers, filepath);

    end

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

    stimuli = readtable([stimpath filesep 'FiveTestSentences.txt']);
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

        if dev
            Screen('Preference', 'SkipSyncTests', 1);
        else
            Screen('Preference', 'SkipSyncTests', 0);
        end

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
    else
        run_start_time = GetSecs;
    end


    for idx = 1:ntrials

        condition = string(order.type(idx));
        value_idx = order.value(idx);

        % Get sentence information from table
        sentence = stimuli.Sentence{value_idx};
        picIndex = stimuli.RebusIndex(value_idx);

        % Split sentence into words
        words = split(sentence);

        % Determine which word is the rebus word
        picWord = regexprep(words(picIndex), '[^\w]', '');

        % Load image
        imageFile = fullfile(stimpath, 'images', ...
        [lower(char(picWord)) '.jpg']);

        disp(imageFile)

        img = imread(imageFile);
        tex = Screen('MakeTexture', window, img);
        [h, w, ~] = size(img);

        sentence_onset_abs = NaN;

    % Present Sentence
    wordDuration = WORD_TIME;
    for wordNum = 1:length(words)

        Screen('FillRect', window, grey);

        if wordNum == picIndex
            if dev
                scale = 0.4;   % adjust until it looks right
            else
                scale = 1.0;
            end

            destRect = CenterRectOnPointd( ...
            [0 0 w*scale h*scale], ...
            windowRect(3)/2, ...
            windowRect(4)/2);

            Screen('DrawTexture', window, tex, [], destRect);    
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
        response_onset_abs + RESPONSE_TIME, ...
        response_onset_abs, ...
        escapeKey ...
    );
    plausibility = ""; % don't know if we're doing a task yet, so I kept this blank
    trialRow = table( ...
            string(subject), ...
            run, ...
            idx, ...
            string(picWord), ...
            condition, ...
            string(keypress), ...
            rt, ...
            plausibility, ...
            sentence_onset, ...
            'VariableNames',{ ...
                'subjectID',...
                'run',...
                'trial',...
                'stimulus',...
                'condition',...
                'buttonResponse',...
                'reactionTime',...
                'plausibility',...
                'trialOnset'});
    % Save Sentence
    writetable(trialRow, filepath, 'WriteMode', 'Append');

   
    % Fixation
    Screen('TextSize', window, FIXATION_SIZE);

    DrawFormattedText(window, ...
        FIXATION_CHAR, ...
        'center', ...
        'center', ...
        TEXT_COLOR);

    fix_onset_abs = Screen('Flip', window);
    WaitSecs(j(idx));
    end

    Screen('CloseAll');
    ShowCursor;

    diary off;
end
