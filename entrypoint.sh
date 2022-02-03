#!/bin/sh -l

set -xeuo pipefail

echo "::group::check packages"
if [ -z ${INPUT_PACKAGES} ]; then
    exit 0
else
    echo "emerge ${INPUT_PACKAGES}"
fi
echo "::endgroup::"

echo "::group::update make.conf"
cat <<EOT >> /etc/portage/make.conf
EMERGE_DEFAULT_OPTS="${INPUT_EMERGE_DEFAULT_OPTS} --jobs $(nproc) --load-average $(nproc)"
MAKEOPTS="-j$(nproc)"
PORTAGE_TMPDIR="${INPUT_PORTAGE_TMPDIR}"
FEATURES="${INPUT_FEATURES}"
ACCEPT_KEYWORDS="${INPUT_ACCEPT_KEYWORDS}"
ACCEPT_LICENSE="${INPUT_ACCEPT_LICENSE}"
EOT
cat /etc/portage/make.conf
echo "::endgroup::"


echo "::group::overlay prepare"
emerge-webrsync
eselect news read all > /dev/null
emerge app-eselect/eselect-repository dev-vcs/git
echo "::endgroup::"


echo "::group::overlay sync"
if [ ! -z "${INPUT_OVERLAY_NAME}" ]; then
    eselect repository add ${INPUT_OVERLAY_NAME} ${INPUT_OVERLAY_SYNC_TYPE} ${INPUT_OVERLAY_SYNC_URI}
    emerge --sync ${INPUT_OVERLAY_NAME}
fi
echo "::endgroup::"


echo "::group::install"
emerge ${INPUT_PACKAGES}
result=$?
echo "::endgroup::"


echo "::group::install"
for file in $(ls "${INPUT_PORTAGE_TMPDIR}/portage/*/*/temp/build.log" 2>/dev/null); do
    echo "$file:"
    cat $file
done
echo "::endgroup::"


exit $result
