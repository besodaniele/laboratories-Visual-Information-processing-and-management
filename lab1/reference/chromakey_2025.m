im1 = im2double( imread('godzilla_chromakey/godzilla_1.jpg'));
im2 = im2double( imread('godzilla_chromakey/godzilla_2.jpg'));
S1 = size(im1);

imshow(im1)

%%% selezione della(e) regione(i) da usare come modello per il green screen
% - opzione 1: interattiva
% crop = imcrop(im1);
% - opzione 2: dando le coordinate esplicitamente
crop = im1(1:10,1:10,:);
figure(2), imshow(crop)
modello = reshape(crop, [], 3); % <------ TDB! definizione modello
modello = unique(modello,'rows');

im1 = reshape(im1, [], 3);
M = zeros(size(im1));
T = 0.2; % <------ TBD! definizione soglia

%%% calcolo della similarità tra i pixel dell'immagine e quelli del modello
% con ciclo for
tic
for ii=1:size(im1,1)
    d = repmat(im1(ii,:),size(modello,1),1) - modello;
    d = sqrt(sum(d.^2,2)); % euclidean distance
    if min(d)>T
        M(ii,:)=1;
    end
end
tempoFor = toc;

% vettorializzata
M = zeros(size(im1));
tic
d = pdist2(im1, modello);
M(min(d,[],2)>T,:)=1;
tempoVec = toc;

% stampa dei tempi per confronto tra le due versioni
[tempoFor tempoVec]

%%% ricostruzione della maschera e dell'immagine
M = reshape(M, S1);
im1 = reshape(im1, S1);

% visualizzazione
figure(1),clf
subplot(1,3,1), imshow(im1)
subplot(1,3,2), imshow(M)
subplot(1,3,3), imshow(im2)

%%% creazione dell'immagine combinata
im_3 = im1 .* M + im2 .* (1-M);
figure(2), imshow(im_3)
