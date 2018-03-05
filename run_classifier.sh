#!/bin/bash
python tensorflow/tensorflow/examples/image_retraining/retrain.py \
  --image_dir TraderJoe/features_augmented \
  --output_graph classifier/output_graph.pb \
  --intermediate_output_graphs_dir classifier/intermediate_graph/ \
  --intermediate_store_frequency 10000 \
  --bottleneck_dir classifier/bottleneck \
  --model_dir classifier/imagenet \
  --output_labels classifier/output_labels.txt \
  --how_many_training_steps 200000 \
  --print_misclassified_test_images \
  > classifier.log 2>&1 &
