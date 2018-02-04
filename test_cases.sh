#!/bin/bash

# beverages cheese - A
# beverages snacks
# bread cheese
# bread meat
# cereal dairy
# cheese meat
# cheese entrance
# cheese counter
# counter frozenfood - A
# counter pasta
# counter meat - A
# dairy entrance
# flowers health - A
# frozenfood pasta - A
# health bread - A
# health counter - A

# 16 test cases: 7 give asymmetric results



python construct_adjacency_matrix.py beverages cheese
echo ''

python construct_adjacency_matrix.py beverages snacks
echo ''

python construct_adjacency_matrix.py bread cheese
echo ''

python construct_adjacency_matrix.py bread meat
echo ''

python construct_adjacency_matrix.py cereal dairy
echo ''

python construct_adjacency_matrix.py cheese meat
echo ''

python construct_adjacency_matrix.py cheese entrance
echo ''

python construct_adjacency_matrix.py cheese counter
echo ''

python construct_adjacency_matrix.py counter frozenfood
echo ''

python construct_adjacency_matrix.py counter pasta
echo ''

python construct_adjacency_matrix.py counter meat
echo ''

python construct_adjacency_matrix.py dairy entrance
echo ''

python construct_adjacency_matrix.py flowers health
echo ''

python construct_adjacency_matrix.py frozenfood pasta
echo ''

python construct_adjacency_matrix.py health bread
echo ''

python construct_adjacency_matrix.py health counter
echo ''
