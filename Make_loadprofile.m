% Adapted Make_loadprofile.m to match output structure of BZ_load_0.xlsx

% Load data from the input file
input_file = 'BZ_Loads.txt';
data = importdata(input_file);

% Extract relevant columns
bus_numbers = data(:, 1);
fifth_column = data(:, 6);

% Calculate the total sum of the 6th column
total_sum = sum(fifth_column);

% Calculate the percentage of the total for each load
percentage_vector = (fifth_column / total_sum) * 100;

% Define new total sum values to test (from load profile)
new_total_sums = [4490, 4400.5, 4307.4, 4140.1, 4152, 3848.7, 3848.6, 3813.2, 3760.7, 3843.5, 3887.3, 3890.6, 3736.7, 3918.9, 4088.7, 4324, 4448.3, 4431.6, 4672.1, 4709.2, 4879.3, 5016.3, 5145.6, 5191.3, 5041, 4957.4, 4863.9, 4536.2, 4465.2, 4337.5, 4140.9, 4141.1, 3985.4, 4094.1, 4221.1, 4430.6, 4416.4, 4778, 4843.1, 5173.9, 5301.6, 5464.3, 5637.7, 5789.3, 6037.4, 6118.6, 6253.4, 6169.4, 6024, 5726.5, 5443.8, 5122.4, 5003, 4750.4, 4550.9, 4436.3, 4516, 4617.9, 4569, 4687.5, 4930.7, 5158.1, 5592.9, 6066.3, 6135.4, 6249.1, 6360.7, 6313.9, 6452.5, 6276.9, 6298.2, 6117.2]./1000;

% Initialize the output matrix
output_matrix = cell(length(bus_numbers) + 1, length(new_total_sums) + 1);

% Add the header row with total sums
output_matrix(1, :) = [{''}, num2cell(new_total_sums)];

% Loop through each bus number
for i = 1:length(bus_numbers)
    % Add the bus number to the first column
    output_matrix{i + 1, 1} = bus_numbers(i);
    
    % Loop through each total sum value
    for j = 1:length(new_total_sums)
        % Calculate the scaled load value
        new_load_value = (percentage_vector(i) / 100) * new_total_sums(j);
        % Store the value in the output matrix
        output_matrix{i + 1, j + 1} = num2str(new_load_value, '%.4f');
    end
end

% Write the output matrix to an Excel file
output_file = 'BZ_load_profile_analysis.xlsx';
writecell(output_matrix, output_file, 'WriteMode', 'replacefile');

fprintf('Load profile analysis written to %s\n', output_file);
