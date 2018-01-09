function plot_reduceddata(TDat,Ttruth,PDat,Ptruth)


% true (ground truth) class

distanceMatrix = pdist(TDat,'euclidean');
newCoor = mdscale(distanceMatrix,2);

x = newCoor(:,1);
y = newCoor(:,2);
i = find(Ttruth); % true cases ID

figure; 
scatter(x,y,'filled'); hold on;      % plot all training data
scatter(x(i,:),y(i,:),'filled','r'); % overlay true cases in red

% now the predictions

pdistanceMatrix = pdist(PDat,'euclidean');
newCoorp = mdscale(pdistanceMatrix,2);

xp = newCoorp(:,1);
yp = newCoorp(:,2);
ip = find(Ptruth); % true cases ID

scatter(xp,yp,'b'); hold on;      % plot all training data
scatter(xp(ip,:),yp(ip,:),'r'); % overlay true cases in red

legend({'Training (g1)','Training (G2)','Classif (G1)','Classif (G2)'});