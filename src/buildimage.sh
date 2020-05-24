# BI - Build Image

# BI is an associative array that holds data specific to building an image.
declare -A BI

# Declare externally defined variables ----------------------------------------

# Defined in GL (globals.sh)
declare OK ERROR STDERR

# Getters/Setters -------------------------------------------------------------

# BI_setflag_useprebuiltimage setter sets the useprebuiltimage array item.
# This is called by the parser.
BI_setflag_useprebuiltimage() {
  BI[useprebuiltimage]="$1"
}

# BI_k8sver outputs the value of the BI[k8sver], the kubernetes version to be
# installed.
# Args: None expected.
BI_k8sver() {
  printf '%s' "${BI[baseimagename]}"
}

# BI_baseimagename outputs the value of the BI[baseimagename].
# Args: None expected.
BI_baseimagename() {
  printf '%s' "${BI[baseimagename]}"
}

# Public Functions ------------------------------------------------------------

# BI_new sets the initial values for the BI associative array.
# This function is called by parse_options once it knows which component is
# being requested but before it sets any array members.
# Args: None expected.
BI_new() {
  BI[k8sver]="1.18.2"
  BI[baseimagename]="mok-centos-7"
  BI[useprebuiltimage]=
  BI[dockerbuildtmpdir]=
  BI[runwithprogress_output]=
}

# BI_usage outputs help text for the build image component.
# It is called by PA_usage().
# Args: None expected.
BI_usage() {

  cat <<'EnD'
BUILD subcommands are:
 
  image - Creates the docker 'mok-centos-7' container image.
 
build image options:
 
 Format:
  build image

 Flags:
  --get-prebuilt-image - Instead of building a 'node' image
         locally, download it from a container registry instead.

EnD
}

# BI_cleanup removes temporary files created during the build.
# This function is called by the 'cleanup' trap only.
# Args: None expected.
BI_cleanup() {
  [[ -e ${BI[dockerbuildtmpdir]} ]] &&
    [[ ${BI[dockerbuildtmpdir]} == "/var/tmp/"* ]] && {
    rm -rf "${BI[dockerbuildtmpdir]}" || {
      printf 'ERROR: "rm -rf %s" failed.\n' "${BI[dockerbuildtmpdir]}" \
        >"${STDERR}"
      err || return
    }
  }
}

# BI_check_valid_options checks if arg1 is in a list of valid build image
# options. This function is called by the parser.
# Args: arg1 - the option to check.
BI_check_valid_options() {

  local opt validopts=(
    "--help"
    "-h"
    "--get-prebuilt-image"
  )

  for opt in "${validopts[@]}"; do
    [[ ${1} == "${opt}" ]] && return
  done

  BI_usage
  printf 'ERROR: "%s" is not a valid "build image" option.\n' "${1}" \
    >"${STDERR}"
  return "${ERROR}"
}

# BI_sanity_checks is expected to run some quick and simple checks to
# see if it has all it's key components. For build image this does nothing.
# This function should not be deleted as it is called in main.sh.
# Args: None expected.
BI_sanity_checks() { :; }

# BI_build_image builds the base image used for masters and workers.
# This function is called in main.sh.
# Args: None expected.
BI_build_image() {

  local retval=0
  _BI_build_container_image
  retval=$?

  if [[ ${retval} -eq ${OK} ]]; then
    : # We only need the tick - no text
  else
    printf 'Image build failed\n' >"${STDERR}"
    err
  fi

  return "${retval}"
}

# Private Functions -----------------------------------------------------------

# _BI_build_container_image creates the docker build directory in
# dockerbuildtmpdir then calls docker build to build the image.
# Args: No args expected.
_BI_build_container_image() {

  local cmd retval tagname buildargs text

  _BI_create_docker_build_dir || return

  buildargs=$(_BI_get_build_args_for_k8s_ver "${BI[k8sver]}") || return
  tagname="${BI[baseimagename]}-v${BI[k8sver]}"

  local imgprefix
  imgprefix=$(CU_imgprefix) || err || return
  if [[ -z ${BI[useprebuiltimage]} ]]; then
    cmd="docker build \
      -t "${imgprefix}local/${tagname}" \
      --force-rm \
      ${buildargs} \
      ${BI[dockerbuildtmpdir]}/${BI[baseimagename]}"
    text="Creating"
  else
    cmd="docker pull mclarkson/${tagname}"
    text="Downloading"
  fi

  run_with_progress \
    "    ${text} base image, '${tagname}'" "${cmd}"

  retval=$?
  [[ ${retval} -ne 0 ]] && {
    local runfile
    runfile=$(UT_get_runfile) || err || return
    printf 'ERROR: Docker returned an error, shown below\n\n' >"${STDERR}"
    cat "${runfile}" >"${STDERR}"
    printf '\n' >"${STDERR}"
    return "${ERROR}"
  }
}

# _BI_get_build_args_for_k8s_ver sets the buildargs variable that is added
# to the 'podman build ...' command line.
# Args: None expected
_BI_get_build_args_for_k8s_ver() {

  local buildargs

  case "${BI[k8sver]}" in
  "1.18.2")
    buildargs="--build-arg"
    buildargs="${buildargs} CRIO_VERSION=1.18"
    buildargs="${buildargs} --build-arg"
    buildargs="${buildargs} CRICTL_VERSION=v1.18.0"
    buildargs="${buildargs} --build-arg"
    buildargs="${buildargs} K8SBINVER=-1.18.2"
    ;;
  *)
    printf 'INTERNAL ERROR: This should not happen.' >"${STDERR}"
    err || return
    ;;
  esac

  printf '%s' "${buildargs}"
}

# _BI_create_docker_build_dir creates a docker build directory in
# /var/tmp/tmp.XXXXXXXX
# Args: None expected
_BI_create_docker_build_dir() {

  BI[dockerbuildtmpdir]="$(mktemp -d -p /var/tmp)" || {
    printf 'ERROR: mktmp failed.\n' >"${STDERR}"
    err || return
  }

  # The following comments should not be removed or changed.
  # embed-dockerfile.sh adds a base64 encoded tarball and
  # unpacking code between them.

  #mok-centos-7-tarball-start
  #mok-centos-7-tarball-end
}

# vim helpers -----------------------------------------------------------------
#include globals.sh
# vim:ft=sh:sw=2:et:ts=2:
