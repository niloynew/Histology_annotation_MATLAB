classdef NDPIAdapter < images.blocked.Adapter
    % NDPIAdapter: Custom adapter for reading .ndpi images using OpenSlide.
    
    properties
        File (1,1) string         % Path to the NDPI file
        Info (1,1) struct         % Metadata for the image
        OpenSlidePointer          % Handle to OpenSlide object
    end

    methods
        %% Method 1: Open the file for reading
        function openToRead(obj, source)
            % Store the file path
            obj.File = source;
            
            % Open the NDPI file using OpenSlide
            obj.OpenSlidePointer = clib.OpenSlideInterface.openslide_open(obj.File);
            
            % Get image dimensions from level 0
            [width, height] = clib.OpenSlideInterface.openslide_get_level_dimensions(obj.OpenSlidePointer, int32(0), int64(0), int64(0));

            % Get the number of levels
            levels = clib.OpenSlideInterface.openslide_get_level_count(obj.OpenSlidePointer);

            % Populate the Info structure
            obj.Info.Size = [double(height), double(width), double(levels)];
            obj.Info.IOBlockSize = [1024, 1024, 1]; % Default block size (from example)
            obj.Info.Datatype = "uint8";          % Image data type
            obj.Info.InitialValue = cast(0, obj.Info.Datatype); % Default pixel value

          
       end

        %% Method 2: Gather information about the image
        function info = getInfo(obj)
            % Return metadata about the image
            info = obj.Info;
        end

        function block = getIOBlock(obj, ioblockSub, level)
            % Ensure `ioblockSub` is a 2-element vector
            assert(numel(ioblockSub) == 2, ...
                'ioblockSub must be a 2-element vector: [rowIndex, colIndex].');

            % Compute pixel region for the block
            regionStart = (ioblockSub - 1) .* obj.Info.IOBlockSize(1:2) + 1;
            regionEnd = ioblockSub .* obj.Info.IOBlockSize(1:2);

            % Clip to image boundaries
            regionStart = max(regionStart, [1, 1]);
            regionEnd = min(regionEnd, obj.Info.Size(1:2));

            % Determine region dimensions
            regionWidth = regionEnd(2) - regionStart(2) + 1;
            regionHeight = regionEnd(1) - regionStart(1) + 1;

            % Allocate buffer for raw data
            rawCData = clibArray('clib.OpenSlideInterface.UnsignedInt', [regionHeight, regionWidth]);

            % Read region using OpenSlide
            clib.OpenSlideInterface.openslide_read_region(obj.OpenSlidePointer, rawCData, ...
                int64(regionStart(2)-1), int64(regionStart(1)-1), int32(level-1));

            % Convert raw data to MATLAB format (RGB)
            rawData = uint32(rawCData);
            RGBA = typecast(rawData(:), 'uint8');

            % Ensure correct dimensions and RGB-only data
            block = zeros(regionHeight, regionWidth, 3, 'uint8');
            block(:,:,1) = reshape(RGBA(3:4:end), regionWidth, regionHeight)';
            block(:,:,2) = reshape(RGBA(2:4:end), regionWidth, regionHeight)';
            block(:,:,3) = reshape(RGBA(1:4:end), regionWidth, regionHeight)';
        end


        %% Cleanup: Close the OpenSlide object
        function close(obj)
            if ~isempty(obj.OpenSlidePointer)
                clib.OpenSlideInterface.openslide_close(obj.OpenSlidePointer);
                obj.OpenSlidePointer = [];
            end
        end
    end
end
