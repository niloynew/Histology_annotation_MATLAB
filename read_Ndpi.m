% Define the path to the NDPI file
ndpiFile = 'F:\Germany\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK\SSES-1 10_J-21-152_100_Pig_HE_RUN23__liver_MAX.ndpi';

% Step 1: Create an instance of the adapter
adapter = NDPIAdapter();

% Step 2: Open the file for reading
adapter.openToRead(ndpiFile);
disp('NDPI file opened successfully.');

% Step 3: Retrieve image metadata using getInfo
info = adapter.getInfo();
disp('Image Metadata:');
disp(info);

% Display image size and block size
fprintf('Image size: %d x %d (height x width)\n', info.Size(1), info.Size(2));
fprintf('Number of levels: %d\n', info.Size(3));
fprintf('Default block size: %d x %d\n', info.IOBlockSize(1), info.IOBlockSize(2));

% Read the top-left block at level 0
fprintf('Reading the top-left block...\n');
topLeftBlock = adapter.getIOBlock([1, 1], 6);
figure;
imshow(topLeftBlock);
title('Top-Left Block (Level 5)');

% Read a center block at level 0
fprintf('Reading a center block...\n');
centerY = ceil(info.Size(1) / (2 * info.IOBlockSize(1)));
centerX = ceil(info.Size(2) / (2 * info.IOBlockSize(2)));
centerBlock = adapter.getIOBlock([centerY, centerX], 1);
figure;
imshow(centerBlock);
title('Center Block (Level 0)');


 %Step 6: Clean up resources
 adapter.close();
 disp('NDPI file closed.');

