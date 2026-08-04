#!/usr/bin/env bash
set -euo pipefail

FREECAD_VERSION="1.1.3"
FREECAD_FILE="FreeCAD_${FREECAD_VERSION}-Linux-aarch64-py311.AppImage"
FREECAD_SHA256="9a8f9f7f2802bb856f2bb70f53d536e2ae06569f4e6d718407803076104ff55e"
FREECAD_URL="https://github.com/FreeCAD/FreeCAD/releases/download/${FREECAD_VERSION}/${FREECAD_FILE}"
INSTALL_ROOT="${HOME}/.local/opt/freecad-${FREECAD_VERSION}"
BIN_DIR="${HOME}/.local/bin"
APPLICATION_DIR="${HOME}/.local/share/applications"

if [[ "$(uname -m)" != "aarch64" ]]; then
  echo "This installer is pinned for DGX Spark aarch64." >&2
  exit 1
fi

mkdir -p "${INSTALL_ROOT}" "${BIN_DIR}" "${APPLICATION_DIR}"
curl --fail --location --retry 3 "${FREECAD_URL}" --output "${INSTALL_ROOT}/${FREECAD_FILE}"
echo "${FREECAD_SHA256}  ${INSTALL_ROOT}/${FREECAD_FILE}" | sha256sum --check --strict
chmod 0755 "${INSTALL_ROOT}/${FREECAD_FILE}"

# Extraction avoids dependence on a host FUSE package and exposes FreeCADCmd.
(
  cd "${INSTALL_ROOT}"
  rm -rf squashfs-root
  "./${FREECAD_FILE}" --appimage-extract >/dev/null
)

ln -sfn "${INSTALL_ROOT}/squashfs-root/AppRun" "${BIN_DIR}/freecad"
FREECAD_CMD="$(find "${INSTALL_ROOT}/squashfs-root" -type f -iname freecadcmd -print -quit)"
if [[ -z "${FREECAD_CMD}" ]]; then
  echo "FreeCADCmd was not found in the extracted AppImage." >&2
  exit 1
fi
printf '#!/usr/bin/env bash\nexec %q freecadcmd "$@"\n' \
  "${INSTALL_ROOT}/squashfs-root/AppRun" > "${BIN_DIR}/freecadcmd"
chmod 0755 "${BIN_DIR}/freecadcmd"

printf '%s\n' \
  '[Desktop Entry]' \
  'Type=Application' \
  'Name=FreeCAD 1.1.3' \
  'Comment=Open-source parametric 3D CAD modeler' \
  "Exec=${BIN_DIR}/freecad %F" \
  "Icon=${INSTALL_ROOT}/squashfs-root/org.freecad.FreeCAD.svg" \
  'Terminal=false' \
  'Categories=Graphics;Engineering;' \
  'MimeType=application/x-extension-fcstd;' \
  > "${APPLICATION_DIR}/org.freecad.FreeCAD.desktop"
chmod 0644 "${APPLICATION_DIR}/org.freecad.FreeCAD.desktop"
command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "${APPLICATION_DIR}" || true

"${BIN_DIR}/freecadcmd" --version
echo "FREECAD_INSTALL_PASS version=${FREECAD_VERSION}"
