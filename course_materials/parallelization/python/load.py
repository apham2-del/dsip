from os.path import join as oj
import pandas as pd


def load_brca_data(path='data'):
    '''
    Load TCGA breast cancer data
    
    Parameters
    ----------
    path : str
        Path to the data

    Returns
    -------
    pd.DataFrame
        A dataframe with the TCGA breast cancer data
    '''
    brca_data = pd.read_csv(oj(path, 'tcga_brca_array_data_filtered.csv'))
    return brca_data


def load_subtype_data(path='data'):
    '''
    Load TCGA breast cancer subtype data

    Parameters
    ----------
    path : str
        Path to the data

    Returns
    -------
    pd.DataFrame
        A dataframe with the TCGA breast cancer subtype data
    '''
    subtype_data = pd.read_csv(oj(path, 'tcga_brca_subtypes.csv'))
    return subtype_data
