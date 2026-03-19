import numpy as np


def apply_log_transform(data):
    """
    Apply log transformation log(x + 1) to data

    Parameters:
    -----------
    data: np.array
        Data to apply log transformation

    Returns:
    --------
    np.array
        Log transformed data
    """
    log_data = np.log1p(data)
    return log_data