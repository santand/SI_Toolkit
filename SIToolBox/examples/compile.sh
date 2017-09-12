#rm ben *.o *~

#export LD_LIBRARY_PATH=/opt/software/intel/impi/4.1.0.024/intel64/bin:$LD_LIBRARY_PATH


mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c test_lm2n.f90  -o test_lm2n.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c test_n2lm.f90  -o test_n2lm.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c test_Clebsch2OneD.f90  -o test_Clebsch2OneD.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c test_CalcBipoSH.f90  -o test_CalcBipoSH.o -fopenmp
mpif90 -O -I/home/sdas33/HOME/Healpix_2.15a/include -c test_slatec.f90  -o test_slatec.o -fopenmp
mpif90 -O -c test_readClebs.f90 -o test_readClebs.o -fopenmp



mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o test_n2lm test_n2lm.o ../lib/libsubroutines.a -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp

mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o test_lm2n test_lm2n.o ../lib/libsubroutines.a -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp

mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o test_Clebsch2OneD test_Clebsch2OneD.o ../lib/libsubroutines.a -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp

mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o test_CalcBipoSH test_CalcBipoSH.o ../lib/libsubroutines.a -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp

mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o test_slatec test_slatec.o ../lib/libslatec.a

mpif90 -I/home/sdas33/HOME/Healpix_2.15a/include -mp -o test_readClebs test_readClebs.o ../lib/libsubroutines.a ../lib/libslatec.a -L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio -fopenmp -xopenmp

#rm berr.err
rm bout.out
#bsub -n 4 -o bout.out -e berr.err mpirun -np 4 ./ben
#mpirun -np 8 ./ben
