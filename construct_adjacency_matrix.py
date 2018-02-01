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
            'diapers',
            'dressing',
            'entrance',
            'flowers',
            'frozenfood',
            'health',
            'meat',
            'oils',
            'pasta',
            'pets',
            'seafood',
            'snacks',
            'vegetables',
            'water',
            'none'
            ]
    n = len(labels)

    adjacency_matrix = np.zeros((n,n))
    labels_file = 'labels_{}.txt'.format(store)

    with open(labels_file) as f:
        lines = list(f)
        # previous left & right labels
        pll, prl = lines[0].strip().split()[1].split(':')
        for i, line in enumerate(lines[1:]):
            time_range, f_labels = line.strip().split()
            # left right labels for the present frame
            ll, rl = f_labels.split(':')
            # find indexes for each of the labels
            plli, prli, lli, rli = labels.index(pll), labels.index(prl), labels.index(ll), labels.index(rl)

            """
            UPDATES:
            1. Left and right sections in the present frame are related
            2. Left section from the previous frame is related to both the left and right sections in the present frame
            3. Above same for the right frame
            """
            # present left-right
            adjacency_matrix[lli,rli] = adjacency_matrix[rli,lli] = adjacency_matrix[lli,rli] + 1
            # previous left to current left-right
            adjacency_matrix[plli,lli] = adjacency_matrix[lli,plli] = adjacency_matrix[plli,lli] + 1
            adjacency_matrix[plli,rli] = adjacency_matrix[rli,plli] = adjacency_matrix[plli,rli] + 1
            # previous right to current left-right
            adjacency_matrix[prli,lli] = adjacency_matrix[lli,prli] = adjacency_matrix[prli,lli] + 1
            adjacency_matrix[prli,rli] = adjacency_matrix[rli,prli] = adjacency_matrix[prli,rli] + 1

            # Update previous labels
            pll, prl = ll, rl

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
    construct_adjacency_matrix('traderjoe')
