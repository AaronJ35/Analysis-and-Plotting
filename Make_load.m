% Adapted Make_loadprofile.m to transpose output structure and include timesteps

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

% PV sums (commented out for re-addition)
%pv_sums = [8.1292, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 9.538, 47.614, 123.322, 188.835, 238.18, 266.38, 263.79, 244.992, 206.789, 150.804, 82.05, 29.105, 5.5205, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 8.6799, 31.897, 78.5, 111.778, 234.564, 247.34, 270.1, 235.14, 198, 142.994, 64.003, 21.802, 3.5838, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 3.4151, 37.067, 95.37, 152.5, 188.225, 208.96, 85.372, 129.46, 58.671, 113.137, 63.5, 22.629];

% Initialize the output matrix with timesteps as the first column
output_matrix = cell(length(new_total_sums) + 1, length(bus_numbers) + 1);

% Add the header row with bus numbers
output_matrix(1, 2:end) = num2cell(bus_numbers');
%output_matrix(1, 2:end) = strcat(cellstr(num2str(bus_numbers')), '-1');
% Add the first column with timesteps
output_matrix(2:end, 1) = num2cell((1:length(new_total_sums))');

% Loop through each total sum value to calculate and transpose data
for j = 1:length(new_total_sums)
    % Calculate the scaled load values for all buses
    scaled_load_values = (percentage_vector / 100) * new_total_sums(j);
    % Add the scaled load values to the respective row in the matrix
    for k = 1:length(scaled_load_values)
        output_matrix{j + 1, k + 1} = scaled_load_values(k);
    end
end

% Write the output matrix to an Excel file
output_file = 'BZ_load_profile_analysis_transposed.xlsx';
writecell(output_matrix, output_file, 'WriteMode', 'replacefile');

fprintf('Load profile analysis written to %s\n', output_file);
