mkdir traderjoe_frames; rm -rf traderjoe_frames/*;
mkdir wholefood_frames; rm -rf wholefood_frames/*;
ffmpeg -i traderjoe.avi -start_number 0 -vf fps=1 traderjoe_frames/img%05d.jpg
ffmpeg -i wholefood.avi -start_number 0 -vf fps=1 wholefood_frames/img%05d.jpg
