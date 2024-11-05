#!/bin/bash

example_dir=$(dirname $(realpath $0))
proj_dir=$(cd ${example_dir}/../../../.. ; pwd)
rundir=`pwd`

use_project_venv=1

if test $use_project_venv -eq 1; then
    interp_bindir=${proj_dir}/packages/python/bin
    interp=$interp_bindir/python
    export PYTHONPATH=${proj_dir}/src:${example_dir}
else
    interp_bindir=$rundir/example_venv/bin
    interp=$interp_bindir/python
    if test ! -d $rundir/example_venv; then
        echo "Creating Python virtual environment"
        python3 -m venv $rundir/example_venv
        $interp -m pip install --upgrade pip
        $interp -m pip install -r $example_dir/requirements.txt
    fi
    export PYTHONPATH=${example_dir}
fi

source ${interp_bindir}/activate

hdl_if_libs=$(${interp} -c "import hdl_if ; print(' '.join(hdl_if.libs()))")
hdl_if_share=$(${interp} -c "import hdl_if ; print(hdl_if.share())")

echo "hdl_if_libs=${hdl_if_libs}"
echo "libpython=${libpython}"

xmsim_args=""
for lib in ${hdl_if_libs}; do
    lib=$(echo $lib | sed -e 's/\.so//')
    xmsim_args="$xmsim_args -sv_lib ${lib}"
done

# Generate the Wrapper API
 ${interp} -m hdl_if api-gen-sv -m call_sv_bfm \
     -p call_sv_bfm_pkg -o call_sv_bfm_pkg.sv
if test $? -ne 0; then exit 1; fi

xmvlog -64bit -sv \
    +incdir+${hdl_if_share}/dpi \
    ${hdl_if_share}/dpi/pyhdl_if.sv \
    ${example_dir}/call_sv_bfm_pkg.sv 
    ${example_dir}/wb_init_bfm.sv 
    ${example_dir}/call_sv_bfm.sv 
if test $? -ne 0; then exit 1; fi

xmelab -64bit -snap call_sv_bfm:snap call_sv_bfm -createdebugdb

xmsim -64bit call_sv_bfm:snap ${xmsim_args}




