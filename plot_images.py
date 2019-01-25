# coding: utf-8
def imscatter(features, images, ax, zoom=0.1):
    flag = False
    x = features[:,0]
    y = features[:,1]
    x,y = np.atleast_1d(x,y)
    for i in range(len(x)):
        x0 = x[i]
        y0 = y[i]
        image = images[i]
        im = plt.imread('images/{}_border.jpg'.format(image))
        if flag or random.uniform(0,1) > 0.3:
            im = OffsetImage(im, zoom=zoom)
        else:
            flag = True
            im = OffsetImage(im, zoom=0.1)
        ab = AnnotationBbox(im, (x0,y0), xycoords='data', frameon=False)
        ax.add_artist(ab)
    ax.update_datalim(np.column_stack([x,y]))
    ax.autoscale()
    
fig, ax = plt.subplots()
for i,cat in enumerate(cats):
    cat_files = random.sample(codebook_labels[cat], 20)
    cat_features = np.array([codebook[file] for file in cat_files])
    pca_features = pca_cnn.transform(cat_features)
    cat_files = [ '{}/{}'.format(cat,file) for file in cat_files ]
    imscatter(pca_features, cat_files, ax, zoom=0.03)
    ax.scatter(pca_features[:,0], pca_features[:,1])


for i,cat in enumerate(cats):    
    cat_files = codebook_labels[cat]
    cat_features = np.array([codebook[file] for file in cat_files])
    pca_features = pca_cnn.transform(cat_features)
    plt.scatter(pca_features[:,0], pca_features[:,1], c=hex_colors[i], marker='.')
plt.show()
