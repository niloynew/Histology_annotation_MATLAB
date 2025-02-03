
addpath(pwd)


OpenSlideInstall = 'C:\Program Files\MATLAB\R2023b\openslide-bin-4.0.0.6-windows-x64\openslide-bin-4.0.0.6-windows-x64';
dir(OpenSlideInstall)

sharedLibLoc = fullfile(OpenSlideInstall, 'bin');
systemPath = getenv('PATH');
setenv('PATH', [sharedLibLoc ';' systemPath])

ExampleDir = 'F:\Germany_2022\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK';

imageLocation = 'F:\Germany_2022\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK\SSES-1 10_J-21-152_100_Pig_HE_RUN23__liver_MAX.ndpi';

OpenSlideInterface = 'F:\Germany_2022\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK\interfaceFolder';



if ~isfolder(OpenSlideInterface)
    mkdir(OpenSlideInterface)
end
cd(OpenSlideInterface)


libPath = fullfile(OpenSlideInstall,'lib');
hppFiles = {'openslide.h', 'openslide-features.h'};
hppPath = fullfile(OpenSlideInstall, 'include', 'openslide');
libFile = 'libopenslide.lib';
myPkg = 'OpenSlideInterface';

%Run the commented snippet if Mingw compiler is missing or unidentified

% Set up MinGW manually
mexSetupDir = 'C:\mingw-w64\mingw64\bin'; % Update to your actual MinGW bin directory
setenv('MW_MINGW64_LOC', fileparts(mexSetupDir));
mex -setup cpp




% Clear previous run (if any)
if isfile('defineOpenSlideInterface.m')
    delete('defineOpenSlideInterface.m')
end
clibgen.generateLibraryDefinition(fullfile(hppPath,hppFiles),...
      'IncludePath', hppPath,...
      'Libraries', fullfile(libPath,libFile),...
      'PackageName', myPkg,...
      'Verbose',false)


movefile('defineOpenSlideInterface.m','defineOpenSlideInterface_generated.m');

%delete defineOpenSlideInterface.mlx;
%rehash

fid = fopen(fullfile('defineOpenSlideInterface_template.m'),'rt');
interfaceContents = fread(fid, 'char=>char');
fclose(fid);

interfaceContents = strrep(interfaceContents','OPENSLIDE_INSTALL_LOCATION',OpenSlideInstall);
interfaceContents = strrep(interfaceContents,'OPENSLIDE_INTERFACE_LOCATION',OpenSlideInterface);

fid = fopen('defineOpenSlideInterface.m','wt');
fwrite(fid, interfaceContents);
fclose(fid);

build(defineOpenSlideInterface)

addpath('F:\Germany_2022\TU Illmenau\Winter24-25\Hiwi\HIWI_WORK\interfaceFolder\osInterface\OpenSlideInterface');
savepath; % Save the path for future MATLAB sessions

summary(defineOpenSlideInterface)


%{
Testing the library interface
ob = clib.OpenSlideInterface.openslide_open(imageLocation);
levels = clib.OpenSlideInterface.openslide_get_level_count(ob);
[w, h] = clib.OpenSlideInterface.openslide_get_level_dimensions(ob,int32(0),int64(0),int64(0));
disp([w, h])


rawCData = clibArray('clib.OpenSlideInterface.UnsignedInt', [1024, 1024]);
clib.OpenSlideInterface.openslide_read_region(ob,rawCData,int64(51584),int64(29184),int32(0));

rawImageData = uint32(rawCData);
RGBA = typecast(rawImageData(:), 'uint8');
% Ignore the A channel
RGB(:,:,1) = reshape(RGBA(3:4:end),1024,1024);
RGB(:,:,2) = reshape(RGBA(2:4:end),1024,1024);
RGB(:,:,3) = reshape(RGBA(1:4:end),1024,1024);

figure;
imshow(RGB);
%end of testing%
%}







