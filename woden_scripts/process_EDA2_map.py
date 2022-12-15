

import healpy as hp
map_fits='EDA2_159MHz_I_wPrior_HPXbin.fits'
SI_fits='EDA2prior159_Haslam408_SI_HPXbin.fits'
map_EDA = hp.read_map(map_fits)
mono = hp.pixelfunc.remove_monopole(map_EDA, nest=False, gal_cut=0, copy=True, verbose=True)
di = hp.pixelfunc.remove_dipole(map_EDA, nest=False, gal_cut=0, copy=True, verbose=True)

mono_up = hp.pixelfunc.ud_grade(mono,2048,order_in='RING')
di_up = hp.pixelfunc.ud_grade(di,2048,order_in='RING')

si_EDA = hp.read_map(SI_fits)
missing_inds = np.argwhere(si_EDA < 1)
reshaped_missing_inds = missing_inds.reshape(missing_inds.size)

from astropy.coordinates import SkyCoord
from astropy import units as u
from numpy import *
pix_inds_subset = arange(hp.nside2npix(512))
l, b = hp.pix2ang(512,pix_inds_subset,lonlat=True)
cel_coords = SkyCoord(l*u.deg, b*u.deg, frame='icrs')
ra_subset = cel_coords.icrs.ra.value
dec_subset = cel_coords.icrs.dec.value

ra_holes = ra_subset[reshaped_missing_inds]
dec_holes = dec_subset[reshaped_missing_inds]
end_holes_inds = np.argwhere((np.abs(np.diff(ra_holes)) > 1.5) & (np.abs(np.diff(dec_holes)) > 0))
start_holes_inds = [[0],end_holes_inds+1]


from astropy.io import fits
outfile = 'EDA2_159MHz_I_wPriori_mono_2049.fits'
hdu = fits.PrimaryHDU(mono_up)
hdu.writeto(outfile, clobber=True)
outfile = 'EDA2_159MHz_I_wPriori_di_2049.fits'
hdu = fits.PrimaryHDU(di_up)
hdu.writeto(outfile, clobber=True)
