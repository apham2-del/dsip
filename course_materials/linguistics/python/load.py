import pandas as pd


def load_q_and_a_key(path = "../data"):
    """
    Load the question and answer key from the given path.
    """
    # Load the question and answer key
    q_and_a_key = pd.read_csv(f"{path}/q_and_a_key.csv")
    return q_and_a_key


def load_ling_data(path = "../data"):
    """
    Load the linguistic data from the given path.
    """
    # Load the linguistic data
    ling_data = pd.read_csv(
        f"{path}/ling_data.csv",
        # make explicit that the ZIP column should be read as a character
        # # (default would've been to load ZIP in as numeric; this may drop the leading 0s)
        dtype={"ZIP": str}
    )
    return ling_data