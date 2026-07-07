function [keypress, rt] = collect_response_until(end_time, stim_onset_abs, escapeKey)

keypress = ""; % default
rt = NaN; % default 
already_responded = false; % keeps only first response

while GetSecs < end_time

    [keyIsDown, secs, keyCode] = KbCheck; % checks if any key is down

    % throw error if escape key is pressed
    if keyCode(KbName(escapeKey))
        error('escape!');
    end

    % if key is down and no response has been recorded yet
    if keyIsDown && ~already_responded
        key_name = KbName(find(keyCode, 1));

        if iscell(key_name)
            key_name = key_name{1};
        end

        keypress = string(key_name);
        rt = secs - stim_onset_abs; % calculate rt
        already_responded = true;
    end

end

end