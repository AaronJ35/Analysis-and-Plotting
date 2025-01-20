function CSV2Table(baseFilePath, numFiles, folderName)
    % Initialize aggregated arrays
    allPg = [];
    allQg = [];
    allLoss = [];
    allVa2 = [];
    allFload = [];
    allVa3 = [];
    allP = [];

    % Create the main folder if it doesn't exist
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end

    % Loop through all files
    for i = 1:numFiles
        % Construct the filename
        currentFile = sprintf('%s%d.csv', baseFilePath, i);

        % Call the provided function to get individual values
        [pg, qg, loss, va2, fload, va3, ~, OS_P, ~] = plotBusAndGeneratorData(currentFile, i);

        % Append the results to aggregated arrays
        allPg = [allPg; pg];
        allQg = [allQg; qg];
        allLoss = [allLoss; loss];
        allVa2 = [allVa2; va2];
        allFload = [allFload; fload];
        allVa3 = [allVa3; va3];
        allP = [allP; OS_P];
    end

    % Aggregate the data (example: sum)
    totalPg = sum(allPg);
    totalQg = sum(allQg);
    totalLoss = sum(allLoss);
    totalVa2 = sum(allVa2);
    totalFload = sum(allFload);
    totalVa3 = sum(allVa3);
    totalP = sum(allP);

    % Create a table for the aggregated data
    aggregatedTable = table(totalPg, totalQg, totalLoss, totalVa2, totalFload, totalVa3, totalP, ...
        'VariableNames', {'Total_PG', 'Total_QG', 'Total_Loss', 'Total_VA2', 'Total_Fload', 'Total_VA3', 'Total_OS_P'});

    % Display the table
    disp('Aggregated Results (Sum):');
    disp(aggregatedTable);

    % Save the table to a CSV file
    outputFileName = fullfile(folderName, 'aggregatedResults.csv');
    writetable(aggregatedTable, outputFileName);

    % Inform the user of completion
    fprintf('Aggregated results saved to: %s\n', outputFileName);
end
