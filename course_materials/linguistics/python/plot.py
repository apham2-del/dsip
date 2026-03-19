import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import seaborn as sns
import geopandas as gpd


def plot_ling_map(ling_data, qa_key, qid, point_size=1,
                  show_contiguous_us=True, ax=None):
    """
    Plot linguistic survey results on US map

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic data
    qa_key : pd.DataFrame
        The question and answer key
    qid : int
        The question ID to plot
    point_size : float, optional
        The size of the points on the map, by default 0.5
    show_contiguous_us : bool, optional
        Whether to show only the contiguous US, by default True
    ax : matplotlib.axes.Axes, optional
        The axes to plot on, by default None
    """

    # Format question column based on qid
    if qid < 100:
        qcol = f"Q0{qid}"
    else:
        qcol = f"Q{qid}"
    
    # Merge on answer_num and qcol
    qid_key = qa_key[qa_key['qid'] == qid]
    plt_df = ling_data.merge(qid_key, left_on=qcol, right_on='answer_num', how='left')
    
    # Filter out non-contiguous states if needed
    if show_contiguous_us:
        plt_df = plt_df[~plt_df['state_abb'].isin(['HI', 'AK'])]
    
    # Set up the map
    if ax is None:
        fig, ax = plt.subplots(figsize=(10, 8), subplot_kw={'projection': ccrs.PlateCarree()})
    
    # ax.add_feature(cfeature.BORDERS, linestyle=':')
    # ax.add_feature(cfeature.COASTLINE)
    ax.add_feature(cfeature.STATES, edgecolor='black')

    # Make colormap
    unique_answers = plt_df['answer'].unique()
    # palette = sns.color_palette("viridis", len(unique_answers))
    # color_map = dict(zip(unique_answers, palette))
    if len(unique_answers) <= 10:
        color_map = dict(zip(unique_answers, plt.cm.tab10.colors))
    else:
        color_map = dict(zip(unique_answers, plt.cm.tab20.colors))
    plt_df['color'] = plt_df['answer'].map(color_map)

    # Plot the data
    ax.scatter(plt_df['long'], plt_df['lat'], 
               c=plt_df['color'], s=point_size, 
               transform=ccrs.PlateCarree())
    
    # Add legend
    for answer, color in color_map.items():
        ax.scatter([], [], c=[color], label=answer)
    ax.legend(title="Answer", loc='center left', bbox_to_anchor=(1, 0.5))

    # Add title and labels
    ax.set_title(f"{qcol}: {qid_key['question'].values[0]}")

    return plt


def plot_ling_map_by_county(ling_data, qa_key, qid, 
                            linewidth=0.1, show_contiguous_us=True, ax=None):
    """
    Plot linguistic survey results, aggregated by county

    Parameters
    ----------
    ling_data : pd.DataFrame
        The linguistic survey data
    qa_key : pd.DataFrame
        The question and answer key
    qid : int
        The question ID
    linewidth : float, optional
        The width of the county borders, by default 0.1
    show_contiguous_us : bool, optional
        Whether to show only the contiguous US, by default True
    ax : matplotlib.axes.Axes, optional
        The axes to plot on, by default None
    """
    # Load county boundaries data from Geopandas
    map_df = gpd.read_file(
        'https://raw.githubusercontent.com/holtzy/The-Python-Graph-Gallery/master/static/data/US-counties.geojson'
    )
    state_df = pd.read_csv(
        'https://raw.githubusercontent.com/ChuckConnell/articles/refs/heads/master/fips2county.tsv',
        sep='\t',
        dtype={'StateFIPS': str}
    )[["StateFIPS", "StateAbbr"]].drop_duplicates()
    map_df = map_df.merge(state_df, how='left', left_on='STATE', right_on='StateFIPS')
    map_df["NAME"] = map_df["NAME"].str.lower()
    
    # Format question ID
    if qid < 100:
        qcol = f"Q0{qid}"
    else:
        qcol = f"Q{qid}"
    
    if show_contiguous_us:
        # Remove Hawaii and Alaska and Puerto Rico
        map_df = map_df[~map_df['StateAbbr'].isin(["HI", "AK"]) & ~map_df['StateAbbr'].isna()]
        ling_data = ling_data[~ling_data['state_abb'].isin(["HI", "AK"])]
    
    # Get responses for the question of interest
    qid_key = qa_key[qa_key['qid'] == qid]
    
    # Clean county names to match map data
    ling_data.loc[:, 'county'] = ling_data.loc[:, 'county'].str.replace(" parish", "").str.lower()
    
    # Merge with question key
    plt_df = ling_data.merge(qid_key, how='left', left_on=qcol, right_on='answer_num')
    plt_df = plt_df.dropna(subset=['answer'])
    
    # Aggregate responses by county
    plt_df = plt_df.groupby(['county', 'state_abb'])['answer'].agg(lambda x: x.value_counts().idxmax()).reset_index()
    
    # Merge with map data
    plt_df = map_df.merge(plt_df, how='left', left_on=['NAME', 'StateAbbr'], right_on=['county', 'state_abb'])
    
    # Plot the map
    if ax is None:
        fig, ax = plt.subplots(1, 1, figsize=(10, 6))
    plt_df.boundary.plot(ax=ax, linewidth=linewidth, color='black')
    plt_df.plot(column='answer', ax=ax, legend=True, edgecolor='black', linewidth=linewidth)
    leg = ax.get_legend()
    leg.set_bbox_to_anchor((1.05, 0.5))
    ax.set_title(f"{qcol}: {qid_key['question'].values[0]}")
    ax.axis('off')

    return plt


def plot_dr_scatter(X, components=[0, 1], color=None, 
                    point_size=1, point_alpha=1, color_label=None):
    """
    Plot dimension reduction results as scatter plot

    Parameters
    ----------
    X : np.ndarray
        The data matrix with scores to plot
    components : list, optional
        List of components to plot, by default [0, 1]
    color : np.ndarray, optional
        A vector to use for coloring data points, by default None
    point_size : float, optional
        The size of the points, by default 0.5
    point_alpha : float, optional
        The transparency of the points, by default 1
    """
    if len(components) == 2:
        # plot 2d scatter plot
        x_var = X.columns[components[0]]
        y_var = X.columns[components[1]]
        if color is None:
            plt.scatter(X[x_var], X[y_var], s=point_size)
        else:
            # if numeric, use viridis
            if np.issubdtype(color.dtype, np.number):
                plt.scatter(X[x_var], X[y_var], c=color, s=point_size, alpha=point_alpha, cmap='magma')
                plt.colorbar(label=color_label)
            else:
                # Make colormap
                unique_answers = np.unique(color)
                palette = sns.color_palette("magma", len(unique_answers))
                color_map = dict(zip(unique_answers, palette))
                color = [color_map[c] for c in color]
                plt.scatter(X[x_var], X[y_var], c=color, s=point_size, alpha=point_alpha)
                # Add legend
                for answer, color in color_map.items():
                    plt.scatter([], [], c=[color], label=answer)
                plt.legend(title=color_label, loc='center left', bbox_to_anchor=(1, 0.5))

        plt.xlabel(x_var)
        plt.ylabel(y_var)
    else:
        # plot pair plot
        sns.pairplot(X[X.columns[components]], hue=color, palette='magma', diag_kind='kde', plot_kws={'alpha': point_alpha, 's': point_size})

    plt.show()


def plot_dr_map(X, ling_data, components=[0, 1], 
                point_size=1, point_alpha=1,
                by_county=False, show_contiguous_us=True):
    """
    Plot dimension reduction results on US map

    Parameters
    ----------
    X : np.ndarray
        The data matrix with scores to plot
    ling_data : pd.DataFrame
        The linguistic data
    components : list, optional
        List of components to plot, by default [0, 1]
    point_size : float, optional
        The size of the points on the map, by default 0.5
    point_alpha : float, optional
        The transparency of the points, by default 1
    by_county : bool, optional
        Whether to plot by county, by default False
    show_contiguous_us : bool, optional
        Whether to show only the contiguous US, by default True
    """
    
    # Merge with ling_data
    ling_cols = [col for col in ling_data.columns if col in ["ZIP", "state_abb", "state", "city", "lat", "long", "county"]]
    plt_df = pd.concat([X, ling_data[ling_cols]], axis=1)
    
    # Filter out non-contiguous states if needed
    if show_contiguous_us:
        plt_df = plt_df[~plt_df['state_abb'].isin(['HI', 'AK'])]
    
    if by_county:
        # Load county boundaries data from Geopandas
        map_df = gpd.read_file(
            'https://raw.githubusercontent.com/holtzy/The-Python-Graph-Gallery/master/static/data/US-counties.geojson'
        )
        state_df = pd.read_csv(
            'https://raw.githubusercontent.com/ChuckConnell/articles/refs/heads/master/fips2county.tsv',
            sep='\t',
            dtype={'StateFIPS': str}
        )[["StateFIPS", "StateAbbr"]].drop_duplicates()
        map_df = map_df.merge(state_df, how='left', left_on='STATE', right_on='StateFIPS')
        map_df["NAME"] = map_df["NAME"].str.lower()
        if show_contiguous_us:
            map_df = map_df[~map_df['StateAbbr'].isin(["HI", "AK"]) & ~map_df['StateAbbr'].isna()]
        
        # Clean county names to match map data
        plt_df.loc[:, 'county'] = plt_df.loc[:, 'county'].str.replace(" parish", "").str.lower()
        
        # Aggregate responses by county
        plt_df = plt_df.groupby(['county', 'state_abb'])[X.columns].agg(lambda x: np.mean(x)).reset_index()
        
        # Merge with map data
        plt_df = map_df.merge(plt_df, how='left', left_on=['NAME', 'StateAbbr'], right_on=['county', 'state_abb'])
        
        # Plot the county map
        fig, ax = plt.subplots(len(components), figsize=(10, 6))
        for i, comp in enumerate(components):
            plt_df.boundary.plot(ax=ax[i], linewidth=0.1, color='black')
            plt_df.plot(column=X.columns[comp], ax=ax[i], legend=True, edgecolor='black', linewidth=0.1, cmap='magma')
            ax[i].set_title(X.columns[comp])
            ax[i].axis('off')

    else:
        # Plot the map
        fig, ax = plt.subplots(len(components), figsize=(10, 8), subplot_kw={'projection': ccrs.PlateCarree()})
        for i, comp in enumerate(components):
            ax[i].add_feature(cfeature.STATES, edgecolor='black')
            scatter = ax[i].scatter(plt_df['long'], plt_df['lat'], c=plt_df[X.columns[comp]], s=point_size, alpha=point_alpha, transform=ccrs.PlateCarree(), cmap='magma')
            cbar = plt.colorbar(scatter, ax=ax[i])
            cbar.set_label(X.columns[comp])

    plt.show()