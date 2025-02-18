function RunPlot()
    % processSpecificFoldersInCurrentDirectory - Loops through specific folders in the
    %                                             current directory, checks for specific
    %                                             dispatch1.csv file patterns,
    %                                             and calls CSV2Plots_v3 with dispatch.csv.
    %
    % Syntax: processSpecificFoldersInCurrentDirectory()
    %
    % Inputs:
    %   None (starts from current working directory)
    
    % Define the specific folder names to process
    folderList = {'UC_LB', 'UC_LB_HV', 'UC_LC', 'UC_LD', 'UC_LE', 'UC_LE_HV'};
    
    % Define folder patterns to search for
    %folderPatterns = {'.7'};
    % folderPatterns = {'.8'};
     folderPatterns = {'.9'};
    % Define the subfolder path structure
    innerPath = fullfile('Q4', 'output');
    
    % Define the specific file name pattern
    baseFileName = 'dispatch1.csv';
    plotFileName = ['dispatch' ...
        ''];
    
    % Loop through each specified folder
    for i = 1:length(folderList)
        mainFolder = folderList{i};
        
        % Check if the folder exists
        if ~isfolder(mainFolder)
            fprintf('Skipping non-existent folder: %s\n', mainFolder);
            continue;
        end
        
        % Loop through .7, .8, .9 folder patterns
        for k = 1:length(folderPatterns)
            specificSubfolder = fullfile(mainFolder, innerPath, folderPatterns{k});
            
            % Check if the subfolder exists
            if ~isfolder(specificSubfolder)
                fprintf('Subfolder does not exist: %s\n', specificSubfolder);
                continue;
            end
            
            % Construct the full path for the dispatch1.csv file
            fileToCheck = strrep(baseFileName, '%', folderPatterns{k}(2));
            fileToCheckPath = fullfile(specificSubfolder, fileToCheck);
            
            % Construct the full path for the dispatch.csv file to be passed to the plotter
            fileToPlot = strrep(plotFileName, '%', folderPatterns{k}(2));
            fileToPlotPath = fullfile(specificSubfolder, fileToPlot);
            
            % Display the folder and file being checked
            fprintf('Checking folder: %s\n', specificSubfolder);
            fprintf('Checking for file: %s\n', fileToCheckPath);
            
            % Check if the specific dispatch1.csv exists
            if isfile(fileToCheckPath)
                % Call the plotting function with the dispatch.csv file
                fprintf('Processing file: %s\n', fileToPlotPath);
                CSV2Plots_v3(fileToPlotPath, 71, mainFolder);
            else
                fprintf('File not found: %s\n', fileToCheckPath);
            end
        end
    end
end
