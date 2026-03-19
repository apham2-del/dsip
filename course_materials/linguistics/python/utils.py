import numpy as np


def get_X_matrix(ling_data):
    """
    Get a numeric X matrix from the linguistics data

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic data

    Returns
    -------
    np.ndarray
        The numeric X matrix
    """
    q_cols = [col for col in ling_data.columns if col.startswith("Q")]
    return ling_data[q_cols]


def get_answers(x, qid, qa_key):
    """
    Convert numeric answers to text

    Parameters
    ----------
    x : np.ndarray
        The numeric answers
    qid : int
        The question ID
    qa_key : pd.DataFrame
        The question and answer key

    Returns
    -------
    np.ndarray
        The text answers
    """
    qid_key = qa_key[qa_key['qid'] == qid]
    out = []
    for ans in x:
        if ans == 0:
            out.append(np.nan)
        else:
            out.append(qid_key[qid_key['answer_num'] == ans]['answer'].values[0])
    return np.array(out)


def get_location(ling_data, what, show_contiguous_us=True):
    """
    Extract latitude/longitude

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic data
    what : str
        What to extract (latitude or longitude)
    show_contiguous_us : bool, optional
        Whether to show only the contiguous US, by default True

    Returns
    -------
    pd.DataFrame
        The location data
    """
    assert what in ['lat', 'long'], "what must be 'lat' or 'long'"
    location = ling_data[what].copy()
    if show_contiguous_us:
        location[ling_data['lat'] > 130] = np.nan
        location[ling_data['lat'] > 130] = np.nan
    return location