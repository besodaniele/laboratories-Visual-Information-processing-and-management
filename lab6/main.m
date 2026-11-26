clear
close all
clc
net = alexnet;
analyzeNetwork(net);

%% 
sz = net.Layers(1).InputSize;
indir = 'image.orig/';

layers = ["conv2","conv5","fc8"]; 
Nim4tr = 70;

for layer=1:numel(layers)

    fprintf('testando layer %s\n', layers(layer));
    %% estrazione feature train
    feat_tr = [];
    labels_tr = [];
    %% estrazione feature train
    fprintf('estrazione feature training\n');
    tic
    for class = 0:9
        for nimage = 0:Nim4tr-1
            im = double(imread([indir num2str(100*class+nimage) '.jpg']));
            im = imresize(im,sz(1:2));
            feat_tmp = activations(net,im,layers(layer),"OutputAs","rows");
            feat_tr = [feat_tr ; feat_tmp]; % TODO: sottocampionamento perché sennò non ci sta in memoria, prova tutto a 4096
            labels_tr = [labels_tr ; class];
        end
    end
    toc
    %% estrazione feature test
    fprintf('estrazione feature test\n');
    feat_te = [];
    labels_te = [];
    tic
    for class = 0:9
        for nimage = Nim4tr:99
            im = double(imread([indir num2str(100*class+nimage) '.jpg']));
            im = imresize(im,sz(1:2));
            feat_tmp = activations(net,im,layers(layer),"OutputAs","rows");
            feat_te = [feat_te ; feat_tmp];
            labels_te = [labels_te ; class];
        end
    end
    toc
    %% normalizzazione features

    feat_tr_norm = feat_tr ./ sqrt(sum(feat_tr .^2,2));
    feat_te_norm = feat_te ./ sqrt(sum(feat_te .^2,2));

    %% classificazione con 1-NN
    D = pdist2(feat_te,feat_tr);
    [dummy,idx_pred_te] = min(D,[],2);
    lab_pred_te = labels_tr(idx_pred_te);
    acc = numel(find(lab_pred_te == labels_te))/numel(labels_te);
    fprintf('finished with accuracy %.4f for layer %s with non normalized features\n', acc, layers(layer));
    %% classificazione con 1-NN
    D = pdist2(feat_te_norm,feat_tr_norm);
    [dummy,idx_pred_te] = min(D,[],2);
    lab_pred_te = labels_tr(idx_pred_te);
    acc = numel(find(lab_pred_te == labels_te))/numel(labels_te);
    fprintf('finished with accuracy %.4f for layer %s with normalized features\n', acc, layers(layer));

end