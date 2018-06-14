# Research Notes

## April 13-14
- Baby-sitting the learning process
  * LEARNING - This takes a LOT more time than you'd expect it to
- Read up on and coded up Orthonormal Matching Pursuit (impressive given that I was getting drunk alongside)
- Looking at examples from Matching Pursuit (redo using examples from latest trained model)

## April 15
- Comparison of models trained till now
- Collect data using zshade

## April 16
- Visit to St. Louis Traderjoe

## April 17-18
- Visit to Traderjoe Shoreview
- Ran classifier to death, organized data

## April 20
### Exp
- Got inspired *bleh*
- Worked on rectification

### Plan of Action

- _Rectification_, image/space morphing can be tried out later
- OMP try out on 3rd store from 1st & 2nd
- Collect Target data
- Supervise labeling and collection

### Ideas
- Spacially weighted optimization using pre-selected images, then think about how to choose basis images
- Labels aisles(?), demarcate images and then classify etc

### April 21-23
- Working with Tierney on data collection
- Need to map 33 stores in the next 2 weeks
- Gravity rectification


### Plan

- 3 kinds of stores, class balance not so important
  - Dense reconstruction
  - Labeling
  - slow movement, not required coz of lit surroundings
  - label point clouds, instead of frame labeling and then transferring labels to point clouds
  - call none 'background', or think about floor and ceiling
  - Build prototype based on just Traderjoe data maybe

- Semantic localization : multiple levels
  - Orientation -> eight subquadrant localization


- Can use FCN for getting representation, and can use spatial transformer in front parametrized by theta (theta, h from cylinder)
- Compute warping using dense SIFT flow

Contributions:
 - Transformer in front of FCN
 - Trajectory prediction


Paper:
 - Method - rectification, NN architecture, loss fn, nearest neighbors
 - Results
 - Related work
 - Dataset - trajectory prediction variety analysis
 - Intro (Hyun Soo)
 
 - use placeholders, structure it, will change depending on how you want to pitch it

 - summarize properties desired in representation and intuition behind, then go into methods
