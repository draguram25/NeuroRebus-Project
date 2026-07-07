stimuli = readtable('stimuli/FiveTestSentences.txt');

nTrials = height(stimuli);

for trial = 1:nTrials

    sentence = stimuli.Sentence{trial};
    rebusIdx = stimuli.RebusIndex(trial);

    words = split(sentence);

    fprintf('\nSentence %d:\n', trial)

    for wordIdx = 1:length(words)

        if wordIdx == rebusIdx  % display picture

        else % display word

        end

    Screen('Flip', window);
    WaitSecs(wordDuration);

end

end