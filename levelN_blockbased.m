%% Step 1: Define the Path to NDPI and NDPA Files
ndpiFile = 'F:\Germany\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK\SSES-1 10_J-21-152_100_Pig_HE_RUN23__liver_MAX.ndpi';
ndpaFile = 'F:\Germany\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK\SSES-1 10_J-21-152_100_Pig_HE_RUN23__liver_MAX.ndpi (4).ndpa';

%% Step 2: Create an Adapter and Open the NDPI File

adapter = NDPIAdapter();
adapter.openToRead(ndpiFile);
disp('✅ NDPI file opened successfully.');

%% Step 3: Retrieve Image Metadata
info = adapter.getInfo();
fprintf('📌 Image size: %d x %d (Height x Width), Levels: %d\n', info.Size(1), info.Size(2), info.Size(3));

%% Step 4: Select a Target Level (Lower Resolution)
% Change to any desired level (e.g., 6, 7, or 8)
targetLevel = 0; 
downsampleFactor = clib.OpenSlideInterface.openslide_get_level_downsample(adapter.OpenSlidePointer, int32(targetLevel));

% Compute target resolution
targetWidth = round(info.Size(2) / downsampleFactor);
targetHeight = round(info.Size(1) / downsampleFactor);
fprintf('✅ Using Level %d: %d x %d (Downsampling Factor: %.2f)\n', targetLevel, targetHeight, targetWidth, downsampleFactor);

%% Step 5: Read a Center Block from the Target Level
fprintf('🔹 Reading a center block from Level %d...\n', targetLevel);
centerY = ceil(targetHeight / (2 * info.IOBlockSize(1)));
centerX = ceil(targetWidth / (2 * info.IOBlockSize(2)));

blockImage = adapter.getIOBlock([centerY, centerX], targetLevel+1);
blockHeight = size(blockImage, 1);
blockWidth = size(blockImage, 2);

% Compute the global coordinate range of this block in Target Level
blockStartX = (centerX - 1) * info.IOBlockSize(2) + 1;
blockStartY = (centerY - 1) * info.IOBlockSize(1) + 1;
blockEndX = min(blockStartX + blockWidth - 1, targetWidth);
blockEndY = min(blockStartY + blockHeight - 1, targetHeight);

fprintf('✅ Block Global Range (Level %d): (%d:%d, %d:%d)\n', targetLevel, blockStartX, blockEndX, blockStartY, blockEndY);

%% Step 6: Load and Downsample Annotations
xDoc = xmlread(ndpaFile);
annotations = xDoc.getElementsByTagName('annotation');
numAnnotations = annotations.getLength();
fprintf('📌 Number of annotations found: %d\n', numAnnotations);

nmPerPixel = 227; % Found from image info

annotation_data = struct();
for i = 0:numAnnotations-1
    annotation = annotations.item(i);
    
    % Extract attributes
    annotation_data(i+1).type = char(annotation.getAttribute('type'));
    annotation_data(i+1).displayname = char(annotation.getAttribute('displayname'));
    annotation_data(i+1).color = char(annotation.getAttribute('color'));

    fprintf('🔹 Annotation %d: Type = %s, Display Name = %s, Color = %s\n', ...
        i+1, annotation_data(i+1).type, annotation_data(i+1).displayname, annotation_data(i+1).color);

    % Extract coordinates
    pointlist = annotation.getElementsByTagName('point');
    numPoints = pointlist.getLength();

    coords = zeros(numPoints, 2);
    for j = 0:numPoints-1
        point = pointlist.item(j);
        originalX_nm = str2double(point.getElementsByTagName('x').item(0).getTextContent());
        originalY_nm = str2double(point.getElementsByTagName('y').item(0).getTextContent());

        % Convert nanometer coordinates to pixel coordinates at Level 0
        originalX = originalX_nm / nmPerPixel;
        originalY = originalY_nm / nmPerPixel;

        % 🔹 Apply Downsampling Factor to Match Target Level
        scaledX = originalX / downsampleFactor;
        scaledY = originalY / downsampleFactor;

        % Filter points inside the block
        if (scaledX >= blockStartX && scaledX <= blockEndX) && ...
           (scaledY >= blockStartY && scaledY <= blockEndY)
            localX = scaledX - blockStartX + 1;
            localY = scaledY - blockStartY + 1;
            coords(j+1, :) = [localX, localY];
            fprintf('   ✅ In-Bounds Point: (X=%.2f, Y=%.2f)\n', localX, localY);
        else
            coords(j+1, :) = NaN; % Mark points outside the block
        end
    end

    % Remove out-of-bounds points
    annotation_data(i+1).coordinates = coords(~isnan(coords(:,1)), :);

    % 🔹 Debugging Output: Print the first 5 coordinates
    fprintf('🔹 Annotation %d: Type = %s, Display Name = %s\n', i+1, annotation_data(i+1).type, annotation_data(i+1).displayname);
    fprintf('   🔸 First 5 Scaled Coordinates (X, Y):\n');
    disp(coords(1:min(5, size(coords, 1)), :)); % Print up to 5 points

    fprintf('   ✅ Filtered %d coordinates for annotation %d\n\n', size(annotation_data(i+1).coordinates, 1), i+1);
end

%% Step 7: Overlay Annotations on the Image Block
figure; imshow(blockImage);
hold on;
title(sprintf('NDPI Image Block at Level %d with Overlaid Annotations', targetLevel));

for i = 1:length(annotation_data)
    if isempty(annotation_data(i).coordinates)
        continue; % Skip if no annotations in this block
    end
    coords = annotation_data(i).coordinates;

    % Convert HEX color to RGB
    hexColor = annotation_data(i).color;
    if startsWith(hexColor, '#')
        rgb_color = sscanf(hexColor(2:end), '%2x%2x%2x', [1 3]) / 255;
    else
        rgb_color = [1, 0, 1]; % Default to purple
    end

    % Overlay annotations
    plot(coords(:,1), coords(:,2), '-o', 'Color', rgb_color, ...
         'LineWidth', 3, 'MarkerSize', 8, 'MarkerFaceColor', rgb_color, ...
         'MarkerEdgeColor', 'k'); % Black edge for contrast
end
hold off;

%% Step 8: Cleanup
adapter.close();
disp('✅ NDPI file closed.');
