mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/bestimator/bestimator.f90  -o obj/bestimator.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/bestimator/BipoSH_ALMll_isotropic_Noise.f90 -o obj/BipoSH_ALMll_isotropic_Noise.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/bestimator/BipoSH_anisotropic_noise.f90  -o obj/BipoSH_anisotropic_noise.o -fopenmp

mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/utility/fits2d.f90     -o obj/fits2d.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/utility/map2fits.f90   -o obj/map2fits.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/utility/nest2ring.f90  -o obj/nest2ring.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/utility/ring2nest.f90  -o obj/ring2nest.o -fopenmp

mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/betaestimator/beta_estimation_nonoise.f90  -o obj/beta_estimation_nonoise.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/betaestimator/beta_estimation_isotropicnoise.f90 -o obj/beta_estimation_isotropicnoise.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/betaestimator/beta_estimation_anisotropicnoise.f90 -o obj/beta_estimation_anisotropicnoise.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c src/betaestimator/betaestimator.f90  -o obj/betaestimator.o -fopenmp


mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o bin/bestimator obj/bestimator.o obj/BipoSH_ALMll_isotropic_Noise.o obj/BipoSH_anisotropic_noise.o -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp

mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o bin/fits2d    obj/fits2d.o    -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp
mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o bin/map2fits  obj/map2fits.o  -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp
mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o bin/nest2ring obj/nest2ring.o -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp
mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o bin/ring2nest obj/ring2nest.o -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp

mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o bin/betaestimator obj/betaestimator.o obj/beta_estimation_nonoise.o obj/beta_estimation_isotropicnoise.o obj/beta_estimation_anisotropicnoise.o  -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp
