import pandas as pd
import numpy as np
import re
from sklearn.preprocessing import OneHotEncoder


def collapse_survey_responses(ling_data, qa_key, min_prop=0.05):
    """
    Collapse rare survey responses into an "other" category

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic data
    qa_key : pd.DataFrame
        The question and answer key
    min_prop : float, optional
        Collapse responses with a proportion less than this value into an "other" category, 
        by default 0.05

    Returns
    -------
    dict
        A dictionary containing the collapsed linguistic data and the updated question-answer key
    """
    # Identify rare responses
    qa_key['answer'] = qa_key['answer'].str.strip()
    qa_key['new_answer'] = np.where(qa_key['percentage'] < (min_prop * 100), 'other', qa_key['answer'])
    qa_key = qa_key.sort_values(by='percentage', ascending=False)
    
    # Update question-answer key to reflect collapsed categories
    collapsed_qa_key = qa_key.copy()
    collapsed_qa_key['answer_num'] = collapsed_qa_key.groupby('qid').cumcount() + 1
    collapsed_qa_key = (
        collapsed_qa_key.groupby(['qid', 'question', 'new_answer'], as_index=False)
        .agg(answer_num=('answer_num', 'min'), percentage=('percentage', 'sum'))
        .rename(columns={'new_answer': 'answer'})
    )

    def collapse_column(column):
        # merge rare responses into the same category/factor
        cur_qid = int(re.sub(r'^Q', '', column.name))
        qid_key = qa_key[qa_key['qid'] == cur_qid]
        collapsed_qid_key = collapsed_qa_key[collapsed_qa_key['qid'] == cur_qid]
        answer_mapping = dict(zip(qid_key['answer_num'], qid_key['new_answer']))
        collapsed_answer_mapping = dict(zip(collapsed_qid_key['answer'], collapsed_qid_key['answer_num']))
        return column.map(answer_mapping).map(collapsed_answer_mapping).fillna(0).astype(int)
    
    collapsed_ling_data = ling_data.copy()
    q_cols = [col for col in ling_data.columns if col.startswith("Q")]
    collapsed_ling_data[q_cols] = ling_data[q_cols].apply(collapse_column)
    
    return {'ling_data': collapsed_ling_data, 'qa_key': collapsed_qa_key}


def one_hot_ling_data(ling_data, remove_zeros=False):
    """
    One-hot encode categorical variables in the linguistic data

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic data
    remove_zeros : bool, optional
        Whether to remove columns corresponding to missing responses, by default False

    Returns
    -------
    pd.DataFrame
        The one-hot encoded linguistic data
    """
    # do one hot encoding
    q_cols = [col for col in ling_data.columns if col.startswith("Q")]
    X = ling_data[q_cols]
    ohe = OneHotEncoder(sparse_output=False)
    X_ohe = ohe.fit_transform(X)

    # add metadata back in
    X_bin = pd.concat([
        ling_data.drop(columns=q_cols).reset_index(drop=True),
        pd.DataFrame(X_ohe, columns=ohe.get_feature_names_out())
    ], axis=1)

    # remove NA columns
    if remove_zeros:
        drop_cols = [col for col in X_bin.columns if col.endswith("_0")]
        X_bin = X_bin.drop(columns=drop_cols)

    return X_bin


def remove_samples(ling_data, min_answers=50):
    """
    Remove samples with too many missing values

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic data
    min_answers : int
        The minimum number of answers required for a sample to be kept

    Returns
    -------
    pd.DataFrame
        The cleaned linguistic data
    """
    q_cols = [col for col in ling_data.columns if col.startswith("Q")]
    X = ling_data[q_cols]
    num_answered = (X != 0).sum(axis=1)
    ling_data = ling_data[num_answered >= min_answers]
    return ling_data


def aggregate_survey_response_by_county(ling_data):
    """
    Aggregate survey responses by county

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic data

    Returns
    -------
    pd.DataFrame
        The aggregated linguistic data. A data frame with one row per county and each column is a question.
        The (i, j) value in this data frame is the most popular response to question j in county i.
    """

    # check if data is one-hot encoded
    q_cols = [col for col in ling_data.columns if col.startswith("Q")]
    is_onehot = np.all(ling_data[q_cols].isin([0, 1]))
    if not is_onehot:
        raise ValueError("Input data must be one-hot encoded to aggregate by county. Run one_hot_ling_data(ling_data) first.")
    if 'county' not in ling_data.columns or 'state' not in ling_data.columns:
        raise ValueError("Input data must have county and state columns. Try running one_hot_ling_data(ling_data) first.")
    
    # aggregate by county
    ling_data_by_county = ling_data.groupby(['county', 'state', 'state_abb'])[["lat", "long"] + q_cols].mean().reset_index()
    return ling_data_by_county