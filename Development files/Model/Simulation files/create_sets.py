n_conv_set = 10 # number of converged per set
n_conv_tot = 1000 # number of converged simulations
n_conv_sim = 1 # number of converged per simulation

num_sets = int(1000/10/1)

str1 = "#!/bin/bash"
str2 = "\n\n#SBATCH --mail-type=BEGIN,END"
str3 = "\n#SBATCH --mail-user=jochemhuismans@gmail.com"
str4 = "\n\n#SBATCH -N 1"
str5 = "\n#SBATCH -t 72:00:00"
str7 = "\n  $HOME/Stata16Linux64/stata -e $HOME/StataFiles/Paper/runsimc.do $i &"
str8 = "\n\ndone"
str9 = "\nwait"

for i in range(num_sets):
    begin = i*10+1
    end = (i+1)*10
    str6 = "\n\nfor i in `seq "+str(begin)+" "+str(end)+"`; do"
    file1 = open("set"+str(i+1)+".sh", "w+", newline="\n")
    file1.writelines([str1, str2, str3, str4, str5, str6, str7, str8, str9])
    file1.close()