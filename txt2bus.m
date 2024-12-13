
function txt2bus(filename)
% Read the input file
fid = fopen(filename, 'r');
lines = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);

% Initialize a container to store all matches
all_matches = containers.Map('KeyType', 'char', 'ValueType', 'any');

% Process each line
for i = 1:length(lines{1})
    line = lines{1}{i};
    
    % Find all numeric matches in the line
    numbers = regexp(line, '\d+', 'match');
    
    if length(numbers) >= 2
        key = numbers{end};  % Use the last number as the key
        
        if ~isKey(all_matches, key)
            all_matches(key) = {};
        end
        
        % Add the match to the container
        if startsWith(line, 'TL')
            all_matches(key) = [all_matches(key), {sprintf('TL_%s_%s', numbers{1}, numbers{2})}];
        elseif startsWith(line, 'L')
            all_matches(key) = [all_matches(key), {sprintf('L%s', numbers{1})}];
        end
    end
end

% Generate and display the output
keys = all_matches.keys;
for i = 1:length(keys)
    key = keys{i};
    matches = all_matches(key);
    
    % Prepare the content of the curly braces
    content = '';
    for j = 1:length(matches)
        if startsWith(matches{j}, 'TL')
            content = [content, sprintf('{%s,''R''}', matches{j})];
        else
            content = [content, sprintf('{%s}', matches{j})];
        end
        if j < length(matches)
            content = [content, ','];
        end
    end
    
    % Generate the output string
    output = sprintf('Bus%s = {%s};', key, content);
    
    % Display the output
    %disp(output);
    % Open the output file for writing
    OFID = fopen(filename, 'a+');
    % Write the output to the new file
    fprintf(OFID, '%s\n', output);
end