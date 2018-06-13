# Semantic Localization

#### Work in Progress - hope to make this somewhat comprehensive soon
TODO - Collect repos in organization

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
