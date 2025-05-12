const allowedOrigin = "https://bluecolab.github.io";
const allowedPath = "/react-kiosk";

if (
  location.origin !== allowedOrigin ||
  !location.pathname.startsWith(allowedPath)
) {
  location.replace(`${allowedOrigin}${allowedPath}`);
}
