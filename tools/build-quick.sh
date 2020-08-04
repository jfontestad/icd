#!/usr/bin/env bash
set -eu
IFS=$'\n\t'

declare IH
old_pwd="${PWD}"
if [[ -z ${IH-} ]]; then
	for d in "${PWD}" "${PWD}"/.. "${PWD}"/../..; do
		[[ -e "${d}/DESCRIPTION" ]] &&
			IH="${d}" &&
			break

		done
fi
cd "${IH?}" || { echo "cannot cd to ${IH?}" >&2; exit 1; }
[[ -e "DESCRIPTION" ]] || {
	echo "still cannot find R package source root" >&2
	exit 1
}

# quickly build the pacakge, and put it in the current directory

declare SED=sed
command -v gsed >/dev/null && SED=gsed
Rscript -e 'Rcpp::compileAttributes()'
# insert pragmas for persistent g++ warning
"$SED" -i -e '/BEGIN_RCPP/i#pragma GCC diagnostic push\n#pragma GCC diagnostic ignored "-Wcast-function-type"' -e "/END_RCPP/a#pragma GCC diagnostic pop" src/RcppExports.cpp || exit 1
"$SED" -i -e '/R_CallMethodDef/i#pragma GCC diagnostic push\n#pragma GCC diagnostic ignored "-Wcast-function-type"' -e "/R_init_icd/i#pragma GCC diagnostic pop" src/RcppExports.cpp || exit 1

cd "${old_pwd}"
R CMD build \
	--log \
	--no-build-vignettes \
	--no-manual \
	--no-resave-data \
	"$@" \
	"${IH?}"
