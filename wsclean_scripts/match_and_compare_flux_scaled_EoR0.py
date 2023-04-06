from numpy import *
import matplotlib.pyplot as plt
from numpy import *
import statsmodels.api as sm
from astropy.table import Table
from scipy.optimize import curve_fit
from scipy.optimize import minimize
from astropy.wcs import WCS
import aplpy
from statsmodels.robust.scale import mad
import statsmodels.api as sm
from my_plotting_lib import add_colourbar
from astropy.io import fits


base_table = Table.read('LoBES_EoR0_FULL_FINAL_SpecGaussModCat_03MAR2022.fits')

def fit_spectra(name,base_table=base_table):
    index = where(base_table['NAME'] == name)[0][0]

    ra = base_table['RA'][index]
    dec = base_table['DEC'][index]

    name = base_table['NAME'][index]
    S107 = base_table['INT_FLX107'][index]
    S115 = base_table['INT_FLX115'][index]
    S122 = base_table['INT_FLX122'][index]
    S130 = base_table['INT_FLX130'][index]
    S143 = base_table['INT_FLX143'][index]
    S151 = base_table['INT_FLX151'][index]
    S158 = base_table['INT_FLX158'][index]
    S166 = base_table['INT_FLX166'][index]
    S174 = base_table['INT_FLX174'][index]
    S181 = base_table['INT_FLX181'][index]
    S189 = base_table['INT_FLX189'][index]
    S197 = base_table['INT_FLX197'][index]
    S204 = base_table['INT_FLX204'][index]
    S212 = base_table['INT_FLX212'][index]
    S220 = base_table['INT_FLX220'][index]
    S227 = base_table['INT_FLX227'][index]

    e_S107 = base_table['ERR_INT_FLX107'][index]
    e_S115 = base_table['ERR_INT_FLX115'][index]
    e_S122 = base_table['ERR_INT_FLX122'][index]
    e_S130 = base_table['ERR_INT_FLX130'][index]
    e_S143 = base_table['ERR_INT_FLX143'][index]
    e_S151 = base_table['ERR_INT_FLX151'][index]
    e_S158 = base_table['ERR_INT_FLX158'][index]
    e_S166 = base_table['ERR_INT_FLX166'][index]
    e_S174 = base_table['ERR_INT_FLX174'][index]
    e_S181 = base_table['ERR_INT_FLX181'][index]
    e_S189 = base_table['ERR_INT_FLX189'][index]
    e_S197 = base_table['ERR_INT_FLX197'][index]
    e_S204 = base_table['ERR_INT_FLX204'][index]
    e_S212 = base_table['ERR_INT_FLX212'][index]
    e_S220 = base_table['ERR_INT_FLX220'][index]
    e_S227 = base_table['ERR_INT_FLX227'][index]

    all_freqs = []
    all_fluxes = []
    all_ferrs = []

    these_fluxes = [S107, S115, S122, S130, S143, S151, S158, S166, S174, S181, S189, S197, S204, S212, S220, S227]
    these_ferrs = [e_S107, e_S115, e_S122, e_S130, e_S143, e_S151, e_S158, e_S166, e_S174, e_S181, e_S189, e_S197, e_S204, e_S212, e_S220, e_S227]
    these_freqs = [107.0, 115.0, 122.0, 130.0, 143.0, 151.0, 158.0, 166.0, 174.0, 181.0, 189.0, 197.0, 204.0, 212.0, 220.0, 227.0]

    for ind in xrange(len(these_fluxes)):
        if isnan(these_fluxes[ind]):
            pass
        else:
            all_freqs.append(these_freqs[ind])
            all_fluxes.append(these_fluxes[ind])
            all_ferrs.append(these_ferrs[ind])

    all_freqs = array(all_freqs)
    all_fluxes = array(all_fluxes)
    all_ferrs = array(all_ferrs)

    def fit_line(freqs, SI, intercept):
        return freqs*SI + intercept

    def get_chi(func,params,x_data,y_data,errors):
        ssr = sum(((y_data - func(x_data,*params)) / errors)**2)
        return ssr / (len(y_data) - len(params))

    def test_function(func=None,label=None,linestyle=None,x_data=None,y_data=None,errors=None,do_exp=False,p0=False):
        if p0:
            popt, pcov = curve_fit(func, x_data, y_data, sigma=errors, absolute_sigma=True,maxfev=1000000,p0=p0)
        else:
            popt, pcov = curve_fit(func, x_data, y_data, sigma=errors, absolute_sigma=True,maxfev=500000)

        chi_resid = get_chi(func, popt, x_data, y_data, errors)

        return popt,chi_resid

    # print('----------------------------------------')
    # print(log(all_freqs))
    # print(log(all_fluxes))

    if len(all_freqs) < 2:
        extrap_flux,extrap_flux_170,chi_resid = -1.0,-1.0,9001.0
    else:

        popt,chi_resid = test_function(func=fit_line,label='Power Law',linestyle='r--',x_data=log(all_freqs),y_data=log(all_fluxes),errors=all_ferrs/all_fluxes,do_exp=True)
        p01,p02 = float(popt[0]),float(popt[1])
        extrap_flux = exp(fit_line(log(182.235), *popt))
        extrap_flux_170 = exp(fit_line(log(170.835), *popt))

    return extrap_flux,chi_resid,ra,dec,extrap_flux_170

def least_squares(parameters,model_function,x_range,observed):
    '''Takes some model_function (must be a function), and calculates
    the model prediction for the given x_range (array) and parameters (array).
    It then calculates the sum of the differences between the model values
    and the observed (array) values'''
    ##Feed the x_range, and all parameters (using *) into the model_funcion
    ##to make a model prediction
    expected = model_function(x_range,*parameters)
    ##return the least squares sum (S in the equation above)
    return sum((observed - expected)**2)

def gauss(x,mu,sigma):
    '''Calculates the probability density function for the gaussian
    for a given x, mu, sigma'''
    return (1 / (sqrt(2*pi*sigma**2))) * exp(-((x - mu)**2 / (2*sigma**2)))


def get_flux(table):
    index = where(table['NAME'] == name)[0][0]

    return table['INT_FLUX'][index]

obs_id = '1088974064_0000'
table_galaxy = Table.read(obs_id + '_match_with_lobes_galaxy.fitss')
table_nogalaxy = Table.read(obs_id + '_match_with_lobes_nogalaxy.fits')

galaxy_names = table_new['NAME']
nogalaxy_names = table_old['NAME']

galaxy_ratios = []
nogalaxy_ratios = []
comp_ratios = []
ras = []
decs = []


for name in galaxy_names:
    if name in nogalaxy_names:
        extrap_flux,chi_resid,ra,dec,extrap_flux_170 = fit_spectra(name)
        galaxy_flux = get_flux(table_galaxy)
        nogalaxy_flux = get_flux(table_nogalaxy)

        if extrap_flux > 0.5 and chi_resid < 10.0:

            galaxy_ratios.append(galaxy_flux / extrap_flux)
            no_galaxy_ratios.append(nogalaxy_flux / extrap_flux)
            comp_ratios.append(galaxy_flux / nogalaxy_flux)
            ras.append(ra)
            decs.append(dec)

num_bins = 10
def hist_plot_and_fit(ax,ratios,color,label,do_fit=True):

    histted,bins,summin = ax.hist(ratios,histtype='stepfilled',linewidth=0.1,alpha=0.1,bins=num_bins,density=True,color=color)
    ax.hist(ratios,histtype='step',linewidth=2.0,label='%s (%02d sources)' %(label,len(ratios)),bins=num_bins,density=True,color=color)

    if do_fit:
        bin_cents = (bins[:-1]+bins[1:]) / 2.0

        initial_guess = array([0,2])
        out = minimize(least_squares,initial_guess,args=(gauss,bin_cents,histted))
        params = out.x

        ax.plot(bin_cents,gauss(bin_cents,*params),color=color,linestyle='--',label='$\mu$ %.2f $\sigma$ %.2f' %(params[0],abs(params[1])))

def plot_by_kde(ax,data,colour,label):
    kde = sm.nonparametric.KDEUnivariate(data)
    kde.fit()

    med = median(data)

    ax.fill(kde.support, kde.density,  facecolor=colour, alpha=0.2,edgecolor=colour)
    ax.plot(kde.support, kde.density, color=colour,linewidth=1.5,label='KDE '+label+' $\mu =$ %.2f' %med,linestyle='-')
    ax.axvline(med,color=colour,linestyle='--')


fig = plt.figure(figsize=(8,10))
ax1 = fig.add_subplot(211)
ax2 = fig.add_subplot(212)

# hist_plot_and_fit(ax1,new_ratios,'C0','New shapelet')
# hist_plot_and_fit(ax1,andre_ratios,'C1','Andre')

plot_by_kde(ax1,nogalaxy_ratios,'C0','nogalaxy')
plot_by_kde(ax1,galaxy_ratios,'C1','galaxy')

# hist_plot_and_fit(ax2,comp_ratios,'C3','Comp',do_fit=False)
# ax2.axvline(median(comp_ratios),linestyle='--',color='C3',label='Median = %.2f' %median(comp_ratios))

plot_by_kde(ax2,array(comp_ratios,dtype=float64),'C3','Ratio galaxy / nogalaxy')

ax1.legend()
ax2.legend()

ax1.set_xlabel('Measured Flux / Extrapolated GLEAM Flux')
ax1.set_ylabel('Prob density')


ax1.set_title('There are %d sources compared for EoR0' %(len(ras)))
# ax2.set_title('Compare new shapes to Andre')

ax2.set_xlabel('Ratio Int Flux galaxy / nogalaxy')
ax2.set_ylabel('Prob density')

fig.savefig(obs_id + '_flux_ratios.png',bbox_inches='tight')
plt.close()


# base_hdu = fits.open('EoR0_wsclean_beam_avg.fits')
# avg_data = base_hdu[0].data[0,0,:,:]
# wcs = WCS(base_hdu[0].header)

# xmesh,ymesh = meshgrid(arange(4096),arange(4096))

# ra_mesh,dec_mesh,_,_, = wcs.all_pix2world(xmesh,ymesh,0,0,0)
# ra_mesh[where(ra_mesh > 180.0)] -= 360.0
# maxpos = where(avg_data == amax(avg_data))

# maxy = maxpos[0][0]
# maxx = maxpos[1][0]

# fig = plt.figure(figsize=(12,8))


# ax1 = fig.add_axes([0.1,0.4,0.35,0.5])
# ax2 = fig.add_axes([0.55,0.4,0.35,0.5])


ax3 = fig.add_axes([0.1,0.12,0.165,0.20])
ax4 = fig.add_axes([0.3,0.12,0.165,0.20])
ax5 = fig.add_axes([0.55,0.12,0.165,0.20])
ax6 = fig.add_axes([0.75,0.12,0.165,0.20])

def plot_ratios_on_sky(ax,ratios,ras,decs,label,ax_ra,ax_dec):
    normed_ratios = array(ratios) #/ max(ratios)

    # normed_ratios[where(normed_ratios > 1.2)] = 1.0
    # normed_ratios[where(normed_ratios < 0.5)] = 0.0

    plot_ras = array(ras)
    plot_decs = array(decs)
    # plot_decs[where(ratios > 1.2)] = 1.0
    # plot_ras[where(ratios > 1.2)] = 1.0

    plot_ras[where(plot_ras > 180.0)] -= 360.0

    cm = ax.scatter(plot_ras,plot_decs,c=normed_ratios,vmin=0.7,vmax=1.1,s=normed_ratios*20)
    add_colourbar(ax=ax,im=cm,fig=fig)
    ax.set_title(label)

    # ax.set_xlim(40,72)
    # ax.set_ylim(-40,-13)
    ax.set_xlabel('RA (deg)')
    ax.set_ylabel('Dec (deg)')
    ax.invert_xaxis()

    # ax.plot(50.26,-37.3493944444,'C1*',label='ForA',mec='k',ms=10)
    ax.legend()

    ax_ra.scatter(plot_ras,ratios,s=6)
    ax_dec.scatter(plot_decs,ratios,s=6)
    ax_ra.set_xlabel('RA')
    ax_dec.set_xlabel('DEC')
    # ax_ra.set_ylim(0.6,1.2)
    # ax_dec.set_ylim(0.6,1.2)

    ax_ra.axhline(1.0,linestyle='--',color='k',alpha=0.6)
    ax_dec.axhline(1.0,linestyle='--',color='k',alpha=0.6)

    # ax_ra.plot(ra_mesh[maxy,:],avg_data[maxy,:],'r-',label='Maximum wsclean beam')
    # ax_dec.plot(dec_mesh[:,maxx],avg_data[:,maxx],'r-',label='Avg wsclean beam')

    ax_ra.invert_xaxis()

ax3.set_ylabel('Ratio')
plot_ratios_on_sky(ax1,nogalaxy_ratios,ras,decs,'Nogalaxy',ax3,ax4)
plot_ratios_on_sky(ax2,galaxy_ratios,ras,decs,'Galaxy',ax5,ax6)
# fig.tight_layout()
fig.savefig(obs_id + '_flux_ratios_on_sky.png',bbox_inches='tight')


# fig = plt.figure(figsize=(8,12))
# ax1 = fig.add_subplot(321)
# ax2 = fig.add_subplot(322)
# ax3 = fig.add_subplot(323)
# ax4 = fig.add_subplot(324)
# ax5 = fig.add_subplot(325)
# ax6 = fig.add_subplot(326)
#
#
# x_sources,y_sources,_,_, = wcs.all_world2pix(ras,decs,0,0,0)
# y_sources, x_sources = around(y_sources,decimals=1),around(x_sources,decimals=1)
# y_sources, x_sources = y_sources.astype(int),x_sources.astype(int)
#
# from astropy.table import Table,Column
#
#
#
#
# plot_ras = array(ras)
# plot_decs = array(decs)
# plot_ras[where(plot_ras > 180.0)] -= 360.0
#
#
# ax1.scatter(plot_ras,new_ratios,label='Uncorrected',s=6)
# ax2.scatter(decs,new_ratios,label='Uncorrected',s=6)
#
# # ax1.plot(ra_mesh[maxy,:],avg_data[maxy,:],'r-',label='Maximum wsclean beam')
# # ax2.plot(dec_mesh[:,maxx],avg_data[:,maxx],'r-',label='Maximum wsclean beams')
#
# good_beams = where((x_sources >= 0) & (x_sources < 4096) & (y_sources >= 0) & (y_sources < 4096))
#
# beam_values = avg_data[y_sources[good_beams], x_sources[good_beams]]
# decs = array(decs)
# new_ratios = array(new_ratios)
#
#
# # ax3.scatter(plot_ras[good_beams],beam_values,label='Manual corrected',s=6)
# # ax4.scatter(decs[good_beams],beam_values,label='Manual corrected',s=6)
#
# ax3.scatter(plot_ras[good_beams],new_ratios[good_beams] / beam_values,label='Manual corrected',s=6)
# ax4.scatter(decs[good_beams],new_ratios[good_beams] / beam_values,label='Manual corrected',s=6)
#
# ax5.scatter(plot_ras,old_ratios,label='IDG Corrected',s=6)
# ax6.scatter(decs,old_ratios,label='IDG Corrected',s=6)
#
# for ax in [ax1,ax3,ax5]:
#     ax.invert_xaxis()
#     ax.set_xlabel('RA (deg)')
#
# for ax in [ax2,ax4,ax6]:
#     ax.set_xlabel('DEC (deg)')
#
# for ax in [ax1,ax2,ax3,ax4,ax5,ax6]:
#     ax.legend()
#
# fig.savefig('check_corrections_EoR0.png',bbox_inches='tight')


# t = Table()
# tras = Column(name='RA',data=ras)
# tdecs = Column(name='DEC',data=decs)
# tnews = Column(name='uncorrected',data=new_ratios)
# tolds = Column(name='corrected',data=array(old_ratios))
#
# t.add_columns([tras,tdecs,tnews,tolds])
#
# t.write('ratios_on_sky.fits',overwrite=True)
