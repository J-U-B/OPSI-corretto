#!/bin/bash
#===========================================================
# for all SPEC files found in this directory:
# - download Corretto MSI (if not already done)
# - build opsi packages depending on argument)
# - install built packages on depot server
# - setup this packages where outdated
#
# Jens Boettge <boettge@mpi-halle.mpg.de>
# 2026-10-05
#===========================================================

TGT_AVAIL=(mpimsp o4i mpimsp_test o4i_test o4i_test_0 o4i_test_noprefix all_prod all_test)

print_help(){
	echo -e "\nUsage: $0 <target>\n"
	echo -e "\tPossible targets:"
	for T in ${TGT_AVAIL[@]}; do echo -e "\t  - $T"; done
	echo ""
	exit 0
}

setup_outdated(){
	[[ -z "$1" ]] && return 1 || SPEC=$1
	SW_NAME=$(cat ${SPEC}   | grep '"O_SOFTWARE"'    |sed -re 's/^.*"(.+)".*$/\1/')
	SW_VER=$(cat ${SPEC}    | grep '"O_SOFTWARE_VER"'|sed -re 's/^.*"(.+)".*$/\1/')
	PKG_BUILD=$(cat ${SPEC} | grep '"O_PKG_VER"'     |sed -re 's/^.*"(.+)".*$/\1/')
	PACKAGES_FOUND=($(ls -tr1 PACKAGES/*.opsi | grep -E "${SW_NAME}_${SW_VER}-${PKG_BUILD}(~dl){0,1}.opsi$" ))
	PKG_NUM=${#PACKAGES_FOUND[@]}
	echo "[I]   Number of installable packages found: ${PKG_NUM}"
	if [ ${PKG_NUM} -gt 0 ]; then
		declare -a PRD=()
		for F in ${PACKAGES_FOUND[@]}; do X=${F##PACKAGES/}; X=${X%_*}; [[ -n $X ]] && PRD+=($X) ;done
		echo "[I]   Products to setup: ${PRD[@]}"
		for P in ${PRD[@]}; do 
			#echo    "[D]   opsi-admin -dc method custom_setupWhereOutdated ${P} false true"
			opsi-admin -dc method custom_setupWhereOutdated ${P} false true
		done
	fi
}


[[ -z $1 ]] && print_help

TGT=""
for T in ${TGT_AVAIL[@]}; do [[ "$T" == "$1" ]] && TGT=$1; done
[[ -z $TGT ]] && print_help || echo "Using target: ${TGT}"

SPECS=$(ls -1 *.json)

for S in ${SPECS}; do 
	HDR="━━━━━━━━━━┫ $S ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo -e "\n${HDR::78}"
	PD=${S%%.json}; PD=${PD##spec_}
	REL=""
	[[ ${PD} == "spec" ]] && PD="corretto" ||REL=${PD##corretto}
	[[ "${S%%.json}" =~ [0-9]+$ ]] && ALL_INC=false || ALL_INC=true
	echo -e "[I]   Product: $PD | ALL_INC=${ALL_INC} | REL='${REL}'"
	#echo    "[D]   make SPEC=${S} ALL_INC=${ALL_INC} ${TGT} install"
	make SPEC=${S} ALL_INC=${ALL_INC} ${TGT} install && setup_outdated ${S}
done
