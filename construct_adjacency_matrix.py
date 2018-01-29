"""
Construct adjacency matrix from video labeling to get a sense of adjacent sections. 

Observation: Store duration whenever label is none, so that it gives a sense of raw distance.
"""


import os
import shutil
import argparse
from collections import defaultdict, Counter



def to_time(s):
    m, s = map(int, s.split(':'))
    return 60*m + s


def construct_adjacency_matrix(store, threshold=0):
    adjacency_matrix = defaultdict(Counter)
    labels_file = 'labels_{}.txt'.format(store)

    with open(labels_file) as f:
        lines = list(f)
        prev_label = None
        for i, line in enumerate(lines):
            time_range, label = line.strip().split()

            # Let's do something simple first
            # Don't update previous label if the none label lasts for no more than 5 seconds
#             if label == 'none':
#                 start_time, end_time = time_range.split('-')
#                 duration = to_time(end_time) - to_time(start_time)
#                 if prev_label:
#                     adjacency_matrix[label][prev_label] += duration
#                     adjacency_matrix[prev_label][label] += duration
#                 prev_label = label

            if prev_label:
                adjacency_matrix[label][prev_label] += 1
                adjacency_matrix[prev_label][label] += 1
            prev_label = label

    for sctn, adjacency_list in adjacency_matrix.items():
        del_list = []
        for nbr_sctn, freq in adjacency_list.items():
            if freq > threshold:
                adjacency_list[nbr_sctn] = 1
            else:
                del_list.append(nbr_sctn)
        for nbr_sctn in del_list:
            del(adjacency_list[nbr_sctn])
        print('{} :\n\t{}\n--'.format(sctn, adjacency_list))



if __name__ == '__main__':
    # construct_adjacency_matrix('wholefood')
    construct_adjacency_matrix('traderjoe', 1)
