#!/bin/bash

gc_kernel=none
pc_workload=none

# Input flags
while getopts k:w: flag
do
	case "${flag}" in
		k) gc_kernel=${OPTARG};;
        w) pc_workload=${OPTARG};;
	esac
done

input_type=simmedium
arch=amd64-linux # Revist: currently is the arch of the host machine

cd /root/pkgs
cp ./libgomp.so.1 /usr/lib64/

if [ $pc_workload != "none" ]; then 
    BENCHMARKS=(${pc_workload})
fi

if [ $pc_workload == "none" ]; then 
    BENCHMARKS=(blackscholes bodytrack dedup facesim ferret fluidanimate freqmine streamcluster swaptions x264)
fi

base_dir=$PWD

if [ $gc_kernel != "none" ]; then
    echo "./initialisation_${gc_kernel}.riscv"
    ./initialisation_${gc_kernel}.riscv
fi

for benchmark in ${BENCHMARKS[@]}; do
    sub_dir=apps
    if [ $benchmark == "dedup" ]; then 
        sub_dir=kernels
    fi

    if [ $benchmark == "streamcluster" ]; then 
        sub_dir=kernels
    fi

    bin_dir=${base_dir}/${sub_dir}/${benchmark}/inst/${arch}.gcc-serial/bin
    run_dir=${base_dir}/${sub_dir}/${benchmark}/run/
    command_dir=${base_dir}/commands/${input_type}


    IFS=$'\n' read -d '' -r -a commands < ${command_dir}/${benchmark}.cmd
    count=0
    for input in "${commands[@]}"; do
        echo "[======= Benchmark: ${benchmark} =======]"
        if [[ ${input:0:1} != '#' ]]; then # allow us to comment out lines in the cmd files
            cd ${run_dir}
            cp ${bin_dir}/${benchmark} $run_dir
            cmd="time ./${benchmark} ${input}"
            echo "workload=[${cmd}]"
            eval ${cmd}
            rm ./${benchmark}
            ((count++))
        fi
    done
    echo ""
done

echo ""
echo "All Done!"