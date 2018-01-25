mkdir traderjoe_frames; mkdir wholefood_frames;
ffmpeg -i traderjoe.avi -vf fps=1 traderjoe_frames/img%03d.jpg
ffmpeg -i wholefood.avi -vf fps=1 wholefood_frames/img%03d.jpg
