clear
close all
clc
disp("creazione griglia")
pointsPosition = [];
featStep = 10; % TODO: trovare valori ottimi
imsize = 500; % same
for ii = featStep:featStep:imsize-featStep
    for jj = featStep:featStep:imsize-featStep
        pointsPosition = [pointsPosition; jj, ii];
    end
end

%% image pre processing
disp("estrazione feature")
Nim4training = 70; % TODO: fix nel caso di necessità del validation set, prendere da qua per validation
features = [];
labels = [];
tic
for class = 0:9
    for nimage= 0:Nim4training-1
        im = imread(['image.orig\' num2str(100*class+nimage) '.jpg']);
        im = imresize(im,[imsize imsize]); % TODO provare se cambia qualcosa facendo crop invece che stretch (mantieni proporzioni)
        im = im2gray(im);
        [imfeatures,dontcare] = extractFeatures(im,pointsPosition,"Method","SURF");
        features = [features;imfeatures];
        labels = [labels ; repmat(class,size(imfeatures,1),1) repmat(nimage,size(imfeatures,1),1)];
    end
end
toc

%% creazione del vocabolario
disp("kmeans")
k = 100;
tic
[idx,c] = kmeans(features,k);
toc
%% istogrammi BOW training
disp("rappresentazone BOW training")
BOW_tr = [];
labels_tr = [];
tic 
for class = 0:9
    for nimage = 0:Nim4training-1
        u = find(labels(:,1)==class & labels(:,2)==nimage);
        imfeaturesIDX = idx(u);
        h = hist(imfeaturesIDX,1:k);
        h = h./sum(h);
        BOW_tr  = [BOW_tr ; h];
        labels_tr = [labels_tr;class];
    end
end
toc
%% classificatore
% input: BOW_tr e labels_tr
% TODO

%% istogrammi BOW test

disp("rappresentazone BOW test")
BOW_te = [];
labels_te = [];
tic 
for class = 0:9
    for nimage = Nim4training:99
        im = imread(['image.orig\' num2str(100*class+nimage) '.jpg']);
        im = imresize(im,[imsize imsize]); % TODO provare se cambia qualcosa facendo crop invece che stretch (mantieni proporzioni)
        im = im2gray(im);
        [imfeatures,dontcare] = extractFeatures(im,pointsPosition,"Method","SURF");
        
        D = pdist2(imfeatures,c);
        [dontcare,words] = min(D,[],2);
        
        h = hist(words,1:k);
        h = h./sum(h);
        BOW_te  = [BOW_te ; h];
        labels_te = [labels_te;class];
    end
end
toc

%% classificazione del test set
% TODO aggioranre con il nostor vero classificatore
disp("classificatore test set")
predicted_class = [];
tic
for ii = 1:size(BOW_te,1)
    h = BOW_te(ii,:);
    dh = pdist2(h,BOW_tr);
    u = find(dh==min(dh));
    u = u(1);
    predicted_class = [predicted_class; labels_tr(u)];
end
toc

%% misurazione performance

% This calculates, normalizes by row, and displays the chart all in one step
cc = confusionchart(labels_te, predicted_class);
cc.Normalization = 'row-normalized'; 
cc.Title = 'Normalized Confusion Matrix';

avg_accuracy = mean(diag(cc.NormalizedValues), 'omitnan');
disp(['Average Diagonal Accuracy: ', num2str(avg_accuracy * 100), '%']);