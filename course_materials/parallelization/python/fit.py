from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import GridSearchCV
import numpy as np


def fit_rf_loo(i, x, y, **kwargs):
    """
    Fit a random forest model with sample `i` left out

    Parameters:
    -----------
    i: int
        The sample to leave out
    x: np.array
        Covariate matrix
    y: np.array
        Response vector
    **kwargs:
        Arbitrary keyword arguments for RandomForestClassifier

    Returns:
    --------
    str
        Predicted class of the left out sample `i`
    """
    # Remove the ith observation for leave-one-out
    x_train = np.delete(x, i, axis=0)
    y_train = np.delete(y, i)

    # Train the RandomForestClassifier
    rf = RandomForestClassifier(**kwargs)
    rf.fit(x_train, y_train)

    # Make a prediction on the left-out observation
    preds = rf.predict(x[i:(i+1), :])[0]
    return preds


def fit_knn_loo(i, x, y, **kwargs):
    """
    Fit a k-nearest neighbors model with sample `i` left out

    Parameters:
    -----------
    i: int
        The sample to leave out
    x: np.array
        Covariate matrix
    y: np.array
        Response vector
    **kwargs:
        Arbitrary keyword arguments for KNeighborsClassifier

    Returns:
    --------
    str
        Predicted class of the left out sample `i`
    """
    # Remove the ith observation for leave-one-out
    x_train = np.delete(x, i, axis=0)
    y_train = np.delete(y, i)

    # Train KNN and use grid search to find the best hyperparameters
    knn = KNeighborsClassifier(**kwargs)
    knn_grid_search = GridSearchCV(
        knn, 
        param_grid={
            "n_neighbors": [5, 10, 15]
        },
        cv=5
    )
    knn_grid_search.fit(x_train, y_train)
    best_knn = knn_grid_search.best_estimator_

    # Make a prediction on the left-out observation
    preds = best_knn.predict(x[i:(i+1), :])[0]
    return preds