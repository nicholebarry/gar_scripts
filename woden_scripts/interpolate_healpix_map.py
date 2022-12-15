import healpy as hp
import numpy as np
import matplotlib.pyplot as plt
from astropy.io import fits


def interpolate_healpix(data,nside):
    '''Takes a data 1D array of ring ordered pixel values, and interpolates
    them to the given healpix nside. Also returns the integrated flux
    density for each pixel'''
    ##Pixel indexes for given nside
    pixels = np.arange(hp.nside2npix(nside))
    ##coordinates for each pixel
    colatitide,longitude = hp.pix2ang(nside, pixels, nest=False)
    ##use the given data and interpolate to all new coord locations
    new_data = hp.get_interp_val(data, colatitide, longitude, nest=False)

    scale = 1

    ##Find the area and convert
    return new_data

def plot_healpix(data,nside):
    hp.mollview(np.log10(data), nest=False, title='nside %d' %nside)
    plt.savefig('gsm_n%d_moll.png' %nside,bbox_inches='tight')
    plt.close()


nside = 1024
orig_data = hp.read_map('pygdsm_180MHz_MJysr_n1024.fits',nest=False)

print('n%d has %d pixels' %(nside,len(orig_data)))

##Make a histogram plot of all maps to check flux is conserved
fig = plt.figure(figsize=(7,7))
ax_hist = fig.add_subplot(111,xscale='log',yscale='log')

ax_hist.hist(orig_data*hp.nside2resol(nside)**2,histtype='step',label='Total Flux n%d = %.7f MJy/pix num pixels %d' %(nside,sum(orig_data*hp.nside2resol(nside)**2),len(orig_data)), density=True)

##Plot the healpix map to check it makes sense
plot_healpix(orig_data, nside)

##Interpolate the map to nside 2048 and 4096
for nside in [2048]:
    ##Interpolate and write out to healpix fits
    interp_data = interpolate_healpix(orig_data, nside)
    hp.write_map("pygdsm_180MHz_MJysr_n%d.fits" %nside, interp_data, overwrite=True, nest=False)

    ##Plot the healpix map to check it makes sense
    plot_healpix(interp_data, nside)

    ##Check the flux is conserved
    ax_hist.hist(interp_data*hp.nside2resol(nside)**2,histtype='step',label='Total Flux n%d = %.7f MJy/pix num pixels %d' %(nside,sum(interp_data*hp.nside2resol(nside)**2),len(interp_data)), density=True)


##make histogram understandable and save
ax_hist.legend()

ax_hist.set_xlabel('Pixel Flux (Jy/sr)')
ax_hist.set_ylabel('Density')
#
fig.savefig('gdsm_map_fluxes.png',bbox_inches='tight')
