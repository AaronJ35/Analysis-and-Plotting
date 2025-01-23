function maketable()
    % maketable - Processes folders and uses CSV2Table to compute totals.
    %
    % This function iterates over specific folders and their subdirectories,
    % calling CSV2Table to aggregate data and compute total values.
    %
    % Syntax: maketable()
    %
    % Inputs:
    %   None (starts from current working directory)
    
    % Define the specific folder names to process
    %folderList = {'UC_LB', 'UC_LB_HV', 'UC_LC', 'UC_LD', 'UC_LE', 'UC_LE_HV'};
    folderList = {'UC_LB', 'UC_LC'};
    % Define folder patterns to search for
    folderPatterns = {'.9'};
    
    % Define the subfolder path structure
    innerPath = fullfile('BZ2_Q4', 'output');
    
    % File name template
    baseFileName = 'BZ2_lowQ_with_PV_buses_67_241_179_479_pf_0.%-dispatch';
    
    % Initialize the master table
    masterTable = table();
    
    % Loop through each specified folder
    for i = 1:length(folderList)
        mainFolder = folderList{i};
        
        % Check if the folder exists
        if ~isfolder(mainFolder)
            fprintf('Skipping non-existent folder: %s\n', mainFolder);
            continue;
        end
        
        % Loop through the folder patterns
        for k = 1:length(folderPatterns)
            specificSubfolder = fullfile(mainFolder, innerPath, folderPatterns{k});
            
            % Check if the subfolder exists
            if ~isfolder(specificSubfolder)
                fprintf('Subfolder does not exist: %s\n', specificSubfolder);
                continue;
            end
            
            % Construct the base file path
            baseFilePath = strrep(baseFileName, '%', folderPatterns{k}(2));
            baseFilePath = fullfile(specificSubfolder, baseFilePath);
            
            % Output folder for aggregated results
            outputFolder = fullfile(specificSubfolder, 'AggregatedResults');
            
            % Number of files to process
            numFiles = 71; % Adjust as needed
            
            % Call CSV2Table
            try
                fprintf('Processing folder: %s\n', specificSubfolder);
                CSV2Table(baseFilePath, numFiles, outputFolder);
                
                % Read the aggregated results back into the master table
                aggregatedFile = fullfile(outputFolder, 'aggregatedResults.csv');
                if isfile(aggregatedFile)
                    aggregatedData = readtable(aggregatedFile);
                    
                    % Add an identifier column for this folder and pattern
                    identifier = sprintf('%s_%s', mainFolder, folderPatterns{k});
                    aggregatedData.Identifier = repmat({identifier}, height(aggregatedData), 1);
                    
                    % Append to the master table
                    masterTable = [masterTable; aggregatedData];
                else
                    fprintf('Aggregated results not found for folder: %s\n', specificSubfolder);
                end
            catch ME
                fprintf('Error processing folder: %s\nError: %s\n', specificSubfolder, ME.message);
            end
        end
    end
    
    % Save the master table to a CSV file in the current directory
    outputFileName = 'Results.csv';
    writetable(masterTable, outputFileName);
    
    % Inform the user of completion
    fprintf('Data aggregation completed. Results saved to: %s\n', outputFileName);
end
