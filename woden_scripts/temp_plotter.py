import healpy as hp
from astropy import units as u
from astropy.coordinates import SkyCoord
from numpy import *
import numpy as np
import matplotlib.pyplot as plt
import healpy as hp
from astropy.io import fits

with fits.open('gsm_182mhz_Jysr_nomono_nogalaxy_2048.fits') as hdu:
    data = hdu[0].data

with fits.open('gsm2016_182MHz_nomono_nogalaxyinterp2048_subset_try2_inds.fits') as hdu:
    pix_inds = hdu[0].data

nside=2048
#pix_inds = arange(hp.nside2npix(nside))
l, b = hp.pix2ang(nside,pix_inds,lonlat=True)
gal_coords = SkyCoord(l*u.deg, b*u.deg, frame='galactic')
ra = gal_coords.icrs.ra.value
dec = gal_coords.icrs.dec.value
#conversion = hp.nside2pixarea(nside)

with fits.open('byrne_interp2048_I.fits') as hdu:
    data_b = hdu[0].data

with fits.open('byrne_interp2048_inds.fits') as hdu:
    pix_inds_b = hdu[0].data

l, b = hp.pix2ang(nside,pix_inds_b,lonlat=True)
cel_coords = SkyCoord(l*u.deg, b*u.deg, frame='icrs')
ra_b = cel_coords.icrs.ra.value
dec_b = cel_coords.icrs.dec.value


#k_boltz = 1.38064852e-23
#vel_c = 299792458.0
#freq=182e6
#Jystr = (1e23*2*freq**2*k_boltz) / vel_c**2
conversion = hp.nside2pixarea(nside)# * Jystr

fluxes = data*conversion
fluxes_b = data_b*conversion
print(np.abs(fluxes).max(),np.abs(fluxes).mean())


fig = plt.figure(figsize=(10,10))
vmin = -0.1
vmax = 0.1

hp.mollview(fluxes, sub=(2,1,1), fig=fig,title='Galactic (Jy / pixel)',min=vmin,max=vmax)
ax2 = fig.add_subplot(2,1,2)
ax2.scatter(ra,dec,c=fluxes[pix_inds],marker='.',vmin=vmin,vmax=vmax)
ax2.scatter(ra_b,dec_b,c=fluxes_b,marker='.',vmin=vmin,vmax=vmax)
ax2.plot(266.416833333,-29.0078055556,'ro',mfc='none',label="Where gal centre should be")
ax2.set_xlabel('RA (deg)')
ax2.set_ylabel('Dec (deg)')
ax2.legend(loc='upper left')

fig.savefig('pygdsm_nomono_nogalaxy_n2048.png',bbox_inches='tight')
plt.close()


#inds = np.argwhere(b > 0)
#false_b = b.copy()
#false_b[inds] = (b[inds]-180.)
#false_b = false_b + 90.

longitude = 0 * u.deg
latitude = -90 * u.deg
rot_custom = hp.Rotator(rot=[longitude.to_value(u.deg), latitude.to_value(u.deg)], inv=True)
fluxes_rotated_alms = rot_custom.rotate_map_alms(fluxes)

hp.mollview(fluxes_rotated_alms, sub=(2,1,1), fig=fig,title='Galactic (Jy / pixel)',min=vmin,max=vmax)
ax2 = fig.add_subplot(2,1,2)
ax2.scatter(l,b,c=fluxes_rotated_alms,marker='.',vmin=vmin,vmax=vmax)
ax2.set_xlabel('Lat (deg)')
ax2.set_ylabel('90deg rotated Lon (deg)')
fig.savefig('falselon_pygdsm_nomono_nogalaxy_n2048.png',bbox_inches='tight')
plt.close()

center_patch_inds = np.argwhere((l > 170) & (l < 190) & (b > -10) & (b < 10))
center_patch = fluxes_rotated_alms[center_patch_inds]
rotated_lonlat = rot_custom(l,b,lonlat=True)
center_patch_latlon = rotated_lonlat[:,center_patch_inds]

hdu = fits.PrimaryHDU(center_patch)
hdu.writeto('center_patch_1024.fits', clobber=True)
hdu = fits.PrimaryHDU(l[center_patch_inds])
hdu.writeto('center_patch_lat_1024.fits', clobber=True)
hdu = fits.PrimaryHDU(b[center_patch_inds])
hdu.writeto('center_patch_lon_1024.fits', clobber=True)



