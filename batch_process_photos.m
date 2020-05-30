% Batch Image Processing for ES24 ALuminum Project
% Written by Anoush Khan, Ben Martin

% clear environment
clear, clc

% debugging flag: set to true to enter verbose mode
DEBUG = false;

% array of image names in user-selected folder
picpath_raw = uigetdir;
picpath = strcat(picpath_raw, '\*.jpg');
picarr = dir(picpath);
picnames = string({picarr.name});

% set previous sample number to impossible value to always calibrate at run
prev_sample_num = 0;
prev_calib_mm_over_pix = 0;

% instructions for use popup
use_message = 'Left click to select initial point, right click to select final point. Watch figure titlebar for instructions (calibrate / measure)';
f = msgbox(use_message);
tbl = table('Size', [1 5], 'VariableTypes', {'string' 'string' 'string' 'string' 'double'}, 'VariableNames', {'alloy' 'temp' 'sample' 'mark' 'diameter'});
% begin processing loop
for pic = picnames
    % get metadata from picture name
    name_parts = string(split(pic, ["_", "."]));
    % part 1 = AK, 2 = alloy, 3 = temp, 4 = sample num, 5 = mark num
    initials = name_parts(1);
    alloy = name_parts(2);
    temp = name_parts(3);
    sample_num = name_parts(4);
    mark_num = name_parts(5);
    
    % for debugging, print the sample metadata
    if DEBUG
        fprintf(pic)
        fprintf('\n')
        fprintf(alloy)
        fprintf('\n')
        fprintf(temp)
        fprintf('\n')
        fprintf(sample_num)
        fprintf('\n')
        fprintf(mark_num)
        fprintf('\n')
    end
    
    % determine whether to ask for calibration based on sample number
    if sample_num == string(prev_sample_num)
        ToCalib = false;
    else
        ToCalib = true;
    end
    
    % load and show the image
    image = imread(strcat(picpath_raw, '\', pic));
    imshow(image);
    set(gcf, 'Position', get(0, 'Screensize'));
    
    % image processing is in two steps
    % first, get calibration factor for a 0.5 mm distance
    if ToCalib == true
        set(gcf,'name','Mark off 0.5mm','numbertitle','off')
        calibration.mm = 0.5;
        [~, ~, ~, xi,yi] = improfile(1000);
        calibration.pix = sqrt( (xi(2)-xi(1)).^2 + (yi(2)-yi(1)).^2);
        clear xi yi
        calibration.mm_over_pix = calibration.mm / calibration.pix;
    elseif ToCalib == false
        calibration.mm_over_pix = prev_calib_mm_over_pix;
    end
    
    % second, measure diameter
    set(gcf,'name','Measure diameter of indent','numbertitle','off')
    [~, ~, ~, xi,yi] = improfile(1000);
    diameter.pix = sqrt( (xi(2)-xi(1)).^2 + (yi(2)-yi(1)).^2);
    diameter.mm = diameter.pix * calibration.mm_over_pix;

    % save the diameter to the correct location here
    data.(genvarname('alloy')) = alloy;
    data.(genvarname('temp')) = temp;
    data.(genvarname('sample')) = sample_num;
    data.(genvarname('mark')) = mark_num;
    data.(genvarname('diameter')) = diameter.mm;
    % write the data to the table
    tbl = vertcat(tbl,struct2table(data));
    % set previous run parameters
    prev_sample_num = sample_num;
    prev_calib_mm_over_pix = calibration.mm_over_pix;
    
    % close image to loop to next one
    close all
end

% write data to excel file
writetable(tbl, strcat(initials,'_alloy_',alloy,'_',temp,'.xlsx'));
 