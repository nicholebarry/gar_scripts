import healpy as hp
import numpy as np
from astropy.io import fits
from astropy import units as u
from astropy.coordinates import SkyCoord
from sklearn.cluster import KMeans

import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt

k_boltz = 1.38064852e-23
vel_c = 299792458.0



def create_spectral_index_map(SI_fits, catalog_dir, make_plots=1):
    ## Create a filled spectral index map, and interpolate to a higher resolution
    
    ## Read in the spectral index map
    si_EDA = hp.read_map(SI_fits)

    ## Calculate the ra, dec of each pixel
    ## Mike's map is originally nside = 64
    pix_inds = np.arange(hp.nside2npix(64)) 
    l, b = hp.pix2ang(64,pix_inds,lonlat=True)
    cel_coords = SkyCoord(l*u.deg, b*u.deg, frame='icrs')
    ra = cel_coords.icrs.ra.value
    dec = cel_coords.icrs.dec.value

    ## Find the holes from bright A-team sources and their ra/decs
    missing_inds = np.argwhere(si_EDA < 0)
    reshaped_missing_inds = missing_inds.reshape(missing_inds.size)
    ra_holes = ra[reshaped_missing_inds]
    dec_holes = dec[reshaped_missing_inds]

    ## Prior: there are 9 holes
    ## Use machine learning to group the ra,decs into 9 groups
    n_holes=9
    data = list(zip(ra_holes, dec_holes))
    kmeans = KMeans(n_clusters=n_holes)
    kmeans.fit(data)
      
    ## Artificially fill each hole  
    SI_holes=[]
    si_EDA_filled = np.copy(si_EDA)
    for hole_i in range(n_holes):
        inds = reshaped_missing_inds[np.argwhere(kmeans.labels_ == hole_i)]
        ra_hole = ra[inds]
        dec_hole = dec[inds]
        around_hole_inds = np.argwhere((ra < (np.amax(ra_hole) + 2.)) & (ra > (np.amin(ra_hole) - 2.)) &
                                        (dec < (np.amax(dec_hole) + 2.)) & (dec > (np.amin(dec_hole) - 2.)) &
                                        (si_EDA > 1))
        SI_holes = np.append(SI_holes, np.average(si_EDA[around_hole_inds]))
        si_EDA_filled[inds] = np.average(si_EDA[around_hole_inds])
    
    ## Interpolate to nside = 2048  
    si_EDA_filled_up = hp.pixelfunc.ud_grade(si_EDA_filled,2048,order_in='RING')
    si_EDA_up = hp.pixelfunc.ud_grade(si_EDA,2048,order_in='RING')

    if make_plots == 1:
        ## Make diagnostic plots

        ## Recreate ra dec to match the interpolated map
        pix_inds = np.arange(hp.nside2npix(2048)) 
        l, b = hp.pix2ang(2048,pix_inds,lonlat=True)
        cel_coords = SkyCoord(l*u.deg, b*u.deg, frame='icrs')
        ra = cel_coords.icrs.ra.value
        dec = cel_coords.icrs.dec.value

        ## Plot 1 -- SI map without filled holes
        fig = plt.figure(figsize=(10,10))

        hp.mollview(si_EDA_up, sub=(2,1,1), fig=fig,title='Interpolated Spectral Index of Diffuse Emission',min=1.8,max=3.0)
        ax2 = fig.add_subplot(2,1,2)
        ax2.scatter(ra,dec,c=si_EDA_up,marker='.',vmin=1.8,vmax=3.0)
        ax2.plot(266.416833333,-29.0078055556,'ro',mfc='none',label="Where gal centre should be")
        ax2.set_xlabel('RA (deg)')
        ax2.set_ylabel('Dec (deg)')
        ax2.legend(loc='upper left')

        fig.savefig(catalog_dir + 'si_EDA2.png',bbox_inches='tight')
        plt.close()

        ## Plot 2 -- SI map with filled holes
        fig = plt.figure(figsize=(10,10))

        hp.mollview(si_EDA_filled_up, sub=(2,1,1), fig=fig,title='Interpolated Spectral Index of Diffuse Emission, Filled',min=1.8,max=3.0)
        ax2 = fig.add_subplot(2,1,2)
        ax2.scatter(ra,dec,c=si_EDA_filled_up,marker='.',vmin=1.8,vmax=3.0)
        ax2.plot(266.416833333,-29.0078055556,'ro',mfc='none',label="Where gal centre should be")
        ax2.set_xlabel('RA (deg)')
        ax2.set_ylabel('Dec (deg)')
        ax2.legend(loc='upper left')

        fig.savefig(catalog_dir + 'si_EDA2_filled.png',bbox_inches='tight')
        plt.close()

    return si_EDA_filled_up



def read_in_diffuse(filename_data, catalog_dir, nside=2048, make_plots=1):
    ## Read in Mike's hpx map with healpy (or it will break)
    ## Remove the monopole to be closer to an interferometer map
    ## Upgrade the map to the proper resolution for point-source breakdown (MWA resolution)

    
    map_EDA = hp.read_map(filename_data)

    ## Remove just the monopole
    data_lowres = hp.pixelfunc.remove_monopole(map_EDA, nest=False, gal_cut=0, copy=True, verbose=True)
    data = hp.pixelfunc.ud_grade(data_lowres,nside,order_in='RING')

    ## Generate ra/dec from the healpix index
    pix_inds = np.arange(hp.nside2npix(nside))
    l, b = hp.pix2ang(nside,pix_inds,lonlat=True)
    cel_coords = SkyCoord(l*u.deg, b*u.deg, frame='icrs')
    ra = cel_coords.icrs.ra.value
    dec = cel_coords.icrs.dec.value 

    ## Optionally cut on the Galactic plane
    ## i.e. make a Galactic plane model only
    #l = cel_coords.galactic.l.value
    #b = cel_coords.galactic.b.value
    #galactic_plane_inds = np.argwhere((b < 25) & (b > -25))
    #ra_subset = ra[galactic_plane_inds]
    #dec_subset = dec[galactic_plane_inds]
    #data = data[galactic_plane_inds]

    if make_plots == 1:
        ## Make diagnostic plots
        ## Plot 1 -- Galactic plane in K
        fig = plt.figure(figsize=(10,10))

        hp.mollview(data, sub=(2,1,1), fig=fig,title='Interpolated EDA2 map in K',min=-100,max=7000)
        ax2 = fig.add_subplot(2,1,2)
        ax2.scatter(ra,dec,c=data,marker='.',vmin=-200,vmax=8000)
        ax2.plot(266.416833333,-29.0078055556,'ro',mfc='none',label="Where gal centre should be")
        ax2.set_xlabel('RA (deg)')
        ax2.set_ylabel('Dec (deg)')
        ax2.legend(loc='upper left')

        fig.savefig(catalog_dir + 'EDA2_map.png',bbox_inches='tight')
        plt.close()


    return data, ra, dec


def convert_to_Jy(data, freq):
    """Convert from K to Jy/sterrad"""

    ##1e26 because it's a Jy

    convert = (1e26*2*freq**2*k_boltz) / vel_c**2

    return data*convert


def write_srclist(ra, dec, jystr_data, si_data, filename, freq=159e6, nside=2048):

    total_len = len(jystr_data)

    jypix_data = jystr_data * hp.nside2pixarea(nside, degrees=False)

    with open(filename, 'w') as outfile:
        outfile.write("SOURCE EDA2_prior_mono_si P "+str(total_len)+" G 0 S 0 0\n")
        #for ra, dec, jyI, jyQ, jyU, jyV in zip(ra, dec, jyI, jyQ, jyU, jyV):
        #    outfile.write(f"COMPONENT POINT {ra*(1/15.0):.10f} {dec:.10f}\n")
        #    #outfile.write(f"LINEAR {freq:.9e} {jyI:.10f} 0 0 0 -2.5\n")
        #    outfile.write(f"LINEAR {freq:.9e} {jyI:.10f} {jyQ:.10f} {jyU:.10f} {jyV:.10f} -2.5\n")
        #    outfile.write(f"ENDCOMPONENT\n")
        for ra, dec, jyI, si  in zip(ra.flatten(), dec.flatten(), jypix_data.flatten(), si_data.flatten()):
            outfile.write("COMPONENT POINT " + "{0:.10f}".format(ra*(1/15.0)) + " " + "{0:.10f}".format(dec) + "\n")
            outfile.write("LINEAR " + "{0:.9e}".format(freq) + " " + "{0:.10f}".format(jyI) + " 0 0 0 -" + "{0:.10f}".format(si) + "\n")
            outfile.write("ENDCOMPONENT\n")
        outfile.write("ENDSOURCE\n")

    return

if __name__ == '__main__':


    nside = 2048
    freq = 159e6
    catalog_dir = '/astro/mwaeor/nbarry/nbarry/gar_scripts/catalog_scripts/'
    make_plots = 0

    kelvin_data, ra, dec  = read_in_diffuse(catalog_dir + 'EDA2_159MHz_I_wPrior_HPXbin.fits', 
                                            catalog_dir, nside=nside, make_plots=make_plots) 
    jystr_data = convert_to_Jy(kelvin_data, freq)

    si_data = create_spectral_index_map(catalog_dir + 'EDA2prior159_Haslam408_SI_HPXbin.fits', 
                                        catalog_dir, make_plots=make_plots)

    filename = catalog_dir + "EDA2_prior_mono_2048_si.txt"
    write_srclist(ra, dec, jystr_data, si_data, filename, freq=freq, nside=nside)
