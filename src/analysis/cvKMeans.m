function [c, mu, distortionValue, k] = cvKMeans(X, kRange, method)
% Use
%   Implementation of k-means with k-fold or hold-out cross-validation to 
%   determine the best number of clusters to use within user-input range.
% Input
%   X : m-samples training set, where each row is a sample feature vector
%   kRange : range of k-values for cross-validation
%   method : string indicating either k-fold ('kfold') or hold-out 
%            ('holdout') cross validation method
% Output
%   c : cluster labels for each point
%   mu : cluster centroid positions, where each column is a centroid
%   distortionValue: distortion function value
%   k : best k-value out of kRange

    % constants
    KFOLD = 'kfold';
    HOLDOUT = 'holdout';

    % check arguments
    if sum(kRange < 1) > 0
        error('Error: kRange must only contain positive integers');
    elseif ~strcmp(method, KFOLD) && ~strcmp(method, HOLDOUT)
        error('Error: method can only be kfold or holdout');
    end % if
    
    % run cross-validation
    if strcmp(method, KFOLD)
        [c, mu, distortionValue, k] = kfold(X, kRange);
    else % strcmp(method, HOLDOUT)
        [c, mu, distortionValue, k] = holdout(X, kRange);
    end % if
    
end


function [c, mu, distortionValue, k] = holdout(X, kRange)
% Use
%   Implementation of k-means with hold-out cross-validation to determine
%   the best number of clusters to use within user-input range.
% Input
%   X : m-samples training set, where each row is a sample feature vector
%   kRange : range of k-values for cross-validation
% Output
%   c : cluster labels for each point
%   mu : cluster centroid positions, where each column is a centroid
%   distortionValue: distortion function value
%   k : best k-value out of kRange

    % constants
    TRAIN_PROP = 0.7;
    NRESTARTS = 10;
    NDATA = size(X, 1);
    
    % initialization
    bestDistortion = inf;
    
    % randomly split X to train and test sets
    nTrain = floor(TRAIN_PROP * NDATA);
    perm = randperm(NDATA);
    Xperm = X(perm, :);
    XTrain = Xperm(1:nTrain, :);
    XTest = Xperm(nTrain + 1:end, :);
    
    % try all k-values
    for kNew = kRange
        
        % train and test centroids
        [~, muNew, ~] = myKMeans(XTrain, kNew, NRESTARTS);
        cNew = getLabels(XTest, muNew);
        newDistortion = distortion(XTest, cNew, muNew);
        
        if newDistortion < bestDistortion
            k = kNew;
            bestDistortion = newDistortion;
        end % if
        
    end % for kNew

    % return k-means result using best k-value
    [c, mu, distortionValue] = myKMeans(X, k, NRESTARTS);
    
end


function c = getLabels(X, mu)
% Use
%   Assign data points to closest centroids.
% Input
%   X : m-samples training set, where each row is a sample feature vector
%   mu : cluster centroid positions, where each column is a centroid
% Output
%   c : cluster labels for each point

    % constants
    NDATA = size(X, 1);

    c = zeros(NDATA, 1);
    for data = 1:NDATA
        diff = repmat(X(data, :)', 1, size(mu, 2)) - mu;
        [~, c(data)] = min(norms(diff, 2));
    end % for data

end


function distortion = distortion(X, c, mu)
% Use
%   Computes the distortion function value.
% Input
%   X : m-samples training set, where each row is a sample feature vector
%   c : cluster labels for each point
%   mu : cluster centroid positions, where each column is a centroid
% Output
%   distortion : distortion function value

    if c(1) < 0
        distortion = inf;
    else
        distortion = sum(norms(X' - mu(:, c), 2)) ^ 2;
    end % if

end


function [c, mu, distortionValue, k] = kfold(X, kRange)
% Use
%   Implementation of k-means with k-fold cross-validation to determine the
%   best number of clusters to use within user-input range.
% Input
%   X : m-samples training set, where each row is a sample feature vector
%   kRange : range of k-values for cross-validation
% Output
%   c : cluster labels for each point
%   mu : cluster centroid positions, where each column is a centroid
%   distortionValue: distortion function value
%   k : best k-value out of kRange

    % constants
    KFOLD = 10;
    NRESTARTS = 10;
    NDATA = size(X, 1);
    
    % randomly split X into KFOLD disjoint subsets
    assignments = randi(KFOLD, NDATA, 1);
    
    % initialization
    bestMeanDistortion = inf;
    
    % try all k-values
    for kNew = kRange
        
        distortions = zeros(KFOLD, 1);
        for kfold = 1:KFOLD
            
            XTrain = X(assignments ~= kfold, :);
            XTest = X(assignments == kfold, :);
            
            [~, muNew, ~] = myKMeans(XTrain, kNew, NRESTARTS);
            cNew = getLabels(XTest, muNew);
            distortions(kfold) = distortion(XTest, cNew, muNew);
            
        end % for kfold
        
        if mean(distortions) < bestMeanDistortion
            k = kNew;
            bestMeanDistortion = mean(distortions);
        end % if
        
    end % for kNew
    
    % return k-means result using best k-value
    [c, mu, distortionValue] = myKMeans(X, k, NRESTARTS);

end