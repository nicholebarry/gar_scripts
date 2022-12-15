from pygdsm import GlobalSkyModel, GlobalSkyModel2016
import pygdsm
print(pygdsm.__path__)

gsm = GlobalSkyModel2016(freq_unit='MHz', data_unit='MJysr')
gsm.generate(180)
gsm.write_fits("pygdsm_180MHz_MJysr_n1024.fits")
