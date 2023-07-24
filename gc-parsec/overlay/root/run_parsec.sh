#!/bin/bash

gc_kernel=0
pc_workload=none
noc=0



# Input flags
while getopts k:w:i:n: flag
do
	case "${flag}" in
		k) gc_kernel=${OPTARG};;
        w) pc_workload=${OPTARG};;
        n) noc=${OPTARG};;
	esac
done

input_type=simmedium
arch=amd64-linux # Revist: currently is the arch of the host machine
minesweeper=/home/centos/asplos22-minesweeper-reproduce/lib
if [[ $gc_kernel == minesweeper ]]; then
    cd /
    if [ ! -d "home" ]; then
        mkdir home
    fi
    cd ./home
    if [ ! -d "centos" ]; then
        mkdir centos
    fi
    cd centos
    if [ ! -d "asplos22-minesweeper-reproduce" ]; then
        mkdir asplos22-minesweeper-reproduce
    fi
    cd asplos22-minesweeper-reproduce
    if [ ! -d "jemalloc-msweeper-public" ]; then
        mkdir jemalloc-msweeper-public
    fi
    if [ ! -d "minesweeper-public" ]; then
        mkdir minesweeper-public
    fi
    if [ ! -d "lib" ]; then
        mkdir lib
    fi
    
    cd /root/pkgs
    cp ./libjemalloc.so ${minesweeper}/
    cp ./libminesweeper.so ${minesweeper}/
fi

cd /root/pkgs
cp ./libgomp.so.1 /usr/lib64/



if [ $pc_workload != "none" ]; then 
    BENCHMARKS=(${pc_workload})
fi

if [ $pc_workload == "none" ]; then 
    BENCHMARKS=(blackscholes bodytrack dedup ferret fluidanimate freqmine streamcluster swaptions x264)
fi

base_dir=$PWD

if [ $gc_kernel != "minesweeper" ]; then
    echo "Configuring GC system:"
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
            if [[ $gc_kernel == minesweeper ]]; then
                ms_path=${base_dir}
                cmd="LD_PRELOAD=${minesweeper}/libminesweeper.so:${minesweeper}/libjemalloc.so time ./${benchmark} ${input}"
            fi

            if [[ $gc_kernel != minesweeper ]]; then
                cmd="time ./${benchmark} ${input}"
            fi
            echo "runing workload...."
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