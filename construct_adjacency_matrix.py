"""
Construct adjacency matrix from video labeling to get a sense of adjacent sections. 

Observation: Store duration whenever label is none, so that it gives a sense of raw distance.
"""


import os
import shutil
import argparse
import numpy as np
import scipy.io
from collections import defaultdict, Counter



def to_time(s):
    m, s = map(int, s.split(':'))
    return 60*m + s


def construct_adjacency_matrix(store, threshold=0):
    labels = [
            'bars',
            'beverages',
            'bodycare',
            'bread',
            'cereal',
            'cheese',
            'counter',
            'dairy',
            'dressing',
            'entrance',
            'flowers',
            'frozenfood',
            'health',
            'meat',
            'none',
            'oils',
            'pasta',
            'pets',
            'seafood',
            'snacks',
            'soup',
            'vegetables',
            'water'
            ]
    n = len(labels)

    adjacency_matrix = np.zeros((n,n))
    labels_file = 'labels_{}.txt'.format(store)

    with open(labels_file) as f:
        lines = list(f)
        prev_label = lines[0].strip().split()[1]
        for i, line in enumerate(lines[1:]):
            time_range, label = line.strip().split()
            li, pli = labels.index(label), labels.index(prev_label)
            adjacency_matrix[li,pli] += 1
            adjacency_matrix[pli,li] += 1
            prev_label = label

            # Let's do something simple first
            # Don't update previous label if the none label lasts for no more than 5 seconds
#             if label == 'none':
#                 start_time, end_time = time_range.split('-')
#                 duration = to_time(end_time) - to_time(start_time)
#                 if prev_label:
#                     adjacency_matrix[label][prev_label] += duration
#                     adjacency_matrix[prev_label][label] += duration
#                 prev_label = label

    print(adjacency_matrix)
    scipy.io.savemat('{}_adjacency.mat'.format(store), mdict={'labels': np.array(labels), 'adjacency_matrix': adjacency_matrix})

#     for sctn, adjacency_list in adjacency_matrix.items():
#         del_list = []
#         for nbr_sctn, freq in adjacency_list.items():
#             if freq > threshold:
#                 adjacency_list[nbr_sctn] = 1
#             else:
#                 del_list.append(nbr_sctn)
#         for nbr_sctn in del_list:
#             del(adjacency_list[nbr_sctn])
#         print('{} :\n\t{}\n--'.format(sctn, adjacency_list))



if __name__ == '__main__':
    construct_adjacency_matrix('wholefood')
    construct_adjacency_matrix('traderjoe', 1)
