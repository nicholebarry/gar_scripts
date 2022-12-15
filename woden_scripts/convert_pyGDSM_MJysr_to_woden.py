import matplotlib
matplotlib.use("agg")

import healpy as hp
from astropy import units as u
from astropy.coordinates import SkyCoord
from numpy import *
import matplotlib.pyplot as plt
import healpy as hp

def convert_healpix(nside):

    data = hp.read_map('pygdsm_180MHz_MJysr_n%d.fits' %nside,nest=False)

    pix_inds = arange(hp.nside2npix(nside))
    l, b = hp.pix2ang(nside,pix_inds,lonlat=True)

    gal_coords = SkyCoord(l*u.deg, b*u.deg, frame='galactic')

    ra = gal_coords.icrs.ra.value
    dec = gal_coords.icrs.dec.value

    conversion = hp.nside2pixarea(nside)*1e+6

    fluxes = data*conversion

    print(fluxes.max(),fluxes.mean())

    fig = plt.figure(figsize=(10,10))

    vmin = 0.0
    vmax = 0.5

    hp.mollview(fluxes, sub=(2,1,1), fig=fig,
                title='Galactic (Jy / pixel)',min=vmin,max=vmax)

    ax2 = fig.add_subplot(2,1,2)

    ax2.scatter(ra,dec,c=fluxes,marker='.',vmin=vmin,vmax=vmax)

    ax2.plot(266.416833333,-29.0078055556,'ro',mfc='none',label="Where gal centre should be")

    ax2.set_xlabel('RA (deg)')
    ax2.set_ylabel('Dec (deg)')

    ax2.legend(loc='upper left')

    fig.savefig('wodencovert_n%d.png' %nside, bbox_inches='tight')
    plt.close()

    source_ind = 0

    with open('pygdsm_woden-list_180MHz_n%d.txt' %nside,'w') as outfile:
        for ind,flux in enumerate(fluxes):
            if source_ind == 0:
                outfile.write('SOURCE pyGDSM P %d G 0 S 0 0\n' %len(fluxes))

            outfile.write('COMPONENT POINT %.12f %.12f\n' %(ra[ind]/15.0,dec[ind]))
            outfile.write('LINEAR 180e+6 %.12f 0 0 0 -2.5\n' %flux)
            outfile.write('ENDCOMPONENT\n')

            source_ind += 1

        outfile.write('ENDSOURCE')

if __name__ == '__main__':

    # #for nside in [1024,2048,4096]:
    for nside in [2048]:
        convert_healpix(nside)
