#  Prob 1 
## Structure from motion be used to determine pose of camera

Using info from one video to predict path/navigation in other - can be very high-level/coarse info. Eg: cash counter at entrance, veggies on the right, bread/milk at the back

### Task breakdown
1. Labeling
  i   Annotation by hand
  ii  Segment images, train network and propagate labels through frames
2. Localization - Observe current frame and localize yourself. I don't understand why this is hard
3. Predict motion in diff video/store


### Tasks
1. Label left and right frames from each video
2. Construct adjacency matrix from previously singly-labeled data and also from the above new labels, using frequency of co-occurrence. Can then threshold this to get a matrix with 1/0 labels



### Script locations:
bin/
`sift++_batch_qsub_jpg.sh`

bin/NavigationQA
`RunEgoNQA_zshade.sh`


## Loop detection using higher order feature/structure capturing from graphs
* embedding graphs
* uniquely localizable graphs
* MDS requires rigid/non-sparse graphs. Can break non-rigid ones into small rigid graphs that can later snap together via some kind of correspondences
* Triangular inequalities - ??

## Aims
* Localization - given a scene, where am I on the graph ? Given location, what does the scene look like ?
* Navigation - Section A to B in new scene


## Deliverables
### Improvements
* Projection from behind image plane to be eliminated
* R' * (X-C) > 0
* Take distortion into account

### Adjacency Matrix
* Stitch point cloud
* Label points and project back
* Compute distance using median metrics
* If not stitching, average across adjacency matrices from batches

### Bag of Words
* Project points onto frame, sample from images then subsample OR window the image, then take windows with sufficiently large fraction 
* Can run classifier using image features on windowed images later
