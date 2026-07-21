# Production TLS deployment

The BudgetBee API certificate observed on 2026-07-18 is issued by
`SSL.com TLS Issuing RSA CA R1` and chains directly to
`SSL.com TLS RSA Root CA 2022`.

SSL.com moved public TLS issuance to its 2022 roots in May 2026 and recommends
cross-certificates for backward compatibility. A live SSL Labs test on
2026-07-18 graded the SNI endpoint A, reported no chain issues, trusted its
Android path, and successfully simulated Android 4.4.2 through 9.0. The
certificate was therefore not the cause of the reproduced client error at
that time. Re-run these checks whenever the certificate or hosting
configuration changes.

Install the CA-provided backward-compatible bundle/full chain in LiteSpeed or
the hosting control panel when renewing or replacing the certificate. Do not
install only the leaf certificate, disable TLS verification in Flutter, or
package a private trust override in the APK.

Deployment checklist:

1. Download the bundle for the exact issued certificate from the SSL.com
   repository or the hosting provider. It must contain the leaf and all
   required intermediates/cross-certificate in the CA-prescribed order.
2. Configure the HTTPS virtual host to serve that bundle as its certificate
   chain/fullchain and reload LiteSpeed.
3. Verify the server-sent chain (not merely a desktop's locally completed
   chain):

   ```bash
   openssl s_client -connect budgetbee.crowdzonebd.com:443 \
     -servername budgetbee.crowdzonebd.com -showcerts </dev/null
   ```

4. Run a public TLS chain test and test registration on the oldest physical
   Android version supported by the APK. Confirm there is no
   `HandshakeException` in `adb logcat`.

The Flutter client intentionally keeps normal certificate and hostname
verification enabled.
