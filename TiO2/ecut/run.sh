#!/bin/bash
#SBATCH --job-name=ecut 	                     # Job name (sesuaikan sesuai kebutuhan)
#SBATCH --partition=short                    # Pilih partisi: short | medium-small | medium-large | long | very-long
#SBATCH --ntasks=64                            # Jumlah total proses MPI
#SBATCH --nodes=1                             # Maksimum jumlah node yang digunakan
#SBATCH --ntasks-per-node=64                   # Jumlah proses per node
#SBATCH --mem=64G                             # Memori per node
#SBATCH --time=01-00:00                        # Waktu maksimum eksekusi (hh:mm:ss)
#SBATCH --output=ecut.log                # Log output dan error (berdasarkan Job ID)

# Informasi dasar tentang job
echo "Date              = $(date)"
echo "Hostname          = $(hostname -s)"
echo "Working Directory = $(pwd)"
echo ""
echo "Number of Nodes Allocated      = $SLURM_JOB_NUM_NODES"
echo "Number of Tasks Allocated      = $SLURM_NTASKS"
echo "Number of Cores/Task Allocated = $SLURM_CPUS_PER_TASK"

# Load module MPI dan Quantum ESPRESSO
module load openmpi4/4.1.4
module load materials/qe/7.2-openmpi 

# Convergence test of cut-off energy.
# Set a variable ecut from 20 to 80 Ry.
for ecut in 20 22 24 26 28 30 35 \
40 45 50 60 70 80 ; do
# Make input file for the SCF calculation.
# ecutwfc is assigned by variable ecut.
cat > ecut.$ecut.in << EOF
&CONTROL
calculation     = 'scf'
pseudo_dir   	= '../pseudo/'
outdir          = '../tmp'
prefix          = 'tio2'
/
&SYSTEM
ibrav           = 6
a               = 3.826
c               = 9.403
nat             = 12
ntyp            = 2
ecutwfc         = ${ecut}
occupations  	= 'smearing'
smearing     	= 'gaussian'
degauss      	= 0.02
/
&ELECTRONS
mixing_beta     = 0.4
conv_thr        = 1.0d-6
/
ATOMIC_SPECIES
O    15.999  O.pbe-n-kjpaw_psl.1.0.0.UPF
Ti   47.867  Ti.pbe-spn-kjpaw_psl.1.0.0.UPF
ATOMIC_POSITIONS {angstrom}
Ti    0.000000   0.000000   0.000000
Ti    0.000000   1.891270   2.403755
Ti    1.891270   1.891270   4.807511
Ti    1.891270   0.000000   7.211266
O     0.000000   0.000000   1.991772
O     0.000000   1.891270   4.395527
O     1.891270   1.891270   6.799283
O     1.891270   0.000000   9.203038
O     0.000000   1.891270   0.411983
O     0.000000   0.000000   7.623249
O     1.891270   0.000000   5.219494
O     1.891270   1.891270   2.815739

K_POINTS (automatic)
3 3 1 0 0 0
EOF
# Launch SCF Calculation Quantum ESPRESSO
mpirun -np $SLURM_NTASKS pw.x < /mgpfs/home/yfadhilah/tio2/ecut/ecut.$ecut.in > /mgpfs/home/yfadhilah/tio2/ecut/ecut.$ecut.out

# Write cut-off and total energies in calc-ecut.dat.
awk '/!/ {printf"%d %s\n",'$ecut',$5}' ecut.$ecut.out >> calc-ecut.dat
# End of for loop
done

echo "Finish            = $(date)"
