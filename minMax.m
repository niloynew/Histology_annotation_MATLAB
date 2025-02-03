% Define the path to the NDPA file
ndpaFile = 'F:\Germany\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK\SSES-1 10_J-21-152_100_Pig_HE_RUN23__liver_MAX.ndpi (2).ndpa';

% Load the XML annotation file
xDoc = xmlread(ndpaFile);
annotations = xDoc.getElementsByTagName('annotation');
numAnnotations = annotations.getLength();
fprintf('📌 Number of annotations found: %d\n', numAnnotations);

% Initialize min/max values
minX = inf;
maxX = -inf;
minY = inf;
maxY = -inf;

% Extract annotation coordinates
for i = 0:numAnnotations-1
    annotation = annotations.item(i);
    pointlist = annotation.getElementsByTagName('point');
    numPoints = pointlist.getLength();
    
    for j = 0:numPoints-1
        point = pointlist.item(j);
        originalX = str2double(point.getElementsByTagName('x').item(0).getTextContent());
        originalY = str2double(point.getElementsByTagName('y').item(0).getTextContent());
        
        % Update min/max values
        minX = min(minX, originalX);
        maxX = max(maxX, originalX);
        minY = min(minY, originalY);
        maxY = max(maxY, originalY);
    end
end

% Display min/max values
fprintf('🔍 Min/Max X: [%.2f, %.2f]\n', minX, maxX);
fprintf('🔍 Min/Max Y: [%.2f, %.2f]\n', minY, maxY);

disp('✅ Min/Max Annotation Coordinates Extracted Successfully.');


mpp_x = clib.OpenSlideInterface.openslide_get_property_value(adapter.OpenSlidePointer, 'openslide.mpp-x');
mpp_y = clib.OpenSlideInterface.openslide_get_property_value(adapter.OpenSlidePointer, 'openslide.mpp-y');










