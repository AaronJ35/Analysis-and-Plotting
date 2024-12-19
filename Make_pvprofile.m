function Make_pvprofile(max_value, output_file)
% Function to create a PV profile scaled to a specified maximum value
% while maintaining the ratios of the original PV sums over time.
% 
% Parameters:
% max_value (scalar): Maximum scaling value for the PV profile
% output_file (string): Name of the output Excel file

% Define the PV sums
pv_sums = [8.1292, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 0.279882, 9.538, 47.614, 123.322, 188.835, 238.18, 266.38, 263.79, 244.992, 206.789, 150.804, 82.05, 29.105, 5.5205, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 0.31967, 8.6799, 31.897, 78.5, 111.778, 234.564, 247.34, 270.1, 235.14, 198, 142.994, 64.003, 21.802, 3.5838, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 0.6179, 3.4151, 37.067, 95.37, 152.5, 188.225, 208.96, 85.372, 129.46, 58.671, 113.137, 63.5, 22.629];

% Define the PV buses
pv_buses = [67, 179, 241, 479];

% Validate input
if ~isscalar(max_value)
    error('The max_value parameter must be a scalar.');
end

% Calculate the scaling ratio based on the specified maximum value
scaling_ratio = max_value / max(pv_sums);

% Scale the PV sums
scaled_pv_sums = pv_sums * scaling_ratio;

% Initialize the output matrix with timesteps as the first column
output_matrix = cell(length(pv_sums) + 1, length(pv_buses) + 1);

% Add the header row with bus numbers
output_matrix(1, 2:end) = strcat(cellstr(num2str(pv_buses')), '-1');

% Add the first column with timesteps
output_matrix(2:end, 1) = num2cell((1:length(pv_sums))');

% Distribute scaled PV sums equally across the specified buses
for j = 1:length(scaled_pv_sums)
    % Calculate the PV value per bus for the current timestep
    pv_values = scaled_pv_sums(j) / length(pv_buses);
    % Add the PV values to the respective row in the matrix
    for k = 1:length(pv_buses)
        output_matrix{j + 1, k + 1} = pv_values;
    end
end

% Write the output matrix to an Excel file
writecell(output_matrix, output_file, 'WriteMode', 'replacefile');

fprintf('PV profile analysis written to %s\n', output_file);
end
