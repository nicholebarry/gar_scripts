import pyvo as vo
import pandas as pd
import sys
import numpy as np
# csv file with 1 obsid on each line
check = pd.read_csv(sys.argv[-1], header=None, names=['obs_id'])
tap = vo.dal.TAPService("http://vo.mwatelescope.org/mwa_asvo/tap")
for index, obs_id in enumerate(check['obs_id']):
    if index == 0:
        all_obs = tap.search(f"""
        SELECT obs_id, projectid, dataquality, deleted_flag, total_archived_data_bytes/1024/1024/1024 as size_gb
        FROM mwa.observation
        WHERE obs_id = {obs_id}
        AND total_archived_data_bytes > 1*1024*1024 -- more than a metafits
        AND deleted_flag != 'TRUE' -- not deleted
        AND projectid = 'G0009' -- optionally speed this up by only looking at eor obsids
        """).to_table().to_pandas()
    else:
        cur_obs = tap.search(f"""
        SELECT obs_id, projectid, dataquality, deleted_flag, total_archived_data_bytes/1024/1024/1024 as size_gb
        FROM mwa.observation
        WHERE obs_id = {obs_id}
        AND total_archived_data_bytes > 1*1024*1024 -- more than a metafits
        AND deleted_flag != 'TRUE' -- not deleted
        AND projectid = 'G0009' -- optionally speed this up by only looking at eor obsids
        """).to_table().to_pandas()
        all_obs = pd.concat([all_obs, cur_obs], ignore_index=True)
matched_obs = check.merge(all_obs, on='obs_id')
matched_obs['obs_id'].to_csv(sys.stdout, index=False, header=False)
