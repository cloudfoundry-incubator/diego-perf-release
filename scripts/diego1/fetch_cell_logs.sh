source $(dirname $0)/bosh_wrapper.sh

if [ -z "$2" ]; then
  echo "Usage: $0 <num_cells> <download_dir>"
  echo "       <num_cells> must be one of '10', '20', '50', or '100'"
  exit 1
fi

set -x -e -u

num_cells=$1
download_dir=$2

fast_bosh target diego1
fast_bosh deployment ~/workspace/deployments-runtime/diego-1/deployments/${num_cells}-cell-experiment/diego.yml

mkdir -p ${download_dir}

for job in cell_z1 cell_z2; do
  for i in $(seq 0 $((${num_cells} / 10 - 1))); do
    for index in $(seq $(($i * 5)) $(($i * 5 + 4))); do
      (
        vm_log_dir="${download_dir}/${job}-${index}"
        mkdir -p ${vm_log_dir}
        if [ "$(ls -A ${vm_log_dir})" ]; then
          echo "Already populated ${vm_log_dir}, skipping..."
        else
          fast_bosh logs $job $index --only 'garden-linux/garden-linux.stdout*,executor/executor.stdout*,rep/rep.stdout*,receptor/receptor.stdout*' --dir ${vm_log_dir}
          cd ${vm_log_dir}
          tar -xzvf *
          gunzip -r .
        fi
      ) &
    done
    wait
  done
done