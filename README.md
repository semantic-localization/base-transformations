# Semantic Localization

#### Work in Progress - hope to make this somewhat comprehensive soon
TODO - Collect repos in organization

NOTE - check out `/home/hspark/sharm546/.bashrc` to know which packages need to be loaded (for MSI)

## Frame Extraction
The following script can be utilized. Note - needs ffmpeg
```bash
# might need to resource params
qsub extract_frames.pbs
```

## Structure from Motion (SfM)
A couple of parts
1. SIFT features' calculation - In the image dir (i.e., directory with image folder), run:
```bash
sift++_batch_qsub_jpg.sh
```
2. After all the jobs are done - you can check this by looking at the number of \*.key and \*.jpg files : the difference should be 0 or almost 0
```bash
RunEgoNQA_zshade.sh
```
You can track progress by grep-ing NumPoses in the reconstruction\* folders. Reconstruction is done in batches of 200 (with an overlap of 30 frames). So if there are 18k images, the last folder will have the name reconstruction0017800 - when camera.txt in this folder has NumPoses close to 230, you're done.

Note that there is a limit of 500 jobs per user in MSI. So that's something to be aware of since some of the jobs might be rejected if the queue is getting full

3. 3d point cloud stitching, in parts. Run:
```bash
EgoMotionAlignment
```

## Rectification
Producing cylindrical rectifications is a 2-step process:
1. Rectification against gravity - this includes the step of computing correction vectors using camera poses from SfM. A plane is fit to 
the camera poses using RANSAC and this is taken to be ground plane.
```python
# pwd - directory containing reconstruction* and image folder
python ransac.py
```
```bash
# On MSI - see example file @ /home/hspark/sharm546/Traderjoe/Shoreview/rectify.pbs
# Might need to edit job resource params

# The pbs script above calls rectifyWrtGroundPlane - this script calculates the homography mapping to correct against gravity
# as well as the cylindrical projection. The latter part is handled by inverse mapping in file CylindricalProjection.m
qsub rectify.pbs

# If you see rectifyWrtGroundPlane, the first line in the function is a for loop that loops over all the directories. 
# Right now the number corresponding to the last directory is hard-coded so must be modified for each new run -- this can probably be automated.
```

2. Cylindrical Projection - explained above


## Scene Recognition
This bit computes features for every image in an image dir. Features are computed using the pre-trained [places365](https://github.com/CSAILVision/places365)
. PyTorch models used

```python
# Code at /home/jayant/places365 on multicam3
python features_from_resnet.py /mnt/grocery_data/Traderjoe/StPaul
# will produce a pickle file named features_places.pkl as result in the same dir
```

Features computed can be used for tasks like retrieving nearest neighbors.
