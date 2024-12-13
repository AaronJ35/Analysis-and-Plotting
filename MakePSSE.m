function MakePSSE(filename)
    % Add the necessary path
    addpath(genpath('\Users\aaron\Desktop\Research\matpower8.0'));
    
    % Load the MATPOWER case
    mpc = loadcase(filename);
    
    % Extract islands and select the first one
    mpc2 = extract_islands(mpc);
    mpc3 = mpc2{1, 1};
    
    % Ensure filename is a string
    filename = string(filename);
    
    % Create the output filename
    output_filename = filename + "_output.raw"; % For string concatenation
    
    % Save the modified case to a PSSE RAW file
    save2psse(output_filename, mpc3);
end
