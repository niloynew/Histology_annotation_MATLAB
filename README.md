# Histology_annotation_MATLAB
Reading is multi-resolution .ndpi histological image and overlaying annotations parsed from .ndpa file

First Step:
 1. Based on the link https://de.mathworks.com/help/images/read-whole-slide-images-with-custom-blocked-image-adapter.html,
            -> added the file defineOpenSlideInterface_template.m to my project
            -> write and run the files named build_openSlide_interface.m, NDPIAdapter.m and finally for block-based reading read_Ndpi.m
 2. Running the Minmax.m made it clear that the annotations were given in nanometers (also mentioned in the tag of the .ndpa file). Dividing the annotation co-ordinates by 
    227(the nanometers/pixel) , derived the level 0 pixel co-ordinates.
 3. Finally ran level0_annotate.m for a block-based overlay of the extracted annotations on level 0 of the .ndpi file,
 4. For overlaying on any other lower resolution level, wrote and ran levelN_blockbased.m , Although the output pictures will be reasonable and good for higher resolution 
    layers(e.g., 0,1,2,3), for lower resolution layers the alignment might not be desirable. In that case, change the default blocksize at NdpiAdapter.m file from 
    [1024,1024,1] to your suitable one.
 5. Every other files are generated. Anyone can start without them.    
