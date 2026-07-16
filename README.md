Neurorebus Project

Overview: This project is a MATLAB/Psychtoolbox experiment that uses rebus stimuli to investigate sentence comprehension. Participants read sentences presented one word at a time, with some words replaced by images. The experiment records participant responses for later analysis.

Parameters/Inputs: 
  -subject: string subject identification (3 digits)
      -Example: 001
  -run: integer of the current run (1-4)
      -Example: 1
  -output: directory where output files are saved
      -Example: "x"
  -practice: logical
      - True = in practice mode so practice trials included
      -False = experiment trials only
  -dev: logical whether to shrink screen size for development mode
      -True = in debug mode where the experiment runs on a smaller window and skips synchronization tests
      -False = full-screen experiment with synchronization tests
  -log string path to send log file
      -Example: "."

  Requirements before Running Experiment:
    - Matlab
    -Psychtoolbox
    -Project repository with all required files and folders
      -stimulus folder should include sentences and images

  Begin Experiment
    -In Matlab, run total_neuroRebus_Project(subject, run, output, practice, dev, log)
    -Examples of Inputs into the Code
        - 
        -
