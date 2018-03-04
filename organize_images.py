import os
import shutil
import argparse

"""
Checks whether a directory at a file_path exists or not. If not, creates it.
"""
def ensure_dir(dir_path):
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)


def copy_file(fname, label_type, label):
    from_dir = 'image'
    to_dir = 'organized/{}/{}'.format(label_type, label)
    ensure_dir(to_dir)
    shutil.copyfile('{}/{}'.format(from_dir, fname), '{}/{}'.format(to_dir, fname))


def copy_files(start_frame, end_frame, llabel, rlabel):
    for frame_num in range(start_frame, end_frame+1):
        fname = 'image{:07d}.jpg'.format(frame_num)
        copy_file(fname, 'left', llabel)
        copy_file(fname, 'right', rlabel)


"""
A directory with the same name as the store residing under section_images is populated with labels as the 
subdirectory names.
"""
def organize(store):
    ending_times = { 'traderjoe': 682, 'wholefood': 302 }
    labels_file = 'labels_{}.txt'.format(store)
    rate = 25
    k = rate//2
    with open(labels_file) as f:
        lines = list(f)[:10]

    _, labels = lines[0].strip().split()
    start_frame = 1
    llabel, rlabel = labels.split(':')
    for i in range(1,len(lines)):
        end, labels = lines[i].strip().split()
        m, s = map(int, end.split(':'))
        end = 60*m + s
        end_frame = end*rate - rate//2

        copy_files(start_frame, end_frame-1, llabel, rlabel)
        llabel, rlabel = labels.split(':')
        start_frame = end_frame

    end_frame = ending_times[store] * rate
    copy_files(start_frame, end_frame, llabel, rlabel)


if __name__ == '__main__':
#     parser = argparse.ArgumentParser()
#         parser.add_argument(
#             '--image_dir',
#             type=str,
#             default=1,
#             help='Path to folders of labeled images.'
#         )
    if os.path.exists('organized'):
        shutil.rmtree('organized')
    organize('traderjoe')
    # organize('wholefood')
