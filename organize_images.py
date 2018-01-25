#!/home/jayant/miniconda3/bin/python

import os
import shutil

"""
Checks whether a directory at a file_path exists or not. If not, creates it.
"""
def ensure_dir(dir_path):
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)


"""
A directory with the same name as the store residing under section_images is populated with labels as the 
subdirectory names.
"""
def organize(store):
    labels_file = 'labels_{}.txt'.format(store)
    from_dir = '{}_frames'.format(store)
    with open(labels_file) as f:
        for line in f.readlines():
            time_range, label = line.strip().split()
            start_time, end_time = time_range.split('-')
            def to_time(s):
                m, s = map(int, s.split(':'))
                return 60*m + s
            start_time, end_time = map(to_time, (start_time, end_time))

            to_dir = 'section_images/{}'.format(label)
            ensure_dir(to_dir)
            for t in range(start_time, end_time+1):
                from_img_file = 'img{:03d}.jpg'.format(t)
                to_img_file = '{}_img_{:03d}.jpg'.format(store, t)
                shutil.copyfile('{}/{}'.format(from_dir, from_img_file), '{}/{}'.format(to_dir, to_img_file))


if __name__ == '__main__':
    shutil.rmtree('section_images/')
    organize('wholefood')
    organize('traderjoe')
