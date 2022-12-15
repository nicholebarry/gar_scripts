import healpy as hp
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt

import healpy as hp
from astropy import units as u
from astropy.coordinates import SkyCoord
from numpy import *
import numpy as np
import matplotlib.pyplot as plt
import healpy as hp
from astropy.io import fits

k_boltz = 1.38064852e-23
vel_c = 299792458.0

def read_in_diffuse(filename_dataI, filename_dataQ, filename_dataU, filename_dataV, filename_data_subset, filename_inds, filename_inds_subset, nside=2048, nside_subset=2048):

    with fits.open(filename_dataI) as hdu:
        dataI = hdu[0].data
    with fits.open(filename_dataQ) as hdu:
        dataQ = hdu[0].data
    with fits.open(filename_dataU) as hdu:
        dataU = hdu[0].data
    with fits.open(filename_dataV) as hdu:
        dataV = hdu[0].data
    with fits.open(filename_data_subset) as hdu:
        data_subset = hdu[0].data

    with fits.open(filename_inds) as hdu:
        pix_inds = hdu[0].data
    with fits.open(filename_inds_subset) as hdu:
        pix_inds_subset = hdu[0].data

    #Outputs from pygdsm are in galactic coordinates
    pix_inds_subset = arange(hp.nside2npix(nside))
    l, b = hp.pix2ang(nside_subset,pix_inds_subset,lonlat=True)
    #gal_coords = SkyCoord(l*u.deg, b*u.deg, frame='galactic')
    #ra_subset = gal_coords.icrs.ra.value
    #dec_subset = gal_coords.icrs.dec.value 
    cel_coords = SkyCoord(l*u.deg, b*u.deg, frame='icrs')
    ra_subset = cel_coords.icrs.ra.value
    dec_subset = cel_coords.icrs.dec.value 

    l = cel_coords.galactic.l.value
    b = cel_coords.galactic.b.value
    galactic_plane_inds = np.argwhere((b < 25) & (b > -25))
    ra_subset = ra_subset[galactic_plane_inds]
    dec_subset = dec_subset[galactic_plane_inds]
    data_subset = data_subset[galactic_plane_inds]


    #Byrne map is in celestial icrs coordinates
    l, b = hp.pix2ang(nside,pix_inds,lonlat=True)
    cel_coords = SkyCoord(l*u.deg, b*u.deg, frame='icrs')
    ra = cel_coords.icrs.ra.value
    dec = cel_coords.icrs.dec.value

    return dataI, dataQ, dataU, dataV, data_subset, ra, dec, ra_subset, dec_subset


def convert_to_Jy(data, freq):
    """Convert from K to Jy/sterrad"""

    ##1e26 because it's a Jy

    convert = (1e26*2*freq**2*k_boltz) / vel_c**2

    return data*convert

def write_srclist(ra, dec, ra_subset, dec_subset, jystrI, jystrQ, jystrU, jystrV, jystr_subset, freq, nside, nside_subset, filename):

    jystr_subset = convert_to_Jy(jystr_subset, freq)

    #Go from jy/str to jy/pixel by multiplying by pixel area in stra
    jyI = jystrI * hp.nside2pixarea(nside, degrees=False)
    jyQ = jystrQ * hp.nside2pixarea(nside, degrees=False)
    jyU = jystrU * hp.nside2pixarea(nside, degrees=False)
    jyV = jystrV * hp.nside2pixarea(nside, degrees=False)
    jy_subset = jystr_subset * hp.nside2pixarea(nside_subset, degrees=False)

    with fits.open('catalogs/EDA2_159-408MHz_SI_wPriori_2049.fits') as hdu:
        si_subset = hdu[0].data

    #total_len = len(jyI) + len(jy_subset)
    #total_len = len(jyI)
    total_len = len(jy_subset)

    with open(filename, 'w') as outfile:
        outfile.write(f"SOURCE EDA2_prior_mono_si P {total_len:} G 0 S 0 0\n")
        #for ra, dec, jyI, jyQ, jyU, jyV in zip(ra, dec, jyI, jyQ, jyU, jyV):
        #    outfile.write(f"COMPONENT POINT {ra*(1/15.0):.10f} {dec:.10f}\n")
        #    #outfile.write(f"LINEAR {freq:.9e} {jyI:.10f} 0 0 0 -2.5\n")
        #    outfile.write(f"LINEAR {freq:.9e} {jyI:.10f} {jyQ:.10f} {jyU:.10f} {jyV:.10f} -2.5\n")
        #    outfile.write(f"ENDCOMPONENT\n")
        for ra, dec, jyI, si  in zip(ra_subset.flatten(), dec_subset.flatten(), jy_subset.flatten(), si_subset.flatten()):
            print(ra, dec)
            print(f"COMPONENT POINT {ra*(1/15.0):.10f} {dec:.10f}\n")
            outfile.write(f"COMPONENT POINT {ra*(1/15.0):.10f} {dec:.10f}\n")
            outfile.write(f"LINEAR {freq:.9e} {jyI:.10f} 0 0 0 -{si:.10f}\n")
            outfile.write(f"ENDCOMPONENT\n")
        outfile.write(f"ENDSOURCE\n")

    return jy

if __name__ == '__main__':


    nside = 2048
    nside_subset = 2048

    jystrI, jystrQ, jystrU, jystrV, jystr_subset, ra, dec, ra_subset, dec_subset  = read_in_diffuse(
                                      "catalogs/byrne_interp2048_I.fits","catalogs/byrne_interp2048_Q.fits","catalogs/byrne_interp2048_U.fits","catalogs/byrne_interp2048_V.fits","catalogs/EDA2_159MHz_I_wPriori_mono_2049.fits",
                                      "catalogs/byrne_interp2048_inds.fits", "catalogs/gsm_182MHz_nomono_nogalaxy_2048_subset_inds.fits") 

    #normally 182e6
    #filename = f"byrne_gsm_182mhz_Jysr_nomono_nogalaxy_2048.txt"
    filename = f"EDA2_prior_mono_2048_si_gp25.txt"
    fluxes = write_srclist(ra, dec, ra_subset, dec_subset, jystrI, jystrQ, jystrU, jystrV, jystr_subset, 159e6,
                           nside, nside_subset, filename)
